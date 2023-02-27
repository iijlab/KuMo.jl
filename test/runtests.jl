using TestItemRunner

@run_package_tests


# using KuMo
# using Test

# using Ipopt

# @testset "KuMo.jl" begin
#     @info "Starting simulation: 4 nodes, square links, sync, statistic requests"
#     println()
#     times, _, _ = simulate(SCENARII[:four_nodes_four_users], ShortestPath(); speed=0)
#     @info "Running times" times

#     @info "Starting simulation: 4 nodes, square links, sync"
#     println()
#     times, _, _ = simulate(SCENARII[:four_nodes], ShortestPath(); speed=0)
#     @info "Running times" times

#     @info "Starting simulation: 4 nodes, square links, async (speed 100)"
#     println()
#     times, _, _ = simulate(SCENARII[:square], ShortestPath(); speed=100)
#     @info "Running times" times
# end
