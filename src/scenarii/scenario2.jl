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
    DURATION_1,
    LINKS_1,
    NODES_1,
    USERS_2,
    JOB_DISTRIBUTIONS_1,
    REQUEST_RATE_1,
)
