"""
    Scenario{N <: AbstractNode, L <: AbstractLink, U <: User}

Structure to store the information of a scenario.

# Arguments:
- `data::Dictionary{Int, Data}`: data collection (currently not in use)
- `duration::Real`: optional duration of the scenario
- `topology::Topology{N, L}`: network's topology
- `users::Dictionary{Int, U}`: collection of users
"""
struct Scenario{T<:AbstractTopology,U<:User}
    data::Dictionary{Int,Data}
    duration::Real
    topology::T
    users::Dictionary{Int,U}
end

"""
    make_nodes(nodes)

Create nodes.
"""
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

"""
    make_links(links)

Creates links.
"""
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

"""
    make_users(args...)

Create users.
"""
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

make_topology(nodes, links, ::Val{true}) = DirectedTopology(nodes, links)
make_topology(nodes, links, ::Val{false}) = Topology(nodes, links)

function scenario(duration, links, nodes, users, directed)
    _nodes = make_nodes(nodes)
    _links = isnothing(links) ? make_links(links, length(_nodes)) : make_links(links)
    _data = Dictionary{Int,Data}()
    locations = 1:length(_nodes)

    _users = make_users(users, locations, _data)

    topo = make_topology(_nodes, _links, Val(directed))

    return Scenario(_data, duration, topo, _users)
end

function scenario(duration, links, nodes, users, job_distribution, request_rate, directed)
    _nodes = make_nodes(nodes)
    _links = isnothing(links) ? make_links(links, length(_nodes)) : make_links(links)
    _data = Dictionary{Int,Data}()
    locations = 1:length(_nodes)

    _users = make_users(users, request_rate, locations, job_distribution, _data)

    topo = make_topology(_nodes, _links, Val(directed))

    return Scenario(_data, duration, topo, _users)
end

"""
    scenario(; duration, links = nothing, nodes, users, job_distribution = nothing, request_rate = nothing)

Build a scenario.

# Arguments:
- `duration`: duration of the interval where requests can be started
- `links`: collection of links resources
- `nodes`: collection of nodes resources
- `users`: collections of users information
- `job_distribution`: (optional) distributions used to generate jobs
- `request_rate`: (optional) average request rate
"""
function scenario(;
    duration,
    links=nothing,
    nodes,
    users,
    job_distribution=nothing,
    request_rate=nothing,
    directed=true
)
    if job_distribution === nothing || request_rate === nothing
        scenario(duration, links, nodes, users, directed)
    else
        scenario(duration, links, nodes, users, job_distribution, request_rate, directed)
    end
end

"""
    make_df(s::Scenario; verbose = true)

Make a DataFrame to describe the scenario `s`.
"""
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


