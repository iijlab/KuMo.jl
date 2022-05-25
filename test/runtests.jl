using KuMo
using Test

using Ipopt
# using JuMP
# using Juniper
using Graphs
using SparseArrays

@testset "KuMo.jl" begin

    g = SimpleDiGraph(6)

    capacities = spzeros(8, 8)
    for e in [(1, 2), (1, 3), (2, 3), (2, 4), (3, 5), (4, 5), (4, 6), (5, 6)]
        add_edge!(g, e[1], e[2])
        add_edge!(g, e[2], e[1])
        capacities[e[1], e[2]] = 500
        capacities[e[2], e[1]] = 500
    end

    current_cap = deepcopy(capacities)

    for i in 1:6, j in 1:6
        current_cap[i, j] > 0 && (current_cap[i, j] -= rand(300:450))
    end

    add_vertices!(g, 2)

    add_edge!(g, 7, 1)
    add_edge!(g, 7, 6)
    add_edge!(g, 3, 8)
    current_cap[7, 1] = 30
    current_cap[7, 6] = 60
    current_cap[3, 8] = 90

    demands = spzeros(8)
    demands[7] = -90
    demands[8] = 90

    # nl_solver = optimizer_with_attributes(Ipopt.Optimizer, "print_level" => 0)
    # minlp_solver = optimizer_with_attributes(Juniper.Optimizer, "nl_solver" => nl_solver)

    flow = mincost_flow(g, demands, capacities, current_cap, Ipopt.Optimizer)

    flow = mincost_flow(g, demands, capacities, current_cap, Ipopt.Optimizer)

    r1 = KuMo.Node(30, 15)
    r2 = KuMo.Node(45, 20)

    predict_cost(r1, 5)
    predict_cost(r2, 10)

    sim = simulate(scenario(), Ipopt.Optimizer)
end
