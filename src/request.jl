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

struct Resquests{J<:AbstractJob} <: AbstractRequests
    requests::Vector{Requests}
end

function make_requests(pr::PeriodicRequests)
    return map(t -> Request(pr.job, t), pr.start:pr.period:pr.stop)
end

make_requests(r::Request) = Requests([r])

make_requests(r::Requests) = r

function make_requests(requests_lst...)
    UT = Union{map(r -> first(typeof(r).parameters), requests_lst)...}
    reqs = Requests(Vector{UT}())
    foreach(r -> push!(reqs.requests, r), Iterators.flatten(requests_lst))
    return reqs
end
