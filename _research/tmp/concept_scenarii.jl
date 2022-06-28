four_nodes() = scenario(;
    duration=349,
    nodes=(4, 100),
    users=1,
    job_distribution=Dict(
        :backend => 0:0,
        :container => 1:1,
        :data_location => 1:4,
        :duration => 400:400,
        :frontend => 0:0,
    ),
    request_rate=1.0
)
