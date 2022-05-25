function pseudo_cost(current, capacity, charge=0)
    ρ = (current + charge) / capacity
    isapprox(1.0, ρ) || ρ > 1.0 && return typemax(Float64)
    return (2 * ρ - 1)^2 / (1 - ρ) + 1
end

function mincost_flow end

@traitfn function mincost_flow(g::AG::Graphs.IsDirected,
    node_demand::AbstractVector,
    edge_capacity::AbstractMatrix,
    edge_current_cap::AbstractMatrix,
    optimizer;
    edge_demand::Union{Nothing,AbstractMatrix}=nothing,
    source_nodes=(), # Source nodes at which to allow a netflow greater than nodal demand
    sink_nodes=()   # Sink nodes at which to allow a netflow less than nodal demand
) where {AG<:Graphs.AbstractGraph}

    m = JuMP.Model(optimizer)

    register(m, :pseudo_cost, 3, pseudo_cost; autodiff=true)
    vtxs = vertices(g)

    source_nodes = [v for v in vtxs if v in source_nodes || node_demand[v] < 0]
    sink_nodes = [v for v in vtxs if v in sink_nodes || node_demand[v] > 0]

    # edgs = map(e -> (src(e), dst(e)), edges(g))
    sg, _ = induced_subgraph(g, 1:(nv(g)-2))

    @variable(m, 0 <= f[i=vtxs, j=vtxs; (i, j) in Graphs.edges(g)] <= abs(edge_capacity[i, j] - edge_current_cap[i, j]))
    # @constraint(m, 0 <= f[i=vtxs, j=vtxs; (i, j) in Graphs.edges(g)] <= abs(edge_capacity[i, j] - edge_current_cap[i, j]))
    # for e in Graphs.edges(g)
    #     set_integer(f[src(e), dst(e)])
    # end

    @NLobjective(m, Min, sum(f[src(e), dst(e)] * pseudo_cost(
        edge_current_cap[src(e), dst(e)],
        edge_capacity[src(e), dst(e)],
        f[src(e), dst(e)]
    ) for e in Graphs.edges(sg)))
    # @NLobjective(m, Min, sum(
    #     pseudo_cost(
    #         edge_current_cap[src(e), dst(e)],
    #         edge_capacity[src(e), dst(e)],
    #         f[src(e), dst(e)]
    #     )) for e in edgs
    # )


    for v in Graphs.vertices(g)
        if v in source_nodes
            @constraint(m,
                sum(f[v, vout] for vout in outneighbors(g, v)) - sum(f[vin, v] for vin in Graphs.inneighbors(g, v)) >= -node_demand[v]
            )
        elseif v in sink_nodes
            @constraint(m,
                sum(f[vin, v] for vin in Graphs.inneighbors(g, v)) - sum(f[v, vout] for vout in outneighbors(g, v)) >= node_demand[v]
            )
        else
            @constraint(m,
                sum(f[vin, v] for vin in Graphs.inneighbors(g, v)) == sum(f[v, vout] for vout in outneighbors(g, v))
            )
        end
    end

    if edge_demand isa AbstractMatrix
        for e in Graphs.edges(g)
            (i, j) = Tuple(e)
            JuMP.set_lower_bound(f[i, j], edge_demand[i, j])
        end
    end
    optimize!(m)
    ts = termination_status(m)
    result_flow = spzeros(nv(g), nv(g))
    # if ts != MOI.OPTIMAL
    #     @warn "Problem does not have an optimal solution, status: $(ts)"
    #     return result_flow
    # end
    for e in Graphs.edges(g)
        (i, j) = Tuple(e)
        result_flow[i, j] = round(JuMP.value(f[i, j]))
    end
    pretty_table(result_flow)
    return result_flow
end
