abstract type AbstractJob end

struct Job <: AbstractJob
    backend::Int
    containers::Int
    data_location::Int
    duration::Float64
    frontend::Int
end

function job_distributions(; backend, container, data_locations, duration, frontend)
    return Dict(
        :backend => censored(Normal(backend[1], backend[2]); lower=1),
        :container => censored(Normal(container[1], container[2]); lower=1),
        :data_location => data_locations,
        :duration => censored(Normal(duration[1], duration[2]); lower=1),
        :frontend => censored(Normal(frontend[1], frontend[2]); lower=1),
    )
end

job(x...) = Job(x...)

function rand_job(jd)
    return Job(
        round(rand(jd[:backend])),
        round(rand(jd[:container])),
        round(rand(jd[:data_location])),
        round(rand(jd[:duration])),
        round(rand(jd[:frontend])),
    )
end
