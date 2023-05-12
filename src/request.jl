"""
    AbstractRequests

An abstract supertype for job requests.
"""
abstract type AbstractRequest end

start(r::AbstractRequest) = r.start

struct Requests
    requests::Vector{AbstractRequest}

    Requests(r::Vector{AbstractRequest}=Vector{AbstractRequest}()) = new(r)
end

Base.push!(reqs::Requests, r) = push!(reqs.requests, r)

Base.iterate(reqs::Requests, args...) = iterate(reqs.requests, args...)

#     PeriodicRequests{J < :AbstractJob} <: AbstractRequests

# A structure to handle job that

# # Arguments:
# - `job::J`: the job being requested periodically
# - `period::Float64`
# - `start::Float64`
# - `stop::Float64`
# - `PeriodicRequests(j, p; start = -Inf, stop = Inf): default constructor
# """
# struct PeriodicRequests{J<:AbstractJob} <: AbstractRequests
#     job::J
#     period::Float64
#     start::Float64
#     stop::Float64

#     PeriodicRequests(j, p; start=-Inf, stop=Inf) = new{typeof(j)}(j, p, start, stop)
# end

# """
#     requests(pr::PeriodicRequests)

# Generate a sequence of aperiodic requests from a periodic request `pr`.
# """
# function requests(pr::PeriodicRequests)
#     return Requests(map(t -> Request(pr.job, t), pr.start:pr.period:pr.stop))
# end

# requests(r::Request) = Requests([r])

# requests(r::Requests) = r

# """
#     requests(j::Job, n::Int, d::UnivariateDistribution, lower::Real, upper::Real)

# Generate a sequence of `n` requests with the same job following the distribution `d`. Limits, `lower` and `upper`, can be specified to truncate `d`.
# """
# function requests(j::Job, n::Int, d::UnivariateDistribution, lower::Real, upper::Real)
#     dtrunc = truncated(d; lower, upper)
#     return Requests(map(_ -> Request(j, rand(dtrunc)), 1:n))
# end

# """
#     requests(requests_lst...)

# Construct a collection of requests.
# """
# function requests(requests_lst...)
#     UT = Union{map(r -> first(typeof(r).parameters), requests_lst)...}
#     reqs = Requests(Vector{UT}())
#     foreach(r -> push!(reqs.requests, r), Iterators.flatten(requests_lst))
#     return reqs
# end

# """
#     spike(j, t, intensity)

# Generate a spike of requests for job `j` at instant `t`. The number of requests is defined by `intensity`.
# """
# spike(j, t, intensity) = fill(Request(j, t), (intensity,))

# """
#     smooth(j, δ, π1, π2)

# Generate a collection of requests for job `j` in [π1, π2] that grows smoothly in intensity. Requests are emitted every `δ` interval.
# """
# function smooth(j, δ, π1, π2)
#     reqs = Vector{KuMo.Request{typeof(j)}}()
#     for i in 0:π2-π1
#         for t in π1+i:δ:π2-i
#             i ≤ π1 && push!(reqs, KuMo.Request(j, t))
#         end
#     end
#     return reqs
# end

# """
#     steady(j, δ, π1, π2, intensity)

# Generate a collection of requests for job `j` in [π1, π2] with a constant `intensity`. Requests are emitted every `δ` interval.
# """
# function steady(j, δ, π1, π2, intensity)
#     reqs = Vector{KuMo.Request{typeof(j)}}()
#     for t in π1:δ:π2
#         foreach(_ -> push!(reqs, KuMo.Request(j, t)), 1:intensity)
#     end
#     return reqs
# end

struct JobRequest{J<:AbstractJob} <: AbstractRequest
    data::Int
    job::J
    start::Float64
    user::Int
end

struct NodeRequest{R<:Union{AbstractNode,Nothing}} <: AbstractRequest
    id::Int
    resource::R
    start::Float64
end

struct LinkRequest{R<:Union{AbstractLink,Nothing}} <: AbstractRequest
    resource::R
    source::Int
    start::Float64
    target::Int
end

struct DataRequest <: AbstractRequest
    id::Int
    location::Int
    start::Float64
end

struct UserRequest <: AbstractRequest
    id::Int
    location::Int
    start::Float64
end
