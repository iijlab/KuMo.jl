include("common.jl")

# extra imports
import KuMo.VizStatsPlots

s1 = EDGESYS2023[:figure3]
s2 = EDGESYS2023[:figure4]

_, df1, _ = simulate(s1)
_, df2, _ = simulate(s2)

p1 = VizStatsPlots.plot_snaps(df1, :plot, Val(:nodes))
p2 = VizStatsPlots.plot_snaps(df1, :areaplot, Val(:nodes))
p3 = VizStatsPlots.plot_snaps(df2, :plot, Val(:nodes))

p = plot(p1, p2, p3; layout=(3,1), plot_titlefontsize=10, legendfontsize=6)

savefig(p, joinpath(figuresdir(), "figure3-equivalent_proportional_nodes.pdf"))
