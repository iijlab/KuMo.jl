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
end

function inner_queue(g, u, j, nodes, capacities, demands, state, algo::MinCostFlow)
    nvtx = nv(g)

    add_edge!(g, nvtx - 1, u)
    add_edge!(g, nvtx - 1, j.data_location)
    state.links[nvtx-1, u] += j.frontend
    state.links[nvtx-1, j.data_location] += j.backend

    demands[nvtx-1] = -(j.backend + j.frontend)
    demands[nvtx] = j.backend + j.frontend

    best_links = spzeros(nvtx, nvtx)
    best_node = 0
    best_cost = Inf

    for (i, v) in pairs(nodes)
        node_cost = pseudo_cost(v, j.containers)
        add_edge!(g, i, nvtx)
        aux_cap = deepcopy(state.links)
        aux_cap[i, nvtx] = j.backend + j.frontend
        # @info "Debug" g demands capacities aux_cap
        f, links_cost = mincost_flow(g, demands, capacities, aux_cap, algo.optimizer)
        cost = node_cost + links_cost
        if cost < best_cost
            best_cost = cost
            best_links = f
            best_node = i
            # pretty_table(f)
            # @info "obj val" cost
        end
        rem_edge!(g, i, nvtx)
    end

    rem_edge!(g, nvtx - 1, u)
    rem_edge!(g, nvtx - 1, j.data_location)
    state.links[nvtx-1, u] = 0.0
    state.links[nvtx-1, j.data_location] = 0.0

    return best_links, best_cost, best_node
end

function inner_queue(g, u, j, nodes, capacities, demands, state, ::ShortestPath)
    best_links = spzeros(nvtx, nvtx)
    best_node = 0
    best_cost = Inf

    costs = map((r, c) -> pseudo_cost(r, c), zip(capacities, state.links))

    @info dijkstra_shortest_paths(g, [u, j.data_location], costs; all_paths=true, trackvertices=true)


    return best_links, best_cost, best_node
end

function simulate(s::Scenario, algo; acceleration=1)
    times = Dict{String,Float64}()
    snapshots = Vector{SnapShot}()
    start_simulation = time()

    tasks = Vector{Pair{Float64,Tuple{Int,Job}}}()

    all_queue = false

    for u in s.users
        jr = u.job_requests
        j = jr.job
        p = jr.period

        foreach(occ -> push!(tasks, occ => (u.location, j)), 0:p:s.duration)
    end

    c = Channel{Tuple{Int,Job}}(10^7)

    push!(times, "start_tasks" => time() - start_simulation)

    for (i, t) in enumerate(tasks)
        @async begin
            sleep(t[1] / acceleration)
            put!(c, t[2])
            i == length(tasks) && (all_queue = true)
        end
    end

    push!(times, "init_queue" => time() - start_simulation)

    g, capacities = graph(s.topology, algo)

    state = State(nv(g))
    demands = spzeros(nv(g))

    push!(times, "start_queue" => time() - start_simulation)

    ii = 0
    while !all_queue || isready(c)
        start_iteration = time()
        ii += 1
        u, j = take!(c)

        start_solving = time() - start_iteration

        best_links, best_cost, best_node = inner_queue(g, u, j, s.topology.nodes, capacities, demands, state, algo)

        n = nv(g) - vtx(algo)
        for i in 1:n, j in 1:n
            state.links[i, j] += best_links[i, j]
        end
        state.nodes[best_node] += j.containers

        @async begin
            sleep(j.duration / acceleration)
            for i in 1:n, j in 1:n
                current_cap[i, j] -= best_links[i, j]
            end
            s.nodes[best_node].current -= j.containers
        end

        links = deepcopy(state.links[1:n, 1:n])
        nodes = state.nodes[1:n]
        duration = time() - start_iteration

        snap = SnapShot(State(links, nodes), best_cost, best_node, duration, duration - start_solving)

        push!(snapshots, snap)

        # @info u j current_cap best_links s.nodes
        # pretty_table(current_cap)
        # ii == 2 && break
        mod(ii, round(length(tasks) / 20)) == 0 && @info("Iteration $ii/$(length(tasks)): $(time() - start_simulation) seconds passed")
    end

    push!(times, "end_queue" => time() - start_simulation)

    return times, snapshots
end

function make_df(snapshots::Vector{SnapShot})
    df = DataFrame(
        total=Float64[],
        selected=Int[],
        duration=Float64[],
        solving_time=Float64[],
    )

    for snap in snapshots
        push!(df, (
            snap.total,
            snap.selected,
            snap.duration,
            snap.solving_time,
        ))
    end

    pretty_table(describe(df))

    return df
end
