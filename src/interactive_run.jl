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
    unchecked_unload::Channel{Bool}
    unloads::Channel{UnloadJobAction}

    function InteractiveChannels()
        channels_size = Inf
        has_queue = Channel{Bool}(1)
        infras = Channel{StructAction}(channels_size)
        loads = Channel{LoadJobAction}(channels_size)
        stop = Channel{Bool}(1)
        unchecked_unload = Channel{Bool}(1)
        unloads = Channel{UnloadJobAction}(channels_size)
        return new(has_queue, infras, loads, stop, unchecked_unload, unloads)
    end
end

function extract_containers(containers::InteractiveChannels)
    has_queue = containers.has_queue
    infras = containers.infras
    loads = containers.loads
    stop = containers.stop
    unchecked_unload = containers.unchecked_unload
    unloads = containers.unloads
    return has_queue, infras, loads, stop, unchecked_unload, unloads
end

"""
    init_execution(::InteractiveRun)

Initialize an interactive run.
"""
init_execution(::InteractiveRun) = InteractiveChannels()

function execute_loop(exe::InteractiveRun, args, containers, start)
    _, demands, g, _, snapshots, _, times = extract_loop_arguments(args)
    v = verbose(exe)

    v && println("Starting the interactive loop...")
    push!(times, "start_tasks" => time() - start)
    put!(containers.unchecked_unload, true)

    @async begin
        v && println("Interactive loop started.")
        while true
            take!(containers.has_queue)

            # Check if the stop signal is received
            if isready(containers.stop) ? take!(containers.stop) : false
                @info "Stopping the interactive run after $(time() - start) seconds"
                break
            end

            # Check if there are any new infrastructures
            if isready(containers.infras)
                infra = take!(containers.infras)
                do!(exe, args, infra)
                continue
            end

            # Check if there are any jobs to unload
            if isready(containers.unloads)
                unload = take!(containers.unloads)
                take!(containers.has_queue)
                v, c, ls = unload.node, unload.vload, unload.lloads
                rem_load!(args.state, ls, c, v, n, g)
                push_snap!(snapshots, args.state, 0, 0, 0, 0, unload.occ, n)
                isready(containers.unchecked_unload) || put!(containers.unchecked_unload, true)
                continue
            end

            # Check if there are any jobs to load
            if isready(containers.loads) && isready(containers.unchecked_unload)
                task = fetch(containers.loads)
                best_links, best_cost, best_node, is_valid = valid_load(exe, task, args)
                if is_valid
                    take!(containers.loads)
                    j = task.job

                    # Add load
                    add_load!(args.state, best_links, j.containers, best_node, n, g)

                    # Snap new state
                    push_snap!(snapshots, args.state, 0, 0, 0, 0, task.occ, n)

                    # Assign unload
                    @async begin
                        wait(j.duration)
                        put!(containers.unloads, UnloadJobAction(time(), best_node, j.containers, best_links))
                        put!(containers.has_queue, true)
                    end
                else
                    put!(containers.has_queue, true)
                    take!(containers.unchecked_unload)
                end
            end
        end
    end

    return nothing
end

struct InteractiveInterface
    exe::InteractiveRun
    containers::InteractiveChannels
    results::ExecutionResults
    start::Float64
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
function execution_results(exe::InteractiveRun, args, containers, start)
    # verbose = exe.verbose
    # df = make_df(clean(args.snapshots), exe.infrastructure.topology; verbose)
    # if !isempty(exe.output)
    #     CSV.write(joinpath(datadir(), output(exe)), df)
    #     verbose && (@info "Output written in $(datadir())")
    # end

    # verbose && pretty_table(df)

    return InteractiveInterface(exe, containers, ExecutionResults(DataFrame(), args.times), start)
end

##SECTION - Interface functions for Interactive runs. Uses the InteractiveInterface struct.

