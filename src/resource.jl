abstract type AbstractResource end

struct Resource{T<:Number} <: AbstractResource
    capacity::T
end

capacity(r::R) where {R<:AbstractResource} = r.capacity

function pseudo_cost(cap, charge)
    cap == 0 && return 0.0
    ρ = charge / cap
    isapprox(1.0, ρ) || ρ > 1.0 && (@warn("Error in pseudo_cost", charge, cap); return Inf)
    return (2 * ρ - 1)^2 / (1 - ρ) + 1
end

pseudo_cost(r::R, charge) where {R<:AbstractResource} = pseudo_cost(capacity(r), charge)
