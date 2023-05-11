abstract type AbstractScenario end

struct EmptyScenario <: AbstractScenario end

"""
    Scenario{N <: AbstractNode, L <: AbstractLink, U <: User}

Structure to store the information of a scenario.

# Arguments:
- `data::Dictionary{Int, Data}`: data collection (currently not in use)
- `duration::Real`: optional duration of the scenario
- `topology::Topology{N, L}`: network's topology
- `users::Dictionary{Int, U}`: collection of users
"""
mutable struct Scenario{T<:AbstractTopology,U<:User} <: AbstractScenario
    d::Int
    data::Dictionary{Int,Data}
    duration::Real
    m::Int
    n::Int
    requests::Requests
    topology::T
    u::Int
    users::Dictionary{Int,U}
end

function Scenario(;
    data=Dictionary{Int,Data}(),
    duration,
    topology,
    users=Dictionary{Int,User}(),
    requests
)
    d = length(data)
    n = topology |> nodes |> length
    m = topology |> links |> length
    u = length(users)
    return Scenario(d, data, duration, m, n, requests, topology, u, users)
end

# Add a node to the scenario
function add_node!(s::Scenario, t::Float64, r::N) where {N<:AbstractNode}
    s.n += 1
    req = NodeRequest(s.n, r, t)
    push!(s.requests, req)
end
node!(s::Scenario, t::Float64, r::AbstractNode) = add_node!(s, t, r)

function rem_node!(s::Scenario, t::Float64, id::Int)
    req = NodeRequest(id, nothing, t)
    push!(s.requests, req)
end
node!(s::Scenario, t::Float64, id::Int) = rem_node!(s, t, id)

function change_node!(s::Scenario, t::Float64, id::Int, r::N) where {N<:AbstractNode}
    req = NodeRequest(id, r, t)
    push!(s.requests, req)
end
node!(s::Scenario, t::Float64, id::Int, r::AbstractNode) = change_node!(s, t, id, r)

# macro node(args...)
#     return if length(args) == 3
#         :(node!($(args[1]), $(args[2]), $(args[3])))
#     else
#         :(node!($(args[1]), $(args[2]), $(args[3]), $(args[4])))
#     end
# end

function add_link!(
    s::Scenario,
    t::Float64,
    source::Int,
    target::Int,
    r::L,
) where {L<:AbstractLink}
    s.m += 1
    req = LinkRequest(r, source, t, target)
    push!(s.requests, req)
end

function rem_link!(s::Scenario, t::Float64, source::Int, target::Int)
    req = LinkRequest(nothing, source, t, target)
    push!(s.requests, req)
end
link!(s::Scenario, t::Float64, source::Int, target::Int) = rem_link!(s, t, source, target)

function change_link!(
    s::Scenario,
    t::Float64,
    source::Int,
    target::Int,
    r::L,
) where {L<:AbstractLink}
    req = LinkRequest(r, source, t, target)
    push!(s.requests, req)
end
function link!(s::Scenario, t::Float64, source::Int, target::Int, r::AbstractLink)
    if (source, target) ∈ s.topology |> links |> keys
        return change_link!(s, t, source, target, r)
    end
    return add_link!(s, t, source, target, r)
end

function add_user!(s::Scenario, t::Float64, loc::Int)
    s.u += 1
    req = UserRequest(s.u, loc, t)
    push!(s.requests, req)
end
user!(s::Scenario, t::Float64, loc::Int) = add_user!(s, t, loc)

function rem_user!(s::Scenario, t::Float64, id::Int)
    req = UserRequest(id, 0, t)
    push!(s.requests, req)
end

function move_user!(s::Scenario, t::Float64, id::Int, loc::Int)
    req = UserRequest(id, loc, t)
    push!(s.requests, req)
end
user!(s::Scenario, t::Float64, id::Int, loc::Int) = move_user!(s, t, id, loc)

function add_data!(s::Scenario, t::Float64, loc::Int)
    s.d += 1
    req = DataRequest(s.d, loc, t)
    push!(s.requests, req)
end
data!(s::Scenario, t::Float64, loc::Int) = add_data!(s, t, loc)

function rem_data!(s::Scenario, t::Float64, id::Int)
    req = DataRequest(id, 0, t)
    push!(s.requests, req)
end

function move_data!(s::Scenario, t::Float64, id::Int, loc::Int)
    req = DataRequest(id, loc, t)
    push!(s.requests, req)
end
data!(s::Scenario, t::Float64, id::Int, loc::Int) = move_data!(s, t, id, loc)

function add_job!(s::Scenario, t::Float64, j::Job, u_id::Int, d_id::Int)
    req = JobRequest(d_id, j, t, u_id)
    push!(s.requests, req)
end

function job!(
    s::Scenario,
    backend,
    container,
    duration,
    frontend,
    data_id,
    user_id,
    ν;
    start=0.0,
    stop=s.duration
)
    j = job(backend, container, duration, frontend)
    for t in start:ν:stop
        add_job!(s, t, j, user_id, data_id)
    end
end

function job!(
    s::Scenario,
    t::Float64,
    backend,
    container,
    duration,
    frontend,
    data_id,
    user_id;
)
    j = job(backend, container, duration, frontend)
    add_job!(s, t, j, user_id, data_id)
end

make_topology(::Val{true}) = DirectedTopology()
make_topology(::Val{false}) = Topology()

function scenario(directed, duration, requests)
    topology = make_topology(Val(directed))
    return Scenario(; duration, requests, topology)
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
    directed=true,
    duration=0,
    requests=Requests()
)
    return scenario(directed, duration, requests)
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
