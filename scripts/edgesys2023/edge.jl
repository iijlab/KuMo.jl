function edge_scenario(nodes, links;
    flock1=(10, 1),
    flock2=(5, 5),
    duration=40,
    rate=0.1,
    σ=1.75,
    seed=68987354
)
    Random.seed!(seed)
    drones = flock1[1] + flock2[1]
    j = job(0, 1, 1, 1.0, 1.0)
    R = map(_ -> Vector{Request{typeof(j)}}(), 0:length(nodes))
    n = length(nodes)
    N = n + 4
    D = [truncated(Normal(duration * i / N, σ); lower=0, upper=duration) for i in 1:(N-1)]
    P = fill(Inf, drones, length(D))
    for i in 1:drones, (k, d) in enumerate(D)
        if k == N - 1 || (i ≤ flock1[1] && k ≥ flock1[2]) || k ≥ flock2[2]
            P[i, k] = rand(d)
        end
    end

    acc = Set{Int}()

    # Flock 1
    for τ in 0:rate:duration, u in 1:drones
        t = τ + rate / drones * (u - 1)
        p = findlast(x -> t ≥ x, P[u, :])
        if !isnothing(p)
            i = (p + n - (u < flock1[1] ? 1 : 2)) % n + 1
            if p ∉ acc
                @info "debug" p n (p + n - 1) i P[u, :] t
                push!(acc, p)
            end
            push!(R[i], Request(j, t))
        end
    end

    users = map(i -> user(R[i], i), 1:length(nodes))
    directed = false

    return scenario(; duration, nodes, links, users, directed)
end

function final_edge(;
    c=100.0,
    flock1=(10, 1),
    flock2=(6, 5),
    duration=40,
    rate=0.1,
    σ=1.75,
    seed=68987354
)

    # scenario 1: FlatNode -- FlatLink
    nodes_1 = [
        FlatNode(c, 0.0),
        FlatNode(c, 0.0),
        FlatNode(c, 0.0),
    ]
    links_1 = [
        (1, 2, FlatLink(c, 1.0)),
        (1, 3, FlatLink(c, 1.0)),
        (2, 3, FlatLink(c, 1.0)),
    ]
    s1 = edge_scenario(nodes_1, links_1; flock1, flock2, duration, rate, σ, seed)
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
    s2 = edge_scenario(nodes_2, links_2_3; flock1, flock2, duration, rate, σ, seed)
    p2, _ = simulate_and_plot(s2, ShortestPath(); target=:nodes, plot_type=:areaplot)

    # scenario 3: MonotonicNode -- MonotonicLink
    nodes_3 = [
        EqualLoadBalancingNode(c),
        EqualLoadBalancingNode(c),
        EqualLoadBalancingNode(c),
    ]
    s3 = edge_scenario(nodes_3, links_2_3; flock1, flock2, duration, rate, σ, seed)
    p3, _ = simulate_and_plot(s3, ShortestPath(); target=:nodes, plot_type=:areaplot)

    for (i, p) in enumerate([p1, p2, p3])
        savefig(p, "final_edge_$i")
    end
end

final_edge(; seed=42)

function small_edge_scenario(nodes, links;
    drones=10,
    duration=25,
    rate=0.1,
    σ=1.75,
    seed=68987354
)
    Random.seed!(seed)
    j = job(0, 1, 1, 1.0, 1.0)
    R = map(_ -> Vector{Request{typeof(j)}}(), 0:length(nodes))
    n = length(nodes)
    N = n + 2
    D = [truncated(Normal(duration * i / N, σ); lower=0, upper=duration) for i in 1:(N-1)]
    P = fill(Inf, drones, length(D))
    for i in 1:drones, (k, d) in enumerate(D)
        # if k == N - 1 || (i ≤ flock1[1] && k ≥ flock1[2]) || k ≥ flock2[2]
        P[i, k] = rand(d)
        # end
    end

    acc = Set{Int}()

    # Flock 1
    for τ in 0:rate:duration, u in 1:drones
        t = τ + rate / drones * (u - 1)
        p = findlast(x -> t ≥ x, P[u, :])
        if !isnothing(p)
            i = (p + n - 1) % n + 1
            if p ∉ acc
                @info "debug" p n (p + n - 1) i P[u, :] t
                push!(acc, p)
            end
            push!(R[i], Request(j, t))
        end
    end

    users = map(i -> user(R[i], i), 1:length(nodes))
    directed = false

    return scenario(; duration, nodes, links, users, directed)
end

function small_final_edge(;
    c=100.0,
    drones=10,
    duration=25,
    rate=0.1,
    σ=1.75,
    seed=68987354
)

    # scenario 1: FlatNode -- FlatLink
    nodes_1 = [
        FlatNode(c, 1.0),
        FlatNode(c, 1.0),
        FlatNode(c, 1.0),
    ]
    links_1 = [
        (1, 2, FlatLink(c, 1.0)),
        (1, 3, FlatLink(c, 1.0)),
        (2, 3, FlatLink(c, 1.0)),
    ]
    s1 = small_edge_scenario(nodes_1, links_1; drones, duration, rate, σ, seed)
    p1, _ = simulate_and_plot(s1, ShortestPath(); target=:all, plot_type=:all)

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
    s2 = small_edge_scenario(nodes_2, links_2_3; drones, duration, rate, σ, seed)
    p2, _ = simulate_and_plot(s2, ShortestPath(); target=:nodes, plot_type=:areaplot)

    # scenario 3: MonotonicNode -- MonotonicLink
    nodes_3 = [
        EqualLoadBalancingNode(c),
        EqualLoadBalancingNode(c),
        EqualLoadBalancingNode(c),
    ]
    s3 = small_edge_scenario(nodes_3, links_2_3; drones, duration, rate, σ, seed)
    p3, _ = simulate_and_plot(s3, ShortestPath(); target=:nodes, plot_type=:areaplot)

    for (i, p) in enumerate([p1, p2, p3])
        savefig(p, "small_final_edge_$i")
    end

    return p1, p2, p3
end

small_final_edge(; seed=42)[1]

c = 100
nodes_1 = [
    FlatNode(c, 1.0),
    FlatNode(c, 1.0),
    FlatNode(c, 1.0),
]
links_1 = [
    (1, 2, FlatLink(c, 10.0)),
    (1, 3, FlatLink(c, 10.0)),
    (2, 3, FlatLink(c, 10.0)),
]
s1 = small_edge_scenario(nodes_1, links_1)
p1, df1 = simulate_and_plot(s1, ShortestPath(); target=:all, plot_type=:all)
p1
