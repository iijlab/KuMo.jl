"""
    AbstractRequests

An abstract supertype for job requests.
"""
abstract type AbstractRequests end

"""
    PeriodicRequests{J<:AbstractJob} <: AbstractRequests

A structure to handle job that
"""
struct PeriodicRequests{J<:AbstractJob} <: AbstractRequests
    job::J
    period::Float64
    start::Float64
    stop::Float64

    PeriodicRequests(j, p; start=-Inf, stop=Inf) = new{typeof(j)}(j, p, start, stop)
end

struct Request{J<:AbstractJob}
    job::J
    start::Float64
end

struct Requests{J<:AbstractJob} <: AbstractRequests
    requests::Vector{Request{J}}
end

function requests(pr::PeriodicRequests)
    return Requests(map(t -> Request(pr.job, t), pr.start:pr.period:pr.stop))
end

requests(r::Request) = Requests([r])

requests(r::Requests) = r

function requests(j::Job, n::Int, d::UnivariateDistribution, lower::Real, upper::Real)
    dtrunc = truncated(d; lower, upper)
    return Requests(map(_ -> Request(j, rand(dtrunc)), 1:n))
end

function requests(requests_lst...)
    UT = Union{map(r -> first(typeof(r).parameters), requests_lst)...}
    reqs = Requests(Vector{UT}())
    foreach(r -> push!(reqs.requests, r), Iterators.flatten(requests_lst))
    return reqs
end

spike(j, t, intensity) = fill(Request(j, t), (intensity,))

function smooth(j, δ, π1, π2)
    reqs = Vector{KuMo.Request{typeof(j)}}()
    for i in 0:π2-π1
        for t in π1+i:δ:π2-i
            i ≤ π1 && push!(reqs, KuMo.Request(j, t))
        end
    end
    return reqs
end

function steady(j, δ, π1, π2, intensity)
    reqs = Vector{KuMo.Request{typeof(j)}}()
    for t in π1:δ:π2
        foreach(_ -> push!(reqs, KuMo.Request(j, t)), 1:intensity)
    end
    return reqs
end
