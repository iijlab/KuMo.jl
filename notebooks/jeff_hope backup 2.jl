### A Pluto.jl notebook ###
# v0.19.22

using Markdown
using InteractiveUtils

# ╔═╡ eb7b42c0-f6b5-11ec-0d00-63b5a9ff3b25
# Packages requirement (only KuMo.jl is private and restricted to IIJ lab members)
using KuMo, DataFrames, StatsPlots, CSV, Distributions, PGFPlotsX

# ╔═╡ da618257-92e7-4264-951e-180533e3a697
# (Optional) Set the plotting and TeX engines
begin
	pgfplotsx()
	latexengine!(PGFPlotsX.LUALATEX)
end;

# ╔═╡ 12104e66-852e-4226-bb6d-8c8627f08a0b
# Graphs related packages
using Graphs, TikzGraphs, LaTeXStrings, TikzPictures

# ╔═╡ 7b9d3d46-a10f-466a-91de-89cea401941f
begin
	c1 = ρ -> (2 * ρ - 1)^2 / (1 - ρ) + 1
	c3 = ρ ->　ρ^4.5 / (1 - ρ) + 1
    plot_pc = StatsPlots.plot(
		[c1, c3], 0:0.01:0.91,
		label = ["convex cost func" "monotonic cost func"], legend=:topleft,
		ylims = (0., Inf),
		xticks = 0.0:0.25:0.75,
		yticks = 1:8,
		xlabel = "load",
		ylabel = "pseudo cost",
		w=.5,
		line=:auto,
		thickness_scaling = 2
	)

	savefig(plot_pc, "pseudo_costs.pdf")
	plot_pc
end

# ╔═╡ d3dffe88-c2af-4962-831b-a7fea9e61df7
begin
	pc1 = ρ -> (2 * ρ - 1)^2 / (1 - ρ) + 1
	pc2 = ρ -> pc1(ρ+0.2)
	pc3 = ρ -> pc1(ρ) * 2
	pc4 = ρ -> pc1(ρ) + 0.5
	n = 2
	pc5 = ρ -> n * (2 * ρ - 1)^2 / (1 - ρ^n) + 1
    plot_pc2 = StatsPlots.plot(
		[pc2, pc3, pc4, pc5], [0:0.01:0.71, 0:0.01:0.91, 0:0.01:0.91, 0:0.01:0.91],
		label = ["load +.2" "cost ×2" "cost +.5" "idle cost ×1.5"], legend=:topleft,
		ylims = (0., 8),
		xticks = 0.0:0.25:0.75,
		yticks = 1:8,
		xlabel = "load",
		ylabel = "pseudo cost",
		w=.65,
		line=:auto,
		thickness_scaling = 2
	)
	plot!(0:0.01:0.91, pc1; label = "std cost func", w = .9)
	savefig(plot_pc2, "pseudo_costs_2.pdf")
	plot_pc2
end

# ╔═╡ 4a5f3a59-8cf7-4a9e-89fe-e9c034851214
function scenarioa(;
    max_load=3.50,
    nodes=(4, 100),
    rate=0.01,
    j=job(0, 1, rand(1:4), 3.25, 0)
)
    _requests = Vector{KuMo.Request{typeof(j)}}()

    L = prod(nodes)
    r = rate
    λ = max_load
    n = nodes[1]
    δ = j.duration
    c = j.containers

    π1 = λ / r
    π2 = (2n - λ) / r

    for i in 0:π1+π2
        for t in i:δ:π1+π2-i
            i ≤ π1 && push!(_requests, KuMo.Request(j, t))
        end
    end

    # @info "Parameters" L r λ n δ c π1 π2 length(_requests)

    scenario(;
        duration=1000,
        nodes=(4, 100),
        users=[
            # user 1
            user(KuMo.Requests(_requests), 1),
        ]
    )
end

# ╔═╡ 7e255750-ea08-4aa5-ae28-00bb03d7042b
# ╠═╡ show_logs = false
_, dfa = simulate_and_plot(scenarioa(), ShortestPath());

