using KuMo
using GLMakie



s = simulation(; directed=false)

node!(s, 0.0, Node(10))
node!(s, 0.0, EqualLoadBalancingNode(10))

link!(s, 0.0, 1, 2, Link(10))

user!(s, 0.0, 1)
data!(s, 0.0, 2)

# job!(s, backend, container, duration, frontend, data_id, user_id, ν; stop = Inf)
job!(s, 1.0, 1, 1.0, 0.0, 1, 1, 0.1; stop=2.0)

simulate(s)

s.infrastructure.topology.links

s

# r = execute()
