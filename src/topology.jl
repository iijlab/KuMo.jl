"""
    Topology{N<:AbstractNode,L<:AbstractLink}

A structure to store the topology of a network. Beside the graph structure itself, it also stores the kinds of all nodes and links.
"""
struct Topology{N<:AbstractNode,L<:AbstractLink}
    nodes::Dictionary{Int,N}
    links::Dictionary{Tuple{Int,Int},L}
end

"""
    vtx(algorithm::AbstractAlgorithm)
Return the number of additional vertices required by the `algorithm` used to allocate resources in the network.
"""
vtx(::MinCostFlow) = 2
vtx(_) = 0

"""
    graph(topo::Topology, algorithm::AbstractAlgorithm)
Creates an appropriate digraph using Graph.jl based on a topology and the requirement of an algorithm.
"""
function graph(topo::Topology, algo)
    n = length(topo.nodes) + vtx(algo)
    g = SimpleDiGraph(n)
    C = spzeros(n, n)
    for (e, r) in pairs(topo.links)
        add_edge!(g, e[1], e[2])
        # add_edge!(g, e[2], e[1])
        C[e[1], e[2]] = capacity(r)
        # C[e[2], e[1]] = capacity(r)
    end
    # show(g)
    return g, C
end
