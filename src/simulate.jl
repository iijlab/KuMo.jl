struct SnapShot
    links::SparseMatrixCSC{Float64, Int64}
    nodes::SparseVector{Float64, Int64}
    total::Float64
    selected::Int
    duration::Float64
    solving_time::Float64
end

function simulate(s::Scenario, optimizer; acceleration=1)
    times = Dict{String, Float64}()
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

    ii = 0

    nvtx = length(s.nodes) + 2

    g = SimpleDiGraph(nvtx)

    capacities = spzeros(nvtx, nvtx)
    for e in pairs(s.links)
        u, v = e[1]
        l = e[2]
        add_edge!(g, u, v)
        add_edge!(g, v, u)
        capacities[u, v] = l.capacity
        capacities[v, u] = l.capacity
    end

    current_cap = spzeros(nvtx, nvtx)
    demands = spzeros(nvtx)

    push!(times, "start_queue" => time() - start_simulation)

    while !all_queue || isready(c)
        start_iteration = time()
        ii += 1
        u, j = take!(c)

        start_solving = time() - start_iteration

        add_edge!(g, nvtx - 1, u)
        add_edge!(g, nvtx - 1, j.data_location)
        current_cap[nvtx-1, u] += j.frontend
        current_cap[nvtx-1, j.data_location] += j.backend

        demands[nvtx-1] = -(j.backend + j.frontend)
        demands[nvtx] = j.backend + j.frontend

        best_links = spzeros(nvtx, nvtx)
        best_node = 0
        best_cost = Inf

        for (i, v) in pairs(s.nodes)
            node_cost = pseudo_cost(v, j.containers)
            add_edge!(g, i, nvtx)
            aux_cap = deepcopy(current_cap)
            aux_cap[i, nvtx] = j.backend + j.frontend
            # @info "Debug" g demands capacities aux_cap
            f, links_cost = mincost_flow(g, demands, capacities, aux_cap, optimizer)
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
        current_cap[nvtx-1, u] = 0.0
        current_cap[nvtx-1, j.data_location] = 0.0

        for i in 1:nvtx-2, j in 1:nvtx-2
            current_cap[i, j] += best_links[i, j]
        end
        s.nodes[best_node].current += j.containers

        @async begin
            sleep(j.duration / acceleration)
            for i in 1:nvtx-2, j in 1:nvtx-2
                current_cap[i, j] -= best_links[i, j]
            end
            s.nodes[best_node].current -= j.containers
        end

        links = deepcopy(current_cap[1:nvtx-2, 1:nvtx-2])
        nodes = spzeros(nvtx-2)
        for (id, n) in pairs(s.nodes)
            nodes[id] = n.current
        end
        duration = time() - start_iteration

        snap = SnapShot(links, nodes, best_cost, best_node, duration, duration - start_solving)

        push!(snapshots, snap)

        # @info u j current_cap best_links s.nodes
        # pretty_table(current_cap)
        # ii == 2 && break
        mod(ii, round(length(tasks)/1000)) == 0 && @info("Iteration $ii/$(length(tasks)): $(time() - start_simulation) seconds passed")
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
