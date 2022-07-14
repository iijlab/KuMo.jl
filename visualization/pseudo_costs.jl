# Script to generate plots for different pseudo-cost functions

using KuMo
using GLMakie
using Colors

set_theme!(backgroundcolor = :gray90)

red = colorant"rgb(230, 25, 75)"
green = colorant"rgb(60, 180, 75)"
blue = colorant"rgb(0, 0, 128)"
cyan = colorant"rgb(70, 200, 200)"
orange = colorant"rgb(245, 130, 48)"
purple = colorant"rgb(145, 30, 180)"

fig = Figure(resolution = (1200,1000))

ax = Axis(fig[1, 1]; title = "Pseudo-costs sandbox", xlabel = "Pseudo-cost", ylabel = "Resource load")

xlims!(ax, nothing, .99)
ylims!(ax, 0, 10.)

sg = SliderGrid(fig[2, 1],
    (label = "Additive", range = 0:0.1:10, startvalue = 0, format = "cost + {:.1f}"),
    (label = "Multiplicative", range = 0:0.1:10, startvalue = 1, format = "cost × {:.1f}"),
    (label = "Load shift", range = 0:0.01:0.5, startvalue = 0, format = "load + {:.1f}"),
    (label = "Idle", range = 1:0.1:10, startvalue = 1),
)



init3, init4, init5, init6 = false, false, false, false

line3 = lift(sg.sliders[1].value) do val3
    global init3
    if init3
        delete!(ax.scene, line3[])
    else
        init3 = true
    end
    lines!(
        0..0.99,
        x -> pseudo_cost(1., x, Val(:default)) + val3,
        label = "additive",
        color = blue,
    )
end

line4 = lift(sg.sliders[2].value) do val4
    global init4
    if init4
        delete!(ax.scene, line4[])
    else
        init4 = true
    end
    lines!(
        0..0.99,
        x -> pseudo_cost(1., x, Val(:default)) * val4,
        label = "multiplicative",
        color = cyan,
    )
end

line5 = lift(sg.sliders[3].value) do val5
    global init5
    if init5
        delete!(ax.scene, line5[])
    else
        init5 = true
    end
    lines!(
        0..0.99,
        x -> pseudo_cost(1., x + val5, Val(:default)),
        label = "load shift",
        color = purple,
    )
end

line6 = lift(sg.sliders[4].value) do val6
    global init6
    if init6
        delete!(ax.scene, line6[])
    else
        init6 = true
    end
    lines!(
        0..0.99,
        x -> pseudo_cost(1., x, Val(:idle_node), val6),
        label = "idle",
        color = orange,
    )
end

line1 = lines!(
    0..0.99,
    x -> pseudo_cost.(1., x, Val(:default));
    label = "std cost func",
    color = red,
)
line2 = lines!(
    0..0.99,
    x -> pseudo_cost(1., x, Val(:equal_load_balancing)),
    label = "equal load balancing",
    color = green
)

axislegend(position = :lt)

fig
