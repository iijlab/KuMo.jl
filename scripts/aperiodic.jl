# Packages requirement (only KuMo.jl is private and restricted to IIJ lab members)

using KuMo, DataFrames, StatsPlots, CSV, PGFPlotsX, Plots

function scenario5(;
    max_load=3.5,
    nodes=(4, 10),
    rate=0.01,
    j=job(0, 1, rand(1:4), 0.5, 0)
)
    _requests = Vector{KuMo.Request{typeof(j)}}()

    L = prod(nodes)
    r = rate
    λ = max_load
    n = nodes[1]
    δ = j.duration
    c = j.containers

    σ = c / (100 * r)
    γ = δ / σ

    π1 = λ / r
    π2 = (2n - λ) / r

    for (i, t) in enumerate(σ:σ:π1)
        k = (i - 1) ÷ γ + 1
        foreach(_ -> push!(_requests, KuMo.Request(j, t)), 1:k)
        t ≈ π1 && @info("k = $k")
    end

    χ = ceil(Int, λ / (δ * r))
    for t in π1+σ:σ:π2
        foreach(_ -> push!(_requests, KuMo.Request(j, t)), 1:χ)
    end

    for (i, t) in enumerate(π2+σ:σ:π1+π2)
        k = χ - (i - 1) ÷ γ
        foreach(_ -> push!(_requests, KuMo.Request(j, t)), 1:k)
    end

    @info "Parameters" L r λ n δ c σ γ π1 π2 χ length(_requests)

    scenario(;
        duration=1000,
        # nodes=[
        #     MultiplicativeNode(100, 1),
        #     MultiplicativeNode(100, 2),
        #     MultiplicativeNode(100, 4),
        #     MultiplicativeNode(100, 8),
        # ],
        nodes=(4, 100),
        users=[
            # user 1
            user(KuMo.Requests(_requests), 1),
        ]
    )
end

# Simulation
_, df5, _ = simulate(scenario5(), ShortestPath(); speed=0);

# Line plot
begin
    p5_line = @df df5 plot(:instant, cols(6:9),
        legend=:none, tex_output_standalone=true, xlabel="time", ylabel="load",
        title="Resources allocations using basic pseudo-cost functions", w=1.25,
    )
end

