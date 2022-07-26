# SECTION - Script to generate plots for different pseudo-cost functions

using KuMo
using GLMakie
using Colors

function interactive_pseudo_cost()
    set_theme!(backgroundcolor=:gray90)
    fontsize_theme = Theme(fontsize=20)
    update_theme!(fontsize_theme)

    red = colorant"rgb(230, 25, 75)"
    green = colorant"rgb(60, 180, 75)"
    blue = colorant"rgb(0, 0, 128)"
    cyan = colorant"rgb(70, 200, 200)"
    orange = colorant"rgb(245, 130, 48)"
    purple = colorant"rgb(145, 30, 180)"

    fig = Figure(resolution=(1200, 1000))

    ax = Axis(
        fig[1, 1];
        title="Pseudo-costs sandbox",
        xlabel="Pseudo-cost",
        ylabel="Resource load",
        xticks=0:0.1:1,
        yticks=0:1:10,
        xminorticksvisible=true,
        yminorticksvisible=true
    )

    xlims!(ax, nothing, 0.99)
    ylims!(ax, 0, 10.0)

    sg = SliderGrid(fig[2, 1],
        (label="Additive", range=-1:0.1:10, startvalue=0, format="cost + {:.1f}"),
        (label="Multiplicative", range=0:0.1:10, startvalue=1, format="cost × {:.1f}"),
        (label="Load shift", range=0:0.01:0.5, startvalue=0, format="load + {:.01f}"),
        (label="Idle", range=1:0.1:10, startvalue=1),
    )

    _lines = Vector{Any}(fill(nothing, 6))

    lift(sg.sliders[1].value) do val
        _lines[1] === nothing || delete!(ax.scene, _lines[1])
        _lines[1] = lines!(
            0 .. 0.99,
            x -> pseudo_cost(1.0, x, Val(:default)) + val,
            label="additive",
            color=blue,
            linewidth=2.0,
        )
    end

    lift(sg.sliders[2].value) do val
        _lines[2] === nothing || delete!(ax.scene, _lines[2])
        _lines[2] = lines!(
            0 .. 0.99,
            x -> pseudo_cost(1.0, x, Val(:default)) * val,
            label="multiplicative",
            color=cyan,
            linewidth=2.0,
        )
    end

    lift(sg.sliders[3].value) do val
        _lines[3] === nothing || delete!(ax.scene, _lines[3])
        _lines[3] = lines!(
            0 .. 0.99,
            x -> pseudo_cost(1.0, x + val, Val(:default)),
            label="load shift",
            color=purple,
            linewidth=2.0,
        )
    end

    lift(sg.sliders[4].value) do val
        _lines[4] === nothing || delete!(ax.scene, _lines[4])
        _lines[4] = lines!(
            0 .. 0.99,
            x -> pseudo_cost(1.0, x, Val(:idle_node), val),
            label="idle",
            color=orange,
            linewidth=2.0,
        )
    end

    _lines[5] = lines!(
        0 .. 0.99,
        x -> pseudo_cost.(1.0, x, Val(:default));
        label="std cost func",
        color=red,
        linewidth=2.0
    )
    _lines[6] = lines!(
        0 .. 0.99,
        x -> pseudo_cost(1.0, x, Val(:equal_load_balancing)),
        label="equal load balancing",
        color=green,
        linewidth=2.0,
    )

    axislegend(position=:lt)

    return fig
end
