"""
    State

A structure to store the state of the different resources, e.g. nodes and links, during a simulation.

# Arguments:
- `links::SparseMatrixCSC{Float64, Int64}`: sparse matrice with the links loads
- `nodes::SparseVector{Float64, Int64}`: sparse vector with the nodes loads
- `State(n)`: inner constructor given the number of nodes `n`
- `State(links, nodes)`: inner constructor given the `links` and `nodes` of an existing state
"""
struct State
    links::SparseMatrixCSC{Float64,Int64}
    nodes::SparseVector{Float64,Int64}

    State(n) = new(spzeros(n, n), spzeros(n))

    State(links, nodes) = new(links, nodes)
end

links(s::State) = s.links
links(s, i, j, ::Val{true}) = s.links[i, j]

links(s, i, j, directed=true) = links(s, i, j, Val(directed))

function links(s, i, j, ::Val{false})
    a, b = minmax(i, j)
    return links(s, a, b)
end

function increase!(s::State, i, j, val, directed)
    s.links[i, j] += val
    directed || (s.links[j, i] += val)
end

decrease!(s::State, i, j, val, directed) = increase!(s::State, i, j, -val, directed)

"""
    add_load!(state, links, containers, v, n)

Adds load to a given state.

# Arguments:
- `state`
- `links`: the load increase to be added on links
- `containers`: the containers load to be added to `v`
- `v`: node selected to execute a task
- `n`: amount of available nodes
"""
function add_load!(state, _links, containers, v, n, g)
    for i in 1:n, j in 1:n
        increase!(state, i, j, _links[i, j], is_directed(g))
    end
    @warn "debug state" state
    state.nodes[v] += containers
end

"""
    rem_load!(state, links, containers, v, n)

Removes load from a given state.

# Arguments:
- `state`
- `links`: the load increase to be removed from links
- `containers`: the containers load to be removed from `v`
- `v`: node where a task is endind
- `n`: amount of available nodes
"""
function rem_load!(state, links, containers, v, n, g)
    for i in 1:n, j in 1:n
        decrease!(state, i, j, links[i, j], is_directed(g))
    end
    state.nodes[v] -= containers
end
