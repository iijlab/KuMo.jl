# Packages requirement (only KuMo.jl is private and restricted to IIJ lab members)
using KuMo, DataFrames, StatsPlots, CSV, PGFPlotsX, Plots

function scenario5(;
    max_load = 3.48,
    nodes = (4, 100),
    rate = 0.01,
    j = job(0, 1, rand(1:4), jd, 0),
)
    _requests = Vector{KuMo.Request{typeof(j)}}()
    total_capacity = prod(nodes)

    c = nodes[2]

    jd = j.duration
    jc = j.containers

    γ = jd * jc / (c * rate)

    for t in 0:γ:(max_load * 100)

    end



    total_capacity = prod(nodes)

    c = nodes[2]

    γ = rate * c
    period = jd / γ
    plateau = c / γ

    π1 = c * max_load / γ
    π2 = π1 + plateau - period

    @info "debrief" total_capacity γ period c plateau π1 π2 rate

    for (i, t) in enumerate(0:period:(π1 - period))
        k = (i - 1) ÷ γ + 1
        foreach(_ -> push!(_requests, KuMo.Request(j, t)), 1:k)
    end

    for t in π1:period:(π2 - period)
        foreach(_ -> push!(_requests, KuMo.Request(j, t)), 1:π1)
    end

    it = π2:period:(π1+π2-period)
    for (i, t) in enumerate(it)
        ι = length(it) - i
        k = (ι - 1) ÷ γ + 1
        foreach(_ -> push!(_requests, KuMo.Request(j, t)), 1:k)
    end

    scenario(;
    duration=1000,
    # nodes=[
    #     MultiplicativeNode(100, 1),
    #     MultiplicativeNode(100, 2),
    #     MultiplicativeNode(100, 4),
    #     MultiplicativeNode(100, 8),
    # ],
    nodes = (4, 100),
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
