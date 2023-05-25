module KuMoMakieExt

# imports

using Colors
using CSV
using DataFrames
import KuMo
using Makie

import KuMo: simulate, marks, show_pseudo_costs, show_simulation, pseudo_cost

# SECTION - Utilities for visualization with Makie

const CAIROMAKIE = "CairoMakie"

const GLMAKIE = "GLMakie"

const WGLMAKIE = "WGLMakie"

# NOTE - Not handled at the moment
const RPRMAKIE = "RPRMakie"

make_colors(l) = distinguishable_colors(l, [RGB(1, 1, 1), RGB(0, 0, 0)], dropseed=true)

# SECTION - pseudo-costs visualization

function show_pseudo_costs(pseudo_costs, ::Val{:interactive})
    set_theme!(backgroundcolor=:gray90)
    fontsize_theme = Theme(fontsize=20)
    update_theme!(fontsize_theme)

    colors = make_colors(4 + length(pseudo_costs))

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

    _lines = Vector{Any}(fill(nothing, 4))

    lift(sg.sliders[1].value) do val
        _lines[1] === nothing || delete!(ax.scene, _lines[1])
        _lines[1] = lines!(
            0 .. 0.99,
            x -> pseudo_cost(1.0, x, Val(:default)) + val,
            label="additive",
            color=colors[1],
            linewidth=2.0,
        )
    end

    lift(sg.sliders[2].value) do val
        _lines[2] === nothing || delete!(ax.scene, _lines[2])
        _lines[2] = lines!(
            0 .. 0.99,
            x -> pseudo_cost(1.0, x, Val(:default)) * val,
            label="multiplicative",
            color=colors[2],
            linewidth=2.0,
        )
    end

    lift(sg.sliders[3].value) do val
        _lines[3] === nothing || delete!(ax.scene, _lines[3])
        _lines[3] = lines!(
            0 .. 0.99,
            x -> pseudo_cost(1.0, x + val, Val(:default)),
            label="load shift",
            color=colors[3],
            linewidth=2.0,
        )
    end

    lift(sg.sliders[4].value) do val
        _lines[4] === nothing || delete!(ax.scene, _lines[4])
        _lines[4] = lines!(
            0 .. 0.99,
            x -> pseudo_cost(1.0, x, Val(:idle_node), val),
            label="idle cost",
            color=colors[4],
            linewidth=2.0,
        )
    end

    for (i, pc) in enumerate(pseudo_costs)
        lines!(
            0 .. 0.99,
            first(pc);
            label=last(pc),
            color=colors[i+4],
            linewidth=2.0
        )
    end

    axislegend(position=:lt)

    return fig
end

function show_pseudo_costs(pseudo_costs, ::Val{:static})
    set_theme!(backgroundcolor=:gray90)
    fontsize_theme = Theme(fontsize=20)
    update_theme!(fontsize_theme)

    colors = make_colors(length(pseudo_costs))

    fig = Figure(resolution=(1200, 1000))

    ax = Axis(
        fig[1, 1];
        title="Pseudo-costs",
        xlabel="Pseudo-cost",
        ylabel="Resource load",
        xticks=0:0.1:1,
        yticks=0:1:10,
        xminorticksvisible=true,
        yminorticksvisible=true
    )

    xlims!(ax, nothing, 0.99)
    ylims!(ax, 0, 10.0)

    for (i, pc) in enumerate(pseudo_costs)
        lines!(
            0 .. 0.99,
            first(pc);
            label=last(pc),
            color=colors[i],
            linewidth=2.0
        )
    end

    axislegend(position=:lt)

    return fig
end

const BASIC_PSEUDO_COSTS = [
    (x -> pseudo_cost(1.0, x, Val(:default))) => "convex pseudo-cost",
    (x -> pseudo_cost(1.0, x, Val(:equal_load_balancing))) => "monotonic pseudo-cost",
]

const DEFAULT_PSEUDO_COSTS = [
    (x -> pseudo_cost(1.0, x + 0.2, Val(:default))) => "load +.2",
    (x -> pseudo_cost(1.0, x, Val(:default)) + 0.5) => "cost +.5",
    (x -> pseudo_cost(1.0, x, Val(:default)) * 2.0) => "cost ×2",
    (x -> pseudo_cost(1.0, x, Val(:idle_node), 1.5)) => "idle cost ×1.5",
    BASIC_PSEUDO_COSTS[1],
    BASIC_PSEUDO_COSTS[2],
]

