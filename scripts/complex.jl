using KuMo, DataFrames, StatsPlots, CSV, PGFPlotsX, Plots

function scenario_c1()
	j1 = job(10, 10, 2, 4, 5)
    π1 = 0.1
    req1 = [Request(j1, t) for t in π1:π1:10.]
    user1 = user(req1, 3)

	j2 = job(5, 5, 1, 4, 10)
    π2 = 0.1
    req2 = [Request(j2, t) for t in π2:π2:10.]
    user2 = user(req2, 3)

    j3 = job(10, 10, 2, 4, 5)
    π3 = 0.1
    req3 = [Request(j3, t) for t in π3:π3:10.]
    user3 = user(req3, 4)

	j4 = job(5, 1, 1, 4, 25)
    π4 = 0.1
    req4 = [Request(j4, t) for t in π4:π4:10.]
    user4 = user(req4, 4)


    scenario(;
        duration=1000,
        nodes=[
			Node(100),
			Node(150),
			Node(10),
			Node(10),
		],
        users=[
            user1,
            user2,
            user3,
            user4,
		],
	    links=[
	    	(1, 2, 150.0), (2, 3, 150.0), (3, 1, 50.0), (4, 1, 50.0),
	        (2, 1, 150.0), (3, 2, 150.0), (1, 3, 50.0), (1, 4, 50.0),
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