# ╔═╡ 96b528be-ae7e-416f-be98-466734aeb029
begin
	pa_1 = @df dfa StatsPlots.plot(:instant,
	    cols([9,8,7,6]), seriestype = :steppre,
	    ylabel="load",
		yticks = 0:.25:1,
	    w=1, tex_output_standalone = true,
		lab = ["r0" "r1" "r3" "r4"]
	)
	pa_2 = @df dfa areaplot(:instant,
	    cols([9,8,7,6]), xlabel="time", seriestype = :steppre,
	    ylabel="total load",
	    w=1, tex_output_standalone = true,
		lab = ["r0" "r1" "r3" "r4"]
	)
	pa = StatsPlots.plot(pa_1, pa_2; layout = (2,1), thickness_scaling = 2, w=.5)
	savefig(pa, "equivalent_nodes.pdf")
	pa
end

# ╔═╡ aba667e8-6a28-4693-8946-af613ce77951
function scenariob(;
    max_load=3.5,
    nodes=(4, 100),
    rate=0.01,
    j=job(0, 1, rand(1:4), 3.25, 0)
)
    _requests = Vector{KuMo.Request{typeof(j)}}()

    L = prod(nodes)
    r = rate
    λ = max_load
    n = nodes[1]
    δ = j.duration
    c = j.containers

    π1 = λ / r
    π2 = (2n - λ) / r

    for i in 0:π1+π2
        for t in i:δ:π1+π2-i
            i ≤ π1 && push!(_requests, KuMo.Request(j, t))
        end
    end

    # @info "Parameters" L r λ n δ c π1 π2 length(_requests)

    scenario(;
        duration=1000,
        nodes=[
            MultiplicativeNode(100, 1),
            MultiplicativeNode(100, 2),
            MultiplicativeNode(100, 4),
            MultiplicativeNode(100, 8),
        ],
        # nodes=(4, 100),
        users=[
            # user 1
            user(KuMo.Requests(_requests), 1),
        ]
    )
end

# ╔═╡ 0ccb45a7-9a82-41fa-b740-86a911b43e7e
# ╠═╡ show_logs = false
_, dfb = simulate_and_plot(scenariob(), ShortestPath());

# ╔═╡ 04d2ee88-af75-498f-8519-f02e7615e64b
begin
	pb_1 = @df dfb StatsPlots.plot(:instant,
	    cols(6:9), seriestype = :steppre,
	    ylabel="load",
		yticks= 0:0.25:1,
	    w=1, tex_output_standalone = true,
		lab = ["r0" "r1" "r3" "r4"]
	)
	pb_2 = @df dfb areaplot(:instant,
	    cols(6:9), xlabel="time", seriestype = :steppre,
	    ylabel="total load",
	    w=1, tex_output_standalone = true,
		lab = ["r0" "r1" "r3" "r4"]
	)
	pb = StatsPlots.plot(pb_1, pb_2; layout = (2,1), thickness_scaling = 2, w=.5)
	savefig(pb, "proportional_nodes.pdf")
	pb
end

