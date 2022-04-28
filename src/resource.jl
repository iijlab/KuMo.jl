abstract type AbstractResource end

mutable struct Node <: AbstractResource
    capacity::Int
    current::Int

    Node(cap, cur=cap) = new(cap, cur)
end

struct Link <: AbstractResource
    capacity::Int
    current::Int

    Link(cap, cur=0) = new(cap, cur)
end

function pseudo_cost(r)
    ρ = r.current / r.capacity
    return (2 * ρ - 1)^2 / (1 - ρ) + 1
end