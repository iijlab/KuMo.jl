# NOTE - Scenarii for the CONEXT 2022 submission

# SECTION - Figure 3: 4 equivalent cost nodes
function s3()
    max_load = 3.50,
    nodes = (4, 100),
    rate = 0.01,
    j = job(0, 1, rand(1:4), 3.25, 0)

    _requests = Vector{KuMo.Request{typeof(j)}}()

    L = prod(nodes)
    r = rate
    λ = max_load
    n = nodes[1]
    δ = j.duration
    c = j.containers

    π1 = λ / r
    π2 = (2n - λ) / r

    for i in 0:π1+π2
        for t in i:δ:π1+π2-i
            i ≤ π1 && push!(_requests, KuMo.Request(j, t))
        end
    end

    scenario(;
        duration=1000,
        nodes=(4, 100),
        users=[user(KuMo.Requests(_requests), 1)]
    )
end

function scenario5(;
)
    _requests = Vector{KuMo.Request{typeof(j)}}()

    L = prod(nodes)
    r = rate
    λ = max_load
    n = nodes[1]
    δ = j.duration
    c = j.containers

    π1 = λ / r
    π2 = (2n - λ) / r

    for i in 0:π1+π2
        for t in i:δ:π1+π2-i
            i ≤ π1 && push!(_requests, KuMo.Request(j, t))
        end
    end

    # @info "Parameters" L r λ n δ c π1 π2 length(_requests)

    scenario(;
        duration=1000,
        nodes=(4, 100),
        users=[
            # user 1
            user(KuMo.Requests(_requests), 1),
        ]
    )
end

const CONEXT2022 = Dict(
# NOTE - Figure 3: 4 equivalent cost nodes

# NOTE - Figure 4: 4 proportional cost nodes

# NOTE - Figure 6: Costs manipulation

# NOTE - Figure 7: Mixed load 2DCs 2 MDCs

# NOTE - Figure 8: Mixed load 18 DCs
)
