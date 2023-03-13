#SECTION 2 - Figure 4 - Load distribution among 4 equivalent cost nodes: the load of each resource (top) and the total load (bottom)

function figure_4(;
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

    p = StatsPlots.plot(
        p1,
        p2;
        layout=(2, 1),
        thickness_scaling=2,
        plot_titlefontsize=10,
        plot_title=title ? "\\bf Figure 4: Load distribution (equivalent nodes)" : "",
        w=0.5)

    splitdir(output)[1] |> mkpath
    savefig(p, output)

    return p
end

# Uncomment to generate the plots independently of the main function
# figure_4()
