abstract type AbstractResource end

struct Resource{T<:Number} <: AbstractResource
    capacity::T
end

capacity(r::R) where {R<:AbstractResource} = r.capacity

function pseudo_cost(cap, charge)
    ρ = charge / cap
    isapprox(1.0, ρ) || ρ > 1.0 && return typemax(Float64)
    return (2 * ρ - 1)^2 / (1 - ρ) + 1
end

pseudo_cost(r::R, charge) where {R<:AbstractResource} = pseudo_cost(capacity(r), charge)

# function predict_cost(resource, current, added)
#     pseudo_cost(resource, current) - pseudo_cost(resource, added)
# end
