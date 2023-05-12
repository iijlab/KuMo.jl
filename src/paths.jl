"""
    AbstractAlgorithm

An abstract supertype for algorithms.
"""
abstract type AbstractAlgorithm end

"""
    ShortestPath <: AbstractAlgorithm

A ShortestPath algorithm.
"""
struct ShortestPath <: AbstractAlgorithm end

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
function inner_queue(exe, task, args, nodes, ii=0; lck=ReentrantLock(), links, demands)
    u, j = task.user, task.job
    capacities, demands, g, _, _, state, _ = extract_loop_arguments(args)
    data_loc = exe.infrastructure.data[task.data].location

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

    lock(lck)
    try
        node_costs = map(
            v -> pseudo_cost(v.second, state.nodes[v.first] + j.containers),
            pairs(nodes)
        )
        user_costs = zeros(size(capacities))
        j.frontend == 0 || for i in 1:size(state.links, 1), k in 1:size(state.links, 1)

            if (i, k) ∈ keys(links)
                user_costs[i, k] =
                    pseudo_cost(links[(i, k)], state.links[i, k] + j.frontend)
            end
        end
    finally
        unlock(lck)
    end

    paths_user = dijkstra_shortest_paths(g, u, user_costs; trackvertices=true)

    for v in keys(node_costs)
        current_path = retrieve_path(u, v, paths_user)

        charges = deepcopy(state.links)
        for p in current_path
            a, b = p.first, p.second
            charges[a, b] = j.frontend
        end

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

        paths_data = dijkstra_shortest_paths(
            g, data_loc, data_costs;
            trackvertices=true
        )

        current_cost = paths_user.dists[v] + paths_data.dists[v] + node_costs[v]

        if current_cost ≤ total_cost
            total_cost = current_cost
            data_path = retrieve_path(data_loc, v, paths_data)
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
    paths_data = dijkstra_shortest_paths(g, data_loc, data_costs; trackvertices=true)

    for v in keys(node_costs)
        current_path = retrieve_path(data_loc, v, paths_data)

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

    return best_links, total_cost, best_node
end
