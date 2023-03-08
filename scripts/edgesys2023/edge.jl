# function edge_scenario(nodes, links;
#     flock1=(10, 1),
#     flock2=(5, 5),
#     duration=40,
#     rate=0.1,
#     σ=1.75,
#     seed=68987354
# )
#     Random.seed!(seed)
#     drones = flock1[1] + flock2[1]
#     j = job(0, 1, 1, 1.0, 1.0)
#     R = map(_ -> Vector{Request{typeof(j)}}(), 0:length(nodes))
#     n = length(nodes)
#     N = n + 4
#     D = [truncated(Normal(duration * i / N, σ); lower=0, upper=duration) for i in 1:(N-1)]
#     P = fill(Inf, drones, length(D))
#     for i in 1:drones, (k, d) in enumerate(D)
#         if k == N - 1 || (i ≤ flock1[1] && k ≥ flock1[2]) || k ≥ flock2[2]
#             P[i, k] = rand(d)
#         end
#     end

#     acc = Set{Int}()

#     # Flock 1
#     for τ in 0:rate:duration, u in 1:drones
#         t = τ + rate / drones * (u - 1)
#         p = findlast(x -> t ≥ x, P[u, :])
#         if !isnothing(p)
#             i = (p + n - (u < flock1[1] ? 1 : 2)) % n + 1
#             if p ∉ acc
#                 @info "debug" p n (p + n - 1) i P[u, :] t
#                 push!(acc, p)
#             end
#             push!(R[i], Request(j, t))
#         end
#     end

#     users = map(i -> user(R[i], i), 1:length(nodes))
#     directed = false

#     return scenario(; duration, nodes, links, users, directed)
# end

# function final_edge(;
#     c=100.0,
#     flock1=(10, 1),
#     flock2=(6, 5),
#     duration=40,
#     rate=0.1,
#     σ=1.75,
#     seed=68987354
# )

#     # scenario 1: FlatNode -- FlatLink
#     nodes_1 = [
#         FlatNode(c, 0.0),
#         FlatNode(c, 0.0),
#         FlatNode(c, 0.0),
#     ]
#     links_1 = [
#         (1, 2, FlatLink(c, 1.0)),
#         (1, 3, FlatLink(c, 1.0)),
#         (2, 3, FlatLink(c, 1.0)),
#     ]
#     s1 = edge_scenario(nodes_1, links_1; flock1, flock2, duration, rate, σ, seed)
#     p1, _ = simulate_and_plot(s1, ShortestPath(); target=:nodes, plot_type=:areaplot)

#     # scenario 2: ConvexNode -- MonotonicLink
#     nodes_2 = [
#         Node(c),
#         Node(c),
#         Node(c),
#     ]
#     links_2_3 = [
#         (1, 2, c),
#         (1, 3, c),
#         (2, 3, c),
#     ]
#     s2 = edge_scenario(nodes_2, links_2_3; flock1, flock2, duration, rate, σ, seed)
#     p2, _ = simulate_and_plot(s2, ShortestPath(); target=:nodes, plot_type=:areaplot)

#     # scenario 3: MonotonicNode -- MonotonicLink
#     nodes_3 = [
#         EqualLoadBalancingNode(c),
#         EqualLoadBalancingNode(c),
#         EqualLoadBalancingNode(c),
#     ]
#     s3 = edge_scenario(nodes_3, links_2_3; flock1, flock2, duration, rate, σ, seed)
#     p3, _ = simulate_and_plot(s3, ShortestPath(); target=:nodes, plot_type=:areaplot)

#     for (i, p) in enumerate([p1, p2, p3])
#         savefig(p, "final_edge_$i")
#     end
# end

# final_edge(; seed=42)

# function small_edge_scenario(nodes, links;
#     drones=10,
#     duration=25,
#     rate=0.1,
#     σ=1.75,
#     seed=68987354
# )
#     Random.seed!(seed)
#     j = job(0, 1, 1, 1.0, 1.0)
#     R = map(_ -> Vector{Request{typeof(j)}}(), 0:length(nodes))
#     n = length(nodes)
#     N = n + 2
#     D = [truncated(Normal(duration * i / N, σ); lower=0, upper=duration) for i in 1:(N-1)]
#     P = fill(Inf, drones, length(D))
#     for i in 1:drones, (k, d) in enumerate(D)
#         # if k == N - 1 || (i ≤ flock1[1] && k ≥ flock1[2]) || k ≥ flock2[2]
#         P[i, k] = rand(d)
#         # end
#     end

#     acc = Set{Int}()

#     # Flock 1
#     for τ in 0:rate:duration, u in 1:drones
#         t = τ + rate / drones * (u - 1)
#         p = findlast(x -> t ≥ x, P[u, :])
#         if !isnothing(p)
#             i = (p + n - 1) % n + 1
#             if p ∉ acc
#                 push!(acc, p)
#             end
#             push!(R[i], Request(j, t))
#         end
#     end

