scenario_3() = scenario(;
    duration = 20,
    nodes = (4, 10),
    users = 1,
    job_distribution = Dict(
        :backend => 0:0,
        :container => 1:1,
        :data_location => 1:4,
        :duration => 5:5,
        :frontend => 0:0,
    ),
    request_rate = 1/20,
)