# ╔═╡ c0b650b6-48c4-4557-aebd-abd1987101cb
function scenario1(;)
	Δ1 = 120
	Δ2 = 180
	δ = 4.
	σ = δ / 4
	norm_dist = truncated(Normal(δ, σ); lower = eps())
	# jd() = rand(norm_dist) 
	jd() = 4

	λ = 1.
	fish = Poisson(λ)
	# ji() = rand(fish)
	ji() = λ

	interactive(data) = job(1, 1, data, jd(), 2)
	data_intensive(data) = job(2, 1, data, jd(), 1)

	reqs = Vector{Request{<:KuMo.AbstractJob}}()
	types = Set()
	k1 = 38
	# user1 - wave 1
	t = 0.0
	r = Float64(Δ1)
	for i in 1:Δ1/2
		k = k1*sin(i*π/Δ1)
		while t ≤ i
			t += ji()
			j = rand() < 1/3 ? interactive(4) : data_intensive(4)
			push!(types, typeof(j))
			foreach(_ -> push!(reqs, Request(j, t)), 1:k)
		end
		i + δ < Δ1/2 && while r ≥ Δ1 - i
			r -= ji()
			j = rand() < 1/3 ? interactive(4) : data_intensive(4)
			push!(types, typeof(j))
			foreach(_ -> push!(reqs, Request(j, r - δ/2)), 1:k)
		end
	end
	
	# user1 - wave 2
	t = 0.0
	r = Float64(Δ1)
	for i in 1:Δ1/2
		k = k1*sin(i*π/Δ1)
		while t ≤ i
			t += ji()
			j = rand() < 1/3 ? interactive(4) : data_intensive(4)
			push!(types, typeof(j))
			foreach(_ -> push!(reqs, Request(j, t + Δ1)), 1:k)
		end
		i + δ < Δ1/2 && while r ≥ Δ1 - i
			r -= ji()
			j = rand() < 1/3 ? interactive(4) : data_intensive(4)
			push!(types, typeof(j))
			foreach(_ -> push!(reqs, Request(j, r - δ/2 + Δ1)), 1:k)
		end
	end

	# user1 - wave 3
	t = 0.0
	r = Float64(Δ1)
	for i in 1:Δ1/2
		k = k1*sin(i*π/Δ1)
		while t ≤ i
			t += ji()
			j = rand() < 1/3 ? interactive(4) : data_intensive(4)
			push!(types, typeof(j))
			foreach(_ -> push!(reqs, Request(j, t + 2Δ1)), 1:k)
		end
		i + δ < Δ1/2 && while r ≥ Δ1 - i
			r -= ji()
			j = rand() < 1/3 ? interactive(4) : data_intensive(4)
			push!(types, typeof(j))
			foreach(_ -> push!(reqs, Request(j, r - δ/2 + 2Δ1)), 1:k)
		end
	end

	# user1 - wave 4
	t = 0.0
	r = Float64(Δ1)
	for i in 1:Δ1/2
		k = k1*sin(i*π/Δ1)
		while t ≤ i
			t += ji()
			j = rand() < 1/3 ? interactive(4) : data_intensive(4)
			push!(types, typeof(j))
			foreach(_ -> push!(reqs, Request(j, t + 3Δ1)), 1:k)
		end
		i + δ < Δ1/2 && while r ≥ Δ1 - i
			r -= ji()
			j = rand() < 1/3 ? interactive(4) : data_intensive(4)
			push!(types, typeof(j))
			foreach(_ -> push!(reqs, Request(j, r - δ/2 + 3Δ1)), 1:k)
		end
	end

	# user1 - wave 5
	t = 0.0
	r = Float64(Δ1)
	for i in 1:Δ1/2
		k = k1*sin(i*π/Δ1)
		while t ≤ i
			t += ji()
			j = rand() < 1/3 ? interactive(4) : data_intensive(4)
			push!(types, typeof(j))
			foreach(_ -> push!(reqs, Request(j, t + 4Δ1)), 1:k)
		end
		i + δ < Δ1/2 && while r ≥ Δ1 - i
			r -= ji()
			j = rand() < 1/3 ? interactive(4) : data_intensive(4)
			push!(types, typeof(j))
			foreach(_ -> push!(reqs, Request(j, r - δ/2 + 4Δ1)), 1:k)
		end
	end
	
	# user1 - wave 6
	t = 0.0
	r = Float64(Δ1)
	for i in 1:Δ1/2
		k = k1*sin(i*π/Δ1)
		while t ≤ i
			t += ji()
			j = rand() < 1/3 ? interactive(4) : data_intensive(4)
			push!(types, typeof(j))
			foreach(_ -> push!(reqs, Request(j, t + 5Δ1)), 1:k)
		end
		i + δ < Δ1/2 && while r ≥ Δ1 - i
			r -= ji()
			j = rand() < 1/3 ? interactive(4) : data_intensive(4)
			push!(types, typeof(j))
			foreach(_ -> push!(reqs, Request(j, r - δ/2 + 5Δ1)), 1:k)
		end
	end

	UT = Union{collect(types)...}
	R = Vector{Request{UT}}()
	foreach(r -> push!(R, r), reqs)

	u1 = user(R, 1)


	reqs = Vector{Request{<:KuMo.AbstractJob}}()	
	types = Set()
	k2 = 23
	# user2 - wave 1
	t = 0.0
	r = Float64(Δ2)
	for i in 1:Δ2/2
		k = k2*sin(i*π/Δ2)
		while t ≤ i
			t += ji()
			j = rand() < 1/3 ? interactive(3) : data_intensive(3)
			push!(types, typeof(j))
			foreach(_ -> push!(reqs, Request(j, t)), 1:k)
		end
		i + δ < Δ2/2 && while r ≥ Δ2 - i
			r -= ji()
			j = rand() < 1/3 ? interactive(3) : data_intensive(3)
			push!(types, typeof(j))
			foreach(_ -> push!(reqs, Request(j, r - δ/2)), 1:k)
		end
	end
	
	# user2 - wave 2
	t = 0.0
	r = Float64(Δ2)
	for i in 1:Δ2/2
		k = k2*sin(i*π/Δ2)
		while t ≤ i
			t += ji()
			j = rand() < 1/3 ? interactive(3) : data_intensive(3)
			push!(types, typeof(j))
			foreach(_ -> push!(reqs, Request(j, t + Δ2)), 1:k)
		end
		i + δ < Δ2/2 && while r ≥ Δ2 - i
			r -= ji()
			j = rand() < 1/3 ? interactive(3) : data_intensive(3)
			push!(types, typeof(j))
			foreach(_ -> push!(reqs, Request(j, r - δ/2 + Δ2)), 1:k)
		end
	end

	# user2 - wave 3
	t = 0.0
	r = Float64(Δ2)
	for i in 1:Δ2/2
		k = k2*sin(i*π/Δ2)
		while t ≤ i
			t += ji() / 2
			j = rand() < 1/3 ? interactive(3) : data_intensive(3)
			push!(types, typeof(j))
			foreach(_ -> push!(reqs, Request(j, t + 2Δ2)), 1:k)
		end
		i + δ/2 < Δ2/2 && while r ≥ Δ2 - i
			r -= ji() / 2
			j = rand() < 1/3 ? interactive(3) : data_intensive(3)
			push!(types, typeof(j))
			foreach(_ -> push!(reqs, Request(j, r - δ/3+ 2Δ2)), 1:k)
		end
	end

	# user2 - wave 4
	t = 0.0
	r = Float64(Δ2)
	for i in 1:Δ2/2
		k = k2*sin(i*π/Δ2)
		while t ≤ i
			t += ji() / 10
			j = rand() < 1/3 ? interactive(3) : data_intensive(3)
			push!(types, typeof(j))
			foreach(_ -> push!(reqs, Request(j, t + 3Δ2)), 1:k)
		end
		i + δ/10 < Δ2/2 && while r ≥ Δ2 - i
			r -= ji() / 10
			j = rand() < 1/3 ? interactive(3) : data_intensive(3)
			push!(types, typeof(j))
			foreach(_ -> push!(reqs, Request(j, r - δ/10 + 3Δ2)), 1:k)
		end
	end

	UT = Union{collect(types)...}
	R = Vector{Request{UT}}()
	foreach(r -> push!(R, r), reqs)
	
	u2 = user(R, 2)

	
    scenario(;
        duration=1000,
        nodes=[
			Node(100),
			Node(100),
			Node(1000),
			Node(1000),
		],
        users=[
            u1,
			u2,
		],
	    links=[
	    	(1, 3, 300.0), (2, 3, 300.0), (3, 4, 3000.0), (4, 2, 3000.0),
	        (3, 1, 300.0), (3, 2, 300.0), (4, 3, 3000.0), (2, 4, 3000.0),
	    ],
    )
