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
    infras::Channel{AbstractAction}
    loads::Channel{LoadJobAction}
    stop::Channel{Bool}
    unloads::Channel{UnloadJobAction}

    function InteractiveChannels()
        channels_size = 10^7
        infras = Channel{AbstractAction}(channels_size)
        loads = Channel{LoadJobAction}(channels_size)
        stop = Channel{Bool}(1)
        unloads = Channel{UnloadJobAction}(channels_size)
        return new(infras, loads, stop, unloads)
    end
end

function extract_containers(containers::InteractiveChannels)
    infras = containers.infras
    loads = containers.loads
    stop = containers.stop
    unloads = containers.unloads
    return infras, loads, stop, unloads
end

"""
    init_execution(::InteractiveRun)

Initialize an interactive run.
"""
init_execution(::InteractiveRun) = InteractiveChannels()

execute_loop(exe::InteractiveRun, args, containers, start) = nothing

# """
#     simulate_loop(s, algo, speed, start, containers, args_loop, ::Val)

# Inner loop of the simulation of scenario `s`.

# # Arguments:
# - `s`: scenario being simulated
# - `algo`: algo solving the resource allocation dynamically at each step
# - `speed`: asynchronous simulation speed
# - `start`: starting time of the simulation
# - `containers`: containers generated to allocate tasks dynamically during the run
# - `args_loop`: arguments required by this loop
# """
# function simulate_loop(s, algo, speed, start, containers, args_loop, ::Val)
#     tasks, c = containers
#     times, snapshots, g, capacities, n, state, demands = args_loop

#     all_queue = false
#     all_unloaded = false
#     ii = 0
#     p = Progress(
#         length(tasks);
#         desc="Simulating with $algo at speed $speed", showspeed=true, color=:normal
#     )

#     push!(times, "start_tasks" => time() - start)

#     for (i, t) in enumerate(tasks)
#         @async begin
#             sleep(t.occ / speed)
#             put!(c, (t.node, t.job))
#             i == length(tasks) && (all_queue = true)
#         end
#     end

#     lck = ReentrantLock()

#     while !all_queue || isready(c)
#         start_iteration = time()
#         ii += 1
#         u, j = take!(c)

#         start_solving = time() - start_iteration
#         is_valid = false

#         while !is_valid
#             best_links, best_cost, best_node = inner_queue(g, u, j, s.topology.nodes, capacities, state, algo; links=s.topology.links, lck, demands)

#             n = nv(g) - vtx(algo)

#             valid_links, valid_nodes = nothing, nothing
#             lock(lck)
#             try
#                 compare_links(i, j) = state.links[i, j] + best_links[i, j] .< capacities[i, j]
#                 valid_links = mapreduce(e -> compare_links(src(e), dst(e)), *, edges(g))
#                 valid_nodes = state.nodes[best_node] + j.containers ≤ capacity(s.topology.nodes[best_node])
#             finally
#                 unlock(lck)
#             end


#             is_valid = valid_links && valid_nodes

#             is_valid || (sleep(0.001); continue)

#             lock(lck)
#             try
#                 add_load!(state, best_links, j.containers, best_node, n, g)
#             finally
#                 unlock(lck)
#             end

#             @async begin
#                 last_unload = ii == length(tasks)
#                 sleep(j.duration / speed)
#                 lock(lck)
#                 try
#                     rem_load!(state, best_links, j.containers, best_node, n, g)
#                     push_snap!(snapshots, state, 0, 0, 0, 0, time() - start, n)
#                 finally
#                     unlock(lck)
#                 end
#                 last_unload && (all_unloaded = true)
#             end

#             lock(lck)
#             try
#                 duration = time() - start_iteration
#                 instant = time() - start
#                 push_snap!(snapshots, state, best_cost, best_node, duration, duration - start_solving, instant, n)
#             finally
#                 unlock(lck)
#             end

#             ProgressMeter.update!(p, ii)
#         end
#     end

#     push!(times, "end_queue" => time() - start)

#     while !all_unloaded
#         sleep(0.001)
#     end

#     return nothing
# end
