# const LINKS_1 = [
#     (1, 2) => 100,
#     (1, 3) => 100,
#     (2, 3) => 100,
#     (2, 4) => 100,
#     (3, 5) => 100,
#     (4, 5) => 100,
#     (4, 6) => 100,
#     (5, 6) => 100,
# ]

# const NODES_1 = [
#     1 => 30,
#     2 => 30,
#     3 => 30,
#     4 => 30,
#     5 => 30,
#     6 => 30,
# ]

const USERS_2 = 100

# const DURATION_1 = 100

# const JOB_DISTRIBUTIONS_1 = job_distributions(
#     backend=60 => 20,
#     container=3 => 1,
#     data_locations=1:6,
#     duration=10 => 5,
#     frontend=30 => 10,
# )

# const REQUEST_RATE_1 = 1.

scenario_2() = scenario(
    duration = DURATION_1,
    links = LINKS_1,
    nodes = NODES_1,
    users = USERS_2,
    job_distribution = JOB_DISTRIBUTIONS_1,
    request_rate = REQUEST_RATE_1,
)
