
"""
    SnapShot

A structure to take snapshot from the state of network and its resources at a specific instant.

# Arguments:
- `state::State`: state at `instant`
- `total::Float64`: total load at `instant`
- `selected::Int`: selected node at `instant`; value is zero if load is removed
- `duration::Float64`: duration of all the actions taken during corresponding to the state of this snap
- `solving_time::Float64`: time taken specifically by the solving algorithm (`<: AbstractAlgorithm`)
- `instant::Float64`
"""
mutable struct SnapShot
    state::State
    total::Float64
    selected::Int
    duration::Float64
    solving_time::Float64
    instant::Float64
end

"""
    push_snap!(snapshots, state, total, selected, duration, solving_time, instant, n)

Add a snapshot to an existing collection of snapshots.

# Arguments:
- `snapshots`: collection of snapshots
- `state`: current state
- `total`: load
- `selected`: node where a request is executed
- `duration`: duration of the whole resource allocation for the request
- `solving_time`: time taken specifically by the solving algorithm (`<: AbstractAlgorithm`)
- `instant`: instant when the request is received
- `n`: number of available nodes
"""
function push_snap!(snapshots, state, total, selected, duration, solving_time, instant, n)
    links = deepcopy(state.links[1:n, 1:n])
    nodes = deepcopy(state.nodes[1:n])
    snap = SnapShot(State(links, nodes), total, selected, duration, solving_time, round(instant; digits=5))
    push!(snapshots, snap)
end


# FIXME - links indices
"""
    make_df(snapshots::Vector{SnapShot}, topo; verbose = true)

Make a DataFrame from the raw snapshots.

# Arguments:
- `snapshots`: A collection of snapshots
- `topo`: topology of the network
- `verbose`: if set to true, it will print a description of the snapshots in the terminal
"""
function make_df(snapshots::Vector{SnapShot}, topo; verbose=true)
    function shape_entry(s)
        entry = Vector{Pair{String,Float64}}()
        push!(entry, "selected" => s.selected)
        push!(entry, "total" => s.total)
        push!(entry, "duration" => s.duration)
        push!(entry, "solving_time" => s.solving_time)
        push!(entry, "instant" => s.instant)

        for v in keys(topo.nodes)
            x = string(v) => safe_get_index(s.state.nodes, v) / capacity(nodes(topo, v))
            push!(entry, x)
        end

        for (i, j) in keys(topo.links)
            c = safe_get_index(s.state.links, i, j)
            push!(entry, string((i, j)) => c / capacity(links(topo, i, j)))
        end

        return entry
    end

    df = DataFrame(shape_entry(first(snapshots)))
    foreach(e -> push!(df, Dict(shape_entry(e))), snapshots[2:end])

    acc = Vector{Symbol}()
    for (i, col) in enumerate(propertynames(df))
        if i < 6 || !all(iszero, df[!, col])
            push!(acc, col)
        end
    end

    df = df[!, acc]

    verbose && pretty_table(describe(df))

    return df
end

function clean!(df::DataFrame)
    acc = Vector{Symbol}()
    for (i, col) in enumerate(propertynames(df))
        if i < 6 || !all(iszero, df[!, col])
            push!(acc, col)
        end
    end

    df = df[!, acc]
    return df
end

"""
    clean(snaps)

Clean the snapshots by merging snaps occuring at the same time.
"""
function clean(snaps)
    snapshots = Vector{SnapShot}()
    fsnap = first(snaps)
    instant = fsnap.instant

    replaced = false

    for (i, s) in enumerate(snaps)
        if s.instant ≉ instant || isempty(snapshots)
            push!(snapshots, s)
            instant = s.instant
        else
            if i == 2
                replaced = true
            end
            snapshots[end] = s
        end
    end

    if replaced
        fsnap.instant = fsnap.instant - snapshots[2].instant
        pushfirst!(snapshots, fsnap)
    end

    return snapshots
end

function add_snap_to_df!(df, snap, topo)
    function shape_entry(s)
        entry = Vector{Pair{String,Float64}}()
        push!(entry, "selected" => s.selected)
        push!(entry, "total" => s.total)
        push!(entry, "duration" => s.duration)
        push!(entry, "solving_time" => s.solving_time)
        push!(entry, "instant" => s.instant)

        for v in keys(topo.nodes)
            str = string(v)
            if str ∉ names(df)
                df[!, str] = zeros(Float64, nrow(df))
            end
            x = str => safe_get_index(s.state.nodes, v) / capacity(nodes(topo, v))
            push!(entry, x)
        end

        for (i, j) in keys(topo.links)
            str = string((i, j))
            if str ∉ names(df)
                df[!, str] = zeros(Float64, nrow(df))
            end
            c = safe_get_index(s.state.links, i, j)
            push!(entry, str => c / capacity(links(topo, i, j)))
        end

        return entry
    end
    # @warn "add_snap_to_df! debug" df snap Dict(shape_entry(snap))

    push!(df, Dict(shape_entry(snap)))
    # @warn "add_snap_to_df! debug out" df

end
