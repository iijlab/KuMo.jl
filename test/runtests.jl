using KuMo
using Test

using Ipopt

@testset "KuMo.jl" begin
    @info "Starting simulation 1"
    println()
    times, snaps = simulate(scenario_1(), ShortestPath(); speed=100)#, output="scenario1-shortestpath.csv")
    @info "Running times" times

    # @info "Starting simulation 2"
    # println()
    # times, snaps = simulate(scenario_1(), MinCostFlow(Ipopt.Optimizer); speed=1)#, output="scenario2-mincostflow.csv")
    # @info "Running times" times
end
