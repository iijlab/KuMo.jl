"""
    State

A structure to store the state of the different resources, e.g. nodes and links, during a simulation.

# Arguments:
- `links::SparseMatrixCSC{Float64, Int64}`: sparse matrice with the links loads
- `nodes::SparseVector{Float64, Int64}`: sparse vector with the nodes loads
- `State(n)`: inner constructor given the number of nodes `n`
- `State(links, nodes)`: inner constructor given the `links` and `nodes` of an existing state
"""
struct State
    links::SparseMatrixCSC{Float64,Int64}
    nodes::SparseVector{Float64,Int64}

    State(n) = new(spzeros(n, n), spzeros(n))

    State(links, nodes) = new(links, nodes)
end

links(s::State) = s.links
links(s, i, j, ::Val{true}) = s.links[i, j]

links(s, i, j, directed=true) = links(s, i, j, Val(directed))

function links(s, i, j, ::Val{false})
    a, b = minmax(i, j)
    return links(s, a, b)
end

function increase!(s::State, i, j, val, directed)
    s.links[i, j] += val
    directed || (s.links[j, i] += val)
end

decrease!(s::State, i, j, val, directed) = increase!(s::State, i, j, -val, directed)

"""
    add_load!(state, links, containers, v, n)

Adds load to a given state.

# Arguments:
- `state`
- `links`: the load increase to be added on links
- `containers`: the containers load to be added to `v`
- `v`: node selected to execute a task
- `n`: amount of available nodes
"""
function add_load!(state, _links, containers, v, n, g)
    for i in 1:n, j in 1:n
        increase!(state, i, j, _links[i, j], is_directed(g))
    end
    state.nodes[v] += containers
end

"""
    rem_load!(state, links, containers, v, n)

Removes load from a given state.

# Arguments:
- `state`
- `links`: the load increase to be removed from links
- `containers`: the containers load to be removed from `v`
- `v`: node where a task is endind
- `n`: amount of available nodes
"""
function rem_load!(state, links, containers, v, n, g)
    for i in 1:n, j in 1:n
        decrease!(state, i, j, links[i, j], is_directed(g))
    end
    state.nodes[v] -= containers
end

"""
    SnapShot

A structure to take snapshot from the state of network and its resources at a specific instant.

# Arguments:
- `state::State`: state at `instant`
- `total::Float64`: total load at `instant`
- `selected::Int`: selected node at `instant`; value is zero if load is removed
- `duration::Float64`: duration of all the actions taken during corresponding to the state of this snap
- `solving_time::Float64`: time taken specifically by the solving algorithm (`<: AbstractAlgorithm`)
- `instant::Float64`
"""
mutable struct SnapShot
    state::State
    total::Float64
    selected::Int
    duration::Float64
    solving_time::Float64
    instant::Float64
end

"""
    push_snap!(snapshots, state, total, selected, duration, solving_time, instant, n)

Add a snapshot to an existing collection of snapshots.

# Arguments:
- `snapshots`: collection of snapshots
- `state`: current state
- `total`: load
- `selected`: node where a request is executed
- `duration`: duration of the whole resource allocation for the request
- `solving_time`: time taken specifically by the solving algorithm (`<: AbstractAlgorithm`)
- `instant`: instant when the request is received
- `n`: number of available nodes
"""
function push_snap!(snapshots, state, total, selected, duration, solving_time, instant, n)
    links = deepcopy(state.links[1:n, 1:n])
    nodes = deepcopy(state.nodes[1:n])
    snap = SnapShot(State(links, nodes), total, selected, duration, solving_time, round(instant; digits=5))
    push!(snapshots, snap)
end

"""
    Load

A structure describing an increase of the total load.

# Arguments:
- `occ::Float64`: time when the load occurs
- `node::Int`: node at which the request is executed
- `job::Job`: the job request
"""
struct Load
    occ::Float64
    node::Int
    job::Job
end

