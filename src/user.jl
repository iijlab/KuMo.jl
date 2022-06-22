struct User{R<:AbstractRequests}
    job_requests::R
    location::Int
end

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
