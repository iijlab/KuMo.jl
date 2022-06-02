struct Topology{N<:AbstractNode,L<:AbstractLink}
    nodes::Dictionary{Int,N}
    links::Dictionary{Tuple{Int,Int},L}
end

vtx(::MinCostFlow) = 2
vtx(_) = 0

function graph(topo::Topology, algo)
    n = length(topo.nodes) + vtx(algo)
    g = SimpleDiGraph(n)
    C = spzeros(n, n)
    for (e, r) in pairs(topo.links)
        add_edge!(g, e[1], e[2])
        add_edge!(g, e[2], e[1])
        C[e[1], e[2]] = capacity(r)
        C[e[2], e[1]] = capacity(r)
    end
    return g, C
end
