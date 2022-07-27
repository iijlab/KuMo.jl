# SECTION - Script to simualte and analyse results for KuMo.jl

using GLMakie
using DataFrames
using CSV
using Colors

function interactive_analysis(df)
    df_no_norm = deepcopy(df)
    df_no_norm[!, 2:3] = df[!, 2:3] .* 1
    df_no_norm[!, 4:5] = df[!, 4:5] .* 10

    set_theme!(backgroundcolor=:gray90)
    fontsize_theme = Theme(fontsize=20)
    update_theme!(fontsize_theme)

    fig = Figure(resolution=(1200, 1000))

    Axis(
        fig[1, 1];
        title="Interactive analysis",
        ylabel="Resource load"
    )

    a, b, δ = 2, 5, 9
    colors = distinguishable_colors(length(a:δ), [RGB(1, 1, 1), RGB(0, 0, 0)], dropseed=true)
    _lines = Vector{Any}(fill(nothing, length(a:δ)))
    toggles = [Toggle(fig, active=i ≤ b) for i in a:δ]
    labels = map(l -> Label(fig, l), names(df)[a:δ])
    fig[1, 2] = grid!(hcat(toggles, labels), tellheight=false)

    for c in a:δ
        γ = c - a + 1
        _lines[γ] = lines!(df[!, Symbol("#time")], df[!, c], color=colors[γ])
        connect!(_lines[γ].visible, toggles[γ].active)
    end

    ax2 = Axis(
        fig[2, 1];
        xlabel="Time",
        ylabel="Total load"
    )

    _areas = Vector{Any}(fill(nothing, length(a:δ)))
    toggles2 = [Toggle(fig, active=i ≤ b) for i in a:δ]
    labels2 = map(l -> Label(fig, l), names(df)[a:δ])
    fig[2, 2] = grid!(hcat(to_value(toggles2), labels2), tellheight=false)

    @info "debug 1" toggles2 first(toggles2) first(toggles2).active toggles2[1].active[]

    actives(toggs) = filter(c -> toggs[c-a+1].active[], a:δ)

    function make_ys(toggs)
        @info "debug toggs" toggs
        C = actives(toggs)
        M = zeros(size(df_no_norm, 1), length(a:δ) + 1)
        for (i, c) in enumerate(a:δ)
            c ∈ C && (M[:, i+1] = df_no_norm[!, c])
        end
        return cumsum(M, dims=2)
    end

    Y = lift((t.active for t in toggles2)...) do actives...
        @info actives
        make_ys(toggles2)
    end

    @lift begin
        for c in 1:length(a:δ)
            _areas[c] === nothing || delete!(ax2.scene, _areas[c])
            _areas[c] = band!(df_no_norm[!, Symbol("#time")], $Y[:, c], $Y[:, c+1], color=colors[c])
            connect!(_areas[c].visible, toggles2[c].active)
        end
    end

    return fig
end

function interactive_analysis(path::String=joinpath(pwd(), "simu2.txt"))
    df = DataFrame(CSV.File(path; delim=' ', ignorerepeated=true))
    return interactive_analysis(df)
end

interactive_analysis()