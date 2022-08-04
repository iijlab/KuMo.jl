"""
    SCENARII

Collection of scenarii.
"""
const SCENARII = Dict(
    :four_nodes_four_users => scenario(;
        duration=399,
        nodes=(4, 125),
        users=[
            user(requests(job(0, 1, rand(1:4), 1, 0), 10, Normal(5, 1), 0, 10), rand(1:4);)
        ]
    ),
    :four_nodes => scenario(;
        duration=399,
        nodes=(4, 125),
        users=[
            user(job(0, 1, rand(1:4), 400, 0), 1.0, rand(1:4); start=200.5, stop=299.5)
            user(job(0, 1, rand(1:4), 400, 0), 1.0, rand(1:4);)
        ]
    ),
    :square => scenario(;
        duration=399,
        nodes=(4, 100),
        links=[
            (1, 2, 400.0), (2, 3, 400.0), (3, 4, 400.0), (4, 1, 400.0),
            (2, 1, 400.0), (3, 2, 400.0), (4, 3, 400.0), (1, 4, 400.0),
        ],
        users=1,
        job_distribution=Dict(
            :backend => 2:2,
            :container => 1:2,
            :data_location => 1:4,
            :duration => 400:400,
            :frontend => 1:1,
        ),
        request_rate=1.0
    )
)