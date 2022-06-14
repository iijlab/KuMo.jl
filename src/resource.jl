"""
    AbstractResource

An abstract supertype for resources in a cloud morphing architecture. Any type `MyResource <: AbstractResource` needs to either:
- have a field `capacity::T` where `T <: Number`,
- implement a `capacity(r::MyResource)` method.
Optionally, one can implement a specific `pseudo_cost(r::MyResource, charge)` method.
"""
abstract type AbstractResource end

capacity(r::R) where {R<:AbstractResource} = r.capacity

pseudo_cost(r::R, charge) where {R<:AbstractResource} = pseudo_cost(capacity(r), charge, :default)

param(r::R) where {R<:AbstractResource} = :param ∉ fieldnames(R) ? nothing : r.param

abstract type AbstractNode <: AbstractResource end

struct Node{T<:Number} <: AbstractNode
    capacity::T
end

struct AdditiveNode{T1<:Number,T2<:Number} <: AbstractNode
    capacity::T1
    param::T2
end

pseudo_cost(r::AdditiveNode, charge) = pseudo_cost(capacity(r), charge, :default) + r.param

struct MultiplicativeNode{T1<:Number,T2<:Number} <: AbstractNode
    capacity::T1
    param::T2
end

pseudo_cost(r::MultiplicativeNode, charge) = pseudo_cost(capacity(r), charge, :default) * r.param

struct IdleStateNode{T1<:Number,T2<:Number} <: AbstractNode
    capacity::T1
    param::T2
end

pseudo_cost(r::IdleStateNode, charge) = pseudo_cost(capacity(r), charge, :idle_node, r.param)

struct PremiumNode{T1<:Number,T2<:Number} <: AbstractNode
    capacity::T1
    param::T2
end

pseudo_cost(r::PremiumNode, charge) = pseudo_cost(capacity(r), charge, :premium_node, r.param)

struct EqualLoadBalancingNode{T<:Number} <: AbstractNode
    capacity::T
end

pseudo_cost(r::EqualLoadBalancingNode, charge) = pseudo_cost(capacity(r), charge, :equal_load_balancing)

abstract type AbstractLink <: AbstractResource end

struct Link{T<:Number} <: AbstractLink
    capacity::T
end

pseudo_cost(r::Link, charge) = pseudo_cost(capacity(r), charge, :equal_load_balancing)

struct FreeLink <: AbstractLink end

capacity(::FreeLink) = Inf

pseudo_cost(::FreeLink, x...) = 0.0
