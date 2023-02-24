
#NOTE - edge computing scenario
function figure_edge_1()
    c_leaf = 10
    c_edge = 200
    c_cloud = 10000
    c_total = 4 * c_leaf + c_edge + c_cloud

    l_edge_cloud = 100000.
    l_edge_leaf = 1000.

    Λ = 0.8
    rate = 0.01


    j1 = job(5,1,3,1,0)
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

    links=[
        (1, 2, l_edge_cloud),
        (2, 3, l_edge_leaf),
        (2, 4, l_edge_leaf),
        (2, 5, l_edge_leaf),
        (2, 6, l_edge_leaf),

    ]

    users = [u1]

    return scenario(;
        duration,
        nodes,
        users,
        directed = false,
        links,
    )

end

simulate_and_plot(KuMo.figure_edge_1(), ShortestPath())[1]

#NOTE - edge computing scenario
function figure_edge_2()
    j = job(0,1,4,1.,1.)

    c = 100

    R = map(_ -> Vector{Request{typeof(j)}}(), 1:4)

    rate = 0.01

    duration = 20
    δ1 = duration * 1 / 4 - 1/2 * rate
    δ2 = duration * 2 / 4 - 1/4 * rate
    δ3 = duration * 3 / 4 - 3/4 * rate



    for t in 0:rate:δ1
        push!(R[1], Request(j, t))
    end

    for t in δ1:rate:δ2
        push!(R[4], Request(j, t))
    end
    for t in δ2:rate:δ3
        push!(R[3], Request(j, t))
    end
    for t in δ3:rate:duration-rate
        push!(R[1], Request(j, t))
        push!(R[3], Request(j, t))
    end


    nodes = (4, 100)
    users = map(i -> user(R[i], i), 1:4)
    links = [
        (1, 2, c),
        (1, 3, c),
        (1, 4, c),
        (2, 3, c),
        (2, 4, c),
        (3, 4, c),

        # (2, 1, 100),
        # (3, 1, 100),
        # (4, 1, 100),
        # (3, 2, 100),
        # (4, 2, 100),
        # (4, 3, 100),
    ]
    directed = false

    return scenario(; duration, nodes, users, links, directed)
end

p, df = simulate_and_plot(figure_edge_2(), ShortestPath(); target=:all)

p

df
