struct InteractiveRun{T<:AbstractTopology} <: AbstractExecution
    algo::AbstractAlgorithm
    infrastructure::Infrastructure{T}
    output::String
    results::ExecutionResults
    time_limit::Float64
    verbose::Bool

    function InteractiveRun(;
        algo::AbstractAlgorithm=ShortestPath(),
        infrastructure::Infrastructure{T}=Infrastructure{DirectedTopology}(),
        output::String="",
        time_limit::Float64=Inf,
        verbose::Bool=false
    ) where {T<:AbstractTopology}
        df = DataFrame(
            selected=Float64[],
            total=Float64[],
            duration=Float64[],
            solving_time=Float64[],
            instant=Float64[]
        )
        times = Dict{String,Float64}()
        results = ExecutionResults(df, times)
        return new{T}(algo, infrastructure, output, results, time_limit, verbose)
    end
end

time_limit(execution::InteractiveRun) = execution.time_limit

struct InteractiveChannels <: AbstractContainers
    has_queue::Channel{Bool}
    infras::Channel{StructAction}
    loads::Channel{LoadJobAction}
    results_free::Channel{Bool}
    stop::Channel{Bool}
    unchecked_unload::Channel{Bool}
    unloads::Channel{UnloadJobAction}

    function InteractiveChannels()
        channels_size = typemax(Int)
        has_queue = Channel{Bool}(channels_size)
        infras = Channel{StructAction}(channels_size)
        loads = Channel{LoadJobAction}(channels_size)
        stop = Channel{Bool}(1)
        results_free = Channel{Bool}(1)
        put!(results_free, true)
        unchecked_unload = Channel{Bool}(1)
        unloads = Channel{UnloadJobAction}(channels_size)
        return new(has_queue, infras, loads, results_free, stop, unchecked_unload, unloads)
    end
end

function extract_containers(containers::InteractiveChannels)
    has_queue = containers.has_queue
    infras = containers.infras
    loads = containers.loads
    results_free = containers.results_free
    stop = containers.stop
    unchecked_unload = containers.unchecked_unload
    unloads = containers.unloads
    return has_queue, infras, loads, results_free, stop, unchecked_unload, unloads
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

    @spawn :interactive begin
        v && println("Interactive loop started.")
        while true
            take!(containers.has_queue)
            n = nv(g) - vtx(exe.algo)

            # Check if the stop signal is received
            if isready(containers.stop) ? fetch(containers.stop) : false
                # @info "pit stop 3"
                v && (@info "Stopping the interactive run after $(time() - start) seconds")
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
                v, c, ls = unload.node, unload.vload, unload.lloads
                rem_load!(args.state, ls, c, v, n, g)
                push_snap!(snapshots, args.state, 0, 0, 0, 0, time() - start, n)
                links = deepcopy(args.state.links[1:n, 1:n])
                nodes = deepcopy(args.state.nodes[1:n])
                snap = SnapShot(State(links, nodes), 0.0, 0.0, 0.0, 0.0, round(time() - start; digits=5))
                take!(containers.results_free)
                add_snap_to_df!(exe.results.df, snap, exe.infrastructure.topology)
                put!(containers.results_free, true)

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
                    push_snap!(snapshots, args.state, 0, 0, 0, 0, time() - start, n)
                    links = deepcopy(args.state.links[1:n, 1:n])
                    nodes = deepcopy(args.state.nodes[1:n])
                    snap = SnapShot(State(links, nodes), 0.0, 0.0, 0.0, 0.0, round(time() - start; digits=5))
                    take!(containers.results_free)
                    add_snap_to_df!(exe.results.df, snap, exe.infrastructure.topology)
                    put!(containers.results_free, true)

                    # Assign unload
                    @spawn begin
                        sleep(j.duration)
                        put!(containers.unloads, UnloadJobAction(time() - start, best_node, j.containers, best_links))
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
    args::LoopArguments
    containers::InteractiveChannels
    exe::InteractiveRun
    job_channels::Vector{Channel{Bool}}
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
    return InteractiveInterface(args, containers, exe, Vector{Channel{Bool}}(), start)
end

results(agent::InteractiveInterface) = agent.exe.results.df

##SECTION - Interface functions for Interactive runs. Uses the InteractiveInterface struct.

# stop
function stop!(agent::InteractiveInterface)
    put!(agent.containers.stop, true)
    put!(agent.containers.has_queue, true)
    return agent
end

function stop!(agent::InteractiveInterface, job_id::Int)
    put!(agent.job_channels[job_id], true)
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
    # @info "entered add_job" LoadJobAction(t, u_id, j, d_id)
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
    push!(agent.job_channels, Channel{Bool}(1))
    job_id = length(agent.job_channels)
    if ν == 0.0
        t = time() - agent.start
        action = add_job!(agent.exe, t, j, user_id, data_id)
        put!(agent.containers.loads, action)
        put!(agent.containers.has_queue, true)
    else
        start = time()
        @spawn while time() - start < stop
            # Check if the stop signal is received
            if isready(agent.containers.stop) ? fetch(agent.containers.stop) : false
                break
            end
            if isready(agent.job_channels[job_id])
                break
            end

            t = time() - agent.start
            action = add_job!(agent.exe, t, j, user_id, data_id)

            put!(agent.containers.loads, action)
            put!(agent.containers.has_queue, true)
            sleep(ν)
        end
    end
    return agent
end
