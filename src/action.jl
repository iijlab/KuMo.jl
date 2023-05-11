abstract type AbstractAction end

occ(action::AbstractAction) = action.occ

Base.isless(x::AbstractAction, y::AbstractAction) = isless(occ(x), occ(y))

struct LoadJobAction{J<:AbstractJob} <: AbstractAction
    occ::Float64
    data::Int
    job::J
    user::Int
end

struct UnloadJobAction{J<:AbstractJob} <: AbstractAction
    occ::Float64
    node::Int
    vload::Int
    lloads::SparseMatrixCSC{Float64,Int64}
end

abstract type StructAction <: AbstractAction end

struct AddNodeAction <: StructAction
end

struct ChangeNodeAction <: StructAction
end

struct RemoveNodeAction <: StructAction
end

struct AddLinkAction <: StructAction
end

struct ChangeLinkAction <: StructAction
end

struct RemoveLinkAction <: StructAction
end

struct AddUserAction <: StructAction
end

struct MoveUserAction <: StructAction
end

struct AddDataAction <: StructAction
end

struct MoveDataAction <: StructAction
end

# SECTION - Requests to actions
