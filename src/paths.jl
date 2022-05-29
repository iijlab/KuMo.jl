abstract type AbstractAlgorithm end

struct MinCostFlow{O<:MathOptInterface.AbstractOptimizer} <: AbstractAlgorithm
    optimizer::Type{O}
end

struct ShortestPath <: AbstractAlgorithm end

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
    JuMP.set_silent(m)
    JuMP.set_optimizer_attribute(m, "tol", 0.01)

    register(m, :pseudo_cost, 2, pseudo_cost; autodiff=true)
    vtxs = vertices(g)

    source_nodes = [v for v in vtxs if v in source_nodes || node_demand[v] < 0]
    sink_nodes = [v for v in vtxs if v in sink_nodes || node_demand[v] > 0]

    sg, _ = induced_subgraph(g, 1:(nv(g)-2))

    @variable(m, 0 <= f[i=vtxs, j=vtxs; (i, j) in Graphs.edges(g)] <= abs(edge_capacity[i, j] - edge_current_cap[i, j]))


    @NLobjective(m, Min, sum(1.0 * pseudo_cost(
        edge_capacity[src(e), dst(e)],
        edge_current_cap[src(e), dst(e)] + f[src(e), dst(e)],
    ) for e in Graphs.edges(sg)))


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

    for e in Graphs.edges(g)
        (i, j) = Tuple(e)
        result_flow[i, j] = round(JuMP.value(f[i, j]))
    end
    return result_flow, JuMP.objective_value(m)
end
