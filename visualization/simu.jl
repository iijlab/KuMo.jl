# SECTION - Script to simualte and analyse results for KuMo.jl

using KuMo
using GLMakie
using DataFrames
using CSV

function interactive_analysis(df)
    set_theme!(backgroundcolor=:gray90)
    fontsize_theme = Theme(fontsize=20)
    update_theme!(fontsize_theme)

    fig = Figure(resolution=(1200, 1000))

    Axis(
        fig[1, 1];
        title="Interactive analysis",
        xlabel="Time",
        ylabel="Resource load",
    )

    a, b, _, d = marks(df)
    δ = d === nothing ? b : d
    _lines = Vector{Any}(fill(nothing, length(a:δ)))
    toggles = [Toggle(fig, active = i ≤ b) for i in a:δ]
    labels = map(l -> Label(fig, l), names(df)[a:δ])
    fig[1, 2][1,1] = grid!(hcat(toggles, labels), tellheight = false)

    for c in a:δ
        γ = c - a + 1
        _lines[γ] = lines!(df[!,:instant], df[!, c])
        connect!(_lines[γ].visible, toggles[γ].active)
    end

    Axis(
        fig[2, 1];
        xlabel="Time",
        ylabel="Total load",
    )

    _areas = Vector{Any}(fill(nothing, length(a:δ)))
    toggles2 = Observable([Toggle(fig, active = i ≤ b) for i in a:δ])
    labels2 = map(l -> Label(fig, l), names(df)[a:δ])
    fig[2, 2][1,1] = grid!(hcat(toggles2[], labels2), tellheight = false)


    actives(toggs) = filter(c -> to_value(toggs)[c-a+1].active[], a:δ)

    function make_ys(toggs)
        C = actives(toggs)
        M = zeros(size(df, 1), length(C) + 1)
        for (i, c) in enumerate(C)
            M[:, i + 1] = df[!, c]
        end
        return cumsum(M, dims=2)
    end

    Y = lift(toggles2) do vals
        make_ys(vals)
    end

    @lift begin
        c = 0
        for i in a:δ
            γ = i - a + 1
            if i ∈ actives($toggles2)
                c += 1
                _areas[γ] = band!(df[!,:instant], $Y[:,c], $Y[:,c+1])
            else
                _areas[γ] = band!(df[!,:instant], $Y[:,1], $Y[:,1])
            end
            connect!(_areas[γ].visible, $toggles2[γ].active)
        end
    end

    Menu(fig[3,:][1,4], prompt = "Select plot type(s)...",options = ["all", "area", "lines"], width = 300)
    Menu(fig[3,:][1,3], prompt = "Select output format...",options = ["pdf", "tex/tikz", "png"], width = 300)
    Textbox(fig[3,:][1,2], placeholder = "file_name", width = 300)
    b_save = Button(fig[3, :][1,5], label = "save")

    # on(b_save.clicks) do end

    for t in toggles2[]
        lift(t) do n
            notify(toggles2)
        end
    end

    return fig, df
end

function interactive_analysis(path::String = joinpath(pwd(), "simu2.txt"))
    df = DataFrame(CSV.File(path; delim=' ', ignorerepeated=true))
    return interactive_analysis(df)
end

function interactive_analysis(s::Scenario = SCENARII[:four_nodes])
    df = simulate(s, ShortestPath())[2]
    return interactive_analysis(df)
end
