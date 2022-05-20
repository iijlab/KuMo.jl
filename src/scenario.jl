struct Scenario
    data::Dict{Int,Data}
    duration::Int
    links::Dict{Tuple{Int,Int},Link}
    nodes::Dict{Int,Node}
    users::Dict{Int,User}
end

const DEFAULT_LINKS = [
    (1, 2) => 1000,
    (1, 3) => 1000,
    (2, 3) => 1000,
    (2, 4) => 1000,
    (3, 5) => 1000,
    (4, 5) => 1000,
    (4, 6) => 1000,
    (5, 6) => 1000,
]

const DEFAULT_NODES = [
    1 => 30,
    2 => 30,
    3 => 30,
    4 => 30,
    5 => 30,
    6 => 30,
]

const DEFAULT_USERS = 100

const DEFAULT_DURATION = 1000

function scenario(;
    duration=DEFAULT_DURATION,
    links=DEFAULT_LINKS,
    nodes=DEFAULT_NODES,
    users=DEFAULT_USERS
)
    _links = Dict{Tuple{Int,Int},Link}()
    foreach(l -> push!(_links, l[1] => Link(l[2])), links)

    _nodes = Dict{Int,Node}()
    foreach(n -> push!(_nodes, n[1] => Node(n[2], 0)), nodes)

    _users = Dict{Int,User}()
    _data = Dict{Int,Data}()

    locations = 1:length(nodes)

    for i in 1:users
        push!(_users, i => user(1 / 20, rand(locations)))
        push!(_data, i => Data(rand(locations)))
    end

    return Scenario(_data, duration, _links, _nodes, _users)
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

function predict_best_cost(s::Scenario, charge)
    predictions = Dict(keys(s.nodes), map(v -> predict_cost(v, charge), values(s.nodes)))
end