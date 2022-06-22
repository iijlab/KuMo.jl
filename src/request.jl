abstract type AbstractRequests end

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
