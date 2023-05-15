struct InteractiveRun{T<:AbstractTopology} <: AbstractExecution
    algo::AbstractAlgorithm
    infrastructure::Infrastructure{T}
    output::String
    time_limit::Float64
    verbose::Bool

    function InteractiveRun(;
        algo::AbstractAlgorithm=ShortestPath(),
        infrastructure::Infrastructure{T}=Infrastructure{DirectedTopology}(),
        output::String="",
        time_limit::Float64=Inf,
        verbose::Bool=false
    ) where {T<:AbstractTopology}
        return new{T}(algo, infrastructure, output, time_limit, verbose)
    end
end

time_limit(execution::InteractiveRun) = execution.time_limit

struct InteractiveChannels <: AbstractContainers
    has_queue::Channel{Bool}
    infras::Channel{StructAction}
    loads::Channel{LoadJobAction}
    stop::Channel{Bool}
    unloads::Channel{UnloadJobAction}

    function InteractiveChannels()
        channels_size = Inf
        has_queue = Channel{Bool}(1)
        infras = Channel{StructAction}(channels_size)
        loads = Channel{LoadJobAction}(channels_size)
        stop = Channel{Bool}(1)
        unloads = Channel{UnloadJobAction}(channels_size)
        return new(has_queue, infras, loads, stop, unloads)
    end
end

function extract_containers(containers::InteractiveChannels)
    has_queue = containers.has_queue
    infras = containers.infras
    loads = containers.loads
    stop = containers.stop
    unloads = containers.unloads
    return has_queue, infras, loads, stop, unloads
end

"""
    init_execution(::InteractiveRun)

Initialize an interactive run.
"""
init_execution(::InteractiveRun) = InteractiveChannels()

function interactive_loop(exe, args, containers, start)
    _, demands, g, _, snapshots, _, times = extract_loop_arguments(args)
    @async begin
        while true
            take!(containers.has_queue)
            # Check if the stop signal is received
            if isready(containers.stop) ? take!(containers.stop) : false
                @info "Stopping the interactive run after $(time() - start) seconds"
                break
            end
        end

        # Your loop execution code goes here
    end
end

function execute_loop(exe::InteractiveRun, args, containers, start)
    v = verbose(exe)
    v && println("Starting the interactive loop...")
    interactive_loop(exe, args, containers, start)
    v && println("Interactive loop started.")
    return nothing
end

struct InteractiveInterface
    exe::InteractiveRun
    containers::InteractiveChannels
    results::ExecutionResults
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
function execution_results(exe::InteractiveRun, args, containers)
    # verbose = exe.verbose
    # df = make_df(clean(args.snapshots), exe.infrastructure.topology; verbose)
    # if !isempty(exe.output)
    #     CSV.write(joinpath(datadir(), output(exe)), df)
    #     verbose && (@info "Output written in $(datadir())")
    # end

    # verbose && pretty_table(df)

    return InteractiveInterface(exe, containers, ExecutionResults(DataFrame(), args.times))
end

function stop!(agent::InteractiveInterface)
    put!(agent.containers.stop, true)
    put!(agent.containers.has_queue, true)
    return agent
end
