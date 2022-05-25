function simulate(s::Scenario, optimizer; acceleration=1)
    tasks = Vector{Pair{Float64,Tuple{Int,Job}}}()

    all_queue = false

    for u in s.users
        jr = u.job_requests
        j = jr.job
        p = jr.period

        foreach(occ -> push!(tasks, occ => (u.location, j)), 0:p:s.duration)
    end

    c = Channel{Tuple{Int,Job}}(10^7)

    for (i, t) in enumerate(tasks)
        @async begin
            sleep(t[1] / acceleration)
            put!(c, t[2])
            i == length(tasks) && (all_queue = true)
        end
    end

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

    while !all_queue || isready(c)
        ii += 1
        u, j = take!(c)

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
            # @info "Debug" g demands capacities current_cap
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
            aux_cap[i, nvtx] = 0.0
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

        # @info u j current_cap best_links s.nodes
        # ii == 100 && break
    end

    return c
end
