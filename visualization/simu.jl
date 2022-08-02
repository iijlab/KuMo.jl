# SECTION - Script to simualte and analyse results for KuMo.jl

using KuMo
using GLMakie
using DataFrames
using CSV
using Colors
using Distributions

function interactive_analysis(df, norms)
    a, b, _, d = marks(df)
    δ = d === nothing ? b : d
    colors = distinguishable_colors(length(a:δ), [RGB(1, 1, 1), RGB(0, 0, 0)], dropseed=true)

    set_theme!(backgroundcolor=:gray90)
    fontsize_theme = Theme(fontsize=20)
    update_theme!(fontsize_theme)

    set_window_config!(;
        title="KuMo.jl: scenario analysis"
    )

    fig = Figure(resolution=(1200, 1000))

    Axis(
        fig[1, 1];
        title="Interactive analysis",
        xlabel="Time",
        ylabel="Resource load (normalized)"
    )

    _lines = Vector{Any}(fill(nothing, length(a:δ)))
    toggles = [Toggle(fig, active=i ≤ b) for i in a:δ]
    labels = map(l -> Label(fig, l), names(df)[a:δ])
    fig[1, 2][1, 1] = grid!(hcat(toggles, labels), tellheight=false)

    for c in a:δ
        γ = c - a + 1
        _lines[γ] = lines!(df[!, :instant], df[!, c], color=colors[γ])
        connect!(_lines[γ].visible, toggles[γ].active)
    end

    df_no_norm = deepcopy(df)
    for (tag, val) in norms
        df_no_norm[!, Symbol(tag)] = df_no_norm[!, Symbol(tag)] .* val
    end

    ax2 = Axis(
        fig[2, 1];
        xlabel="Time",
        ylabel="Total load"
    )

    _areas = Vector{Any}(fill(nothing, length(a:δ)))
    toggles2 = [Toggle(fig, active=i ≤ b) for i in a:δ]
    labels2 = map(l -> Label(fig, l), names(df)[a:δ])
    fig[2, 2][1, 1] = grid!(hcat(to_value(toggles2), labels2), tellheight=false)


    actives(toggs) = filter(c -> toggs[c-a+1].active[], a:δ)

    function make_ys(toggs)
        C = actives(toggs)
        M = zeros(size(df_no_norm, 1), length(a:δ) + 1)
        for (i, c) in enumerate(a:δ)
            c ∈ C && (M[:, i+1] = df_no_norm[!, c])
        end
        return cumsum(M, dims=2)
    end

    Y = lift((t.active for t in toggles2)...) do actives...
        make_ys(toggles2)
    end

    @lift begin
        for c in 1:length(a:δ)
            _areas[c] === nothing || delete!(ax2.scene, _areas[c])
            _areas[c] = band!(df[!, :instant], $Y[:, c], $Y[:, c+1], color=colors[c])
            connect!(_areas[c].visible, toggles2[c].active)
        end
    end

    Menu(fig[3, :][1, 4], prompt="Select plot type(s)...", options=["all", "resource load", "total load"], width=300)
    Menu(fig[3, :][1, 3], prompt="Select output format...", options=[".pdf", ".tikz", ".png"], width=300)
    Textbox(fig[3, :][1, 2], placeholder="file_base_name", width=300)
    b_save = Button(fig[3, :][1, 5], label="save")

    return fig
end

function interactive_analysis(path::String; norms=Dict())
    df = DataFrame(CSV.File(path; delim=','))
    return interactive_analysis(df, norms)
end

function interactive_analysis(s::Scenario=SCENARII[:four_nodes]; norms=Dict())
    df = simulate(s, ShortestPath())[2]
    return interactive_analysis(df, norms)
end

norms = Dict(
    [
    "2" => 10,
    "3" => 10,
]
)
interactive_analysis("simu2.csv"; norms)

interactive_analysis()

interactive_analysis(SCENARII[:four_nodes_four_users])

interactive_analysis(SCENARII[:square])