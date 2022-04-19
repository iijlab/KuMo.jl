abstract type AbstractJob end

struct Job <: AbstractJob
    backend::Int
    containers::Int
    data_location::Int
    duration::Int
    frontend::Int
end

function job_distributions(;
    backend = 60 => 20,
    container = 3 => 1,
    data_locations = 1:6,
    duration = 10 => 5,
    frontend = 30 => 10,
    )
    return Dict(
        :backend => censored(Normal(backend[1], backend[2]); lower = 1),
        :container => censored(Normal(container[1], container[2]); lower = 1),
        :data_location => data_locations,
        :duration => censored(Normal(duration[1], duration[2]); lower = 1),
        :frontend => censored(Normal(frontend[1], frontend[2]); lower = 1),
    )
end

const DEFAULT_JOB_DISTRIBUTIONS = job_distributions()

function rand_job(jd = DEFAULT_JOB_DISTRIBUTIONS)
    return Job(
        round(rand(jd[:backend])),
        round(rand(jd[:container])),
        round(rand(jd[:data_location])),
        round(rand(jd[:duration])),
        round(rand(jd[:frontend])),
    )
end