"""
    Unload

A structure describing a decrease of the total load.

# Arguments:
- `occ::Float64`: time when the unload occurs
- `node::Int`: node at which the request was executed
- `vload::Int`: the number of freed containers
- `lloads::SparseMatrixCSC{Float64, Int64}`: the freed loads on each link
"""
struct Unload
    occ::Float64
    node::Int
    vload::Int
    lloads::SparseMatrixCSC{Float64,Int64}
end

Base.isless(x::Union{Load,Unload}, y::Union{Load,Unload}) = isless(x.occ, y.occ)

"""
    retrieve_path(u, v, paths)

Retrieves the path from `u` to `v`.

# Arguments:
- `u`: source vertex
- `v`: target vertex
- `paths`: list of shortest paths within a network
"""
function retrieve_path(u, v, paths)
    path = Vector{Pair{Int,Int}}()
    w = v
    while w != u
        x = paths.parents[w]
        pushfirst!(path, x => w)
        w = x
    end
    return path
end

"""
    inner_queue(g, u, j, nodes, capacities, state, ::ShortestPath, ii = 0; lck = ReentrantLock(), demands = nothing, links)

DOCSTRING

# Arguments:
- `g`: a graph representing the topology of the network
- `u`: user location
- `j`: requested job
- `nodes`: nodes capacities
- `capacities`: links capacities
- `state`: current state of the network
- `algo`: `ShortestPath <: AbstractAlgorithm`
- `ii`: a counter to mesure the progress in the simulation
- `lck`: a lck for asynchronous simulation
- `demands`: not needed for `ShortestPath` algorithm
- `links`: description of the links topology
"""
function inner_queue(
    g, u, j, nodes, capacities, state, ::ShortestPath, ii=0;
    lck=ReentrantLock(), demands=nothing, links
)
    nvtx = nv(g)
    best_links = spzeros(nvtx, nvtx)
    best_node = 0
    best_cost = Inf

    node_costs = nothing
    data_costs = nothing
    user_costs = nothing
    total_cost = Inf

    data_path = Vector{Pair{Int,Int}}()
    user_path = Vector{Pair{Int,Int}}()

    # if ii >= 0
    #     @info "debug shortest: start" ii state.links state.nodes j
    #     @info "edges" collect(edges(g))
    # end

    # computing shortest paths starting with frontend (user)
    lock(lck)
    try
        node_costs = map(
            v -> pseudo_cost(v.second, state.nodes[v.first] + j.containers),
            pairs(nodes)
        )
        user_costs = zeros(size(capacities))
        j.frontend == 0 || for i in 1:size(state.links, 1), k in 1:size(state.links, 1)
            # @info "entered loop" i k user_costs

            if (i, k) ∈ keys(links)
                # @info "debug pseudo cost" j.frontend state.links[i, k] links[(i, k)] pseudo_cost(links[(i, k)], state.links[i, k] + j.frontend)
                user_costs[i, k] =
                    pseudo_cost(links[(i, k)], state.links[i, k] + j.frontend)
            end
        end
    finally
        unlock(lck)
    end

    # if ii >= 0
    #     @info "debug shortest: frontend" user_costs
    # end

    paths_user = dijkstra_shortest_paths(g, u, user_costs; trackvertices=true)
    # paths_user2 = dijkstra_shortest_paths(
    #     g, u, transpose(user_costs);
    #     trackvertices=true
    # )

    # if ii >= 0
    #     @info "debug shortest" u paths_user.dists paths_user.parents
    #     @info "retriev path" retrieve_path(u, 3, paths_user)
    #     @info "debug shortest" u paths_user2.dists paths_user2.parents
    #     @info "retriev path" retrieve_path(u, 3, paths_user2)
    # end

    for v in keys(node_costs)
        current_path = retrieve_path(u, v, paths_user)

        charges = deepcopy(state.links)
        for p in current_path
            a, b = p.first, p.second
            charges[a, b] = j.frontend
        end

        # if ii >= 0
        #     @info "debug shortest" u v current_path charges
        # end

        lock(lck)
        try
            data_costs = zeros(size(capacities))
            j.backend == 0 || for i in 1:size(state.links, 1), k in 1:size(state.links, 1)
                if (i, k) ∈ keys(links)
                    data_costs[i, k] = pseudo_cost(links[(i, k)], charges[i, k] + j.backend)
                end
            end
        finally
            unlock(lck)
        end

        # if ii >= 0
        #     @info "debug shortest" data_costs user_costs node_costs
        # end

        paths_data = dijkstra_shortest_paths(
            g, j.data_location, data_costs;
            trackvertices=true
        )

        # paths_data2 = dijkstra_shortest_paths(
        #     g, j.data_location, transpose(data_costs);
        #     trackvertices=true
        # )

        # if ii >= 0
        #     @info "debug shortest  123" j.data_location paths_data.dists paths_data.parents
        #     @info "retriev path" retrieve_path(j.data_location, v, paths_data)
        #     # @info "debug shortest" j.data_location paths_data2.dists paths_data2.parents
        #     # @info "retriev path" retrieve_path(j.data_location, v, paths_data2)
        # end

        current_cost = paths_user.dists[v] + paths_data.dists[v] + node_costs[v]

        # if ii >= 0
        #     @info "debug shortest" current_cost paths_user.dists[v] paths_data.dists[v] node_costs[v]
        # end

        if current_cost ≤ total_cost
            total_cost = current_cost
            data_path = retrieve_path(j.data_location, v, paths_data)
            user_path = current_path
            best_node = v
        end
    end

    # computing shortest paths starting with backend (data)
    lock(lck)
    try
        data_costs = zeros(size(capacities))
        j.backend == 0 || for i in 1:size(state.links, 1), k in 1:size(state.links, 1)
            if (i, k) ∈ keys(links)
                data_costs[i, k] = pseudo_cost(links[(i, k)], state.links[i, k] + j.backend)
            end
        end
    finally
        unlock(lck)
    end
    paths_data = dijkstra_shortest_paths(g, j.data_location, data_costs; trackvertices=true)

    for v in keys(node_costs)
        current_path = retrieve_path(j.data_location, v, paths_data)

        charges = deepcopy(state.links)
        for p in current_path
            a, b = p.first, p.second
            charges[a, b] = state.links[a, b] + j.backend
        end

        lock(lck)
        try
            user_costs = zeros(size(capacities))
            j.frontend == 0 || for i in 1:size(state.links, 1), k in 1:size(state.links, 1)
                if (i, k) ∈ keys(links)
                    user_costs[i, k] = pseudo_cost(links[(i, k)], charges[i, k] + j.frontend)
                end
            end
        finally
            unlock(lck)
        end

        paths_user = dijkstra_shortest_paths(
            g, u, user_costs;
            trackvertices=true
        )

        current_cost = paths_user.dists[v] + paths_data.dists[v] + node_costs[v]
        if current_cost ≤ total_cost
            total_cost = current_cost
            data_path = current_path
            user_path = retrieve_path(u, v, paths_user)
            best_node = v
        end
    end

    foreach(p -> best_links[p.first, p.second] = j.frontend, user_path)
    foreach(p -> best_links[p.first, p.second] += j.backend, data_path)

    # if ii >= 0
    #     @info "debug shortest" best_links total_cost best_node
    # end


    return best_links, total_cost, best_node
