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

# Uncomment to generate the plots independently of the main function
# figure_5()