end

# ╔═╡ 0c296017-8a73-49fe-adb4-4fd604f54bc6
begin
	s = scenario1()
	g = KuMo.graph(s.topology, ShortestPath())[1]
	
	capacities = Dict(filter(p -> p.first[1] < p.first[2], [p.first => Int(p.second.capacity) for p in pairs(s.topology.links)]))
	
	t = TikzGraphs.plot(
		g,
		Layouts.SpringElectrical(charge=20000),
		# Layouts.Spring(dist=10),
		node_style="draw, rounded corners, fill=blue!10",
		node_styles=Dict(
			1=>"fill=green!10",
			2=>"fill=green!10",
			3=>"fill=red!10",
			4=>"fill=red!10",
		),
		# edge_labels=capacities,
		# edge_styles=Dict((3,4)=>"blue"),
		options="scale=.1",
	)
	TikzPictures.save(PDF("2levelsnetwork"), t)
	t
end

# ╔═╡ 07f6987c-8e00-4443-bcef-06ce2e21136f
g0 = Graphs.SimpleGraphs.SimpleDiGraph{Int64}(8, [[3], [3, 4], [1, 2, 4], [2, 3]], [[3], [3, 4], [1, 2, 4], [2, 3]])

# ╔═╡ a08e33b1-7285-46b9-8241-9f2570aad781
TikzGraphs.plot(g0)

