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

# Uncomment to generate the plots independently of the main function
# figure_6()
