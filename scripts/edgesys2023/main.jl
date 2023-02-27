include("common.jl")

#SECTION - edge
s = EDGESYS2023[:edge]

p = simulate_and_plot(s, ShortestPath(); target=:nodes, plot_type=:areaplot)[1]

f = "figure-edge.pdf"

savefig(p, joinpath(figuresdir(), f))
