struct State
    links::SparseMatrixCSC{Float64,Int64}
    nodes::SparseVector{Float64,Int64}

    State(n) = new(spzeros(n, n), spzeros(n))

    State(links, nodes) = new(links, nodes)
end

struct SnapShot
    state::State
    total::Float64
    selected::Int
    duration::Float64
    solving_time::Float64
    instant::Float64
end

function inner_queue(g, u, j, nodes, links, capacities, demands, state, lck, algo::MinCostFlow)
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

function inner_queue(g, u, j, nodes, links, capacities, _, state, lck, ::ShortestPath)
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

        pretty_table(describe(df))

        return df
    else
        return DataFrame()
    end
end

function simulate(s::Scenario, algo, speed, output, verbose, ::Val{true})
    times = Dict{String,Float64}()
    snapshots = Vector{SnapShot}()
    start_simulation = time()

    tasks = Vector{Pair{Float64,Tuple{Int,Job}}}()

    all_queue = false
    all_unloaded = false

    for u in s.users
        jr = u.job_requests
        j = jr.job
        p = jr.period

        foreach(occ -> push!(tasks, occ => (u.location, j)), 0:p:s.duration)
    end

    c = Channel{Tuple{Int,Job}}(10^7)
    c = Channel{Tuple{Int,Job}}(10^7)

    push!(times, "start_tasks" => time() - start_simulation)

    for (i, t) in enumerate(tasks)
        @async begin
            sleep(t[1] / speed)
            put!(c, t[2])
            i == length(tasks) && (all_queue = true)
        end
    end

    push!(times, "init_queue" => time() - start_simulation)

    g, capacities = graph(s.topology, algo)

    state = State(nv(g))
    demands = spzeros(nv(g))

    lck = ReentrantLock()

    push!(times, "start_queue" => time() - start_simulation)

    ii = 0
    p = Progress(
        length(tasks);
        desc="Simulating with $algo at speed $speed", showspeed=true, color=:normal)
    while !all_queue || isready(c)
        start_iteration = time()
        ii += 1
        u, j = take!(c)

        start_solving = time() - start_iteration
        is_valid = false

        while !is_valid
            best_links, best_cost, best_node = inner_queue(g, u, j, s.topology.nodes, s.topology.links, capacities, demands, state, lck, algo)

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
                for i in 1:n, j in 1:n
                    state.links[i, j] += best_links[i, j]
                end
                state.nodes[best_node] += j.containers
            finally
                unlock(lck)
            end

            @async begin
                last_unload = ii == length(tasks)
                sleep(j.duration / speed)
                lock(lck)
                try
                    for i in 1:n, j in 1:n
                        state.links[i, j] -= best_links[i, j]
                    end
                    state.nodes[best_node] -= j.containers
                    links = deepcopy(state.links[1:n, 1:n])
                    nodes = deepcopy(state.nodes[1:n])
                    instant = time() - start_simulation
                    snap = SnapShot(State(links, nodes), 0, 0, 0, 0, instant)
                    push!(snapshots, snap)
                finally
                    unlock(lck)
                end
                last_unload && (all_unloaded = true)
            end

            lock(lck)
            try
                links = deepcopy(state.links[1:n, 1:n])
                nodes = deepcopy(state.nodes[1:n])
                duration = time() - start_iteration
                instant = time() - start_simulation
                snap = SnapShot(State(links, nodes), best_cost, best_node, duration, duration - start_solving, instant)
                push!(snapshots, snap)
            finally
                unlock(lck)
            end

            update!(p, ii)
        end
    end

    push!(times, "end_queue" => time() - start_simulation)

    while !all_unloaded
        # @warn "debug" all_unloaded ii
        sleep(0.001)
    end

    df_snaps = make_df(snapshots, s.topology; verbose)
    if !isempty(output)
        CSV.write(joinpath(datadir(), output), df_snaps)
        verbose && (@info "Output written in $(datadir())")
    end

    verbose && pretty_table(df_snaps)

    return times, df_snaps, snapshots
