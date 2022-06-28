# Script to generate plots for different pseudo-cost functions

using KuMo
using GLMakie

set_theme!(backgroundcolor = :gray90)

fig = Figure(resolution = (1200,1000))

ax = Axis(fig[1, 1]; title = "Pseudo-costs sandbox", xlabel = "Pseudo-cost", ylabel = "Resource load")

toggles = [Toggle(fig, active = active) for active in [true, true, true]]
labels = [Label(fig, lift(_ -> "$l", t.active))
    for (t, l) in zip(toggles, ["convex", "monotonic", "convex (×2)"])]

fig[1, 2] = grid!(hcat(toggles, labels), tellheight = false)

line1 = lines!(
    0..0.9,
    x -> pseudo_cost.(1., x, Val(:default));
    label = "convex",
)
line2 = lines!(
    0..0.9,
    x -> pseudo_cost(1., x, Val(:equal_load_balancing)),
    label = "equal load balancing",
)
line3 = lines!(
    0..0.9,
    x -> pseudo_cost(1., x, Val(:default)) * 2,
    label = "convex (×2)",
)

# axislegend()

connect!(line1.visible, toggles[1].active)
connect!(line2.visible, toggles[2].active)
connect!(line3.visible, toggles[3].active)

fig
