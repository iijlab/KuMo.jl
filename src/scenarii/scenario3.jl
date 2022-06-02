scenario_3() = scenario(;
    duration = 200,
    nodes = (4, 50),
    users = 1,
    job_distribution = Dict(
        :backend => 0:0,
        :container => 1:1,
        :data_location => 1:4,
        :duration => 10:10,
        :frontend => 0:0,
    ),
    request_rate = 1/10,
)
