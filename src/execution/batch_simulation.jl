# SECTION - Initialization

struct BatchSimulation{T<:AbstractTopology} <: AbstractExecution
    algo::AbstractAlgorithm
    infrastructure::Infrastructure{T}
    output::String
    requests::Requests
    verbose::Bool

    function BatchSimulation(;
        algo::AbstractAlgorithm=ShortestPath(),
        infrastructure::Infrastructure{T}=Infrastructure{T}(),
        output::String="",
        requests::Requests=Requests(),
        verbose::Bool=false
    ) where {T<:AbstractTopology}
        return new{T}(algo, infrastructure, output, requests, verbose)
    end
end

requests(execution::BatchSimulation) = execution.requests

struct SimulationVectors <: AbstractContainers
    infras::Vector{AbstractAction}
    loads::Vector{LoadJobAction}
    queued::Vector{LoadJobAction}
    unloads::Vector{UnloadJobAction}

    function SimulationVectors()
        infras = Vector{AbstractAction}()
        loads = Vector{LoadJobAction}()
        queued = Vector{LoadJobAction}()
        unloads = Vector{UnloadJobAction}()
        return new(infras, loads, queued, unloads)
    end
end

function extract_containers(containers::SimulationVectors)
    infras = containers.infras
    loads = containers.loads
    queued = containers.queued
    unloads = containers.unloads
    return infras, loads, queued, unloads
end

"""
    init_execution(::BatchSimulation)

Initialize a synchronous batch simulation.
"""
init_execution(::BatchSimulation) = SimulationVectors()

# SECTION - simulation loop

"""
    valid_load(s, task, g, capacities, state, algo, demands, ii = 0)

Compute the best load allocation and return if it is a valid one.

# Arguments:
- `s`: scenario being simulated
- `task`: task being requested
- `g`: graph of the network topology
- `capacities`: capacities of the network
- `state`: current state of resources
- `algo`: algo used for computing the best allocation cost
- `demands`: if algo is `KuMoFlowExt.MinCostFlow`, demands are required
- `ii`: a counter to measure the approximative progress of the simulation
"""
function valid_load(s, task, g, capacities, state, algo, demands, ii=0)
    occ, u, j = task.occ, task.node, task.job

    nodes = s.topology.nodes
    links = s.topology.links
    best_links, best_cost, best_node = inner_queue(
        g, u, j, nodes, capacities, state, algo, ii;
        links, demands
    )
    compare_links(i, j) = state.links[i, j] + best_links[i, j] .< capacities[i, j]
    valid_links = mapreduce(e -> compare_links(src(e), dst(e)), *, edges(g))
    valid_nodes =
        state.nodes[best_node] + j.containers ≤ capacity(s.topology.nodes[best_node])

    return (best_links, best_cost, best_node, valid_links && valid_nodes)
end

function execute_loop(exe::BatchSimulation, args, containers, start)
    # extract from args and containers
    capacities, demands, g, n, snapshots, state, times = extract_loop_arguments(args)
    infras, loads, queued, unloads = extract_containers(containers)

    ii = 0
    p = Progress(
        2 * length(loads);
        desc="Simulating with $algo synchronously", showspeed=true, color=:normal
    )

    push!(times, "start_tasks" => time() - start)

    next_infra = iterate(infras)
    previous_infra = 1

    next_queued = iterate(queued)
    previous_queued = 1

    next_unload = iterate(unloads)
    previous_unload = 1

    next_load = iterate(loads)

    last_unload = zero(Float64)
    unchecked_unload = true

    while ii < 2 * length(loads) && next_infra !== nothing
        # next_infra = iterate(infras, previous_infra)
        # if next_infra !== nothing
        #     (infra, _) = next_infra
        #     # Change infrastructure
        #     # do!(state, infra, g)
        #     # Advance iterator
        #     previous_infra += 1
        #     continue
        # end

        next_queued = iterate(queued, previous_queued)
        if next_queued !== nothing && unchecked_unload
            (task, _) = next_queued
            best_links, best_cost, best_node, is_valid =
                valid_load(s, task, g, capacities, state, algo, demands)

            if is_valid
                j = task.job
                # Add load
                add_load!(state, best_links, j.containers, best_node, n, g)
                # Snap new state
                push_snap!(snapshots, state, 0, 0, 0, 0, last_unload, n)
                # Assign unload
                unload = Unload(last_unload + j.duration, best_node, j.containers, best_links)
                insert_sorted!(unloads, unload, next_unload)

                # Advance iterator
                previous_queued += 1
                ii += 1
                ProgressMeter.update!(p, ii)
                continue
            else
                unchecked_unload = false
            end
        end

        next_unload = iterate(unloads, previous_unload)
        if next_unload !== nothing
            (unload, _) = next_unload

            if next_load === nothing || unload.occ ≤ next_load[1].occ
                v, c, ls = unload.node, unload.vload, unload.lloads
                rem_load!(state, ls, c, v, n, g)
                push_snap!(snapshots, state, 0, 0, 0, 0, unload.occ, n)

                previous_unload += 1
                unchecked_unload = true
                last_unload = unload.occ

                ii += 1
                ProgressMeter.update!(p, ii)
                continue
            end
        end

        # Nothing can be unload or executed from the queue => load new task
        (task, ts) = next_load
        best_links, best_cost, best_node, is_valid =
            valid_load(s, task, g, capacities, state, algo, demands)
        if is_valid
            ii += 1
            j = task.job

            # Add load
            add_load!(state, best_links, j.containers, best_node, n, g)

            # Snap new state
            push_snap!(snapshots, state, 0, 0, 0, 0, task.occ, n)

            # Assign unload
            unload = Unload(task.occ + j.duration, best_node, j.containers, best_links)
            insert_sorted!(unloads, unload, next_unload)
        else
            unchecked_unload = false
            push!(queued, task)
        end

        # Advance iterator
        next_load = iterate(loads, ts)
        ProgressMeter.update!(p, ii)
    end
    push!(times, "end_queue" => time() - start)
    return nothing
end
