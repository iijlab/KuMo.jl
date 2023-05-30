mutable struct Infrastructure{T<:AbstractTopology}
    # Data
    d::Int # |data|
    data::Dictionary{Int,Data}

    # Topology
    n::Int # |nodes|
    m::Int # |links|
    topology::T

    # Users
    u::Int # |users|
    users::Dictionary{Int,User}

    function Infrastructure{T}(;
        data=Dictionary{Int,Data}(),
        topology=T(),
        users=Dictionary{Int,User}()
    ) where {T<:AbstractTopology}
        d = length(data)
        n = topology |> nodes |> length
        m = topology |> links |> length
        u = length(users)
        return new{T}(d, data, n, m, topology, u, users)
    end
end

user_location(i::Infrastructure, id::Int) = i.users[id].location