end

# FIXME - links indices
"""
    make_df(snapshots::Vector{SnapShot}, topo; verbose = true)

Make a DataFrame from the raw snapshots.

# Arguments:
- `snapshots`: A collection of snapshots
- `topo`: topology of the network
- `verbose`: if set to true, it will print a description of the snapshots in the terminal
"""
function make_df(snapshots::Vector{SnapShot}, topo; verbose=true)
    function shape_entry(s)
        entry = Vector{Pair{String,Float64}}()
        push!(entry, "selected" => s.selected)
        push!(entry, "total" => s.total)
        push!(entry, "duration" => s.duration)
        push!(entry, "solving_time" => s.solving_time)
        push!(entry, "instant" => s.instant)

        foreach(p -> push!(entry, string(p.first) => p.second / capacity(nodes(topo, p.first))), pairs(s.state.nodes))

        # @info "debug links" topo.links s.state.links entry snapshots[end] topo

        for (i, j) in keys(topo.links)
            push!(entry, string((i, j)) => s.state.links[i, j] / capacity(links(topo, i, j)))
        end

        return entry
    end


    df = DataFrame(shape_entry(first(snapshots)))
    foreach(e -> push!(df, Dict(shape_entry(e))), snapshots[2:end])

    acc = Vector{Symbol}()
    for (i, col) in enumerate(propertynames(df))
        if i < 6 || !all(iszero, df[!, col])
            push!(acc, col)
        end
    end

    df = df[!, acc]

    verbose && pretty_table(describe(df))

    return df
