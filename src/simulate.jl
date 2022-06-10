struct State
    links::SparseMatrixCSC{Float64,Int64}
    nodes::SparseVector{Float64,Int64}

    State(n) = new(spzeros(n, n), spzeros(n))

    State(links, nodes) = new(links, nodes)
end

function add_load!(state, links, containers, v, n)
    for i in 1:n, j in 1:n
        state.links[i, j] += links[i, j]
    end
    state.nodes[v] += containers
end

function rem_load!(state, links, containers, v, n)
    for i in 1:n, j in 1:n
        state.links[i, j] -= links[i, j]
    end
    state.nodes[v] -= containers
end

struct SnapShot
    state::State
    total::Float64
    selected::Int
    duration::Float64
    solving_time::Float64
    instant::Float64
end

function push_snap!(snapshots, state, total, selected, duration, solving_time, instant, n)
    links = deepcopy(state.links[1:n, 1:n])
    nodes = deepcopy(state.nodes[1:n])
    snap = SnapShot(State(links, nodes), total, selected, duration, solving_time, instant)
    push!(snapshots, snap)
end

struct Load
    occ::Float64
    node::Int
    job::Job
end

struct Unload
    occ::Float64
    node::Int
    vload::Int
    lloads::SparseMatrixCSC{Float64,Int64}
end

function inner_queue(
    g, u, j, nodes, capacities, state, algo::MinCostFlow;
    lck=ReentrantLock(), demands, links=nothing
)
    nvtx = nv(g)

    add_edge!(g, nvtx - 1, u)
    add_edge!(g, nvtx - 1, j.data_location)

    lock(lck)
    try
        state.links[nvtx-1, u] += j.frontend
        state.links[nvtx-1, j.data_location] += j.backend
    finally
        unlock(lck)
    end

    demands[nvtx-1] = -(j.backend + j.frontend)
    demands[nvtx] = j.backend + j.frontend

    best_links = spzeros(nvtx, nvtx)
    best_node = 0
    best_cost = Inf

    for (i, v) in pairs(nodes)
        node_cost = pseudo_cost(v, j.containers)
        aux_cap = nothing

        lock(lck)
        try
            aux_cap = deepcopy(state.links)
        finally
            unlock(lck)
        end

        aux_cap[i, nvtx] = j.backend + j.frontend
        f, links_cost = mincost_flow(g, demands, capacities, aux_cap, algo.optimizer)
        cost = node_cost + links_cost
        if cost < best_cost
            best_cost = cost
            best_links = f
            best_node = i
        end
    end

    rem_edge!(g, nvtx - 1, u)
    rem_edge!(g, nvtx - 1, j.data_location)


    lock(lck)
    try
        state.links[nvtx-1, u] = 0.0
        state.links[nvtx-1, j.data_location] = 0.0
    finally
        unlock(lck)
    end

    return best_links, best_cost, best_node
end

function retrieve_path(u, v, paths)
    path = Vector{Pair{Int,Int}}()
    w = v
    while w != u
        x = paths.parents[w]
        push!(path, w => x)
        w = x
    end
    return path
end

function inner_queue(
    g, u, j, nodes, capacities, state, ::ShortestPath;
    lck=ReentrantLock(), demands=nothing, links
)
    nvtx = nv(g)
    best_links = spzeros(nvtx, nvtx)
    best_node = 0
    best_cost = Inf

    node_costs = nothing
    link_costs = nothing
    lock(lck)
    try
        node_costs = map(v -> pseudo_cost(v.second, state.nodes[v.first]), pairs(nodes))
        link_costs = zeros(size(capacities))
        for i in 1:size(state.links, 1), j in 1:size(state.links, 1)
            if (i, j) ∈ keys(links)
                link_costs[i, j] = pseudo_cost(links[(i, j)], state.links[i, j])
            end
        end
    finally
        unlock(lck)
    end

    paths_user = dijkstra_shortest_paths(g, u, link_costs; trackvertices=true)
    paths_data = dijkstra_shortest_paths(g, j.data_location, link_costs; trackvertices=true)
    best_cost, best_node = findmin(paths_user.dists + paths_data.dists + [node_costs[i] for i in keys(node_costs)])

    path_user = retrieve_path(u, best_node, paths_user)
    path_data = retrieve_path(j.data_location, best_node, paths_data)

    foreach(p -> best_links[p.first, p.second] = j.frontend, path_user)
    foreach(p -> best_links[p.first, p.second] = j.backend, path_data)

    return best_links, best_cost, best_node
end