# ╔═╡ 9c21d620-a684-4a44-8a96-f5c2e5c352c0
# ╠═╡ show_logs = false
p1, df1 = simulate_and_plot(scenario1(), ShortestPath()); p1

# ╔═╡ f7d43c5a-dd86-4c79-9dd6-974ffc6a4afa
begin
	df1_no_norm = deepcopy(df1)
	df1_no_norm[!, 6:6] = df1[!,6:6] .* 1
	df1_no_norm[!, 7:7] = df1[!,7:7] .* 10

	# df1_no_norm[!, 8:9] = df1[!,8:9] .* 1
	# df7_no_norm[!, 33:48] = df7[!,33:48] .* 10
	
	df1_no_norm
end;

# ╔═╡ 6b596bd9-dbaa-4f8a-a9b2-9c8280ca2e64
# keep it
p11 = @df df1_no_norm areaplot(:instant,
    cols(6:7), xlabel="time", seriestype = :steppre,
    ylabel="total load",
    w=1, tex_output_standalone = true,
	lab = ["MDC0" "DC2" "DC3"]
)

# ╔═╡ 0de8409c-aa08-45df-8d75-1f6167ef9f76
function scenario2a(;)
    reqs = Vector{Request{<:KuMo.AbstractJob}}()
	
	types = Set()

	Δ = 180
	δ = 4.
	σ = δ / 4
	norm_dist = truncated(Normal(δ, σ); lower = eps())
	# jd() = rand(norm_dist) 
	jd() = 4

	λ = 1.
	fish = Poisson(λ)
	# ji() = rand(fish)
	ji() = λ

	interactive(data) = job(1, 1, data, jd(), 2)
	data_intensive(data) = job(2, 1, data, jd(), 1)
	

	t = 0.0
	r = Float64(Δ)
	for i in 1:Δ/2
		k = 25.5*sin(i*π/Δ)
		while t ≤ i
			t += ji()
			# j = rand() < 1/3 ? interactive(3) : data_intensive(3)
			j = interactive(4)
			push!(types, typeof(j))
			foreach(_ -> push!(reqs, Request(j, t)), 1:k)
		end
		i + δ < Δ/2 && while r ≥ Δ - i
			r -= ji()
			j = interactive(4)
			push!(types, typeof(j))
			foreach(_ -> push!(reqs, Request(j, r - δ/2)), 1:k)
		end
	end

	
	# t = 120.0
	# r = Float64(Δ) + 120.0
	# for i in 121.:Δ/2+120.0
	# 	k = (i - 120) ÷ δ + 1
	# 	while t ≤ i
	# 		t += ji()
	# 		# j = rand() < 1/3 ? interactive(3) : data_intensive(3)
	# 		j = interactive(3)
	# 		push!(types, typeof(j))
	# 		foreach(_ -> push!(reqs, Request(j, t)), 1:k)
	# 	end
	# 	i + δ < Δ/2 + 120. && while r ≥ Δ + 120 - i
	# 		r -= ji()
	# 		j = interactive(3)
	# 		push!(types, typeof(j))
	# 		foreach(_ -> push!(reqs, Request(j, r - δ/2)), 1:k)
	# 	end
	# end

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
        users=[
            # user 1
            u1,
		],
	    links=[
	    	(1, 3, 300.0), (2, 3, 300.0), (3, 4, 3000.0), (4, 2, 3000.0),
	        (3, 1, 300.0), (3, 2, 300.0), (4, 3, 3000.0), (2, 4, 3000.0),
	    ],
    )