#     users = map(i -> user(R[i], i), 1:length(nodes))
#     directed = false

#     return scenario(; duration, nodes, links, users, directed)
# end

# function small_final_edge(;
#     c=100.0,
#     drones=10,
#     duration=25,
#     rate=0.1,
#     σ=1.75,
#     seed=68987354
# )

#     # scenario 1: FlatNode -- FlatLink
#     nodes_1 = [
#         FlatNode(c, 1.0),
#         FlatNode(c, 1.0),
#         FlatNode(c, 1.0),
#     ]
#     links_1 = [
#         (1, 2, FlatLink(c, 1.0)),
#         (1, 3, FlatLink(c, 1.0)),
#         (2, 3, FlatLink(c, 1.0)),
#     ]
#     s1 = small_edge_scenario(nodes_1, links_1; drones, duration, rate, σ, seed)
#     p1, _ = simulate_and_plot(s1, ShortestPath(); target=:all, plot_type=:all)

#     # scenario 2: ConvexNode -- MonotonicLink
#     nodes_2 = [
#         Node(c),
#         Node(c),
#         Node(c),
#     ]
#     links_2_3 = [
#         (1, 2, c),
#         (1, 3, c),
#         (2, 3, c),
#     ]
#     s2 = small_edge_scenario(nodes_2, links_2_3; drones, duration, rate, σ, seed)
#     p2, _ = simulate_and_plot(s2, ShortestPath(); target=:nodes, plot_type=:areaplot)

#     # scenario 3: MonotonicNode -- MonotonicLink
#     nodes_3 = [
#         EqualLoadBalancingNode(c),
#         EqualLoadBalancingNode(c),
#         EqualLoadBalancingNode(c),
#     ]
#     s3 = small_edge_scenario(nodes_3, links_2_3; drones, duration, rate, σ, seed)
#     p3, _ = simulate_and_plot(s3, ShortestPath(); target=:nodes, plot_type=:areaplot)

#     for (i, p) in enumerate([p1, p2, p3])
#         savefig(p, "small_final_edge_$i")
#     end

#     return p1, p2, p3
# end

# small_final_edge(; seed=42)[1]

# c = 100
# nodes_1 = [
#     FlatNode(c, 1.0),
#     FlatNode(c, 1.0),
#     FlatNode(c, 1.0),
# ]
# links_1 = [
#     (1, 2, FlatLink(c, 10.0)),
#     (1, 3, FlatLink(c, 10.0)),
#     (2, 3, FlatLink(c, 10.0)),
# ]
# s1 = small_edge_scenario(nodes_1, links_1)
# p1, df1 = simulate_and_plot(s1, ShortestPath(); target=:all, plot_type=:all)
# p1

# nodes_2 = [
#     FlatNode(c, 0.1),
#     FlatNode(c, 0.1),
#     FlatNode(c, 0.1),
# ]
# links_2 = [
#     #     (1, 2),
#     #     (1, 3),
#     #     (2, 3),
#     (1, 2, FlatLink(c, 0.1)),
#     (1, 3, FlatLink(c, 0.1)),
#     (2, 3, FlatLink(c, 0.1)),
# ]
# s2 = small_edge_scenario(nodes_2, links_2; rate=25, drones=1)
# p2, df2 = simulate_and_plot(s2, ShortestPath(); target=:all, plot_type=:all)
# p2

function mini_edge_scenario(nodes, links=nothing;
    drones=10,
    duration=100,
    phase=20,
    rate=0.01,
    jd=1.0
)
    j = job(0, 1, 1, jd, 1.0)
    R = map(_ -> Vector{Request{KuMo.Job}}(), 1:3)

    for τ in 0:rate:duration, u in 1:drones
        t = τ + rate / drones * (u - 1)
        i = 0
        if 5 ≤ t < 10
            i = 1
        elseif 10 ≤ t < 30
            i = t < 10 + phase / drones * (u - 1) ? 1 : 2
        elseif 30 ≤ t < 50
            i = t < 30 + phase / drones * (u - 1) ? 2 : 3
        elseif 50 ≤ t < 75
            i = t ≤ 50 + phase / drones * (u - 1) ? 3 : 1
        end
        i == 0 || push!(R[i], Request(j, t))
    end

    users = map(i -> user(R[i], i), 1:length(nodes))
    directed = false

    return scenario(; duration, nodes, links, users, directed)
end

