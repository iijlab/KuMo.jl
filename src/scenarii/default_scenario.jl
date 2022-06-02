const DEFAULT_LINKS = [
    (1, 2, 1000),
    (1, 3, 1000),
    (2, 3, 1000),
    (2, 4, 1000),
    (3, 5, 1000),
    (4, 5, 1000),
    (4, 6, 1000),
    (5, 6, 1000),
]

const DEFAULT_NODES = make_nodes(6, 30)

const DEFAULT_USERS = 100

const DEFAULT_DURATION = 1000

const DEFAULT_JOB_DISTRIBUTIONS = job_distributions(
    backend=60 => 20,
    container=3 => 1,
    data_locations=1:6,
    duration=10 => 5,
    frontend=30 => 10,
)

const DEFAULT_REQUEST_RATE = 1 / 20

default_scenario() = scenario(;
    duration = DEFAULT_DURATION,
    links = DEFAULT_LINKS,
    nodes = DEFAULT_NODES,
    users = DEFAULT_USERS,
    job_distribution = DEFAULT_JOB_DISTRIBUTIONS,
    request_rate = DEFAULT_REQUEST_RATE,
)
