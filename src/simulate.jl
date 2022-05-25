function simulate(s::Scenario, acceleration=20)
    tasks = Vector{Pair{Float64,Job}}()

    all_queue = false

    for u in s.users
        jr = u.job_requests
        j = jr.job
        p = jr.period

        foreach(occ -> push!(tasks, occ => j), 0:p:s.duration)
    end

    c = Channel{Job}(10^7)

    for (i, t) in enumerate(tasks)
        @async begin
            sleep(t[1] / acceleration)
            put!(c, t[2])
            i == length(tasks) && (all_queue = true)
        end
    end

    while !all_queue || isready(c)
        j = take!(c)

        @info j
    end

    return c
end