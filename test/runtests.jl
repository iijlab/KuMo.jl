using KuMo
using Test

@testset "KuMo.jl" begin
    sim = simulate(scenario(), 1000)
    sleep(20)
    @test sim.n_avail_items > 2000000
end
