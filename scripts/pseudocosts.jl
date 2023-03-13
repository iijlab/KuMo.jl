#SECTION 2 - Figure 3 - Standard cost functions and variants

function figure_3(;
    latex=true,
    output=joinpath(figuresdir(), "figure3_pseudocosts.pdf"),
    select=:all, # use :standard or :variants to plot respective pseudocosts
    title=true
)

    pcs = Vector{Function}()
    labels = Vector{String}()
    thickness = Vector{Float64}()
    linestyles = Vector{Symbol}()

    ls = latex ? "\\bf " : ""

    if select ∈ [:all, :standard]
        # Standard pseudo costs
        convex_pc = x -> pseudo_cost(1.0, x, Val(:default))
        monotonic_pc = x -> pseudo_cost(1.0, x, Val(:equal_load_balancing))
        foreach(pc -> push!(pcs, pc), [convex_pc, monotonic_pc])
        foreach(label -> push!(labels, label), [(ls * "convex") (ls * "monotonic")])
        foreach(thick -> push!(thickness, thick), [1.25, 1.25])
        foreach(linestyle -> push!(linestyles, linestyle), [:solid, :solid])
    end

    lv = latex ? "\\em " : ""

    if select ∈ [:all, :variants]
        # Variants
        load_plus_pc = x -> pseudo_cost(1.0, x + 0.2, Val(:default))
        cost_plus_pc = x -> pseudo_cost(1.0, x, Val(:default)) + 0.5
        cost_times_pc = x -> pseudo_cost(1.0, x, Val(:default)) * 2.0
        idle_cost_pc = x -> pseudo_cost(1.0, x, Val(:idle_node), 1.5)
        foreach(
            pc -> push!(pcs, pc),
            [load_plus_pc, cost_plus_pc, cost_times_pc, idle_cost_pc],
        )
        foreach(
            label -> push!(labels, label),
            [
                (lv * "convex load +.2")
                (lv * "convex cost +.5")
                (lv * "convex cost ×2")
                (lv * "convex idle cost ×1.5")
            ],
        )
        foreach(thick -> push!(thickness, thick), [0.625, 0.625, 0.625, 0.625])
        foreach(linestyle -> push!(linestyles, linestyle), [:dash, :dot, :dashdot, :dashdotdot])
    end

    plot_pc = plot(
        pcs,
        0:0.01:0.95;
        label=reshape(labels, 1, :),
        legend=:topleft,
        line=(reshape(thickness, 1, :), reshape(linestyles, 1, :)),
        thickness_scaling=latex ? 2 : 1,
        title=title ? (ls * "Figure 3: Standard cost functions and variants") : "",
        titlefontsize=10,
        w=0.5,
        xlabel="load",
        xlims=(0, 1),
        xticks=0.25:0.25:1,
        ylabel="pseudo cost",
        ylims=(0.0, 10.0),
        yticks=0:1:10
    )

    splitdir(output)[1] |> mkpath
    savefig(plot_pc, output)

    return plot_pc
end

# Uncomment to generate the plots independently of the main function
# figure_3()
# figure_3(
#     select=:standard,
#     output=joinpath(figuresdir(), "figure3_pseudocosts_standard_standard.pdf")
# )
# figure_3(
#     select=:variants,
#     output=joinpath(figuresdir(), "figure3_pseudocosts_standard_variants.pdf"),
# )