end

"""
    init_simulate(::Val{0})

Initialize a synchronous simulation.
"""
function init_simulate(::Val{0})
    tasks = Vector{Load}()
    queued = Vector{Load}()
    unloads = Vector{Unload}()
    return tasks, queued, unloads
end

"""
    init_simulate(::Val)

Initialize an asynchronous simulation.
"""
function init_simulate(::Val)
    tasks = Vector{Load}()
    c = Channel{Tuple{Int,Job}}(10^7)
    return tasks, c
end

# """
#     init_user(s::Scenario, u::User, tasks, ::PeriodicRequests)

# Initialize user `u` periodic requests.

# # Arguments:
# - `s`: scenario that is about to be simulated
# - `u`: a user id
# - `tasks`: container of sorted tasks
# """
# function init_user(s::Scenario, u::User, tasks, ::PeriodicRequests)
#     jr = u.job_requests
#     j = jr.job
#     p = jr.period
#     t0 = max(jr.start, 0.0)
#     t1 = min(jr.stop, s.duration)

#     foreach(occ -> push!(tasks, Load(occ, u.location, j)), t0:p:t1)
#     sort!(tasks)
#     # @info "debug PR" tasks
# end

"""
    init_user(::Scenario, u::User, tasks, ::Requests)

Initialize user `u` non-periodic requests.

# Arguments:
- `u`: a user id
- `tasks`: container of sorted tasks
"""
function init_user(::Scenario, u::User, tasks, ::Requests)
    foreach(r -> push!(tasks, Load(r.start, u.location, r.job)), u.job_requests.requests)
    sort!(tasks)
    # @info "debug Rs" tasks
end

"""
    init_simulate(s, algo, tasks, start)

Initialize structures before the simualtion of scenario `s`.

# Arguments:
- `s`: the scenario being simulated
- `algo`: algorithm allocating resources at best known lower costs resources
- `tasks`: sorted container of tasks to be simulated
- `start`: instant when the simulation started
"""
function init_simulate(s, algo, tasks, start)
    times = Dict{String,Float64}()
    snapshots = Vector{SnapShot}()

    @info "foreach init_user start" (time() - start)
    foreach(u -> init_user(s, u, tasks, u.job_requests), s.users)
    @info "foreach init_user end" (time() - start)

    push!(times, "start_tasks" => time() - start)
    g, capacities = graph(s.topology, algo)
    n = nv(g) - vtx(algo)

    state = State(nv(g))
    demands = spzeros(nv(g))

    push_snap!(snapshots, state, 0, 0, 0, 0, 0, n)

    push!(times, "start_queue" => time() - start)
    return times, snapshots, g, capacities, n, state, demands
end

"""
    simulate_loop(s, algo, speed, start, containers, args_loop, ::Val)

Inner loop of the simulation of scenario `s`.

# Arguments:
- `s`: scenario being simulated
- `algo`: algo solving the resource allocation dynamically at each step
- `speed`: asynchronous simulation speed
- `start`: starting time of the simulation
- `containers`: containers generated to allocate tasks dynamically during the run
- `args_loop`: arguments required by this loop
"""
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
                add_load!(state, best_links, j.containers, best_node, n, g)
            finally
                unlock(lck)
            end

            @async begin
                last_unload = ii == length(tasks)
                sleep(j.duration / speed)
                lock(lck)
                try
                    rem_load!(state, best_links, j.containers, best_node, n, g)
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

