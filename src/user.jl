abstract type AbstractRequests end

struct PeriodicRequests{J<:AbstractJob} <: AbstractRequests
    job::J
    period::Float64
end

function splat(pr::PeriodicRequests, scenario_duration)
    sequence = 0:pr.period:scenario_duration
    return fill(pr.job, length(sequence))
end

struct User{R<:AbstractRequests}
    job_requests::R
    location::Int
end

function user(period, location, job_distribution)
    return User(PeriodicRequests(rand_job(job_distribution), period), location)
end