function KuMo.show_pseudo_costs(; interaction=:auto, pseudo_costs=[])
    cb = string(Makie.current_backend())
    is_static = occursin(CAIROMAKIE, cb) || occursin(RPRMAKIE, cb)
    if interaction ∈ [:static] || is_static
        aux = isempty(pseudo_costs) ? DEFAULT_PSEUDO_COSTS : pseudo_costs
        return show_pseudo_costs(aux, Val(:static))
    end
    return show_pseudo_costs(vcat(BASIC_PSEUDO_COSTS, pseudo_costs), Val(:interactive))
end

# SECTION - Visualization of simulations

function show_simulation(df, norms, _, ::Val{:interactive})
    a, b, _, d = marks(df)
    δ = d === nothing ? b : d
    colors = make_colors(length(a:δ))

    set_theme!(backgroundcolor=:gray90)
    fontsize_theme = Theme(fontsize=20)
    update_theme!(fontsize_theme)

    labels2 = names(df)

    # set_window_config!(;
    #     title="KuMo.jl: scenario analysis"
    # )

    fig = Figure(resolution=(1200, 1000))

    ax1 = Axis(
        fig[1, 1];
        title="Interactive analysis",
        ylabel="Resource load (normalized)"
    )

    _lines = Vector{Any}(fill(nothing, length(a:δ)))
    toggles = [Toggle(fig, active=i ≤ b) for i in a:δ]
    labels = map(l -> Label(fig, l), names(df)[a:δ])
    fig[1, 2][1, 1] = grid!(hcat(toggles, labels), tellheight=false)

    for c in a:δ
        γ = c - a + 1
        _lines[γ] = lines!(df[!, :instant], df[!, c]; color=colors[γ], label=labels2[c])
        connect!(_lines[γ].visible, toggles[γ].active)
    end

    axislegend(ax1; position=:lt)

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
            _areas[c] = band!(df[!, :instant], $Y[:, c], $Y[:, c+1]; color=colors[c])
            connect!(_areas[c].visible, toggles2[c].active)
        end
    end

    m1 = Menu(fig[3, :][1, 4], prompt="Select plot type(s)...", options=["all", "resource load", "total load"], width=300)
    m2 = Menu(fig[3, :][1, 3], prompt="Select output format...", options=[".png"], width=300)
    tb = Textbox(fig[3, :][1, 2], width=300)
    b_save = Button(fig[3, :][1, 5], label="save")

    on(b_save.clicks) do n
        b1 = m1.selection[] !== nothing
        b2 = m2.selection[] !== nothing
        b3 = tb.displayed_string[] != "Click to edit..."
        if b1 && b2 && b3
            target = ""
            m1.selection[] == "resource load" && (target = "-resource_load")
            m1.selection[] == "total load" && (target = "-total_load")
            file_name = tb.displayed_string[] * target * m2.selection[]
            path = joinpath(pwd(), file_name)

            save(path, fig)
        else
            @warn "Save information are not complete" m1.selection[] m2.selection[] tb.displayed_string[]
        end
    end

    return fig
end

