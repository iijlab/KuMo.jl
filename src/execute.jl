## Abstract types

abstract type AbstractExecution end

algo(execution::AbstractExecution) = execution.algo

infrastructure(execution::AbstractExecution) = execution.infrastructure

output(execution::AbstractExecution) = execution.output

verbose(execution::AbstractExecution) = execution.verbose

abstract type AbstractContainers end

# include all execution types
include("execution/batch_simulation.jl")
include("execution/interactive.jl")

## Initialization

struct LoopArguments
    capacities::Dict{Int64,Float64}
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

    # TODO - make a execution_results multiple dispatch function
    # return execution_results(exe, args_loop, containers, start)
    return nothing

    # formerly
    # return args_loop[1], post_simulate(s, args_loop[2], verbose, output), args_loop[2]
end
