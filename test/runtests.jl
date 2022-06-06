using KuMo
using Test

using Ipopt

@testset "KuMo.jl" begin
    @info "Starting simulation: 4 nodes, free links"
    println()
    times, snaps = simulate(NODES_ONLY_SCENARIO, ShortestPath(); speed=100)
    @info "Running times" times

    @info "Starting simulation: 4 nodes, SQUARE_SCENARIO links"
    println()
    times, snaps = simulate(SQUARE_SCENARIO, ShortestPath(); speed=100)
    @info "Running times" times
end