end

# ╔═╡ 480f90df-f395-457f-813f-4d80bf75793b
# ╠═╡ show_logs = false
p2, df2 = simulate_and_plot(scenario2a(), ShortestPath());

# ╔═╡ ca7815d4-d97f-4300-9226-48a7fe159978
begin
	df2_no_norm = deepcopy(df2)
	df2_no_norm[!, 6:6] = df2[!,6:6] .* 1
	df2_no_norm[!, 7:7] = df2[!,7:7] .* 10

	df2_no_norm[!, 8:9] = df2[!,8:9] .* 1
	# df7_no_norm[!, 33:48] = df7[!,33:48] .* 10
	
	df2_no_norm
end;

# ╔═╡ 16ccae76-6591-4167-bab1-edc5ac931c96
function scenario2b(;)
    reqs = Vector{Request{<:KuMo.AbstractJob}}()
	
	types = Set()

	Δ = 180
	δ = 4.
	σ = δ / 4
	norm_dist = truncated(Normal(δ, σ); lower = eps())
	# jd() = rand(norm_dist) 
	jd() = 4

	λ = 1.
	fish = Poisson(λ)
	# ji() = rand(fish)
	ji() = λ

	interactive(data) = job(1, 1, data, jd(), 2)
	data_intensive(data) = job(2, 1, data, jd(), 1)
	

	t = 0.0
	r = Float64(Δ)
	for i in 1:Δ/2
		k = 25.5*sin(i*π/Δ)
		while t ≤ i
			t += ji()
			# j = rand() < 1/3 ? interactive(3) : data_intensive(3)
			j = interactive(4)
			push!(types, typeof(j))
			foreach(_ -> push!(reqs, Request(j, t + Δ)), 1:k)
		end
		i + δ < Δ/2 && while r ≥ Δ - i
			r -= ji()
			j = interactive(4)
			push!(types, typeof(j))
			foreach(_ -> push!(reqs, Request(j, r - δ/2 + Δ)), 1:k)
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
        users=[
            # user 1
            u1,
		],
	    links=[
	    	(1, 3, 300.0), (2, 3, 300.0), (3, 4, 3000.0), (4, 2, 3000.0),
	        (3, 1, 300.0), (3, 2, 300.0), (4, 3, 3000.0), (2, 4, 3000.0),
	    ],
    )
end

# ╔═╡ e54c3071-721e-4773-ae73-b5916e003ad4
# ╠═╡ show_logs = false
p2b, df2b = simulate_and_plot(scenario2b(), ShortestPath());

# ╔═╡ a427be40-0f2f-404b-9649-f3e3220edccd
begin
	df2b_no_norm = deepcopy(df2b)
	df2b_no_norm[!, 6:6] = df2b[!,6:6] .* 1
	df2b_no_norm[!, 7:7] = df2b[!,7:7] .* 10

	df2b_no_norm[!, 8:9] = df2b[!,8:9] .* 1
	# df7_no_norm[!, 33:48] = df7[!,33:48] .* 10
	
	df2b_no_norm
end;

