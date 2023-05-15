# SECTION - Abstract types

abstract type AbstractExecution end

algo(execution::AbstractExecution) = execution.algo

infrastructure(execution::AbstractExecution) = execution.infrastructure

output(execution::AbstractExecution) = execution.output

verbose(execution::AbstractExecution) = execution.verbose

abstract type AbstractContainers end

Base.push!(sv::AbstractContainers, action::LoadJobAction) = insert_sorted!(sv.loads, action)
Base.push!(sv::AbstractContainers, action::UnloadJobAction) = insert_sorted!(sv.unloads, action)
Base.push!(sv::AbstractContainers, action::AbstractAction) = insert_sorted!(sv.infras, action)

include("batch_simulation.jl")
include("interactive_run.jl")

# SECTION - Requests API: node!, link!, user!, data!, job!

node!(exe::AbstractExecution, t::Float64, r::AbstractNode) = add_node!(exe, t, r)
node!(exe::AbstractExecution, t::Float64, id::Int) = rem_node!(exe, t, id)
function node!(exe::AbstractExecution, t::Float64, id::Int, r::AbstractNode)
    return change_node!(exe, t, id, r)
end

function link!(exe::AbstractExecution, t::Float64, source::Int, target::Int)
    return rem_link!(exe, t, source, target)
end
function link!(
    exe::AbstractExecution, t::Float64, source::Int, target::Int, r::AbstractLink
)
    if (source, target) ∈ exe.infrastructure.topology |> links |> keys
        return change_link!(exe, t, source, target, r)
    end
    return add_link!(exe, t, source, target, r)
end

user!(exe::AbstractExecution, t::Float64, loc::Int) = add_user!(exe, t, loc)
user!(exe::AbstractExecution, t::Float64, id::Int, loc::Int) = move_user!(exe, t, id, loc)

data!(exe::AbstractExecution, t::Float64, loc::Int) = add_data!(exe, t, loc)
data!(exe::AbstractExecution, t::Float64, id::Int, loc::Int) = move_data!(exe, t, id, loc)

function job!(
    exe::AbstractExecution,
    backend,
    container,
    duration,
    frontend,
    data_id,
    user_id,
    ν;
    start=0.0,
    stop=start
)
    j = job(backend, container, duration, frontend)
    for t in start:ν:stop
        add_job!(exe, t, j, user_id, data_id)
    end
end

function job!(
    exe::AbstractExecution,
    t::Float64,
    backend,
    container,
    duration,
    frontend,
    data_id,
    user_id;
)
    j = job(backend, container, duration, frontend)
    add_job!(exe, t, j, user_id, data_id)
end

#SECTION - do! actions

do!(exe::AbstractExecution, args, action::LoadJobAction) = nothing
do!(exe::AbstractExecution, args, action::UnloadJobAction) = nothing

function do!(exe::AbstractExecution, args, action::NodeAction)
    if haskey(exe.infrastructure.topology.nodes, action.id)
        if isnothing(action.resource)
            # remove node
            delete!(exe.infrastructure.topology.nodes, action.id)
            rem_vertex!(args.g, action.id)
            args.demands[action.id] = 0.0
            args.state.nodes[action.id] = 0.0
            # TODO - remove edges from/to node
        else
            # change node
            exe.infrastructure.topology.nodes[action.id] = action.resource
        end
    else
        # add node
        insert!(exe.infrastructure.topology.nodes, action.id, action.resource)
        add_vertex!(args.g)
        D = spzeros(args.demands.n + 1)
        foreach(i -> D[i] = args.demands[i], 1:args.demands.n)
        args.demands = D
        SN = spzeros(args.state.nodes.n + 1)
        foreach(i -> SN[i] = args.state.nodes[i], 1:args.state.nodes.n)

        C = spzeros(args.capacities.n + 1, args.capacities.m + 1)
        for i in 1:args.capacities.n, j in 1:args.capacities.m
            C[i, j] = args.capacities[i, j]
        end
        args.capacities = C
        SL = spzeros(args.state.links.n + 1, args.state.links.m + 1)
        for i in 1:args.state.links.n, j in 1:args.state.links.m
            SL[i, j] = args.state.links[i, j]
        end
        args.state = State(SL, SN)
    end

    return nothing
end

