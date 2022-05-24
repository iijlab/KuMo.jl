using KuMo
using Test

@testset "KuMo.jl" begin

    r1 = KuMo.Node(30, 15)
    r2 = KuMo.Node(45, 20)

    predict_cost(r1, 5)
    predict_cost(r2, 10)

    sim = simulate(scenario(), 1000)
    sleep(20)
    @test sim.n_avail_items > 2000000
end
