#SECTION 3 - Figure 7 - Cost manipulations: shifting the load +.2, +.4 and raising the weight for data access

function figure_7(; output=joinpath(figuresdir(), "figure7_cost_manipulations.pdf"))
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

    p = StatsPlots.plot(
        p1,
        p2;
        layout=(2, 1),
        plot_title="\\bf Figure 7: Cost manipulations",
        plot_titlefontsize=10,
        thickness_scaling=2,
        w=0.5
    )

    splitdir(output)[1] |> mkpath
    savefig(p, output)

    return p
end

# Uncomment to generate the plots independently of the main function
# figure_7()
