using KuMo, DataFrames, StatsPlots, CSV, PGFPlotsX, Plots

function scenario_c1()
	j1=job(75, 30, 2, 10, 20)
    user1 = user(requests(PeriodicRequests(
        j1, 1.0/10;
        start = 0., stop = 100.)), 3
    )

	j2=job(75, 30, 1, 10, 20)
    user2 = user(PeriodicRequests(
        j2, 1.0/10;
        start = 0., stop = 100.), 3
    )
    # user2 = user(PeriodicRequests(j, 1.0/150; start = 0., stop = 10.), 3)

    userss = [user1, user2]

    @info typeof(userss)

    scenario(;
        duration=1000,
        nodes=[
			Node(120),
			Node(100),
			Node(10),
			Node(10),
		],
        users=[
			# user 1
	        user1,
            user2,
			# # user 2
			# user(job(50, 1, 1, 1, 10), 1.0/1000, 1;)
			# # user 3
			# user(job(10, 1, 4, 1, 50), 1.0/1000, 2;)
			# # user 4
			# user(job(10, 1, 2, 1, 10), 1.0/1000, 4;)
		],
	    links=[
	    	(1, 2, 100.0), (2, 3, 100.0), (3, 1, 100.0), (4, 1, 100.0),
	        (2, 1, 100.0), (3, 2, 10.0), (1, 3, 100.0), (1, 4, 100.0),
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
