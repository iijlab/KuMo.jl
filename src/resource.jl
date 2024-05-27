"""
    AbstractResource

An abstract supertype for resources in a cloud morphing architecture. Any type `MyResource <: AbstractResource` needs to either:
- have a field `capacity::T` where `T <: Number`,
- implement a `capacity(r::MyResource)` method.
Optionally, one can implement a specific `pseudo_cost(r::MyResource, charge)` method.
"""
abstract type AbstractResource end

"""
    capacity(r::R) where {R<:AbstractResource}

Return the capacity of a resource `r`.
"""
capacity(r::R) where {R <: AbstractResource} = r.capacity

"""
    pseudo_cost(r::R, charge) where {R<:AbstractResource}

Compute the pseudo-cost of `r` given its `charge`.
"""
pseudo_cost(r::R, charge) where {R <: AbstractResource} = pseudo_cost(
    capacity(r), charge, :default)

"""
    param(r::R) where {R<:AbstractResource}

Default accessor for an optional parameter for `R`. If no `param` field exists, returns `nothing`.
"""
param(r::R) where {R <: AbstractResource} = :param ∉ fieldnames(R) ? nothing : r.param

abstract type AbstractNode <: AbstractResource end

"""
    Node{T <: Number} <: AbstractNode

Default node structure, defined by its maximal capacity and the default convex pseudo-cost function.
"""
struct Node{T <: Number} <: AbstractNode
    capacity::T
end

"""
    AdditiveNode{T1 <: Number, T2 <: Number} <: AbstractNode

A node structure where the default pseudo-cost is translated by the value in the `param` field.
"""
struct AdditiveNode{T1 <: Number, T2 <: Number} <: AbstractNode
    capacity::T1
    param::T2
end

pseudo_cost(r::AdditiveNode, charge) = pseudo_cost(capacity(r), charge, :default) + r.param

"""
    MultiplicativeNode{T1 <: Number, T2 <: Number} <: AbstractNode

A node structure where the default pseudo-cost is multiplied by the value in the `param` field.
"""
struct MultiplicativeNode{T1 <: Number, T2 <: Number} <: AbstractNode
    capacity::T1
    param::T2
end

function pseudo_cost(r::MultiplicativeNode, charge)
    pseudo_cost(capacity(r), charge, :default) * r.param
end

"""
    IdleStateNode{T1 <: Number, T2 <: Number} <: AbstractNode

Node structure that stays iddle until a bigger system load than the default node. The `param` field is used to set the activation threshold.
"""
struct IdleStateNode{T1 <: Number, T2 <: Number} <: AbstractNode
    capacity::T1
    param::T2
end

function pseudo_cost(r::IdleStateNode, charge)
    pseudo_cost(capacity(r), charge, :idle_node, r.param)
end

"""
    PremiumNode{T1 <: Number, T2 <: Number} <: AbstractNode

A node structure for premium resources. The `param` field set the premium threshold.
"""
struct PremiumNode{T1 <: Number, T2 <: Number} <: AbstractNode
    capacity::T1
    param::T2
end

function pseudo_cost(r::PremiumNode, charge)
    pseudo_cost(capacity(r), charge, :premium_node, r.param)
end

"""
    EqualLoadBalancingNode{T <: Number} <: AbstractNode

Node structure with an equal load balancing (monotonic) pseudo-cost function.
"""
struct EqualLoadBalancingNode{T <: Number} <: AbstractNode
    capacity::T
end

function pseudo_cost(r::EqualLoadBalancingNode, charge)
    pseudo_cost(capacity(r), charge, :equal_load_balancing)
end

"""
    FlatNode{T <: Number} <: AbstractNode

Node structure with a constant pseudo-cost function.
"""
struct FlatNode{T1 <: Number, T2 <: Number} <: AbstractNode
    capacity::T1
    param::T2
end

pseudo_cost(r::FlatNode, _) = param(r)

abstract type AbstractLink <: AbstractResource end

"""
    Link{T <: Number} <: AbstractLink

Default link structure with an equal load balancing (monotonic) pseudo-cost function.
"""
struct Link{T <: Number} <: AbstractLink
    capacity::T
end

pseudo_cost(r::Link, charge) = pseudo_cost(capacity(r), charge, :equal_load_balancing)

"""
    FreeLink <: AbstractLink

The pseudo-cost of such links is always zero.
"""
struct FreeLink <: AbstractLink end

capacity(::FreeLink) = Inf
pseudo_cost(::FreeLink, ::Any, ::Any) = 0.0

"""
    ConvexLink <: KuMo.AbstractLink

Link structure with a convex pseudo-cost function.
"""
struct ConvexLink{T <: Number} <: AbstractLink
    capacity::T
end

"""
    FlatLink <: KuMo.AbstractLink

Link structure with a constant pseudo-cost function.
"""
struct FlatLink{T1 <: Number, T2 <: Number} <: AbstractLink
    capacity::T1
    param::T2
end

pseudo_cost(r::FlatLink, _) = param(r)
