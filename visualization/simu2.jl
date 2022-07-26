# SECTION - Script to simualte and analyse results for KuMo.jl

using KuMo
using GLMakie
using DataFrames

function interactive_analysis(df)
    df_no_norm = deepcopy(df)
    df_no_norm[!, 2:3] = df[!,2:3] .* 1
    df_no_norm[!, 4:5] = df[!,4:5] .* 10

    set_theme!(backgroundcolor=:gray90)
    fontsize_theme = Theme(fontsize=20)
    update_theme!(fontsize_theme)

    fig = Figure(resolution=(1200, 1000))

    Axis(
        fig[1, 1];
        title="Interactive analysis",
        ylabel="Resource load",
    )

    a, b, δ = 2, 5, 9
    _lines = Vector{Any}(fill(nothing, length(a:δ)))
    toggles = [Toggle(fig, active = i ≤ b) for i in a:δ]
    labels = map(l -> Label(fig, l), names(df)[a:δ])
    fig[1, 2] = grid!(hcat(toggles, labels), tellheight = false)

    for c in a:δ
        γ = c - a + 1
        _lines[γ] = lines!(df[!,Symbol("#time")], df[!, c])
        connect!(_lines[γ].visible, toggles[γ].active)
    end

    Axis(
        fig[2, 1];
        xlabel="Time",
        ylabel="Total load",
    )

    _areas = Vector{Any}(fill(nothing, length(a:δ)))
    toggles2 = [Toggle(fig, active = i ≤ b) for i in a:δ]
    labels2 = map(l -> Label(fig, l), names(df)[a:δ])
    fig[2, 2] = grid!(hcat(toggles2, labels2), tellheight = false)

    for c in a:δ
        γ = c - a + 1
        _areas[γ] = density!(df_no_norm[!,Symbol("#time")], df_no_norm[!, c])
        connect!(_areas[γ].visible, toggles2[γ].active)
    end

    return fig
end

function interactive_analysis(path::String = joinpath(pwd(), "simu2.txt"))
    df = DataFrame(CSV.File(path; delim=' ', ignorerepeated=true))
    return interactive_analysis(df)
end