"""
    execute_valid_load(s, task, g, capacities, state, algo, demands, ii = 0)

Compute the best load allocation and return if it is a valid one.

# Arguments:
- `s`: scenario being simulated
- `task`: task being requested
- `g`: graph of the network topology
- `capacities`: capacities of the network
- `state`: current state of resources
- `algo`: algo used for computing the best allocation cost
- `demands`: if algo is `KuMoFlowExt.MinCostFlow`, demands are required
- `ii`: a counter to measure the approximative progress of the simulation
"""
function execute_valid_load(s, task, g, capacities, state, algo, demands, ii=0)
    occ, u, j = task.occ, task.node, task.job

    nodes = s.topology.nodes
    links = s.topology.links
    best_links, best_cost, best_node = inner_queue(
        g, u, j, nodes, capacities, state, algo, ii;
        links, demands
    )

    # if ii != 0
    #     @info "debug 1" state.links best_links capacities best_cost best_node
    # end
    compare_links(i, j) = state.links[i, j] + best_links[i, j] .< capacities[i, j]
    valid_links = mapreduce(e -> compare_links(src(e), dst(e)), *, edges(g))
    valid_nodes =
        state.nodes[best_node] + j.containers ≤ capacity(s.topology.nodes[best_node])

    return (best_links, best_cost, best_node, valid_links && valid_nodes)
end

"""
    insert_sorted!(w, val, it = iterate(w))

Insert element in a sorted collection.

# Arguments:
- `w`: sorted collection
- `val`: value to be inserted
- `it`: optional iterator
"""
function insert_sorted!(w, val, it=iterate(w))
    # @debug "debug" w val it
    while it !== nothing
        (elt, state) = it
        # @debug "debug while" elt state elt.occ val.occ
        if elt.occ ≥ val.occ
            insert!(w, state - 1, val)
            return w
        end
        it = iterate(w, state)
    end
    push!(w, val)
    # @debug "debug after insert" w val
    return w
end

"""
    simulate_loop(s, algo, _, start, containers, args_loop, ::Val{0})

Inner loop of the simulation of scenario `s`.

# Arguments:
- `s`: scenario being simulated
- `algo`: algo solving the resource allocation dynamically at each step
- `_`: simulation speed (unrequired)
- `start`: starting time of the simulation
- `containers`: containers generated to allocate tasks dynamically during the run
- `args_loop`: arguments required by this loop
"""
function simulate_loop(s, algo, _, start, containers, args_loop, ::Val{0})
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

    # ii_stop = Inf

    while ii < 2 * length(tasks)
        # if ii == ii_stop + 1
        #     @warn "debug" state g
        #     break
        # end
        start_iteration = time()

        next_queued = iterate(queued, previous_queued)
        if next_queued !== nothing && !unchecked_unload
            @debug "debug !unchecked" next_queued ii
        end
        if next_queued !== nothing && unchecked_unload
            @debug "debug entering queued" next_queued ii
            (task, _) = next_queued
            best_links, best_cost, best_node, is_valid =
                execute_valid_load(s, task, g, capacities, state, algo, demands)

            if is_valid
                @debug "debug is_valid" task
                j = task.job
                # Add load
                add_load!(state, best_links, j.containers, best_node, n, g)
                # if ii == ii_stop
                #     @info "debug snapshots prior push" snapshots last_unload n
                # end
                @debug "debug snapshots prior push" snapshots last_unload n
                # Snap new state
                push_snap!(snapshots, state, 0, 0, 0, 0, last_unload, n)
                @debug "debug snapshots after push" snapshots last_unload n
                # if ii == ii_stop
                #     @info "debug snapshots after push" last(snapshots)
                # end
                # Assign unload
                unload = Unload(last_unload + j.duration, best_node, j.containers, best_links)
                insert_sorted!(unloads, unload, next_unload)

                # Advance iterator
                previous_queued += 1
                ii += 1
                ProgressMeter.update!(p, ii)
                continue
            else
                @debug "debug !is_valid"
                unchecked_unload = false
            end
        end

        next_unload = iterate(unloads, previous_unload)
        if next_unload !== nothing
            (unload, _) = next_unload

            if next_task === nothing || unload.occ ≤ next_task[1].occ
                v, c, ls = unload.node, unload.vload, unload.lloads
                rem_load!(state, ls, c, v, n, g)
                # if ii == ii_stop
                #     @info "debug snapshots prior push" snapshots last_unload n
                # end
                push_snap!(snapshots, state, 0, 0, 0, 0, unload.occ, n)
                # if ii == ii_stop
                #     @info "debug snapshots after push" last(snapshots)
                # end

                previous_unload += 1
                unchecked_unload = true
                last_unload = unload.occ

                ii += 1
                ProgressMeter.update!(p, ii)
                continue
            end
        end

        # Nothing can be unload or exexecuted from the queue => load new task
        # isnothing(next_task) && break
        (task, ts) = next_task
        best_links, best_cost, best_node, is_valid =
            execute_valid_load(s, task, g, capacities, state, algo, demands)
        if is_valid
            ii += 1
            j = task.job

            # Add load
            add_load!(state, best_links, j.containers, best_node, n, g)

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

