# Packages requirement (only KuMo.jl is private and restricted to IIJ lab members)
using KuMo, DataFrames, StatsPlots, CSV, PGFPlotsX, Plots

scenario5() = scenario(;
    duration=100,
    nodes=[
        MultiplicativeNode(100, 1),
        MultiplicativeNode(100, 2),
        MultiplicativeNode(100, 4),
        MultiplicativeNode(100, 8),
    ],
    users=[
        # user 1
        user(job(0, 1, rand(1:2), 4.5, 0), 0.06, rand(1:2); stop=34.5),
        user(job(0, 1, rand(1:2), 4.5, 0), 0.06, rand(1:2); start=6.015, stop=39.0),
        user(job(0, 1, rand(1:2), 4.5, 0), 0.06, rand(1:2); start=12.03, stop=43.5),
        user(job(0, 1, rand(1:2), 4.5, 0), 0.06, rand(1:2); start=18.045, stop=48.0),
        user(job(0, 1, rand(1:2), 4.5, 0), 0.06, rand(1:2); start=22.56, stop=52.5), user(job(0, 1, rand(1:2), 2.25, 0), 0.06, rand(1:2); start=43.5, stop=61.5),
        user(job(0, 1, rand(1:2), 2.25, 0), 0.06, rand(1:2); start=50.25, stop=59.25),
    ]
)

# Simulation
_, df5, _ = simulate(scenario5(), ShortestPath(); speed=0);

# Line plot
begin
    p5_line = @df df5 plot(:instant, cols(6:9),
        legend=:none, tex_output_standalone=true, xlabel="time", ylabel="load",
        title="Resources allocations using basic pseudo-cost functions", w=1.25,
    )
end