# stop
function stop!(agent::InteractiveInterface)
    put!(agent.containers.stop, true)
    put!(agent.containers.has_queue, true)
    return agent
end

# node
function add_node!(exe::InteractiveRun, t::Float64, r::N) where {N<:AbstractNode}
    exe.infrastructure.n += 1
    return NodeAction(exe.infrastructure.n, t, r)
end

rem_node!(::InteractiveRun, t::Float64, id::Int64) = NodeAction(id, t, nothing)

function change_node!(::InteractiveRun, t::Float64, id::Int64, r::N) where {N<:AbstractNode}
    return NodeAction(id, t, r)
end

function node!(agent::InteractiveInterface, args...)
    t = time() - agent.start
    action = node!(agent.exe, t, args...)
    put!(agent.containers.infras, action)
    put!(agent.containers.has_queue, true)
    return agent
end

# link
function add_link!(exe::InteractiveRun, t::Float64, source::Int, target::Int, r::L) where {L<:AbstractLink}
    exe.infrastructure.m += 1
    return LinkAction(t, r, source, target)
end

function rem_link!(::InteractiveRun, t::Float64, source::Int, target::Int)
    return LinkAction(t, nothing, source, target)
end

function change_link!(::InteractiveRun, t::Float64, source::Int, target::Int, r::L) where {L<:AbstractLink}
    return LinkAction(t, r, source, target)
end

function link!(agent::InteractiveInterface, args...)
    t = time() - agent.start
    action = link!(agent.exe, t, args...)
    put!(agent.containers.infras, action)
    put!(agent.containers.has_queue, true)
    return agent
end

# user
function add_user!(exe::InteractiveRun, t::Float64, loc::Int)
    exe.infrastructure.u += 1
    return UserAction(exe.infrastructure.u, loc, t)
end

function rem_user!(::InteractiveRun, t::Float64, id::Int)
    return UserAction(id, nothing, t)
end

function move_user!(::InteractiveRun, t::Float64, id::Int, loc::Int)
    return UserAction(id, loc, t)
end

function user!(agent::InteractiveInterface, args...)
    t = time() - agent.start
    action = user!(agent.exe, t, args...)
    put!(agent.containers.infras, action)
    put!(agent.containers.has_queue, true)
    return agent
end

# data
function add_data!(exe::InteractiveRun, t::Float64, loc::Int)
    exe.infrastructure.d += 1
    return DataAction(exe.infrastructure.d, loc, t)
end

function rem_data!(::InteractiveRun, t::Float64, id::Int)
    return DataAction(id, nothing, t)
end

function move_data!(::InteractiveRun, t::Float64, id::Int, loc::Int)
    return DataAction(id, loc, t)
end

function data!(agent::InteractiveInterface, args...)
    t = time() - agent.start
    action = data!(agent.exe, t, args...)
    put!(agent.containers.infras, action)
    put!(agent.containers.has_queue, true)
    return agent
end

# job
function add_job!(::InteractiveRun, t::Float64, j::J, u_id::Int, d_id::Int) where {J<:AbstractJob}
    return LoadJobAction(t, u_id, j, d_id)
end

function job!(agent::InteractiveInterface, args...)
    t = time() - agent.start
    action = job!(agent.exe, t, args...)
    put!(agent.containers.loads, action)
    put!(agent.containers.has_queue, true)
    return agent
end

function job!(
    agent::InteractiveInterface,
    backend,
    container,
    duration,
    frontend,
    data_id,
    user_id,
    ν=0.0;
    stop=Inf
)
    j = job(backend, container, duration, frontend)
    if ν == 0.0
        add_job!(agent.exe, time() - agent.start, j, user_id, data_id)
    else
        @async while true
            t = time() - agent.start
            c = (isready(agent.containers.stop) ? take!(agent.containers.stop) : false)
            if c || t > stop
                break
            end
            add_job!(agent.exe, t, j, user_id, data_id)
            sleep(ν)
        end
    end
    return nothing
end