function show_simulation(df, norms, select, ::Val{:static})
    a, b, _, d = marks(df)
    δ = d === nothing ? b : d
    colors = make_colors(length(a:δ))

    set_theme!(backgroundcolor=:gray90)
    fontsize_theme = Theme(fontsize=20)
    update_theme!(fontsize_theme)

    labels = names(df)

    # set_window_config!(;
    #     title="KuMo.jl: scenario analysis"
    # )

    fig = Figure(resolution=(1200, 1000))

    ax1 = Axis(
        fig[1, 1];
        title="Node Loads",
        ylabel="Resource load (normalized)"
    )

    selected(c) = select === nothing || labels[c] ∈ select

    for c in a:b
        γ = c - a + 1
        selected(c) && lines!(df[!, :instant], df[!, c]; color=colors[γ], label=labels[c])
    end

    axislegend(ax1; position=:lt)

    df_no_norm = deepcopy(df)
    for (tag, val) in norms
        df_no_norm[!, Symbol(tag)] = df_no_norm[!, Symbol(tag)] .* val
    end

    ax2 = Axis(
        fig[2, 1];
        xlabel="Time",
        ylabel="Total load"
    )

    function make_ys(C)
        u, v = first(C), last(C)
        M = zeros(size(df_no_norm, 1), length(u:v) + 1)
        for (i, c) in enumerate(u:v)
            c ∈ C && (M[:, i+1] = df_no_norm[!, c])
        end
        return cumsum(M, dims=2)
    end

    Y = make_ys(a:b)

    for c in 1:length(a:b)
        γ = a - 1 + c
        selected(γ) && band!(df[!, :instant], Y[:, c], Y[:, c+1], color=colors[c], label=labels[γ])
    end

    axislegend(ax2; position=:lt)

    if d !== nothing
        α = b + 1

        ax3 = Axis(
            fig[1, 2];
            title="Links loads"
        )

        for c in α:δ
            γ = c - a + 1
            selected(c) && lines!(df[!, :instant], df[!, c], color=colors[γ], label=labels[c])
        end

        axislegend(ax3; position=:lt)

        df_no_norm = deepcopy(df)
        for (tag, val) in norms
            df_no_norm[!, Symbol(tag)] = df_no_norm[!, Symbol(tag)] .* val
        end

        ax4 = Axis(
            fig[2, 2];
            xlabel="Time"
        )

        Y = make_ys(α:δ)

        for c in α:δ
            γ = c - b
            selected(c) && band!(df[!, :instant], Y[:, γ], Y[:, γ+1], color=colors[c-a+1], label=labels[c])
        end

        axislegend(ax4; position=:lt)
    end

    return fig
end

function KuMo.show_simulation(df::DataFrame, norms=Dict(); interaction=:auto, select=nothing)
    cdf = KuMo.clean!(df)
    cb = string(Makie.current_backend())
    is_static = occursin(CAIROMAKIE, cb) || occursin(RPRMAKIE, cb)
    if interaction ∈ [:static] || is_static
        return show_simulation(cdf, norms, select, Val(:static))
    end
    return show_simulation(cdf, norms, select, Val(:interactive))
end

function KuMo.show_simulation(path::String; norms=Dict(), interaction=:auto, select=nothing)
    df = DataFrame(CSV.File(path; delim=','))
    return KuMo.show_simulation(df, norms; interaction, select)
end

function KuMo.show_simulation(s::Symbol=:_four_nodes; norms=Dict(), interaction=:auto, select=nothing)
    df = KuMo.simulate(KuMo.eval(s)()).df
    return KuMo.show_simulation(df, norms; interaction, select)
end

