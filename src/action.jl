abstract type AbstractAction end

occ(action::AbstractAction) = action.occ

Base.isless(x::AbstractAction, y::AbstractAction) = isless(occ(x), occ(y))

struct LoadJobAction{J <: AbstractJob} <: AbstractAction
    occ::Float64
    data::Int
    job::J
    user::Int
end
action(r::JobRequest) = LoadJobAction(r.start, r.data, r.job, r.user)

struct UnloadJobAction <: AbstractAction
    occ::Float64
    node::Int
    vload::Int
    lloads::SparseMatrixCSC{Float64, Int64}
end
function action(last_unload, j::AbstractJob, node_id, links)
    return UnloadJobAction(last_unload + j.duration, node_id, j.containers, links)
end

abstract type StructAction <: AbstractAction end

struct NodeAction{R <: Union{AbstractNode, Nothing}} <: StructAction
    id::Int
    occ::Float64
    resource::R
end
action(r::NodeRequest) = NodeAction(r.id, r.start, r.resource)

struct LinkAction{R <: Union{AbstractLink, Nothing}} <: StructAction
    occ::Float64
    resource::R
    source::Int
    target::Int
end
action(r::LinkRequest) = LinkAction(r.start, r.resource, r.source, r.target)

struct UserAction <: StructAction
    id::Int
    location::Int
    occ::Float64
end
action(r::UserRequest) = UserAction(r.id, r.location, r.start)

struct DataAction <: StructAction
    id::Int
    location::Int
    occ::Float64
end
action(r::DataRequest) = DataAction(r.id, r.location, r.start)
