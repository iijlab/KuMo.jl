include("common.jl")

convex_pc = x -> pseudo_cost(1.0, x, Val(:default))
monotonic_pc = x -> pseudo_cost(1.0, x, Val(:equal_load_balancing))

plot_pc = StatsPlots.plot(
    [convex_pc, monotonic_pc],
    0:0.01:0.9;
    label=["convex cost func" "monotonic cost func"],
    legend=:topleft,
    xlabel="load",
    ylabel="pseudo cost",
    yticks=0:1:10,
    xticks=0:0.25:1,
    w=1.25,
    plot_titlefontsize=20,
    legendfontsize=12,
    labelfontsize=18
)
savefig(plot_pc, joinpath(figuresdir(), "figure2-standard_pseudo_costs.pdf"))
