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

    # NOTE - Figure 6: Costs manipulation

    # NOTE - Figure 7: Mixed load 2DCs 2 MDCs

    # NOTE - Figure 8: Mixed load 18 DCs

    return Dict(
        :figure3 => figure3(),
        :figure4 => figure4(),
    )
end

const EDGESYS2023 = _edgesys2023()
