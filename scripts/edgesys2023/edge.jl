function edge_scenario(nodes, links;
    drones=10,
    duration=30,
    rate=0.1,
    σ=1.75,
    seed=68987354
)
    Random.seed!(seed)
    j = job(0, 1, 1, 1.0, 1.0)
    R = map(_ -> Vector{Request{typeof(j)}}(), 0:length(nodes))

    N = length(nodes) + 3
    μ1 = duration * 1 / N
    μ2 = duration * 2 / N
    μ3 = duration * 3 / N
    μ4 = duration * 4 / N
    μ5 = duration * 5 / N

    d1 = truncated(Normal(μ1, σ); lower=0, upper=duration)
    d2 = truncated(Normal(μ2, σ); lower=0, upper=duration)
    d3 = truncated(Normal(μ3, σ); lower=0, upper=duration)
    d4 = truncated(Normal(μ4, σ); lower=0, upper=duration)
    d5 = truncated(Normal(μ5, σ); lower=0, upper=duration)
    D = [d1, d2, d3, d4, d5]

    P = [rand(d) for _ in 1:drones, d in D]

    for τ in 0:rate:duration, u in 1:drones
        t = τ + rate / drones * (u - 1)
        p = findfirst(x -> t < x, P[u, :])
        if isnothing(p)
            continue
        elseif P[u, 4] ≤ t ≤ P[u, 5]
            push!(R[1], Request(j, t))
            push!(R[length(nodes)], Request(j, t))
        elseif P[u, 1] ≤ t
            push!(R[p-1], Request(j, t))
        end
    end

    users = map(i -> user(R[i], i), 1:length(nodes))
    directed = false

    return scenario(; duration, nodes, links, users, directed)
end

struct FlatNode{T<:Number} <: KuMo.AbstractNode
    capacity::T
end

pseudo_cost(r::FlatNode, charge) = charge ≥ r.capacity ? Inf : 0.0

struct ConstantLink{T<:Number} <: KuMo.AbstractLink
    capacity::T
    param::T
end

pseudo_cost(r::ConstantLink, _) = param(r)

function final_edge(
    c=100.0,
    drones=10,
    duration=30,
    rate=0.1,
    σ=1.75,
    seed=68987354,
)

    # scenario 1: FlatNode -- ConstantLink
    nodes_1 = [
        FlatNode(c),
        FlatNode(c),
        FlatNode(c),
    ]
    links_1 = [
        (1, 2, ConstantLink(c, 1.0)),
        (1, 3, ConstantLink(c, 1.0)),
        (2, 3, ConstantLink(c, 1.0)),
    ]
    s1 = edge_scenario(nodes_1, links_1; drones, duration, rate, σ, seed)
    p1, _ = simulate_and_plot(s1, ShortestPath(); target=:nodes, plot_type=:areaplot)

    # scenario 2: ConvexNode -- MonotonicLink
    nodes_2 = [
        Node(c),
        Node(c),
        Node(c),
    ]
    links_2_3 = [
        (1, 2, c),
        (1, 3, c),
        (2, 3, c),
    ]
    s2 = edge_scenario(nodes_2, links_2_3; drones, duration, rate, σ, seed)
    p2, _ = simulate_and_plot(s2, ShortestPath(); target=:nodes, plot_type=:areaplot)

    # scenario 3: MonotonicNode -- MonotonicLink
    nodes_3 = [
        EqualLoadBalancingNode(c),
        EqualLoadBalancingNode(c),
        EqualLoadBalancingNode(c),
    ]
    s3 = edge_scenario(nodes_3, links_2_3; drones, duration, rate, σ, seed)
    p3, _ = simulate_and_plot(s3, ShortestPath(); target=:nodes, plot_type=:areaplot)

    for (i, p) in enumerate([p1, p2, p3])
        savefig(p, "final_edge_$i.pdf")
    end
end

final_edge()
