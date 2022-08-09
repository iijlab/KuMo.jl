include("common.jl")

function scenario6a(;)
    reqs = Vector{Request{<:KuMo.AbstractJob}}()

    types = Set()

    Δ = 180
    δ = 4.0
    jd() = 4

    λ = 1.0
    ji() = λ

    interactive(data) = job(1, 1, data, jd(), 2)
    data_intensive(data) = job(2, 1, data, jd(), 1)


    t = 0.0
    r = Float64(Δ)
    for i in 1:Δ/2
        k = 25.5 * sin(i * π / Δ)
        while t ≤ i
            t += ji()
            j = interactive(4)
            push!(types, typeof(j))
            foreach(_ -> push!(reqs, Request(j, t)), 1:k)
        end
        i + δ < Δ / 2 && while r ≥ Δ - i
            r -= ji()
            j = interactive(4)
            push!(types, typeof(j))
            foreach(_ -> push!(reqs, Request(j, r - δ / 2)), 1:k)
        end
    end

    UT = Union{collect(types)...}
    R = Vector{Request{UT}}()
    foreach(r -> push!(R, r), reqs)

    u1 = user(R, 1)


    scenario(;
        duration=1000,
        nodes=[
            Node(100),
            Node(100),
            Node(1000),
            Node(1000),
        ],
        users=[u1],
        links=[
            (1, 3, 300.0), (2, 3, 300.0), (3, 4, 3000.0), (4, 2, 3000.0),
            (3, 1, 300.0), (3, 2, 300.0), (4, 3, 3000.0), (2, 4, 3000.0),
        ],
        directed=false
    )
end

function scenario6b(;)
    reqs = Vector{Request{<:KuMo.AbstractJob}}()

    types = Set()

    Δ = 180
    δ = 4.0
    jd() = 4

    λ = 1.0
    ji() = λ

    interactive(data) = job(1, 1, data, jd(), 2)
    data_intensive(data) = job(2, 1, data, jd(), 1)


    t = 0.0
    r = Float64(Δ)
    for i in 1:Δ/2
        k = 25.5 * sin(i * π / Δ)
        while t ≤ i
            t += ji()
            j = interactive(4)
            push!(types, typeof(j))
            foreach(_ -> push!(reqs, Request(j, t + Δ)), 1:k)
        end
        i + δ < Δ / 2 && while r ≥ Δ - i
            r -= ji()
            j = interactive(4)
            push!(types, typeof(j))
            foreach(_ -> push!(reqs, Request(j, r - δ / 2 + Δ)), 1:k)
        end
    end

    UT = Union{collect(types)...}
    R = Vector{Request{UT}}()
    foreach(r -> push!(R, r), reqs)

    u1 = user(R, 1)


    scenario(;
        duration=1000,
        nodes=[
            PremiumNode(100, 0.2),
            Node(100),
            Node(1000),
            Node(1000),
        ],
        users=[u1],
        links=[
            (1, 3, 300.0), (2, 3, 300.0), (3, 4, 3000.0), (4, 2, 3000.0),
            (3, 1, 300.0), (3, 2, 300.0), (4, 3, 3000.0), (2, 4, 3000.0),
        ],
        directed=false
    )
end

function scenario6c(;)
    reqs = Vector{Request{<:KuMo.AbstractJob}}()

    types = Set()

    Δ = 180
    δ = 4.0
    jd() = 4

    λ = 1.0
    ji() = λ

    interactive(data) = job(1, 1, data, jd(), 2)
    data_intensive(data) = job(2, 1, data, jd(), 1)


    t = 0.0
    r = Float64(Δ)
    for i in 1:Δ/2
        k = 25.5 * sin(i * π / Δ)
        while t ≤ i
            t += ji()
            j = interactive(4)
            push!(types, typeof(j))
            foreach(_ -> push!(reqs, Request(j, t + 2Δ)), 1:k)
        end
        i + δ < Δ / 2 && while r ≥ Δ - i
            r -= ji()
            j = interactive(4)
            push!(types, typeof(j))
            foreach(_ -> push!(reqs, Request(j, r - δ / 2 + 2Δ)), 1:k)
        end
    end

    UT = Union{collect(types)...}
    R = Vector{Request{UT}}()
    foreach(r -> push!(R, r), reqs)

    u1 = user(R, 1)

    scenario(;
        duration=1000,
        nodes=[
            PremiumNode(100, 0.4),
            Node(100),
            Node(1000),
            Node(1000),
        ],
        users=[u1],
        links=[
            (1, 3, 300.0), (2, 3, 300.0), (3, 4, 3000.0), (4, 2, 3000.0),
            (3, 1, 300.0), (3, 2, 300.0), (4, 3, 3000.0), (2, 4, 3000.0),
        ],
        directed=false
    )
end

function scenario6d(;)
    reqs = Vector{Request{<:KuMo.AbstractJob}}()

    types = Set()

    Δ = 180
    δ = 4.0
    jd() = 4

    λ = 1.0
    ji() = λ

    interactive(data) = job(250, 1, data, jd(), 2)
    data_intensive(data) = job(2, 1, data, jd(), 1)


    t = 0.0
    r = Float64(Δ)
    for i in 1:Δ/2
        k = 25.5 * sin(i * π / Δ)
        while t ≤ i
            t += ji()
            j = interactive(4)
            push!(types, typeof(j))
            foreach(_ -> push!(reqs, Request(j, t + 3Δ)), 1:k)
        end
        i + δ < Δ / 2 && while r ≥ Δ - i
            r -= ji()
            j = interactive(4)
            push!(types, typeof(j))
            foreach(_ -> push!(reqs, Request(j, r - δ / 2 + 3Δ)), 1:k)
        end
    end

    UT = Union{collect(types)...}
    R = Vector{Request{UT}}()
    foreach(r -> push!(R, r), reqs)

    u1 = user(R, 1)


    scenario(;
        duration=1000,
        nodes=[
            PremiumNode(100, 0.4),
            Node(100),
            Node(1000),
            Node(1000),
        ],
        users=[u1],
        links=[
            (1, 3, 300.0), (2, 3, 300.0), (3, 4, 3000.0), (4, 2, 3000.0),
            # (3, 1, 300.0), (3, 2, 300.0), (4, 3, 3000.0), (2, 4, 3000.0),
            (3, 1, 300.0), (3, 2, 300.0), (4, 3, 3000.0), (2, 4, 3000.0),
        ],
        directed=false
    )
end

df = simulate(scenario6a())[2]
dfb = simulate(scenario6b())[2]
dfc = simulate(scenario6c())[2]
dfd = simulate(scenario6d())[2]

append!(df, dfb, cols=:union)
append!(df, dfc, cols=:union)
append!(df, dfd, cols=:union)

df_norm = deepcopy(df)
df_norm[!, 6:6] = df[!, 6:6] .* 1
df_norm[!, 7:7] = df[!, 7:7] .* 10

df_norm[!, 11:11] = df[!, 11:11] .* 10