const LINKS_1 = [
    (1, 2, 1000),
    (1, 3, 1000),
    (2, 3, 1000),
    (2, 4, 1000),
    (3, 5, 1000),
    (4, 5, 1000),
    (4, 6, 1000),
    (5, 6, 1000),
]

const NODES_1 = (6, 30)
const USERS_1 = 10

const DURATION_1 = 100

const JOB_DISTRIBUTIONS_1 = job_distributions(
    backend=50 => 20,
    container=3 => 1,
    data_locations=1:6,
    duration=5 => 2,
    frontend=30 => 10,
)

const REQUEST_RATE_1 = 1.0

scenario_1() = scenario(;
    duration = DURATION_1,
    links = LINKS_1,
    nodes = NODES_1,
    users = USERS_1,
    job_distribution = JOB_DISTRIBUTIONS_1,
    request_rate = REQUEST_RATE_1,
)
