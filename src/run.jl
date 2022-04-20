function task_job(t, j)
    wait(t)
end


function simulate(s::Scenario, acceleration = 20)
    tasks = Vector{Pair{Float64, Job}}()

    for u in s.users
        jr = u[2].job_requests
        j = jr.job
        p = jr.period

        foreach(occ -> push!(tasks, occ => j), 0:p:s.duration)
    end

    c = Channel{Job}(10^7)

    for t in tasks
        @async begin; sleep(t[1]/acceleration); put!(c, t[2]); end
    end

    return c
end