"""
    clean(snaps)

Clean the snapshots by merging snaps occuring at the same time.
"""
function clean(snaps)
    snapshots = Vector{SnapShot}()
    fsnap = first(snaps)
    instant = fsnap.instant

    replaced = false

    for (i, s) in enumerate(snaps)
        if s.instant ≉ instant || isempty(snapshots)
            push!(snapshots, s)
            instant = s.instant
        else
            if i == 2
                replaced = true
            end
            snapshots[end] = s
        end
    end

    if replaced
        fsnap.instant = fsnap.instant - snapshots[2].instant
        pushfirst!(snapshots, fsnap)
    end

    return snapshots
end

"""
    post_simulate(s, snapshots, verbose, output)

Post-simulation process that covers cleaning the snapshots and producing an output.

# Arguments:
- `s`: simulated scenario
- `snapshots`: resulting snapshots (before cleaning)
- `verbose`: if set to true, prints information about the output and the snapshots
- `output`: output path
"""
function post_simulate(s, snapshots, verbose, output)

    df_snaps = make_df(clean(snapshots), s.topology; verbose)
    # df_snaps = make_df(snapshots, s.topology; verbose)
    if !isempty(output)
        CSV.write(joinpath(datadir(), output), df_snaps)
        verbose && (@info "Output written in $(datadir())")
    end

    verbose && pretty_table(df_snaps)

    return df_snaps
end

"""
    simulate(s::Scenario, algo; speed = 0, output = "", verbose = true)

Simulate a scenario.

# Arguments:
- `s`: simulation targetted scenario
- `algo`: algorithm used to estimate the best allocation regarding to the pseudo-cost
- `speed`: simulation speed. If set to 0, the requests are handled sequentially without computing time limits. Otherwise the requests are made as independant asynchronous processes
- `output`: path to save the output, if empty (default), nothing is saved
- `verbose`: if set to true, prints information about the simulation
"""
function simulate(s::Scenario, algo=ShortestPath(); speed=0, output="", verbose=true)
    start = time()

    @info "containers stuff start" (time() - start)
    # dispatched containers
    containers = init_simulate(Val(speed))

    @info "args loop stuff start" (time() - start)
    # shared init
    args_loop = init_simulate(s, algo, containers[1], start)

    @info "start simulation" (time() - start)
    # simulate loop
    simulate_loop(s, algo, speed, start, containers, args_loop, Val(speed))

    @info "debug" args_loop
    @info "debug" containers



    # post-process
    return args_loop[1], post_simulate(s, args_loop[2], verbose, output), args_loop[2]
end