end

function simulate(s::Scenario, algo, _, output, verbose, ::Val{false})
    times = Dict{String,Float64}()
    snapshots = Vector{SnapShot}()
    start_simulation = time()

    tasks = SortedMultiDict{Float64, Tuple{Int, Job}}()
    queued = Vector{Pair{Float64, Tuple{Int, Job}}}()
    unloads =
        SortedMultiDict{Float64, Tuple{Int, Float64, SparseMatrixCSC{Float64,Int64}}}()

    for u in s.users
        jr = u.job_requests
        j = jr.job
        p = jr.period

        foreach(occ -> insert!(tasks, occ, (u.location, j)), 0:p:s.duration)
    end

    push!(times, "start_tasks" => time() - start_simulation)

    g, capacities = graph(s.topology, algo)
    n = nv(g) - vtx(algo)

    state = State(nv(g))
    demands = spzeros(nv(g))

    push!(times, "start_queue" => time() - start_simulation)

    ii = 0
    p = Progress(
        2 * length(tasks);
        desc="Simulating with $algo at speed $speed", showspeed=true, color=:normal
    )

    lck = ReentrantLock()
    next_queued = nothing
    previous_unload = nothing
    next_unload = nothing
    next_task = iterate(tasks)

    last_unload = zero(Float64)
    unchecked_unload = true

    while (next_queued, next_unload, next_task) !== (nothing, nothing, nothing)
        start_iteration = time()

        if next_queued !== nothing && unchecked_unload
            (task, ts) = next_queued
            occ = task.first
            u, j = task.second

            nodes = s.topology.nodes
            links = s.topology.links
            bs = inner_queue(g, u, j, nodes, links, capacities, demands, state, lck, algo)
            best_links, best_cost, best_node = bs

            compare_links(i, j) = state.links[i, j] + best_links[i, j] .< capacities[i, j]
            valid_links = mapreduce(e -> compare_links(src(e), dst(e)), *, edges(g))
            valid_nodes = state.nodes[best_node] + j.containers ≤ capacity(s.topology.nodes[best_node])

            if valid_links && valid_nodes
                ii += 1

                # Add load
                for i in 1:n, j in 1:n
                    state.links[i, j] += best_links[i, j]
                end
                state.nodes[best_node] += j.containers

                # Snap new state
                _links = deepcopy(state.links[1:n, 1:n])
                _nodes = deepcopy(state.nodes[1:n])
                instant = last_unload
                snap = SnapShot(State(_links, _nodes), 0, 0, 0, 0, instant)
                push!(snapshots, snap)

                # Assign unload
                unload_time = occ + j.duration
                push!(unloads, unload_time => (best_node, j.containers, best_links))
                isempty(unloads) && previous_unload = iterate(unloads)

                # Advance iterator
                next_queued = iterate(queued, ts)
                continue
            else
                unchecked_unload = false
            end
        end

        if next_unload === nothing && previous_unload !== nothing
            next_unload = iterate(unloads, previous_unload)
        end

        if next_unload !== nothing
            (unload, us) = next_unload
            (task, _) = next_task

            unload_time = unload.first
            task_occ = task.first

            if unload_time ≤ task_occ
                ii += 1

                v, c, ls = unload.second
                for i in 1:n, j in 1:n
                    state.links[i, j] -= ls[i, j]
                end
                state.nodes[v] -= c

                links = deepcopy(state.links[1:n, 1:n])
                nodes = deepcopy(state.nodes[1:n])
                snap = SnapShot(State(links, nodes), 0, 0, 0, 0, unload_time)
                push!(snapshots, snap)

                previous_unload = next_unload
                next_unload = iterate(unloads, us)

                unchecked_unload = true
                continue
            end
        end

        (task, _) = next_task
        task_occ = task.first
        while next_task

        end

    end
    return nothing
end

function simulate(s::Scenario, algo; speed=1, output="", verbose=true, async=true)
    return simulate(s, algo, speed, output, verbose, Val(async))
end
