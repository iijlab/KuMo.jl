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

link(cap, cur) = Link(cap, cur)

function pseudo_cost(r::R, charge=0) where {R<:AbstractResource}
    ρ = (r.current + charge) / r.capacity
    return (2 * ρ - 1)^2 / (1 - ρ) + 1
end

predict_cost(resource, charge) = pseudo_cost(resource, charge) - pseudo_cost(resource)
