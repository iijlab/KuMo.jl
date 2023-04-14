module KuMoPlotsExt

# imports
using CSV
using DataFrames
using DrWatson
using KuMo
using PrettyTables
using StatsPlots

# exports
export figures
export simulate_and_plot

"""
    plot_nodes(df::DataFrame; kind=:plot)

A simple function to quickly plot the load allocation of the nodes. The `kind` keyarg can take the value `:plot` (default) or `:areaplot`. Both corresponds to the related methods in `Plots.jl` and `StatsPlots.jl`.
"""
function plot_nodes(df; kind=:plot)
    a, b, _, _ = marks(df)
    p = @df df eval(kind)(:instant,
        cols(a:b), xlabel="time", seriestype=:steppre,
        ylabel="load",
        linestyle=kind == :plot ? :auto : :solid,
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
            cols(c:d), xlabel="time", seriestype=:steppre,
            ylabel="load",
            linestyle=kind == :plot ? :auto : :solid,
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
            cols(a:d), xlabel="time", seriestype=:steppre,
            ylabel="load",
            linestyle=kind == :plot ? :auto : :solid,
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
function KuMo.simulate_and_plot(
    s=SCENARII[:four_nodes], algo=ShortestPath();
    speed=0, output="", verbose=true, target=:all, plot_type=:all, title="Cloud Morphing: a responsive allocation of resources"
)
    times, df, _ = simulate(s, algo; speed, output, verbose)
    verbose && pretty_table(times)

    return plot_snaps(df; plot_type, target, title), df
end

#NOTE - Define figures directory
figuresdir() = joinpath(findproject(), "figures")

#SECTION Includes

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

    ls = latex && select == :all ? "\\bf " : ""

    if select ∈ [:all, :standard]
        # Standard pseudo costs
        convex_pc = x -> pseudo_cost(1.0, x, Val(:default))
        monotonic_pc = x -> pseudo_cost(1.0, x, Val(:equal_load_balancing))
        foreach(pc -> push!(pcs, pc), [convex_pc, monotonic_pc])
        foreach(label -> push!(labels, label), [(ls * "convex") (ls * "monotonic")])
        t = select == :standard ? 1 : 1.25
        foreach(thick -> push!(thickness, thick), [t, t])
        foreach(linestyle -> push!(linestyles, linestyle), [:solid, :solid])
    end

    lv = latex ? "\\em " : ""

    if select ∈ [:all, :variants]
        if select == :variants
            # Standard pseudo costs
            convex_pc = x -> pseudo_cost(1.0, x, Val(:default))
            foreach(pc -> push!(pcs, pc), [convex_pc])
            foreach(label -> push!(labels, label), [(ls * "convex")])
            t = select == 1.25
            foreach(thick -> push!(thickness, thick), [t])
            foreach(linestyle -> push!(linestyles, linestyle), [:solid])
        end
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
        t = select == :variants ? 1 : 0.625
        L = [:dash, :dot, :dashdot, :dashdotdot]
        foreach(thick -> push!(thickness, thick), [t, t, t, t])
        foreach(linestyle -> push!(linestyles, linestyle), L)
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

#SECTION 2 - Figure 4 - Load distribution among 4 equivalent cost nodes: the load of each resource (top) and the total load (bottom)

function figure_4(;
    latex=true,
    output=joinpath(figuresdir(), "figure4_equivalent_nodes.pdf"),
    title=false
)
    function local_scenario()
        # maximum duration
        duration = 1000

        # default constructor (convex node) => Node(...)
        nodes = (4, 100)

        # job(backend, containers, data_location, duration, frontend)
        j = job(0, 1, rand(1:4), 3.25, 0)

        # storage for requests
        _requests = Vector{KuMo.Request{KuMo.Job}}()

        λ = 3.50
        rate = 0.01
        δ = j.duration
        π1 = λ / rate
        π2 = (2 * nodes[1] - λ) / rate

        for i in 0:π1+π2
            for t in i:δ:π1+π2-i
                i ≤ π1 && push!(_requests, KuMo.Request(j, t))
            end
        end

        users = [user(KuMo.Requests(_requests), 1)]

        return scenario(; duration, nodes, users)
    end

    # DataFrame to store simualtion results
    df = simulate(local_scenario())[2]

    # Plot
    lab = ["r0" "r1" "r3" "r4"]
    seriestype = :steppre
    w = 1

    p1 = @df df StatsPlots.plot(
        :instant,
        cols([9, 8, 7, 6]);
        lab,
        seriestype=:steppre,
        w=1,
        ylabel="load",
        ylims=(0, 1),
        yticks=0:0.25:1
    )

    p2 = @df df areaplot(
        :instant,
        cols([9, 8, 7, 6]);
        lab,
        seriestype,
        w,
        xlabel="time",
        ylabel="total load",
        ylims=(0, 4)
    )

    pt = latex ? "\\bf " : ""

    p = StatsPlots.plot(
        p1,
        p2;
        layout=(2, 1),
        thickness_scaling=latex ? 2 : 1,
        plot_titlefontsize=10,
        plot_title=title ? (pt * "Figure 4: Load distribution (equivalent nodes)") : "",
        w=0.5)

    splitdir(output)[1] |> mkpath
    savefig(p, output)

    return p
end

#SECTION 2 - Figure 5 - Load distribution: 4 proportional cost nodes

function figure_5(;
    latex=true,
    output=joinpath(figuresdir(), "figure5_proportional_nodes.pdf"),
    title=false
)
    function local_scenario()
        # maximum duration
        duration = 1000

        # Proportional nodes
        nodes = [
            MultiplicativeNode(100, 1),
            MultiplicativeNode(100, 2),
            MultiplicativeNode(100, 4),
            MultiplicativeNode(100, 8),
        ]

        # job(backend, containers, data_location, duration, frontend)
        j = job(0, 1, rand(1:4), 3.25, 0)

        # storage for requests
        _requests = Vector{KuMo.Request{KuMo.Job}}()

        λ = 3.50
        rate = 0.01
        δ = j.duration
        π1 = λ / rate
        π2 = (2 * length(nodes) - λ) / rate

        for i in 0:π1+π2
            for t in i:δ:π1+π2-i
                i ≤ π1 && push!(_requests, KuMo.Request(j, t))
            end
        end

        users = [user(KuMo.Requests(_requests), 1)]

        return scenario(; duration, nodes, users)
    end

    # DataFrame to store simualtion results
    df = simulate(local_scenario())[2]

    # Plot
    lab = ["r0" "r1" "r3" "r4"]
    seriestype = :steppre
    w = 1

    p1 = @df df StatsPlots.plot(
        :instant,
        cols([9, 8, 7, 6]);
        lab,
        seriestype,
        w,
        ylabel="load",
        ylims=(0, 1),
        yticks=0:0.25:1
    )

    p2 = @df df areaplot(
        :instant,
        cols([9, 8, 7, 6]);
        lab,
        seriestype,
        w,
        xlabel="time",
        ylabel="total load",
        ylims=(0, 4)
    )

    pt = latex ? "\\bf " : ""

    p = StatsPlots.plot(
        p1,
        p2;
        layout=(2, 1),
        thickness_scaling=latex ? 2 : 1,
        plot_titlefontsize=10,
        plot_title=title ? (pt * "Figure 5: Load distribution (proportional nodes)") : "",
        w=0.5)

    splitdir(output)[1] |> mkpath
    savefig(p, output)

    return p
end

#SECTION 3 - Figure 6 - Comparing (a) constant, (b) monotonic and (c) convex behaviors with a flock of drone scenario

function figure_6(;
    latex=true,
    output=joinpath(figuresdir(), "figure6_edge.pdf"),
    title=false
)
    function core_scenario(
        nodes,
        links;
        drones,
        duration,
        phase,
        rate,
        jd
    )
        j = job(0, 1, 1, jd, 1.0)
        R = map(_ -> Vector{Request{KuMo.Job}}(), 1:3)

        for τ in 0:rate:duration, u in 1:drones
            t = τ + rate / drones * (u - 1)
            i = 0
            if 0 ≤ t < 20
                i = t < 0 + phase / drones * (u - 1) ? 1 : 2
            elseif 20 ≤ t < 40
                i = t < 20 + phase / drones * (u - 1) ? 2 : 3
                # elseif 50 ≤ t < 75
                #     i = t ≤ 50 + phase / drones * (u - 1) ? 3 : 1
            end
            i == 0 || push!(R[i], Request(j, t))
        end

        users = map(i -> user(R[i], i), 1:length(nodes))
        directed = false

        return scenario(; duration, nodes, links, users, directed)
    end

    function edge_simulation()
        c = 100.0
        flat = 1.0
        drones = 100
        duration = 100
        jd = 0.1
        phase = 20
        rate = 0.1

        flat_nodes = [
            FlatNode(c, flat),
            FlatNode(c, flat),
            FlatNode(c, flat),
        ]

        convex_nodes = [
            Node(c),
            Node(c),
            Node(c),
        ]

        monotonic_nodes = [
            EqualLoadBalancingNode(c),
            EqualLoadBalancingNode(c),
            EqualLoadBalancingNode(c),
        ]

        flat_links = [
            (1, 2, FlatLink(c, flat)),
            (1, 3, FlatLink(c, flat)),
            (2, 3, FlatLink(c, flat)),
        ]

        monotonic_links = [
            (1, 2, c),
            (1, 3, c),
            (2, 3, c),
        ]

        resources = Dict([
            # scenario 1: FlatNode -- FlatLink
            :flat_flat => (flat_nodes, flat_links),
            # scenario 2: ConvexNode -- MonotonicLink
            :convex_monotonic => (convex_nodes, monotonic_links),
            # scenario 3: MonotonicNode -- MonotonicLink
            :monotonic_monotonic => (monotonic_nodes, monotonic_links),
        ])

        function simu(r)
            s = core_scenario(r...; duration, rate, jd, drones, phase)
            return simulate(s, ShortestPath();)[2]
        end

        return map(simu, values(resources))
    end

    DF = edge_simulation()

    seriestype = :steppre
    linestyle = :solid
    w = 1
    ylabel = "load"

    # convex monotonic
    p_convex_monotonic = @df DF[3] plot(
        :instant,
        cols(6:8);
        linestyle,
        seriestype,
        title="(c) convex",
        w,
        xlabel="time",
        ylabel
    )


    # monotonic monotonic
    p_monotonic_monotonic = @df DF[1] plot(
        :instant,
        cols(6:8);
        linestyle,
        seriestype,
        title="(b) monotonic",
        w,
        ylabel
    )

    # flat flat
    p_flat_flat = @df DF[2] plot(
        :instant,
        cols(6:8);
        linestyle,
        seriestype,
        title="(a) constant",
        w,
        ylabel
    )

    pt = latex ? "\\bf " : ""

    # all
    p = plot(
        p_flat_flat,
        p_monotonic_monotonic,
        p_convex_monotonic;
        layout=(3, 1),
        size=(600, 600),
        thickness_scaling=latex ? 2 : 1,
        plot_title=title ? (pt * "Figure 6: Flock of drones") : "",
        plot_titlefontsize=10,
        titlefontsize=10,
        titlelocation=:center,
        w=0.5,
        ylims=(0, 1),
        yticks=0:0.25:1
    )

    savefig(p, output)

    return p
end

#SECTION 3 - Figure 7 - Cost manipulations: shifting the load +.2, +.4 and raising the weight for data access

function figure_7(;
    latex=true,
    output=joinpath(figuresdir(), "figure7_cost_manipulations.pdf"),
    title=true
)
    function scenario6a(;)
        reqs = Vector{Request{<:KuMo.AbstractJob}}()

        types = Set()

        Δ = 180
        δ = 4.0
        jd() = 4

        λ = 1.0
        ji() = λ

        interactive(data) = job(1, 1, data, jd(), 2)
        data_intensive(data) = job(2, 1, data, jd(), 1)


        t = 0.0
        r = Float64(Δ)
        for i in 1:Δ/2
            k = 25.5 * sin(i * π / Δ)
            while t ≤ i
                t += ji()
                j = interactive(4)
                push!(types, typeof(j))
                foreach(_ -> push!(reqs, Request(j, t)), 1:k)
            end
            i + δ < Δ / 2 && while r ≥ Δ - i
                r -= ji()
                j = interactive(4)
                push!(types, typeof(j))
                foreach(_ -> push!(reqs, Request(j, r - δ / 2)), 1:k)
            end
        end

        UT = Union{collect(types)...}
        R = Vector{Request{UT}}()
        foreach(r -> push!(R, r), reqs)

        u1 = user(R, 1)


        scenario(;
            duration=1000,
            nodes=[
                Node(100),
                Node(100),
                Node(1000),
                Node(1000),
            ],
            users=[u1],
            links=[
                (1, 3, 300.0), (2, 3, 300.0), (3, 4, 3000.0), (4, 2, 3000.0),
                (3, 1, 300.0), (3, 2, 300.0), (4, 3, 3000.0), (2, 4, 3000.0),
            ],
            directed=false
        )
    end

    function scenario6b(;)
        reqs = Vector{Request{<:KuMo.AbstractJob}}()

        types = Set()

        Δ = 180
        δ = 4.0
        jd() = 4

        λ = 1.0
        ji() = λ

        interactive(data) = job(1, 1, data, jd(), 2)
        data_intensive(data) = job(2, 1, data, jd(), 1)


        t = 0.0
        r = Float64(Δ)
        for i in 1:Δ/2
            k = 25.5 * sin(i * π / Δ)
            while t ≤ i
                t += ji()
                j = interactive(4)
                push!(types, typeof(j))
                foreach(_ -> push!(reqs, Request(j, t + Δ)), 1:k)
            end
            i + δ < Δ / 2 && while r ≥ Δ - i
                r -= ji()
                j = interactive(4)
                push!(types, typeof(j))
                foreach(_ -> push!(reqs, Request(j, r - δ / 2 + Δ)), 1:k)
            end
        end

        UT = Union{collect(types)...}
        R = Vector{Request{UT}}()
        foreach(r -> push!(R, r), reqs)

        u1 = user(R, 1)


        scenario(;
            duration=1000,
            nodes=[
                PremiumNode(100, 0.2),
                Node(100),
                Node(1000),
                Node(1000),
            ],
            users=[u1],
            links=[
                (1, 3, 300.0), (2, 3, 300.0), (3, 4, 3000.0), (4, 2, 3000.0),
                (3, 1, 300.0), (3, 2, 300.0), (4, 3, 3000.0), (2, 4, 3000.0),
            ],
            directed=false
        )
    end

    function scenario6c(;)
        reqs = Vector{Request{<:KuMo.AbstractJob}}()

        types = Set()

        Δ = 180
        δ = 4.0
        jd() = 4

        λ = 1.0
        ji() = λ

        interactive(data) = job(1, 1, data, jd(), 2)
        data_intensive(data) = job(2, 1, data, jd(), 1)


        t = 0.0
        r = Float64(Δ)
        for i in 1:Δ/2
            k = 25.5 * sin(i * π / Δ)
            while t ≤ i
                t += ji()
                j = interactive(4)
                push!(types, typeof(j))
                foreach(_ -> push!(reqs, Request(j, t + 2Δ)), 1:k)
            end
            i + δ < Δ / 2 && while r ≥ Δ - i
                r -= ji()
                j = interactive(4)
                push!(types, typeof(j))
                foreach(_ -> push!(reqs, Request(j, r - δ / 2 + 2Δ)), 1:k)
            end
        end

        UT = Union{collect(types)...}
        R = Vector{Request{UT}}()
        foreach(r -> push!(R, r), reqs)

        u1 = user(R, 1)

        scenario(;
            duration=1000,
            nodes=[
                PremiumNode(100, 0.4),
                Node(100),
                Node(1000),
                Node(1000),
            ],
            users=[u1],
            links=[
                (1, 3, 300.0), (2, 3, 300.0), (3, 4, 3000.0), (4, 2, 3000.0),
                (3, 1, 300.0), (3, 2, 300.0), (4, 3, 3000.0), (2, 4, 3000.0),
            ],
            directed=false
        )
    end

    function scenario6d(;)
        reqs = Vector{Request{<:KuMo.AbstractJob}}()

        types = Set()

        Δ = 180
        δ = 4.0
        jd() = 4

        λ = 1.0
        ji() = λ

        interactive(data) = job(250, 1, data, jd(), 2)
        data_intensive(data) = job(2, 1, data, jd(), 1)


        t = 0.0
        r = Float64(Δ)
        for i in 1:Δ/2
            k = 25.5 * sin(i * π / Δ)
            while t ≤ i
                t += ji()
                j = interactive(4)
                push!(types, typeof(j))
                foreach(_ -> push!(reqs, Request(j, t + 3Δ)), 1:k)
            end
            i + δ < Δ / 2 && while r ≥ Δ - i
                r -= ji()
                j = interactive(4)
                push!(types, typeof(j))
                foreach(_ -> push!(reqs, Request(j, r - δ / 2 + 3Δ)), 1:k)
            end
        end

        UT = Union{collect(types)...}
        R = Vector{Request{UT}}()
        foreach(r -> push!(R, r), reqs)

        u1 = user(R, 1)


        scenario(;
            duration=1000,
            nodes=[
                PremiumNode(100, 0.4),
                Node(100),
                Node(1000),
                Node(1000),
            ],
            users=[u1],
            links=[
                (1, 3, 300.0), (2, 3, 300.0), (3, 4, 3000.0), (4, 2, 3000.0),
                # (3, 1, 300.0), (3, 2, 300.0), (4, 3, 3000.0), (2, 4, 3000.0),
                (3, 1, 300.0), (3, 2, 300.0), (4, 3, 3000.0), (2, 4, 3000.0),
            ],
            directed=false
        )
    end

    df = simulate(scenario6a())[2]
    dfb = simulate(scenario6b())[2]
    dfc = simulate(scenario6c())[2]
    dfd = simulate(scenario6d())[2]

    append!(df, dfb, cols=:union)
    append!(df, dfc, cols=:union)
    append!(df, dfd, cols=:union)

    replace!(df[!, 6], missing => 0)
    replace!(df[!, 7], missing => 0)
    replace!(df[!, 12], missing => 0)

    dfn = deepcopy(df)
    dfn[!, 6:6] = df[!, 6:6] .* 1
    dfn[!, 7:7] = df[!, 7:7] .* 10

    dfn[!, 12:12] = df[!, 12:12] .* 10

    # Plot
    lab = ["MDC0" "DC2" "DC3"]
    seriestype = :steppre
    w = 1

    p1 = @df df plot(
        :instant,
        cols([6, 7, 12]);
        lab,
        seriestype,
        w,
        ylabel="load",
        ylims=(0, 1),
        yticks=0:0.25:1
    )

    p2 = @df dfn areaplot(
        :instant,
        cols([6, 7, 12]);
        lab,
        seriestype,
        w,
        xlabel="time",
        ylabel="total load",
        ylims=(0, 1),
        yticks=0:0.25:1
    )

    pt = latex ? "\\bf " : ""

    p = StatsPlots.plot(
        p1,
        p2;
        layout=(2, 1),
        plot_title=title ? (pt * "Figure 7: Cost manipulations") : "",
        plot_titlefontsize=10,
        thickness_scaling=latex ? 2 : 1,
        w=0.5
    )

    splitdir(output)[1] |> mkpath
    savefig(p, output)

    return p
end

#SECTION 3 - Figure 8 - Mixed load with 2 DCs and 2 MDCs

function figure_8(;
    latex=true,
    output=joinpath(figuresdir(), "figure8_mixed_load.pdf"),
    title=true
)
    df = DataFrame(CSV.File(joinpath(datadir(), "figure8.csv")))

    df_no_norm = deepcopy(df)
    df_no_norm[!, 6:7] = df[!, 6:7] .* 1
    df_no_norm[!, 8:9] = df[!, 8:9] .* 10

    p1 = @df df plot(
        :instant,
        cols(6:9);
        ylabel="load",
        w=1,
        xticks=0:120:1000,
        ylims=(0, 1),
        yticks=0:0.25:1,
        lab=["MDC0" "MDC1" "DC2" "DC3"]
    )

    p2 = @df df plot(
        :instant,
        cols(10:13);
        ylabel="links load",
        xticks=0:120:1000,
        ylims=(0, 1),
        yticks=0:0.25:1,
        w=1,
        lab=["MDC0-DC2" "MDC1-DC3" "MDC1-DC2" "DC2-DC3"]
    )

    p3 = @df df_no_norm areaplot(
        :instant,
        cols(6:9);
        ylabel="total load",
        xlabel="time",
        xticks=0:120:1000,
        yticks=0:4:12,
        w=1,
        lab=["MDC0" "MDC1" "DC2" "DC3"]
    )

    pt = latex ? "\\bf " : ""

    p = plot(
        p1,
        p2,
        p3;
        layout=(3, 1),
        plot_title=title ? (pt * "Figure 8: Mixed load") : "",
        plot_titlefontsize=10,
        thickness_scaling=latex ? 2 : 1,
        w=0.5,
        size=(600, 600)
    )

    splitdir(output)[1] |> mkpath
    savefig(p, output)

    return p
end

const FIGURES = Dict(
    :figure_3 => figure_3,
    :figure_4 => figure_4,
    :figure_5 => figure_5,
    :figure_6 => figure_6,
    :figure_7 => figure_7,
    :figure_8 => figure_8,
)

KuMo.figures(symb::Symbol; kwargs...) = FIGURES[symb](; kwargs...)

end
