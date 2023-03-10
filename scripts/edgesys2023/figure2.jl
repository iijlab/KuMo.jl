# include("common.jl")

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
    0:0.01:0.95;
    label=["\\bf convex" "\\bf monotonic" "\\em load +.2" "\\em cost +.5" "\\em cost ×2" "\\em idle cost ×1.5"],
    legend=:topleft,
    xlabel="load",
    ylabel="pseudo cost",
    yticks=0:1:10,
    xticks=0.25:0.25:1,
    xlims=(0.0, 1.0),
    ylims=(0.0, 10.0),
    # w=[2.0, 2.0, 1.0, 1.0, 1.0, 1.0],
    plot_titlefontsize=20,
    legendfontsize=10,
    legendtitlefontsize=12,
    labelfontsize=18,
    line=([2.5 2.5 1.25 1.25 1.25 1.25], [:solid :solid :dash :dot :dashdot :dashdotdot])
    # legendtitle="Pseudo-costs"
)
savefig(plot_pc, joinpath(figuresdir(), "figure2-pseudo_costs.pdf"))