function do!(exe::AbstractExecution, args, action::LinkAction)
    if haskey(exe.infrastructure.topology.links, (action.source, action.target))
        if isnothing(action.resource)
            # remove link
            delete!(exe.infrastructure.topology.links, (action.source, action.target))
            rem_edge!(args.g, action.source, action.target)
            args.capacities[action.source, action.target] = 0.0
            args.state.links[action.source, action.target] = 0.0
            if isa(exe.infrastructure.topology, Topology)
                args.capacities[action.target, action.source] = 0.0
                args.state.links[action.target, action.target] = 0.0
            end
        else
            # change link
            exe.infrastructure.topology.links[(action.source, action.target)] =
                action.resource
        end
    else
        # add link
        insert!(
            exe.infrastructure.topology.links,
            (action.source, action.target),
            action.resource
        )
        add_edge!(args.g, action.source, action.target)

        args.capacities[action.source, action.target] = capacity(action.resource)
        if isa(exe.infrastructure.topology, Topology)
            args.capacities[action.target, action.source] = capacity(action.resource)
        end
    end
    return nothing
end

function do!(exe::AbstractExecution, _, action::UserAction)
    if haskey(exe.infrastructure.users, action.id)
        if iszero(action.location)
            # remove user
            delete!(exe.infrastructure.users, action.id)
        else
            # move user
            exe.infrastructure.users[action.id].location = action.location
        end
    else
        # add user
        insert!(exe.infrastructure.users, action.id, user(action.location))
    end
    return nothing
end

function do!(exe::AbstractExecution, _, action::DataAction)
    if haskey(exe.infrastructure.data, action.id)
        if iszero(action.location)
            # remove data
            delete!(exe.infrastructure.data, action.id)
        else
            # move data
            exe.infrastructure.data[action.id].location = action.location
        end
    else
        # add data
        insert!(exe.infrastructure.data, action.id, data(action.location))
    end
    return nothing
end

#SECTION - Loop arguments
mutable struct LoopArguments
    capacities::SparseMatrixCSC{Float64,Int64}
    demands::SparseVector{Float64,Int64}
    g::AbstractGraph
    n::Int64
    snapshots::Vector{SnapShot}
    state::State
    times::Dict{String,Float64}

    function LoopArguments(infra, algo, start)
        times = Dict{String,Float64}()
        snapshots = Vector{SnapShot}()

        push!(times, "start_tasks" => time() - start)
        g, capacities = graph(infra.topology, algo)
        n = nv(g) - vtx(algo)

        state = State(nv(g))
        demands = spzeros(nv(g))

        push_snap!(snapshots, state, 0, 0, 0, 0, 0, n)

        push!(times, "start_queue" => time() - start)
        return new(capacities, demands, g, n, snapshots, state, times)
    end
end

function extract_loop_arguments(args::LoopArguments)
    capacities = args.capacities
    demands = args.demands
    g = args.g
    n = args.n
    snapshots = args.snapshots
    state = args.state
    times = args.times
    return capacities, demands, g, n, snapshots, state, times
end

## Results
struct ExecutionResults
    df::DataFrame
    times::Dict{String,Float64}
end

"""
    post_simulate(s, snapshots, verbose, output)

Post-simulation process that covers cleaning the snapshots and producing an output.

# Arguments:
- `s`: simulated scenario
- `snapshots`: resulting snapshots (before cleaning)
- `verbose`: if set to true, prints information about the output and the snapshots
- `output`: output path
"""
function execution_results(exe, args)
    verbose = exe.verbose
    df = make_df(clean(args.snapshots), exe.infrastructure.topology; verbose)
    if !isempty(exe.output)
        CSV.write(joinpath(datadir(), output(exe)), df)
        verbose && (@info "Output written in $(datadir())")
    end

    verbose && pretty_table(df)

    return ExecutionResults(df, args.times)
end

## Execution

function execute(exe::AbstractExecution=InteractiveRun())
    start = time()
    v = verbose(exe)

    v && (@info "containers stuff start" (time() - start))
    # dispatched containers
    containers = init_execution(exe)

    v && (@info "args loop stuff start" (time() - start))
    # shared init
    args_loop = LoopArguments(infrastructure(exe), algo(exe), start)

    v && (@info "start execution: $(typeof(exe))" (time() - start))
    # start execution
    execute_loop(exe, args_loop, containers, start)

    return execution_results(exe, args_loop)
end
