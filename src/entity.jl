abstract type AbstractEntity end

location(e::AbstractEntity) = e.location
location!(e::AbstractEntity, loc) = e.location = loc

"""
    Data
Structure to store the information related to some `Data`. Currently, only the location of such data is stored.
"""
mutable struct Data <: AbstractEntity
    location::Int
end

"""
    data(location)

Construct data at `location`. If the location is a collection, a random location is chosen.
"""
data(loc::Int) = Data(loc)
data(loc) = data(rand(loc))

"""
    User{R<:AbstractRequests}

A structure to store a user information. A user is defined as a location (node id).
"""
mutable struct User <: AbstractEntity
    location::Int
end

"""
    user(location)

Construct a user at `location`. If the location is a collection, a random location is chosen.
"""
user(loc::Int) = User(loc)
user(loc) = user(rand(loc))

#SECTION - Test Items

@testitem "Entities: Data" tags = [:entity, :data] begin
    import KuMo: data, location, location!
    d = data(42)
    @test location(d) == 42
    location!(d, 1)
    @test location(d) == 1
end

@testitem "Entities: User" tags = [:entity, :user] begin
    import KuMo: user, location, location!
    u = user(42)
    @test location(u) == 42
    location!(u, 1)
    @test location(u) == 1
end
