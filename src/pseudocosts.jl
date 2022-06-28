function pseudo_cost(cap, charge, ::Val{:default})
    ρ = charge / cap
    isapprox(1.0, ρ) || ρ > 1.0 && (@debug("Error in pseudo_cost", charge, cap); return Inf)
    return (2 * ρ - 1)^2 / (1 - ρ) + 1
end

function pseudo_cost(cap, charge, resource, param...)
    return cap == 0 ? 0.0 : pseudo_cost(cap, charge, Val(resource), param...)
end

function pseudo_cost(cap, charge, ::Val{:equal_load_balancing})
    ρ = charge / cap
    isapprox(1.0, ρ) || ρ > 1.0 && (@debug("Error in pseudo_cost", charge, cap); return Inf)
    return ρ^4.5 / (1 - ρ) + 1
end

function pseudo_cost(cap, charge, ::Val{:idle_node}, n)
    ρ = charge / cap
    isapprox(1.0, ρ) || ρ > 1.0 && (@debug("Error in pseudo_cost", charge, cap); return Inf)
    return n * (2 * ρ - 1)^2 / (1 - ρ^n) + 1
end

function pseudo_cost(cap, charge, ::Val{:premium_node}, Δ)
    ρ = charge / cap + Δ
    isapprox(1.0, ρ) || ρ > 1.0 && (@debug("Error in pseudo_cost", charge, cap); return Inf)
    return (2 * ρ - 1)^2 / (1 - ρ) + 1
end
