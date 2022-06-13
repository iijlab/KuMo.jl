struct User{R<:AbstractRequests}
    job_requests::R
    location::Int
end

user(jr, loc::Int) = User(jr, loc)

user(jr, loc) = user(jr, rand(loc))

function user(job, period, loc; start=-Inf, stop=Inf)
    return user(PeriodicRequests(job, period; start, stop), loc)
end

function periodic_user(period, loc, job_distributions; start=-Inf, stop=Inf)
    jr = PeriodicRequests(rand_job(job_distributions), period; start, stop)
    return user(jr, loc)
end