function make_df(snapshots::Vector{SnapShot}, topo; verbose=true)
    function shape_entry(s)
        entry = Vector{Pair{String,Float64}}()
        push!(entry, "selected" => s.selected)
        push!(entry, "total" => s.total)
        push!(entry, "duration" => s.duration)
        push!(entry, "solving_time" => s.solving_time)
        push!(entry, "instant" => s.instant)

        foreach(p -> push!(entry, string(p.first) => p.second / capacity(topo.nodes[p.first])), pairs(s.state.nodes))

        for (i, j) in keys(topo.links)
            push!(entry, string((i, j)) => s.state.links[i, j] / capacity(topo.links[(i, j)]))
        end

        return entry
    end

    if !isempty(snapshots)
        df = DataFrame(shape_entry(first(snapshots)))
        foreach(e -> push!(df, Dict(shape_entry(e))), snapshots[2:end])

        verbose && pretty_table(describe(df))

        return df
    else
        return DataFrame()
    end
end

function init_simulate(::Val{0})
    tasks = Vector{Load}()
    queued = Vector{Load}()
    unloads = Vector{Unload}()
    return tasks, queued, unloads
end

function init_simulate(::Val)
    tasks = Vector{Load}()
    c = Channel{Tuple{Int,Job}}(10^7)
    return tasks, c
end

function init_simulate(s, algo, tasks, start)
    times = Dict{String,Float64}()
    snapshots = Vector{SnapShot}()

    for u in s.users
        jr = u.job_requests
        j = jr.job
        p = jr.period
        t0 = max(jr.start, 0.0)
        t1 = min(jr.stop, s.duration)

        foreach(occ -> insert_sorted!(tasks, Load(occ, u.location, j)), t0:p:t1)
    end

    push!(times, "start_tasks" => time() - start)
    g, capacities = graph(s.topology, algo)
    n = nv(g) - vtx(algo)

    state = State(nv(g))
    demands = spzeros(nv(g))

    push!(times, "start_queue" => time() - start)
    return times, snapshots, g, capacities, n, state, demands
end

function simulate_loop(s, algo, speed, start, containers, args_loop, ::Val)
    tasks, c = containers
    times, snapshots, g, capacities, n, state, demands = args_loop

    all_queue = false
    all_unloaded = false
    ii = 0
    p = Progress(
        length(tasks);
        desc="Simulating with $algo at speed $speed", showspeed=true, color=:normal
    )

    push!(times, "start_tasks" => time() - start)

    for (i, t) in enumerate(tasks)
        @async begin
            sleep(t.occ / speed)
            put!(c, (t.node, t.job))
            i == length(tasks) && (all_queue = true)
        end
    end

    lck = ReentrantLock()

    while !all_queue || isready(c)
        start_iteration = time()
        ii += 1
        u, j = take!(c)

        start_solving = time() - start_iteration
        is_valid = false

        while !is_valid
            best_links, best_cost, best_node = inner_queue(g, u, j, s.topology.nodes, capacities, state, algo; links=s.topology.links, lck, demands)

            n = nv(g) - vtx(algo)

            valid_links, valid_nodes = nothing, nothing
            lock(lck)
            try
                compare_links(i, j) = state.links[i, j] + best_links[i, j] .< capacities[i, j]
                valid_links = mapreduce(e -> compare_links(src(e), dst(e)), *, edges(g))
                valid_nodes = state.nodes[best_node] + j.containers ≤ capacity(s.topology.nodes[best_node])
            finally
                unlock(lck)
            end


            is_valid = valid_links && valid_nodes

            is_valid || (sleep(0.001); continue)

            lock(lck)
            try
                add_load!(state, best_links, j.containers, best_node, n)
            finally
                unlock(lck)
            end

            @async begin
                last_unload = ii == length(tasks)
                sleep(j.duration / speed)
                lock(lck)
                try
                    rem_load!(state, best_links, j.containers, best_node, n)
                    push_snap!(snapshots, state, 0, 0, 0, 0, time() - start, n)
                finally
                    unlock(lck)
                end
                last_unload && (all_unloaded = true)
            end

            lock(lck)
            try
                duration = time() - start_iteration
                instant = time() - start
                push_snap!(snapshots, state, best_cost, best_node, duration, duration - start_solving, instant, n)
            finally
                unlock(lck)
            end

            ProgressMeter.update!(p, ii)
        end
    end

    push!(times, "end_queue" => time() - start)

    while !all_unloaded
        sleep(0.001)
    end

    return nothing
end