function mini_final_edge(;
    c=100.0,
    flat=1.0,
    drones=10,
    duration=100,
    phase=20,
    rate=0.1,
    jd=1.0
)

    # scenario 1: FlatNode -- FlatLink
    nodes_1 = [
        FlatNode(c, flat),
        FlatNode(c, flat),
        FlatNode(c, flat),
    ]
    links_1_4_5 = [
        (1, 2, FlatLink(c, flat)),
        (1, 3, FlatLink(c, flat)),
        (2, 3, FlatLink(c, flat)),
    ]
    s1 = mini_edge_scenario(nodes_1, links_1_4_5; duration, rate, jd, drones, phase)
    title = "scenario 1: FlatNode -- FlatLink"
    p1, _ = simulate_and_plot(s1, ShortestPath(); target=:nodes, plot_type=:areaplot, title)

    # scenario 2: ConvexNode -- MonotonicLink
    nodes_2_4 = [
        Node(c),
        Node(c),
        Node(c),
    ]
    links_2_3 = [
        (1, 2, c),
        (1, 3, c),
        (2, 3, c),
    ]
    s2 = mini_edge_scenario(nodes_2_4, links_2_3; duration, rate, jd, drones, phase)
    title = "scenario 2: ConvexNode -- MonotonicLink"
    p2, _ = simulate_and_plot(s2, ShortestPath(); target=:nodes, plot_type=:areaplot, title)

    # scenario 3: MonotonicNode -- MonotonicLink
    nodes_3_5 = [
        EqualLoadBalancingNode(c),
        EqualLoadBalancingNode(c),
        EqualLoadBalancingNode(c),
    ]
    s3 = mini_edge_scenario(nodes_3_5, links_2_3; duration, rate, jd, drones, phase)
    title = "scenario 3: MonotonicNode -- MonotonicLink"
    p3, _ = simulate_and_plot(s3, ShortestPath(); target=:nodes, plot_type=:areaplot, title)

    # scenario 4: ConvexNode -- FlatLink
    s4 = mini_edge_scenario(nodes_2_4, links_1_4_5; duration, rate, jd, drones, phase)
    title = "scenario 4: ConvexNode -- FlatLink"
    p4, _ = simulate_and_plot(s4, ShortestPath(); target=:nodes, plot_type=:areaplot, title)

    # scenario 5: MonotonicNode -- FlatLink
    s5 = mini_edge_scenario(nodes_3_5, links_1_4_5; duration, rate, jd, drones, phase)
    title = "scenario 5: MonotonicNode -- FlatLink"
    p5, _ = simulate_and_plot(s5, ShortestPath(); target=:nodes, plot_type=:areaplot, title)

    # scenario 6: ConvexNode -- FreeLink
    s6 = mini_edge_scenario(nodes_2_4; duration, rate, jd, drones, phase)
    title = "scenario 6: ConvexNode -- FreeLink"
    p6, _ = simulate_and_plot(s6, ShortestPath(); target=:nodes, plot_type=:areaplot, title)

    # scenario 7: MonotonicNode -- FreeLink
    s7 = mini_edge_scenario(nodes_3_5; duration, rate, jd, drones, phase)
    title = "scenario 7: MonotonicNode -- FreeLink"
    p7, _ = simulate_and_plot(s7, ShortestPath(); target=:nodes, plot_type=:areaplot, title)


    # scenario 8: AdditiveNode -- MonotonicLink
    nodes_8 = [
        AdditiveNode(c, -1.0),
        AdditiveNode(c, -1.0),
        AdditiveNode(c, -1.0),
    ]
    s8 = mini_edge_scenario(nodes_8, links_1_4_5; duration, rate, jd, drones, phase)
    title = "scenario 8: AdditiveNode -- MonotonicLink"
    p8, _ = simulate_and_plot(s8, ShortestPath(); target=:nodes, plot_type=:areaplot, title)

    # scenario 9: AdditiveNode -- ConvexLink
    links_9 = [
        (1, 2, ConvexLink(c)),
        (1, 3, ConvexLink(c)),
        (2, 3, ConvexLink(c)),
    ]
    s9 = mini_edge_scenario(nodes_2_4, links_9; duration, rate, jd, drones, phase)
    title = "scenario 9: ConvexNode -- ConvexLink"
    p9, _ = simulate_and_plot(s9, ShortestPath(); target=:nodes, plot_type=:areaplot, title)

    # scenario 10: Mix Nodes -- MonotonicLink
    nodes_10 = [
        AdditiveNode(c, 0.5),
        EqualLoadBalancingNode(c),
        Node(c),
    ]
    links_2_3 = [
        (1, 2, c),
        (1, 3, c),
        (2, 3, c),
    ]
    s10 = mini_edge_scenario(nodes_10, links_2_3; duration, rate, jd, drones, phase)
    title = "scenario 10: Mix Nodes -- MonotonicLink"
    p10, _ = simulate_and_plot(s10, ShortestPath(); target=:nodes, plot_type=:areaplot, title)

    P = [p1, p2, p3, p4, p5, p6, p7, p8, p9, p10]
    S = [s1, s2, s3, s4, s5, s6, s7, s8, s9, s10]

    # for (i, p) in enumerate(P)
    #     savefig(p, "mini_final_edge_$i")
    # end

    return P, S
end

# P, S = mini_final_edge(; drones=10, rate=0.1, jd=1.0)
P, S = mini_final_edge(; drones=100, rate=0.1, jd=0.1, flat=1.125, c=75)

show_simulation(S[3])
