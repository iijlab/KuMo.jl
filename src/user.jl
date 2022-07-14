"""
    User{R<:AbstractRequests}

A structure to store a user information. A user is defined through a sequence of requests and a location (node id).
"""
struct User{R<:AbstractRequests}
    job_requests::R
    location::Int
end

"""
    user(job_distributions::Dict, period, loc; start=-Inf, stop=Inf)
    user(job, period, loc; start=-Inf, stop=Inf)
    user(jr::Vector{R}, loc::Int) where {R<:Request}
    user(jr, loc::Int)
    user(jr, loc)

A serie of methods to generate users.
"""
function user end

user(jr, loc::Int) = User(jr, loc)

user(jr, loc) = user(jr, rand(loc))

user(jr::Vector{R}, loc::Int) where {R<:Request} = user(requests(jr), loc)

function user(job, period, loc; start=-Inf, stop=Inf)
    return user(PeriodicRequests(job, period; start, stop), loc)
end

function user(job_distributions::Dict, period, loc; start=-Inf, stop=Inf)
    jr = PeriodicRequests(rand_job(job_distributions), period; start, stop)
    return user(jr, loc)
end
