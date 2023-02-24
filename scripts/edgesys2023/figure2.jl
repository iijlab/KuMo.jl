include("common.jl")

convex_pc = x -> pseudo_cost(1.0, x, Val(:default))
monotonic_pc = x -> pseudo_cost(1.0, x, Val(:equal_load_balancing))
load_plus_pc = x -> pseudo_cost(1.0, x + 0.2, Val(:default))
cost_plus_pc = x -> pseudo_cost(1.0, x, Val(:default)) + 0.5
cost_times_pc = x -> pseudo_cost(1.0, x, Val(:default)) * 2.0
idle_cost_pc = x -> pseudo_cost(1.0, x, Val(:idle_node), 1.5)

plot_pc = StatsPlots.plot(
    [
        convex_pc,
        monotonic_pc,
        load_plus_pc,
        cost_plus_pc,
        cost_times_pc,
        idle_cost_pc,
    ],
    0:0.01:0.9;
    label=["convex" "monotonic" "load +.2" "cost +.5" "cost ×2" "idle cost ×1.5"],
    legend=:topleft,
    xlabel="load",
    ylabel="pseudo cost",
    yticks=0:1:10,
    xticks=0:0.25:1,
    ylims = (0., 10.),
    w=1.,
    plot_titlefontsize=20,
    legendfontsize=12,
    labelfontsize=18
)
savefig(plot_pc, joinpath(figuresdir(), "figure2-pseudo_costs.pdf"))
