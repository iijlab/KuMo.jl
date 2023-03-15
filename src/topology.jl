abstract type AbstractTopology end

nodes(topo::AbstractTopology) = topo.nodes
nodes(topo::AbstractTopology, n) = topo.nodes[n]

links(topo::AbstractTopology) = topo.links
links(topo::AbstractTopology, i, j) = topo.links[(i, j)]

"""
    DirectedTopology{N<:AbstractNode,L<:AbstractLink}

A structure to store the topology of a network. Beside the graph structure itself, it also stores the kinds of all nodes and links.
"""
struct DirectedTopology{N<:AbstractNode,L<:AbstractLink} <: AbstractTopology
    nodes::Dictionary{Int,N}
    links::Dictionary{Tuple{Int,Int},L}
end

"""
    Topology{N<:AbstractNode,L<:AbstractLink}

A structure to store the topology of a network. Beside the graph structure itself, it also stores the kinds of all nodes and links.
"""
struct Topology{N<:AbstractNode,L<:AbstractLink} <: AbstractTopology
    nodes::Dictionary{Int,N}
    links::Dictionary{Tuple{Int,Int},L}
end

links(topo::Topology, i, j) = topo.links[minmax(i, j)]

"""
    vtx(algorithm::AbstractAlgorithm)
Return the number of additional vertices required by the `algorithm` used to allocate resources in the network.
"""
vtx(_) = 0

make_graph(n, ::DirectedTopology) = SimpleDiGraph(n)
make_graph(n, ::Topology) = SimpleGraph(n)

function make_capacity!(g::SimpleGraph, a, b, C, r)
    α, β = minmax(a, b)
    add_edge!(g, α, β)
    C[α, β] = capacity(r)
end

function make_capacity!(g::SimpleDiGraph, α, β, C, r)
    add_edge!(g, α, β)
    C[α, β] = capacity(r)
end

"""
    graph(topo::Topology, algorithm::AbstractAlgorithm)
Creates an appropriate digraph using Graph.jl based on a topology and the requirement of an algorithm.
"""
function graph(topo::AbstractTopology, algo)
    n = length(topo.nodes) + vtx(algo)
    g = make_graph(n, topo)
    C = spzeros(n, n)
    foreach(((e, r),) -> make_capacity!(g, e[1], e[2], C, r), pairs(topo.links))
    return g, C
end
