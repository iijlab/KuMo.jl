using KuMo, DataFrames, StatsPlots, CSV, PGFPlotsX, Plots

function scenario_c1()
	j=job(0, 1, rand(1:4), 4, 0)
    _requests = Vector{KuMo.Request{typeof(j)}}()

    scenario(;
        duration=10,
        nodes=[
			Node(1000),
			Node(1000),
			Node(100),
			Node(100),
		],
        users=[
			# user 1
	        user(job(10, 1, 2, 1, 50), 1.0/1000, 3;)
			# # user 2
			# user(job(50, 1, 1, 1, 10), 1.0/1000, 1;)
			# # user 3
			# user(job(10, 1, 4, 1, 50), 1.0/1000, 2;)
			# # user 4
			# user(job(10, 1, 2, 1, 10), 1.0/1000, 4;)
		],
	    links=[
	    	(1, 2, 200.0), (2, 3, 200.0), (3, 1, 200.0), (4, 1, 200.0),
	        (2, 1, 200.0), (3, 2, 200.0), (1, 3, 200.0), (1, 4, 200.0),
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
