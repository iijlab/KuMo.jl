"""
    AbstractJob

An abstract supertype for jobs.
"""
abstract type AbstractJob end

"""
    Job <: AbstractJob

The most generic job type.
"""
struct Job <: AbstractJob
    backend::Int
    containers::Int
    data_location::Int
    duration::Float64
    frontend::Int
end

"""
    job_distributions(; backend, container, data_locations, duration, frontend)

Construct a dictionary with random distributions to generate new jobs.
"""
function job_distributions(; backend, container, data_locations, duration, frontend)
    return Dict(
        :backend => censored(Normal(backend[1], backend[2]); lower=1),
        :container => censored(Normal(container[1], container[2]); lower=1),
        :data_location => data_locations,
        :duration => censored(Normal(duration[1], duration[2]); lower=1),
        :frontend => censored(Normal(frontend[1], frontend[2]); lower=1),
    )
end

"""
    job(backend::Int, containers::Int, data_location::Int, duration::Float64, frontend::Int)

Method to create new jobs.
"""
job(x...) = Job(x...)

"""
    rand_job(jd::Dict)

Create a random job given a job_distribution dictionary.
"""
function rand_job(jd)
    return Job(
        round(rand(jd[:backend])),
        round(rand(jd[:container])),
        round(rand(jd[:data_location])),
        round(rand(jd[:duration])),
        round(rand(jd[:frontend])),
    )
end
