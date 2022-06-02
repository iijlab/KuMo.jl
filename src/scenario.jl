struct Scenario
    data::Dictionary{Int,Data}
    duration::Int
    topology::Topology{Int,Int}
    users::Dictionary{Int,User}
end

function scenario(duration, links, nodes, users, job_distribution, request_rate)
    _links = Dictionary{Tuple{Int,Int},Link{Int}}()
    foreach(l -> set!(_links, l[1], Link(l[2])), links)

    _nodes = Dictionary{Int,Node{Int}}()
    foreach(n -> set!(_nodes, n[1], Node(n[2])), nodes)

    _users = Dictionary{Int,User}()
    _data = Dictionary{Int,Data}()

    locations = 1:length(nodes)

    for i in 1:users
        set!(_users, i, user(request_rate, rand(locations), job_distribution))
        set!(_data, i, Data(rand(locations)))
    end

    topo = Topology(_nodes, _links)

    return Scenario(_data, duration, topo, _users)
end

function make_df(s::Scenario)
    df = DataFrame(
        backend=Int[],
        containers=Int[],
        data_location=Int[],
        duration=Float64[],
        frontend=Int[],
        user_id=Int[],
        user_location=Int[],
    )

    for u in s.users
        user_id = u[1]
        user_location = u[2].location
        jr = u[2].job_requests
        for j in splat(jr, s.duration)
            push!(df, (
                j.backend,
                j.containers,
                j.data_location,
                j.duration,
                j.frontend,
                user_id,
                user_location,
            ))
        end
    end

    pretty_table(describe(df))

    return df
end
