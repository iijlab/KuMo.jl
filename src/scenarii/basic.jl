"""
    SCENARII

Collection of scenarii.
"""

function _four_nodes()
    s = simulation(; directed=false)
    # Add 4 nodes
    node!(s, 0.0, Node(75))
    node!(s, 0.0, Node(75))
    node!(s, 0.0, Node(75))
    node!(s, 0.0, Node(75))

    # Add freelinks
    link!(s, 0.0, 1, 2, FreeLink())
    link!(s, 0.0, 2, 3, FreeLink())
    link!(s, 0.0, 3, 4, FreeLink())
    link!(s, 0.0, 2, 4, FreeLink())

    # Add users
    user!(s, 0.0, rand(1:4))
    user!(s, 0.0, rand(1:4))

    # Add data
    data!(s, 0.0, rand(1:4))
    data!(s, 0.0, rand(1:4))

    # Add jobs
    job!(s, 0, 1, 1, 0, 1, 1, 0.01; start=10.5, stop=20.5)
    job!(s, 0, 1, 1, 0, 2, 2, 0.01; start=0.0, stop=40.0)

    return s
end

const SCENARII = Dict(
    :four_nodes => _four_nodes,
)
