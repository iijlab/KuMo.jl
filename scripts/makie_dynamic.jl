using GLMakie
using KuMo

agent = show_interactive_run(;)
foreach(_ -> node!(agent, Node(100)), 1:2)

link!(agent, 2, 1, FlatLink(25.0, 1.0))
link!(agent, 1, 2, Link(75.0))

user!(agent, 1);
data!(agent, 1);

# job!(agent, backend, container, duration, frontend, data_id, user_id, ν; stop = Inf)
job!(agent, 0, 2, 1, 1, 1, 1, 0.001);

sleep(10)

data!(agent, 1, 2)
user!(agent, 1, 2)

sleep(10);
stop!(agent, 1);

sleep(5)
stop!(agent)

show_simulation(results(agent))
