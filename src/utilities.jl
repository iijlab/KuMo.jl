"""
    marks(df::DataFrame)

Returns a 4-tuple `(a, b, c, d)` that marks the start and end of the `nodes` and `links` columns in the dataframe.
- `(a, b)` mark the start and end indices of the `nodes` columns
- `(c, d)` mark the start and end indices of the `links` columns
"""
function marks(df)
    a, b, c, d = 6, 0, 0, 0
    b0 = findfirst(map(x -> occursin("(", x), names(df)))
    if b0 === nothing
        b = length(names(df))
        c = nothing
        d = nothing
    else
        b = b0 - 1
        c = b0
        d = length(names(df))
    end
    return a, b, c, d
end

"""
    plot_nodes(df::DataFrame; kind=:plot)

A simple function to quickly plot the load allocation of the nodes. The `kind` keyarg can take the value `:plot` (default) or `:areaplot`. Both corresponds to the related methods in `Plots.jl` and `StatsPlots.jl`.
"""
function plot_nodes(df; kind=:plot)
    a, b, _, _ = marks(df)
    p = @df df eval(kind)(:instant,
        cols(a:b), xlabel="time", seriestype = :steppre,
        ylabel="load", linestyle=:auto,
        w=1.25,
    )
    return p
end

"""
    plot_links(df::DataFrame; kind=:plot)

A simple function to quickly plot the load allocation of the links. The `kind` keyarg can take the value `:plot` (default) or `:areaplot`. Both corresponds to the related methods in `Plots.jl` and `StatsPlots.jl`.
"""
function plot_links(df; kind=:plot)
    _, _, c, d = marks(df)
    if isnothing(d)
        return nothing
    else
        p = @df df eval(kind)(:instant,
            cols(c:d), xlabel="time", seriestype = :steppre,
            ylabel="load", linestyle=:auto,
            w=1.25,
        )
        return p
    end
end

"""
    plot_resources(df::DataFrame; kind=:plot)

A simple function to quickly plot the load allocation of all resources. The `kind` keyarg can take the value `:plot` (default) or `:areaplot`. Both corresponds to the related methods in `Plots.jl` and `StatsPlots.jl`.
"""
function plot_resources(df; kind=:plot)
    a, _, _, d = marks(df)
    if isnothing(d)
        return nothing
    else
        p = @df df eval(kind)(:instant,
            cols(a:d), xlabel="time", seriestype = :steppre,
            ylabel="load", linestyle=:auto,
            w=1.25,
        )
        return p
    end
end

plot_snaps(df, kind, ::Val{:links}) = plot_links(df; kind)

plot_snaps(df, kind, ::Val{:nodes}) = plot_nodes(df; kind)

plot_snaps(df, kind, ::Val{:resources}) = plot_resources(df; kind)

"""
    plot_snaps(df::DataFrame; target=:all, plot_type=:all, title="")

Plots the snapshots in `df` in a single multiplot figure.
- `target` defines the targetted resources: `:all` (default), `:nodes`, `:links`, `resources`
- `plot_type` defines the kind of plots that will be generated: `:all` (default), `:plot`, `:areaplot`
- an optional `title`
"""
function plot_snaps(df; target=:all, plot_type=:all, title="")
    P = Vector()
    kinds = plot_type == :all ? [:plot, :areaplot] : [plot_type]
    targets = target == :all ? [:links, :nodes, :resources] : [target]

    k = plot_type == :all ? 2 : 1
    l = target == :all ? 3 : 1

    layout = k * l

    for k in kinds, t in targets
        p = plot_snaps(df, k, Val(t))
        if !isnothing(p)
            push!(P, p)
        end
    end
    layout = length(P)

    return plot(P...; plot_title=title, layout, plot_titlefontsize=10, legendfontsize=6)
end

"""
    simulate_and_plot(
        s::Scenario, algo<:AbstractAlgorithm;
        speed=0, output="", verbose=true, target=:all, plot_type=:all,
        title="Cloud Morphing: a responsive allocation of resources",
    )

Simulate and plot the snapshots generate through `scenario` in a single multiplot figure.
- `verbose` defines if the simulation is verbose or not (default to `true`)
- `target` defines the targetted resources: `:all` (default), `:nodes`, `:links`, `resources`
- `plot_type` defines the kind of plots that will be generated: `:all` (default), `:plot`, `:areaplot`
- an optional `title`
"""
function simulate_and_plot(
    s, algo;
    speed=0, output="", verbose=true, target=:all, plot_type=:all, title="Cloud Morphing: a responsive allocation of resources"
)
    times, df, _ = simulate(s, algo; speed, output, verbose)
    verbose && pretty_table(times)

    return plot_snaps(df; plot_type, target, title), df
end
