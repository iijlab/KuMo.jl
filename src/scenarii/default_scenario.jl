const DEFAULT_LINKS = [
    (1, 2) => 1000,
    (1, 3) => 1000,
    (2, 3) => 1000,
    (2, 4) => 1000,
    (3, 5) => 1000,
    (4, 5) => 1000,
    (4, 6) => 1000,
    (5, 6) => 1000,
]

const DEFAULT_NODES = [
    1 => 30,
    2 => 30,
    3 => 30,
    4 => 30,
    5 => 30,
    6 => 30,
]

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

const DEFAULT_SCENARIO = scenario(
    DEFAULT_DURATION,
    DEFAULT_LINKS,
    DEFAULT_NODES,
    DEFAULT_USERS,
    DEFAULT_JOB_DISTRIBUTIONS,
    DEFAULT_REQUEST_RATE,
)
