using KuMo, DataFrames, StatsPlots, CSV, PGFPlotsX, Plots

function scenario_c1()
	j1 = job(100, 5, 4, 3, 1)
    π1 = 0.001
    req1 = [Request(j1, t) for t in π1:π1:10.]
    user1 = user(req1, 3)

	j2 = job(1, 1, 0, 4, 2)
    π2 = 0.1
    req2 = [Request(j2, t) for t in π2:π2:10.]
    user2 = user(req2, 3)

    _requests = Vector{KuMo.Request{typeof(j1)}}()

    L = 1000
    r = 0.01
    λ = 1.
    n = 1
    δ = j1.duration
    c = j1.containers

    π1 = λ / r
    π2 = (2n - λ) / r

    for i in 0:π1+π2
        for t in i:δ:π1+π2-i
            i ≤ π1 && push!(_requests, KuMo.Request(j1, t))
        end
    end


    scenario(;
        duration=1000,
        nodes=[
			Node(100),
			Node(100),
			Node(1000),
			Node(1000),
		],
        users=[
            user(_requests, 1)
            # user1,
            # user2,
		],
	    links=[
	    	(1, 3, 200.0), (2, 3, 200.0), (3, 4, 1000.0), (4, 2, 200.0),
	        (3, 1, 200.0), (3, 2, 200.0), (4, 3, 1000.0), (2, 4, 200.0),
	    ],
    )
end

# Simulation
_, dfc1, _ = simulate(scenario_c1(), ShortestPath(); speed=0);

# Line plot
begin
    pc_1_nodes = @df dfc1 plot(:instant,
        cols(6:9), tex_output_standalone=true, xlabel="time",
        ylabel="load", title="Resources allocations using basic pseudo-cost functions",
        w=1.25,
    );
	pc_1_links = @df dfc1 plot(:instant,
        cols(10:17), tex_output_standalone=true, xlabel="time",
        ylabel="load",
        w=1.25,
	);
	pc_1_line = plot(pc_1_nodes, pc_1_links, layout = grid(2,1))
end
