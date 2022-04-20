abstract type AbstractResource end

mutable struct Node <: AbstractResource
    capacity::Int
    current::Int
end

struct Link <: AbstractResource
    capacity::Int
    current::Int
end

load(r::R) where {R<:AbstractResource} = capacity / current