# ╔═╡ 11a0c1d4-2230-4390-9853-e407b1398828
function scenario2c(;)
    reqs = Vector{Request{<:KuMo.AbstractJob}}()
	
	types = Set()

	Δ = 180
	δ = 4.
	σ = δ / 4
	norm_dist = truncated(Normal(δ, σ); lower = eps())
	# jd() = rand(norm_dist) 
	jd() = 4

	λ = 1.
	fish = Poisson(λ)
	# ji() = rand(fish)
	ji() = λ

	interactive(data) = job(1, 1, data, jd(), 2)
	data_intensive(data) = job(2, 1, data, jd(), 1)
	

	t = 0.0
	r = Float64(Δ)
	for i in 1:Δ/2
		k = 25.5*sin(i*π/Δ)
		while t ≤ i
			t += ji()
			# j = rand() < 1/3 ? interactive(3) : data_intensive(3)
			j = interactive(4)
			push!(types, typeof(j))
			foreach(_ -> push!(reqs, Request(j, t + 2Δ)), 1:k)
		end
		i + δ < Δ/2 && while r ≥ Δ - i
			r -= ji()
			j = interactive(4)
			push!(types, typeof(j))
			foreach(_ -> push!(reqs, Request(j, r - δ/2 + 2Δ)), 1:k)
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
        users=[
            # user 1
            u1,
		],
	    links=[
	    	(1, 3, 300.0), (2, 3, 300.0), (3, 4, 3000.0), (4, 2, 3000.0),
	        (3, 1, 300.0), (3, 2, 300.0), (4, 3, 3000.0), (2, 4, 3000.0),
	    ],
    )
end

# ╔═╡ a407a75e-7b9d-42f8-9b2c-98c6505c9682
# ╠═╡ show_logs = false
p2c, df2c = simulate_and_plot(scenario2c(), ShortestPath());

# ╔═╡ f960e2ca-c6d1-4dc2-a4d3-39cdcdeeb1b7
begin
	df2c_no_norm = deepcopy(df2c)
	df2c_no_norm[!, 6:6] = df2c[!,6:6] .* 1
	df2c_no_norm[!, 7:7] = df2c[!,7:7] .* 10

	df2c_no_norm[!, 8:9] = df2c[!,8:9] .* 1
	# df7_no_norm[!, 33:48] = df7[!,33:48] .* 10
	
	df2c_no_norm
end;

# ╔═╡ 7114f833-263e-41cf-9ca6-38d8700d4fa4
function scenario2d(;)
    reqs = Vector{Request{<:KuMo.AbstractJob}}()
	
	types = Set()

	Δ = 180
	δ = 4.
	σ = δ / 4
	norm_dist = truncated(Normal(δ, σ); lower = eps())
	# jd() = rand(norm_dist) 
	jd() = 4

	λ = 1.
	fish = Poisson(λ)
	# ji() = rand(fish)
	ji() = λ

	interactive(data) = job(250, 1, data, jd(), 2)
	data_intensive(data) = job(2, 1, data, jd(), 1)
	

	t = 0.0
	r = Float64(Δ)
	for i in 1:Δ/2
		k = 25.5*sin(i*π/Δ)
		while t ≤ i
			t += ji()
			# j = rand() < 1/3 ? interactive(3) : data_intensive(3)
			j = interactive(4)
			push!(types, typeof(j))
			foreach(_ -> push!(reqs, Request(j, t + 3Δ)), 1:k)
		end
		i + δ < Δ/2 && while r ≥ Δ - i
			r -= ji()
			j = interactive(4)
			push!(types, typeof(j))
			foreach(_ -> push!(reqs, Request(j, r - δ/2 + 3Δ)), 1:k)
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
        users=[
            # user 1
            u1,
		],
	    links=[
	    	(1, 3, 300.0), (2, 3, 300.0), (3, 4, 3000.0), (4, 2, 3000.0),
	        (3, 1, 300.0), (3, 2, 300.0), (4, 3, 3000.0), (2, 4, 3000.0),
	    ],
    )
end

# ╔═╡ eec65bd7-5c3c-4974-8bce-a7fbf4ce3259
# ╠═╡ show_logs = false
p2d, df2d = simulate_and_plot(scenario2d(), ShortestPath());

# ╔═╡ c10c2e69-5525-4cad-9dc9-623470eab30e
begin
	append!(df2, df2b, cols = :union)
	append!(df2, df2c, cols = :union)
	append!(df2, df2d, cols = :union)
	l1,l2 = size(df2)
	for i in 1:l1, j in 1:l2
		if df2[i,j] === missing
			df2[i,j] = 0.0
		end
	end
	
	df2_no_norm_final = deepcopy(df2)
	df2_no_norm_final[!, 6:6] = df2[!,6:6] .* 1
	df2_no_norm_final[!, 7:7] = df2[!,7:7] .* 10

	df2_no_norm_final[!, 11:11] = df2[!,11:11] .* 10
	# df7_no_norm[!, 33:48] = df7[!,33:48] .* 10
	
	df2_no_norm_final