function execute_valid_load(s, task, g, capacities, state, algo, demands)
    occ, u, j = task.occ, task.node, task.job

    nodes = s.topology.nodes
    links = s.topology.links
    best_links, best_cost, best_node = inner_queue(
        g, u, j, nodes, capacities, state, algo;
        links, demands
    )

    compare_links(i, j) = state.links[i, j] + best_links[i, j] .< capacities[i, j]
    valid_links = mapreduce(e -> compare_links(src(e), dst(e)), *, edges(g))
    valid_nodes =
        state.nodes[best_node] + j.containers ≤ capacity(s.topology.nodes[best_node])

    return (best_links, best_cost, best_node, valid_links && valid_nodes)
end

function insert_sorted!(w, val, it=iterate(w))
    while it !== nothing
        (elt, state) = it
        if elt.occ ≥ val.occ
            insert!(w, state - 1, val)
            return w
        end
        it = iterate(w, state)
    end
    push!(w, val)
end

function simulate_loop(s, algo, speed, start, containers, args_loop, ::Val{0})
    tasks, queued, unloads = containers
    times, snapshots, g, capacities, n, state, demands = args_loop

    ii = 0
    p = Progress(
        2 * length(tasks);
        desc="Simulating with $algo synchronously", showspeed=true, color=:normal
    )

    push!(times, "start_tasks" => time() - start)

    next_queued = iterate(queued)
    previous_queued = 1

    next_unload = iterate(unloads)
    previous_unload = 1

    next_task = iterate(tasks)

    last_unload = zero(Float64)
    unchecked_unload = true

    while ii < 2 * length(tasks)
        start_iteration = time()

        next_queued = iterate(queued, previous_queued)
        if next_queued !== nothing && unchecked_unload
            (task, _) = next_queued
            best_links, best_cost, best_node, is_valid =
                execute_valid_load(s, task, g, capacities, state, algo, demands)

            if is_valid
                j = task.job
                # Add load
                add_load!(state, best_links, j.containers, best_node, n)

                # Snap new state
                push_snap!(snapshots, state, 0, 0, 0, 0, last_unload, n)

                # Assign unload
                unload = Unload(task.occ + j.duration, best_node, j.containers, best_links)
                insert_sorted!(unloads, unload, next_unload)

                # Advance iterator
                previous_queued += 1
                ii += 1
                ProgressMeter.update!(p, ii)
                continue
            else
                unchecked_unload = false
            end
        end

        next_unload = iterate(unloads, previous_unload)
        if next_unload !== nothing
            (unload, _) = next_unload

            if next_task === nothing || unload.occ ≤ next_task[1].occ
                v, c, ls = unload.node, unload.vload, unload.lloads
                rem_load!(state, ls, c, v, n)
                push_snap!(snapshots, state, 0, 0, 0, 0, unload.occ, n)

                previous_unload += 1
                unchecked_unload = true
                last_unload = unload.occ

                ii += 1
                ProgressMeter.update!(p, ii)
                continue
            end
        end

        # Nothing can be unload or exexecuted from the queue => load new task
        (task, ts) = next_task
        best_links, best_cost, best_node, is_valid =
            execute_valid_load(s, task, g, capacities, state, algo, demands)
        if is_valid
            ii += 1
            j = task.job

            # Add load
            add_load!(state, best_links, j.containers, best_node, n)

            # Snap new state
            push_snap!(snapshots, state, 0, 0, 0, 0, task.occ, n)

            # Assign unload
            unload = Unload(task.occ + j.duration, best_node, j.containers, best_links)
            insert_sorted!(unloads, unload, next_unload)
        else
            unchecked_unload = false
            push!(queued, task)
        end

        # Advance iterator
        next_task = iterate(tasks, ts)
        ProgressMeter.update!(p, ii)
    end
    push!(times, "end_queue" => time() - start)
    return nothing
end

function post_simulate(s, snapshots, verbose, output)
    df_snaps = make_df(snapshots, s.topology; verbose)
    if !isempty(output)
        CSV.write(joinpath(datadir(), output), df_snaps)
        verbose && (@info "Output written in $(datadir())")
    end

    verbose && pretty_table(df_snaps)

    return df_snaps
end

function simulate(s::Scenario, algo; speed=0, output="", verbose=true)
    start = time()

    # dispatched containers
    containers = init_simulate(Val(speed))

    # shared init
    args_loop = init_simulate(s, algo, containers[1], start)

    # simulate loop
    simulate_loop(s, algo, speed, start, containers, args_loop, Val(speed))

    # post-process
    return args_loop[1], post_simulate(s, args_loop[2], verbose, output), args_loop[2]
end
