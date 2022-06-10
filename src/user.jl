abstract type AbstractRequests end

struct PeriodicRequests{J<:AbstractJob} <: AbstractRequests
    job::J
    period::Float64
    start::Float64
    stop::Float64

    PeriodicRequests(j, p; start=-Inf, stop=Inf) = new{typeof(j)}(j, p, start, stop)
end

function splat(pr::PeriodicRequests, scenario_duration)
    sequence = 0:pr.period:scenario_duration
    return fill(pr.job, length(sequence))
end

struct User{R<:AbstractRequests}
    job_requests::R
    location::Int
end

function user(period, location, job_distribution; start=-Inf, stop=Inf)
    return User(PeriodicRequests(rand_job(job_distribution), period; start, stop), location)
end

user(pr::PeriodicRequests, loc) = User(pr, rand(collect(loc)))

function user(job, period, loc; start=-Inf, stop=Inf)
    return user(PeriodicRequests(job, period; start, stop), loc)
end