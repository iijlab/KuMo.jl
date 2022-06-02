"""
    AbstractResource

An abstract supertype for resources in a cloud morphing architecture. Any type `MyResource <: AbstractResource` needs to either:
- have a field `capacity::T` where `T <: Number`,
- implement a `capacity(r::MyResource)` method.
Optionally, one can implement a specific `pseudo_cost(r::MyResource, charge)` method.
"""
abstract type AbstractResource end

capacity(r::R) where {R<:AbstractResource} = r.capacity

pseudo_cost(r::R, charge) where {R<:AbstractResource} = pseudo_cost(capacity(r), charge)

struct Node{T<:Number} <: AbstractResource
    capacity::T
end

struct Link{T<:Number} <: AbstractResource
    capacity::T
end

pseudo_cost(r::Link, charge) = pseudo_cost(r, charge, :optical_link)
