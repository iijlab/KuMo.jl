# SECTION - Abstract types

abstract type AbstractExecution end

algo(execution::AbstractExecution) = execution.algo

infrastructure(execution::AbstractExecution) = execution.infrastructure

output(execution::AbstractExecution) = execution.output

verbose(execution::AbstractExecution) = execution.verbose

abstract type AbstractContainers end

Base.push!(sv::AbstractContainers, action::LoadJobAction) = push!(sv.loads, action)
Base.push!(sv::AbstractContainers, action::UnloadJobAction) = push!(sv.unloads, action)
Base.push!(sv::AbstractContainers, action) = push!(sv.infras, action)

include("execution/batch_simulation.jl")
include("execution/interactive.jl")

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
    stop=s.duration
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

#SECTION - Loop arguments
struct LoopArguments
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
