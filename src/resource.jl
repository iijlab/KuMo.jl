abstract type AbstractResource end

struct Resource{T <: Number} <: AbstractResource
    capacity::T
end

capacity(r::R) where {R <: AbstractResource} = r.capacity

function pseudo_cost(r::R, charge) where {R<:AbstractResource}
    ρ = charge / capacity(r)
    return (2 * ρ - 1)^2 / (1 - ρ) + 1
end

function predict_cost(resource, current, added)
    pseudo_cost(resource, current) - pseudo_cost(resource, added)
end
