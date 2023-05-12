"""
    SCENARII

Collection of scenarii.
"""

function _four_nodes()
    s = simulation(; directed=false)
    # Add 4 nodes
    node!(s, 0.0, Node(125))
    node!(s, 0.0, Node(125))
    node!(s, 0.0, Node(125))
    node!(s, 0.0, Node(125))

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
    job!(s, 0, 1, 1, 0, 1, 1, 1.0; start=200.5, stop=299.5)
    job!(s, 0, 1, 1, 0, 2,
        2, 1.0;)

    return s
end

const SCENARII = Dict(
    # :four_nodes_four_users => scenario(;
    #     duration=399,
    #     nodes=(4, 125),
    #     users=[
    #         user(requests(job(0, 1, rand(1:4), 1, 0), 10, Normal(5, 1), 0, 10), rand(1:4);)
    #     ]
    # ),
    :four_nodes => _four_nodes(),
    # nodes=(4, 125),
    # users=[
    #     user(job(0, 1, rand(1:4), 400, 0), 1.0, rand(1:4); start=200.5, stop=299.5)
    #     user(job(0, 1, rand(1:4), 400, 0), 1.0, rand(1:4);)
    # ]
    # :square => scenario(;
    #     duration=399,
    #     nodes=(4, 100),
    #     links=[
    #         (1, 2, 400.0), (2, 3, 400.0), (3, 4, 400.0), (4, 1, 400.0),
    #         # (2, 1, 400.0), (3, 2, 400.0), (4, 3, 400.0), (1, 4, 400.0),
    #     ],
    #     users=1,
    #     job_distribution=Dict(
    #         :backend => 2:2,
    #         :container => 1:2,
    #         :data_location => 1:4,
    #         :duration => 400:400,
    #         :frontend => 1:1,
    #     ),
    #     request_rate=1.0,
    #     directed=false
    # )
)
