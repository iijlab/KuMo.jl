struct Scenario{N<:AbstractNode,L<:AbstractLink,R<:AbstractRequests}
    data::Dictionary{Int,Data}
    duration::Real
    topology::Topology{N,L}
    users::Dictionary{Int,User{R}}
end

function make_nodes(nodes)
    types = Set{Type}()
    foreach(v -> push!(types, v), Iterators.map(typeof, nodes))
    UT = Union{collect(types)...}
    _nodes = Dictionary{Int,UT}()
    foreach(v -> set!(_nodes, v[1], v[2]), enumerate(nodes))
    return _nodes
end

function make_nodes(nt::DataType, capacities)
    _nodes = Dictionary{Int,nt}()
    foreach((i, c) -> set!(_nodes, i, nt(c)), enumerate(capacities))
    return _nodes
end

function make_nodes(nt::DataType, n, capacity)
    _nodes = Dictionary{Int,nt}()
    foreach(i -> set!(_nodes, i, nt(capacity)), 1:n)
    return _nodes
end

make_nodes(n, c) = make_nodes(Node{typeof(c)}, n, c)

function make_nodes(capacities::Vector{T}) where {T<:Number}
    return make_nodes(Node{T}, capacities)
end

make_nodes(x::Tuple) = make_nodes(x...)

function make_links(links)
    _links = Dictionary{Tuple{Int,Int},FreeLink}()
    foreach(l -> set!(_links, (l[1], l[2]), FreeLink()), links)
    return _links
end

make_links(::Nothing, n::Int) = make_links(Iterators.product(1:n, 1:n))

function make_links(links::Vector{Tuple{DataType,Int,Int,T}}) where {T<:Number}
    types = Set{Type}()
    foreach(l -> push!(types, l[1]), links)
    UT = Union{collect(s)...}
    _links = Dictionary{Tuple{Int,Int},UT}()
    foreach(l -> set!(_links, (l[2], l[3]), l[1](l[4])), links)
    return _links
end

function make_links(lt::DataType, links) where {T<:Number}
    _links = Dictionary{Tuple{Int,Int},lt}()
    foreach(l -> set!(_links, (l[1], l[2]), lt(l[3])), links)
    return _links
end

make_links(links::Vector{Tuple{Int,Int,T}}) where {T<:Number} = make_links(Link{T}, links)

function make_links(lt::DataType, links, c)
    _links = Dictionary{Tuple{Int,Int},lt}()
    foreach(l -> set!(_links, (l[1], l[2]), lt(c)), links)
    return _links
end

make_links(links, c) = make_links(Link{typeof(c)}, links, c)

make_links(n::Int, c) = make_links(Iterators.product(1:n, 1:n), c)

make_links(x::Tuple) = make_links(x...)

function make_users(n::Int, rate, locations, jd, data)
    users = Dictionary{Int,User{PeriodicRequests{Job}}}()
    for i in 1:n
        set!(users, i, user(jd, rate, locations))
        set!(data, i, Data(rand(locations)))
    end
    return users
end

function make_users(users, locations, data)
    _users = Dictionary(users)
    for i in 1:length(users)
        set!(data, i, Data(rand(locations)))
    end
    return _users
end

function scenario(duration, links, nodes, users)
    _nodes = make_nodes(nodes)
    _links = isnothing(links) ? make_links(links, length(_nodes)) : make_links(links)
    _data = Dictionary{Int,Data}()
    locations = 1:length(_nodes)

    _users = make_users(users, locations, _data)

    topo = Topology(_nodes, _links)

    return Scenario(_data, duration, topo, _users)
end

function scenario(duration, links, nodes, users, job_distribution, request_rate)
    _nodes = make_nodes(nodes)
    _links = isnothing(links) ? make_links(links, length(_nodes)) : make_links(links)
    _data = Dictionary{Int,Data}()
    locations = 1:length(_nodes)

    _users = make_users(users, request_rate, locations, job_distribution, _data)

    topo = Topology(_nodes, _links)

    return Scenario(_data, duration, topo, _users)
end

function scenario(;
    duration,
    links=nothing,
    nodes,
    users,
    job_distribution=nothing,
    request_rate=nothing
)
    if job_distribution === nothing || request_rate === nothing
        scenario(duration, links, nodes, users)
    else
        scenario(duration, links, nodes, users, job_distribution, request_rate)
    end
end

function make_df(s::Scenario; verbose=true)
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

    verbose && pretty_table(describe(df))

    return df
end

const SCENARII = Dict(
    :four_nodes_four_users => scenario(;
        duration=399,
        nodes=(4, 125),
        users=[
            user(requests(job(0, 1, rand(1:4), 1, 0), 10, Normal(5, 1), 0, 10), rand(1:4);)
        ]
    ),
    :four_nodes => scenario(;
        duration=399,
        nodes=(4, 125),
        users=[
            user(job(0, 1, rand(1:4), 400, 0), 1.0, rand(1:4); start=200.5, stop=299.5)
            user(job(0, 1, rand(1:4), 400, 0), 1.0, rand(1:4);)
        ]
    ),
    :square => scenario(;
        duration=399,
        nodes=(4, 100),
        links=[
            (1, 2, 400.0), (2, 3, 400.0), (3, 4, 400.0), (4, 1, 400.0),
            (2, 1, 400.0), (3, 2, 400.0), (4, 3, 400.0), (1, 4, 400.0),
        ],
        users=1,
        job_distribution=Dict(
            :backend => 2:2,
            :container => 1:2,
            :data_location => 1:4,
            :duration => 400:400,
            :frontend => 1:1,
        ),
        request_rate=1.0
    )
)
