@testset "Aqua.jl" begin
    import Aqua
    import KuMo

    # TODO: Fix the broken tests and remove the `broken = true` flag
    Aqua.test_all(
        KuMo;
        ambiguities = (broken = true,),
        deps_compat = false,
        piracies = (broken = false,)
    )

    @testset "Ambiguities: ConstraintCommons" begin
        Aqua.test_ambiguities(KuMo;)
    end

    @testset "Piracies: ConstraintCommons" begin
        Aqua.test_piracies(KuMo;)
    end

    @testset "Dependencies compatibility (no extras)" begin
        Aqua.test_deps_compat(
            KuMo;
            check_extras = false            # ignore = [:Random]
        )
    end
end
