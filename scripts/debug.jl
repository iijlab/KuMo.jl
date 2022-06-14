# Packages requirement (only KuMo.jl is private and restricted to IIJ lab members)
using KuMo, DataFrames, StatsPlots, CSV, PGFPlotsX, Plots

scenario5() = scenario(;
    duration=100,
    nodes=(4, 100),
    users=[
        # user 1
        user(job(0, 1, rand(1:2), 4.5, 0), 0.06, rand(1:2); stop=34.5 |> prevfloat),
        user(job(0, 1, rand(1:2), 4.5, 0), 0.06, rand(1:2); start=6.015, stop=39.0 |> prevfloat),
        user(job(0, 1, rand(1:2), 4.5, 0), 0.06, rand(1:2); start=12.03, stop=43.5 |> prevfloat),
        user(job(0, 1, rand(1:2), 4.5, 0), 0.06, rand(1:2); start=18.045, stop=48.0 |> prevfloat),
        user(job(0, 1, rand(1:2), 4.5, 0), 0.06, rand(1:2); start=22.56, stop=52.5 |> prevfloat),
        user(job(0, 1, rand(1:2), 4.5, 0), 0.06, rand(1:2); start=40, stop=80),
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

df2 = df5[450:800, 5:9]

pc1 = ρ -> (2 * ρ - 1)^2 / (1 - ρ) + 1

pc1(0.65), pc1(0.35)
pc1(0.60), pc1(0.35)
pc1(0.65), pc1(0.30)
pc1(0.55), pc1(0.49)
map(pc1, [0.67, 0.71, 0.25])