function KuMo.show_interactive_run(;
    fps=60,
    interval=60,
    norms=Dict()
)
    function make_ys(toggs, df_no_norm, a, δ)
        C = actives(toggs)
        # @warn "debug"
        M = zeros(size(df_no_norm, 1), length(a:δ) + 1)
        # @warn "debug"
        for (i, c) in enumerate(a:δ)
            c ∈ C && (M[:, i+1] = df_no_norm[!, c])
        end
        # @warn "debug"
        return cumsum(M, dims=2)
    end

    agent = KuMo.execute()
    df = agent.exe.results.df

    set_theme!(backgroundcolor=:gray90, fullscreen=true)
    fontsize_theme = Theme(fontsize=20)
    update_theme!(fontsize_theme)



    fig = Figure(resolution=(3960, 2160))
    display(fig)

    ax1 = Axis(
        fig[1, 1];
        title="Interactive analysis",
        ylabel="Resource load (normalized)",
        xlabel="Time",
        limits=(0, 60, 0, 1)
    )

    # axislegend(ax1; position=:lt)

    # ax2 = Axis(
    #     fig[2, 1];
    #     xlabel="Time",
    #     ylabel="Total load"
    # )

    @async begin
        while !isready(agent.containers.stop)
            # take!(agent.containers.results_free)

            # @warn "debug"

            # take!(containers.results_free)
            if size(df, 1) ≤ 5 || !isready(agent.containers.results_free)
                sleep(1.0 / fps)
                continue
            end

            take!(agent.containers.results_free)
            # put!(containers.results_free, true)

            # @warn "debug"

            results = DataFrame()

            current = time() - agent.start
            min_t = max(0, current - interval)
            max_t = max(current, interval)
            # lock(agent.exe.results.df) do
            #     results = filter(row -> min_t ≤ row.instant, df)
            # end
            # take!(containers.results_free)
            results = filter(row -> min_t ≤ row.instant, df)
            # put!(containers.results_free, true)

            # @warn "debug"

            a, b, _, d = marks(results)
            δ = d === nothing ? b : d
            colors = make_colors(length(a:δ))
            labels2 = names(results)

            # @info fieldnames(ax1 |> typeof)

            # axislegend(ax1; position=:lt)

            empty!(fig)

            ax1 = Axis(
                fig[1, 1];
                title="Interactive analysis",
                ylabel="Resource load (normalized)",
                xlabel="Time",
                limits=(min_t, max_t, 0, 1)
            )

            # @warn "debug"

            _lines = Vector{Any}(fill(nothing, length(a:δ)))
            toggles = [Toggle(fig, active=i ≤ b) for i in a:δ]
            labels = map(l -> Label(fig, l), names(results)[a:δ])
            # fig[1, 2][1, 1] = grid!(hcat(toggles, labels), tellheight=false)

            # @warn "debug"

            for c in a:δ
                γ = c - a + 1
                _lines[γ] = lines!(results[!, :instant], results[!, c]; color=colors[γ], label=labels2[c])
                connect!(_lines[γ].visible, toggles[γ].active)
            end

            # axislegend(ax1; position=:lt)

            # @warn "debug"

            # df_no_norm = deepcopy(results)

            # @warn "debug" df_no_norm results agent.exe.results.df df
            # @show df

            # for (tag, val) in norms
            #     df_no_norm[!, Symbol(tag)] = df_no_norm[!, Symbol(tag)] .* val
            # end

            # # empty!(ax2)
            # ax2 = Axis(
            #     fig[2, 1];
            # )

            # @warn "debug"

            # _areas = Vector{Any}(fill(nothing, length(a:δ)))
            # @warn "debug"
            # toggles2 = [Toggle(fig, active=i ≤ b) for i in a:δ]
            # @warn "debug"
            # labels2 = map(l -> Label(fig, l), names(results)[a:δ])
            # @warn "debug"
            # fig[2, 2][1, 1] = grid!(hcat(to_value(toggles2), labels2), tellheight=false)
            # @warn "debug"
            # actives(toggs) = filter(c -> toggs[c-a+1].active[], a:δ)
            # @warn "debug"
            # Y = lift((t.active for t in toggles2)...) do actives...
            #     @warn "debug"
            #     make_ys(toggles2, df_no_norm, a, δ)
            #     @warn "debug"
            # end

            # @warn "debug"

            # @lift begin
            #     for c in 1:length(a:δ)
            #         _areas[c] === nothing || delete!(ax2.scene, _areas[c])
            #         _areas[c] = band!(results[][!, :instant], $Y[:, c], $Y[:, c+1]; color=colors[c])
            #         connect!(_areas[c].visible, toggles2[c].active)
            #     end
            # end
            put!(agent.containers.results_free, true)

            sleep(1 / fps)
        end
    end

    # results = Observable(agent.exe.results.df)

    # interval = 10.0

    # while !isready(agent.containers.stop)
    #     current = time() - agent.start
    #     min_t = min(0, current - interval)
    #     results[] = filter(row -> row.instant ∈ min_t:current, agent.results.df)

    #     df[!, :col]
    #     df[(df.A.>500).&(300 .< df.C .< 400), :]

    #     sleep(1 / fps)
    # end



    # points = Observable(Point2f[randn(2)])

    # fig, ax = scatter(points)
    # limits!(ax, -4, 4, -4, 4)
    # display(fig)

    # @async begin
    #     nframes = 120

    #     for i = 1:nframes
    #         new_point = Point2f(randn(2))
    #         points[] = push!(points[], new_point)
    #         sleep(1 / fps) # refreshes the display!
    #     end
    # end

    return agent

end

end # module KuMoMakieExt
