struct Topology{N <: Number, L <: Number}
    nodes::Dictionary{Int, Node{N}}
    links::Dictionary{Tuple{Int, Int}, Link{L}}
end
