function _edgesys2023()
    # NOTE - Figure 3: 4 equivalent cost nodes
    function figure3()
        max_load = 3.50
        nodes = (4, 100)
        rate = 0.01
        j = job(0, 1, rand(1:4), 3.25, 0)

        _requests = Vector{Request{typeof(j)}}()

        r = rate
        λ = max_load
        n = nodes[1]
        δ = j.duration

        π1 = λ / r
        π2 = (2n - λ) / r

        for i in 0:π1+π2
            for t in i:δ:π1+π2-i
                i ≤ π1 && push!(_requests, Request(j, t))
            end
        end

        return scenario(;
            duration=1000,
            nodes=(4, 100),
            users=[user(Requests(_requests), 1)]
        )
    end

    # NOTE - Figure 4: 4 proportional cost nodes
    function figure4()
        max_load = 3.5
        nodes = (4, 100)
        rate = 0.01
        j = job(0, 1, rand(1:4), 3.25, 0)

        _requests = Vector{Request{typeof(j)}}()

        r = rate
        λ = max_load
        n = nodes[1]
        δ = j.duration

        π1 = λ / r
        π2 = (2n - λ) / r

        for i in 0:π1+π2
            for t in i:δ:π1+π2-i
                i ≤ π1 && push!(_requests, Request(j, t))
            end
        end

        return scenario(;
            duration=1000,
            nodes=[
                MultiplicativeNode(100, 1),
                MultiplicativeNode(100, 2),
                MultiplicativeNode(100, 4),
                MultiplicativeNode(100, 8),
            ],
            # nodes=(4, 100),
            users=[user(Requests(_requests), 1)]
        )
    end

    #NOTE - edge computing scenario
    function figure_edge(;
        drones=10,
        duration=20,
        σ=1.75,
        seed=68987354
    )
        Random.seed!(seed)

        nodes = (3, 100)
        j = job(0, 1, 1, 1.0, 1.0)

        c = 100


        R = map(_ -> Vector{Request{typeof(j)}}(), 1:nodes[1])

        rate = 0.1

        N = nodes[1] + 1
        μ1 = duration * 1 / N
        μ2 = duration * 2 / N
        μ3 = duration * 3 / N

        d1 = truncated(Normal(μ1, σ); lower=0, upper=duration)
        d2 = truncated(Normal(μ2, σ); lower=0, upper=duration)
        d3 = truncated(Normal(μ3, σ); lower=0, upper=duration)
        D = [d1, d2, d3]

        P = [rand(d) for _ in 1:drones, d in D]

        for τ in 0:rate:duration, u in 1:drones
            t = τ + rate / drones * (u - 1)
            p = findfirst(x -> t < x, P[u, :])
            if isnothing(p)
                push!(R[1], Request(j, t))
                push!(R[nodes[1]], Request(j, t))
            else
                push!(R[p], Request(j, t))
            end
        end

        users = map(i -> user(R[i], i), 1:nodes[1])
        links = [
            (1, 2, c),
            (1, 3, c),
            (2, 3, c),
        ]
        directed = false

        return scenario(; duration, nodes, users, links, directed)
    end

    return Dict(
        :figure3 => figure3(),
        :figure4 => figure4(),
        :edge => figure_edge(),
    )
end

const EDGESYS2023 = _edgesys2023()
