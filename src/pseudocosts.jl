function pseudo_cost(cap, charge, ::Val{:default})
    ρ = charge / cap
    isapprox(1.0, ρ) || ρ > 1.0 && (@warn("Error in pseudo_cost", charge, cap); return Inf)
    return (2 * ρ - 1)^2 / (1 - ρ) + 1
end

function pseudo_cost(cap, charge, resource=:default)
    return cap == 0 ? 0.0 : pseudo_cost(cap, charge, Val(resource))
end

function pseudo_cost(cap, charge, ::Val{:optical_link})
    ρ = charge / cap
    isapprox(1.0, ρ) || ρ > 1.0 && (@warn("Error in pseudo_cost", charge, cap); return Inf)
    return (ρ - 0.0375)^2 / (1 - ρ)
end
