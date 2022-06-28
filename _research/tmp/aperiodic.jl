# Packages requirement (only KuMo.jl is private and restricted to IIJ lab members)

using KuMo, DataFrames, StatsPlots, CSV, PGFPlotsX, Plots

function scenario5(;
    max_load=3.5,
    nodes=(4, 100),
    rate=0.01,
    j=job(0, 1, rand(1:4), 1, 0)
)
    _requests = Vector{KuMo.Request{typeof(j)}}()

    L = prod(nodes)
    r = rate
    λ = max_load
    n = nodes[1]
    δ = j.duration
    c = j.containers

    π1 = λ / r
    π2 = (2n - λ) / r

    for i in 0:π1+π2
        for t in i:δ:π1+π2-i
            i ≤ π1 && push!(_requests, KuMo.Request(j, t))
        end
    end

    @info "Parameters" L r λ n δ c π1 π2 length(_requests)

    scenario(;
        duration=1000,
        nodes=[
            MultiplicativeNode(100, 1),
            MultiplicativeNode(100, 2),
            MultiplicativeNode(100, 4),
            MultiplicativeNode(100, 8),
        ],
        # nodes=(4, 100),
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
