
#NOTE - edge computing scenario
function figure_edge_1()
    c_leaf = 10
    c_edge = 200
    c_cloud = 10000
    c_total = 4 * c_leaf + c_edge + c_cloud

    l_edge_cloud = 100000.0
    l_edge_leaf = 1000.0

    Λ = 0.8
    rate = 0.01


    j1 = job(5, 1, 3, 1, 0)
    _requests = Vector{Request{typeof(j1)}}()

    r = rate
    λ = Λ
    n = 1
    δ = j1.duration

    π1 = λ / r
    π2 = (2n - λ) / r

    for i in 0:π1+π2
        for t in i:δ:π1+π2-i
            i ≤ π1 && push!(_requests, Request(j1, t))
        end
    end

    u1 = user(Requests(_requests), 3)

    # j2 = job(3,3,2,3,3)

    # max_load = 3.5
    # nodes = (4, 100)
    # rate = 0.01
    # j = job(0, 1, rand(1:4), 3.25, 0)



    # r = rate
    # λ = max_load
    # n = nodes[1]
    # δ = j.duration

    # π1 = λ / r
    # π2 = (2n - λ) / r

    # for i in 0:π1+π2
    #     for t in i:δ:π1+π2-i
    #         i ≤ π1 && push!(_requests, Request(j, t))
    #     end
    # end

    duration = 1000
    nodes = [
        # Cloud Servers
        Node(c_cloud),

        # Edge Server
        Node(c_edge),

        # Local Nodes
        Node(c_leaf),
        Node(c_leaf),
        Node(c_leaf),
        Node(c_leaf),
    ]

    links = [
        (1, 2, l_edge_cloud),
        (2, 3, l_edge_leaf),
        (2, 4, l_edge_leaf),
        (2, 5, l_edge_leaf),
        (2, 6, l_edge_leaf),]

    users = [u1]

    return scenario(;
        duration,
        nodes,
        users,
        directed=false,
        links
    )

end

# simulate_and_plot(KuMo.figure_edge_1(), ShortestPath())[1]

#NOTE - edge computing scenario
function figure_edge_2(;
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

p, df = simulate_and_plot(figure_edge_2(), ShortestPath(); target=:nodes, plot_type=:areaplot);
p;

df

#NOTE - edge computing scenario
function figure_edge_3(;
    drones=[10, 5],
    duration=20,
    σ=[1.0, 1.0],
    seed=42,
    Δ=[5, 7.5],
    starts=[0.0, Δ[1] * 3]
)
    Random.seed!(seed)

    nodes = (3, 100)
    j = job(0, 1, 1, 1.0, 1.0)

    c = 100

    R = map(_ -> Vector{Request{typeof(j)}}(), 1:nodes[1])

    rate = 0.1

    Ω = map(δ -> ceil(Int, (duration - starts[δ[1]]) / δ[2]) - 1, enumerate(Δ))

    means = Dict{Tuple{Int,Int,Int},Float64}()

    for (i, flock) in enumerate(drones), ω in 1:Ω[i]
        μ = ω * Δ[i]
        d = truncated(Normal(μ, σ[i]); lower=0.0, upper=duration)
        for j in 1:flock
            push!(means, (i, j, ω) => rand(d))
        end
    end

    @info "debug" Ω means

    node_mod = n -> (n + 2) % 3 + 1

    acc = 0

    for (i, flock) in enumerate(drones), drone in 1:flock, τ in reverse(starts[i]:rate:duration)
        t = τ + rate * (drone - 1) / drone

        d = filter(p -> p.first[1] == i && p.first[2] == drone, means)
        P = sort(collect(values(d)))
        p = findfirst(x -> t < x, P)
        q = isnothing(p) ? Ω[i] : p
        push!(R[node_mod(q)], Request(j, t))
        # @info P p q node_mod(q) i j t
        # acc += 1
        # acc > 10 && break
    end

    @info "debug 2" R R[1] R[2] R[3]

    users = map(i -> user(R[i], i), 1:nodes[1])
    links = [
        (1, 2, c),
        (1, 3, c),
        (2, 3, c),
    ]
    directed = false

    return scenario(; duration, nodes, users, links, directed)
end

# p, df = simulate_and_plot(figure_edge_3(; σ = [1.75, 3.75], seed = 68987354), ShortestPath(); target=:nodes, plot_type =:areaplot); p

# df
