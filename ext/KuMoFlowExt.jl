module KuMoFlowExt

# imports
using Graphs
using JuMP
using KuMo
using MathOptInterface

# exports
export MinCostFlow

# Core

"""
    MinCostFlow{O<:MathOptInterface.AbstractOptimizer} <: AbstractAlgorithm

A structure to construct a MinCostFlow algorithm associated with an NLP Optimizer, such as Ipopt.
"""
struct MinCostFlow{O<:MathOptInterface.AbstractOptimizer} <: KuMo.AbstractAlgorithm
    optimizer::Type{O}
end

@traitfn function mincost_flow(
    g::AG::Graphs.IsDirected,
    node_demand::AbstractVector,
    edge_capacity::AbstractMatrix,
    edge_current_cap::AbstractMatrix,
    optimizer;
    edge_demand::Union{Nothing,AbstractMatrix}=nothing,
    source_nodes=(),
    sink_nodes=()
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

"""
    inner_queue(
        g, u, j, nodes, capacities, state, algo::MinCostFlow, ii = 0;
        lck = ReentrantLock(), demands, links = nothing
    )

The inner queue step of the resource allocation of a new request. Uses a `MinCostFlow` algorithm.

# Arguments:
- `g`: a graph representing the topology of the network
- `u`: user location
- `j`: requested job
- `nodes`: nodes capacities
- `capacities`: links capacities
- `state`: current state of the network
- `algo`: `MinCostFlow <: AbstractAlgorithm`
- `ii`: a counter to mesure the progress in the simulation
- `lck`: a lck for asynchronous simulation
- `demands`: flow demands for `MinCostFlow` algorithm
- `links`: not needed for `MinCostFlow` algorithm
"""
function KuMo.inner_queue(
    g, u, j, nodes, capacities, state, algo::MinCostFlow, ii=0;
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

KuMo.vtx(::MinCostFlow) = 2

end