end;

# ╔═╡ 566e957f-68f3-4d0d-847e-1242f1e5278f
# keep it
p_no_norm_area2_final = @df df2_no_norm_final areaplot(:instant,
    cols([6,7,11]), xlabel="time", seriestype = :steppre,
    ylabel="total load",
    w=0.01, tex_output_standalone = true,
	lab = ["MDC0" "DC2" "DC3"]
);

# ╔═╡ 2cc63aa9-d9f2-4110-90b5-cebc92ff4ad9
# keep it
p_line_final = @df df2 plot(:instant,
    cols([6,7,11]), xlabel="time", seriestype = :steppre,
    ylabel="total load",
    w=1, tex_output_standalone = true,
	lab = ["MDC0" "DC2" "DC3"]
);

# ╔═╡ 495135df-7a2a-4235-9cd5-3ba17c6ef845
p2_final = plot(p_line_final, p_no_norm_area2_final; layout = (2,1))

# ╔═╡ b9a6c8db-e0e7-49f1-8ef1-e4adcb311f94
savefig(p2_final, "../papers/conext2022/fig6.pdf")

# ╔═╡ Cell order:
# ╠═eb7b42c0-f6b5-11ec-0d00-63b5a9ff3b25
# ╠═da618257-92e7-4264-951e-180533e3a697
# ╠═12104e66-852e-4226-bb6d-8c8627f08a0b
# ╠═7b9d3d46-a10f-466a-91de-89cea401941f
# ╠═d3dffe88-c2af-4962-831b-a7fea9e61df7
# ╠═4a5f3a59-8cf7-4a9e-89fe-e9c034851214
# ╠═7e255750-ea08-4aa5-ae28-00bb03d7042b
# ╠═96b528be-ae7e-416f-be98-466734aeb029
# ╠═aba667e8-6a28-4693-8946-af613ce77951
# ╠═0ccb45a7-9a82-41fa-b740-86a911b43e7e
# ╠═04d2ee88-af75-498f-8519-f02e7615e64b
# ╠═c0b650b6-48c4-4557-aebd-abd1987101cb
# ╠═0c296017-8a73-49fe-adb4-4fd604f54bc6
# ╠═07f6987c-8e00-4443-bcef-06ce2e21136f
# ╠═a08e33b1-7285-46b9-8241-9f2570aad781
# ╠═9c21d620-a684-4a44-8a96-f5c2e5c352c0
# ╠═f7d43c5a-dd86-4c79-9dd6-974ffc6a4afa
# ╠═6b596bd9-dbaa-4f8a-a9b2-9c8280ca2e64
# ╟─0de8409c-aa08-45df-8d75-1f6167ef9f76
# ╠═480f90df-f395-457f-813f-4d80bf75793b
# ╠═ca7815d4-d97f-4300-9226-48a7fe159978
# ╟─16ccae76-6591-4167-bab1-edc5ac931c96
# ╠═e54c3071-721e-4773-ae73-b5916e003ad4
# ╟─a427be40-0f2f-404b-9649-f3e3220edccd
# ╟─11a0c1d4-2230-4390-9853-e407b1398828
# ╠═a407a75e-7b9d-42f8-9b2c-98c6505c9682
# ╟─f960e2ca-c6d1-4dc2-a4d3-39cdcdeeb1b7
# ╟─7114f833-263e-41cf-9ca6-38d8700d4fa4
# ╠═eec65bd7-5c3c-4974-8bce-a7fbf4ce3259
# ╟─c10c2e69-5525-4cad-9dc9-623470eab30e
# ╟─566e957f-68f3-4d0d-847e-1242f1e5278f
# ╟─2cc63aa9-d9f2-4110-90b5-cebc92ff4ad9
# ╠═495135df-7a2a-4235-9cd5-3ba17c6ef845
# ╠═b9a6c8db-e0e7-49f1-8ef1-e4adcb311f94
