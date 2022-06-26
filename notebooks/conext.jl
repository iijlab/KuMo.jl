### A Pluto.jl notebook ###
# v0.19.9

using Markdown
using InteractiveUtils

# ╔═╡ 61189540-e578-11ec-3030-c3ebb611c28b
# Packages requirement (only KuMo.jl is private and restricted to IIJ lab members)
using KuMo, DataFrames, StatsPlots, CSV

# ╔═╡ bc72d307-12f7-47c6-b90a-062814186978
# ╠═╡ disabled = true
#=╠═╡
# (Optional) Set the plotting and TeX engines
begin
	using PGFPlotsX
	pgfplotsx()
	latexengine!(PGFPlotsX.LUALATEX)
end;
  ╠═╡ =#

# ╔═╡ 217a9755-f4d6-4b13-b47b-9ad08430cffd
# Graphs related packages
using Graphs, TikzGraphs, LaTeXStrings, TikzPictures

# ╔═╡ a575616a-81d4-4829-ae89-41eee625ad9b
# Stats related packages
using Distributions

# ╔═╡ d3221f99-adcc-457c-82f5-95aaa2a9e197
md"""# Series of plots to illustrate the use of pseudo-cost functions

The package `KuMo.jl` is used both as an interface and a simulator of scenarii. Several algorithms can be used to evaluate the cost of allocating a task in a network.
"""

# ╔═╡ 21639215-1463-46ff-80a0-f1f2028c7558
begin
	c1 = ρ -> (2 * ρ - 1)^2 / (1 - ρ) + 1
	c2 = ρ ->　ρ^2 / (1 - ρ) + 1
	c3 = ρ ->　ρ^4.5 / (1 - ρ) + 1
    plot_pc = StatsPlots.plot([c1, c2, c3], 0:0.01:0.9, label = ["ρ -> (2 * ρ - 1)^2 / (1 - ρ) + 1" "ρ -> ρ^2 / (1 - ρ) + 1" "ρ -> ρ^4.5 / (1 - ρ) + 1"], legend=:topleft)
	savefig(plot_pc, "pseudo_costs.pdf")
	plot_pc
end

# ╔═╡ 6eff9ab6-620a-4a31-833d-8b8ec2b399a6
md"""
## Nodes-only scenarii

To illustrate the intended behaviour of pseudo-cost functions without the impact of a network infrastructure, we consider complete networks with free links (no cost).
This is done automatically in `KuMo.jl` by not providing any link.

A basic four-nodes scenario reaching full load is provided as `SCENARII[:four_nodes]`. We define another four-nodes scenario with total load of 3.5 (87.5%) in the next section.

The first scenario is plotted with the number of the resources load snapshot to illustrate how such a network would behave if loaded exactly to the max. Such a situation is unlikely to happen in practice.
Plots after that takes the time of allocation/deallocation as parameter.
"""

# ╔═╡ 698ef7c5-1be3-43fe-bbf0-6c5fa1afef6f
# ╠═╡ show_logs = false
pa1, dfa1 = simulate_and_plot(SCENARII[:four_nodes], ShortestPath()); pa1

# ╔═╡ 12169dd2-6ea2-43a3-b6fd-94d55e23a568
# Load of 87.5% (long duration, low request rate)
scenario2() = scenario(;
    duration=349,
    nodes=(4, 100),
    users=1,
    job_distribution=Dict(
        :backend => 0:0,
        :container => 1:1,
        :data_location => 1:4,
        :duration => 400:400,
        :frontend => 0:0,
    ),
    request_rate=1.0
)

# ╔═╡ d3da1adc-91a8-4a97-bb23-586582a31ad7
# ╠═╡ show_logs = false
pa2, dfa2 = simulate_and_plot(scenario2(), ShortestPath()); pa2

# ╔═╡ c1a3e0fe-c63d-41eb-9ef4-6a9c68246dc0
# Load of 87.5% (small duration, high request rate)
scenario3() = scenario(;
    duration=10,
    nodes=(4, 32),
    users=[
		user(job(0, 1, rand(1:4), 1, 0), 1.0/50, rand(1:4); start=4.01, stop=6.)
        user(job(0, 1, rand(1:4), 1, 0), 1.0/50, rand(1:4);)
	]
)

# ╔═╡ 015b87d8-c652-41ea-8bd8-0634383afea9
# ╠═╡ show_logs = false
pa3, dfa3 = simulate_and_plot(scenario3(), ShortestPath()); pa3

# ╔═╡ cd893c83-7f8d-486e-af73-e411e154e631
# Load of 87.5% (small duration, high request rate, more users)
scenario4() = scenario(;
    duration=10,
    nodes=(4, 32),
    users=[
		# user 1
        user(job(0, 1, rand(1:4), 1, 0), 1.0/20, rand(1:4);)
		# user 2
		user(job(0, 1, rand(1:4), 1, 0), 1.0/20, rand(1:4); stop=12.)
		# user 3
		user(job(0, 1, rand(1:4), 1, 0), 1.0/20, rand(1:4); start=2.01, stop=5.)
		# user 4
		user(job(0, 1, rand(1:4), 1, 0), 1.0/75, rand(1:4); start=7.01, stop=9.)
	]
)

# ╔═╡ 63f15cd5-fb1b-4f74-a287-8e2265ad5d9e
# ╠═╡ show_logs = false
pa4, dfa4 = simulate_and_plot(scenario4(), ShortestPath()); pa4

# ╔═╡ e2144b8b-6b09-4f99-8bf3-819d0a7704f1
function scenario5(;
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

# ╔═╡ 83f8c3e1-9a29-4e86-9125-ace58b0ad794
# ╠═╡ show_logs = false
pa5, dfa5 = simulate_and_plot(scenario5(), ShortestPath()); pa5

# ╔═╡ 971d2a6e-72bb-4875-aee7-aeab10878dec
function scenario6(;
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

# ╔═╡ 4fbcbb5d-f320-432f-b6df-df5c72bb10a5
# ╠═╡ show_logs = false
pa6, dfa6 = simulate_and_plot(scenario6(), ShortestPath()); pa6

# ╔═╡ 2d603282-70c8-4a36-ada3-2459a6877e88
function scenario7(;
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
            IdleStateNode(100, 1),
            IdleStateNode(100, 25),
            IdleStateNode(100, 50),
            IdleStateNode(100, 75),
        ],
        # nodes=(4, 100),
        users=[
            # user 1
            user(KuMo.Requests(_requests), 1),
        ]
    )
end

# ╔═╡ 2454e123-aedc-4b7f-871f-4707e7c76b5c
# ╠═╡ show_logs = false
pa7, dfa7 = simulate_and_plot(scenario7(), ShortestPath()); pa7

# ╔═╡ f62e4864-8690-411a-b1c0-0c5d42f73dc1
function scenario8(;
    max_load=3.50,
    nodes=(4, 100),
    rate=0.01,
    j=job(0, 1, rand(1:4), 1, 0)
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

# ╔═╡ 50b84495-921d-42c8-91fb-8b933cf3d7be
# ╠═╡ show_logs = false
pa8, dfa8 = simulate_and_plot(scenario8(), ShortestPath()); pa8

# ╔═╡ 69cda46a-380f-45c2-b5f8-a491f7d362d6
function scenario9(;
    max_load=3.50,
    nodes=(4, 100),
    rate=0.01,
    j=job(0, 1, rand(1:4), .8, 0)
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

# ╔═╡ e318bb27-bc9b-40c1-af63-9feccb5fcda7
# ╠═╡ show_logs = false
pa9, dfa9 = simulate_and_plot(scenario9(), ShortestPath()); pa9

# ╔═╡ 73ab86d3-7ab6-4288-a1d0-ca30432da9fc
begin
	figures_a = [
		pa1 => "nodes-only-saturated-load.pdf",
		pa2 => "4nodes-high-duration.pdf",
		pa3 => "4nodes-low-duration.pdf",
		pa4 => "4nodes-low-duration_4users.pdf",
		pa5 => "4nodes-low-duration_steadyload.pdf",
		pa6 => "4nodes-low-duration_nonequalload.pdf",
		pa7 => "4nodes-low-duration_idle.pdf",
		pa8 => "4nodes-1-duration.pdf",
		pa9 => "4nodes-0.8-duration.pdf",
	]
	foreach(p -> savefig(p.first, p.second), figures_a)
end

# ╔═╡ 101246ef-1753-4174-ab16-109b425adbec
md"""
## Square networks scenarii
We consider an infrastructure connected as a square `(a <-> b <-> c <-> d <-> a)`.
"""

# ╔═╡ 1c7238b6-6a2c-4123-8f9b-061820e74c98
square_full_load() = scenario(;
    duration=349,
    nodes=(4, 100),
    links=[
    	(1, 2, 200.0), (2, 3, 200.0), (3, 4, 200.0), (4, 1, 200.0),
        (2, 1, 200.0), (3, 2, 200.0), (4, 3, 200.0), (1, 4, 200.0),
    ],
    users=1,
    job_distribution=Dict(
    	:backend => 2:2,
        :container => 1:1,
        :data_location => 1:4,
        :duration => 400:400,
        :frontend => 1:1,
    ),
    request_rate=1.0
)

# ╔═╡ 9ba5c4d2-6197-46ab-a2b6-ff81dd5175d5
# ╠═╡ show_logs = false
pb1, dfb1 = simulate_and_plot(square_full_load(), ShortestPath()); pb1

# ╔═╡ 3ee399d2-40fd-4994-b98b-7cb81c2fbf0e
function scenario_b2(;
    max_load=3.50,
    nodes=(4, 100),
    rate=0.01,
    j=job(0, 1, rand(1:4), 4, 0)
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
            i ≤ π1 && push!(_requests, KuMo.Request(job(1., 1, rand(1:4), 3.25, 2.), t))
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
        users=[
            # user 1
            user(KuMo.Requests(_requests), rand(1:4)),
		],
	    links=[
	    	(1, 2, 200.0), (2, 3, 200.0), (3, 4, 200.0), (4, 1, 200.0),
	        (2, 1, 200.0), (3, 2, 200.0), (4, 3, 200.0), (1, 4, 200.0),
	    ],
    )
end

# ╔═╡ 6e597df8-6b06-4ef8-8f9f-212f72022f48
# ╠═╡ show_logs = false
pb2, dfb2 = simulate_and_plot(scenario_b2(), ShortestPath()); pb2

# ╔═╡ 8fb3400b-bd36-4cb4-a466-3b7f75c07e6b
begin
	figures_b = [
		pb1 => "square_long-duration.pdf",
		pb2 => "square_aperiodic_multiplicative.pdf",
	]
	foreach(p -> savefig(p.first, p.second), figures_b)
end

# ╔═╡ 21fc0470-2c99-45fb-a3d2-e9cd40b01835
md"""
## Complex Scenarii
"""

# ╔═╡ dbd801ce-d8fe-4d68-9493-088295b4f663
function complex_network()
	g = Graph(4)
	add_edge!(g, 1, 3)
	add_edge!(g, 2, 3)
	add_edge!(g, 3, 4)
	add_edge!(g, 2, 4)
	p = TikzGraphs.plot(
		g,
		Layouts.Spring(),
		[L"v_1", L"v_2", L"v_3", L"v_4"],
		node_style="draw, rounded corners, fill=blue!10",
		node_styles=Dict(1=>"fill=green!10",2=>"fill=green!10"),
		edge_labels=Dict((1,3)=>"200", (2,3)=>"200", (3,4)=>"1000", (2,4)=>"200"),
		edge_styles=Dict((3,4)=>"blue"),
		options="scale=2",
	)
	return p
end

# ╔═╡ 22f9488e-73c4-4d0b-8d42-abd654b99795
function scenario_c1()
	# backend - containers - data_center - duration - frontend
	j = job(2, 1, 4, 3, 1)

    _requests = Vector{KuMo.Request{typeof(j)}}()

    # L = 1000
    r = 0.01
    λ = 50
    n = 1
    δ = j.duration
    # c = j.containers

    π1 = λ / r
    π2 = (2n - λ) / r

    for i in 0:π1+π2
        for t in i:δ:π1+π2-i
            i ≤ π1 && push!(_requests, KuMo.Request(j, t))
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
		],
	    links=[
	    	(1, 3, 200.0), (2, 3, 200.0), (3, 4, 1000.0), (4, 2, 200.0),
	        (3, 1, 200.0), (3, 2, 200.0), (4, 3, 1000.0), (2, 4, 200.0),
	    ],
    )
end

# ╔═╡ 4541deee-dfa5-462c-a797-b221637baf64
complex_network()

# ╔═╡ 2a9aadf8-cbd3-43ab-b8a6-14025d551208
# ╠═╡ show_logs = false
pc1, dfc1 = simulate_and_plot(scenario_c1(), ShortestPath()); pc1

# ╔═╡ a61fb19f-3e94-4097-844f-72ec845d55b2
function scenario_c2()
	# backend - containers - data_center - duration - frontend
	j = job(1, 1, 4, 3, 2)

    _requests = Vector{KuMo.Request{typeof(j)}}()

    # L = 1000
    r = 0.01
    λ = 50
    n = 1
    δ = j.duration
    # c = j.containers

    π1 = λ / r
    π2 = (2n - λ) / r

    for i in 0:π1+π2
        for t in i:δ:π1+π2-i
            i ≤ π1 && push!(_requests, KuMo.Request(j, t))
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
		],
	    links=[
	    	(1, 3, 200.0), (2, 3, 200.0), (3, 4, 1000.0), (4, 2, 200.0),
	        (3, 1, 200.0), (3, 2, 200.0), (4, 3, 1000.0), (2, 4, 200.0),
	    ],
    )
end

# ╔═╡ 6cc00479-e1d3-4b88-a0b6-28a50d12d610
complex_network()

# ╔═╡ ba99d317-87ae-4405-9237-f60748cec26f
# ╠═╡ show_logs = false
pc2, dfc2 = simulate_and_plot(scenario_c2(), ShortestPath()); pc2

# ╔═╡ fda02e26-8425-4ceb-93e5-7101b7acb8be
complex_network()

# ╔═╡ b8b4ebbe-0443-4471-b062-4605e4504702
function scenario_c3()
	# backend - containers - data_center - duration - frontend
	j1 = job(1, 3, 4, 4, 2)
	j2 = job(2, 3, 3, 4, 1)

    reqs1 = Vector{KuMo.Request{typeof(j1)}}()
    reqs2 = Vector{KuMo.Request{typeof(j2)}}()

    # L = 1000
    r = 0.01
    λ = 1
    n = 1
    δ = j1.duration
    # c = j.containers

    π1 = λ / r
    π2 = (2n - λ) / r

    for i in 0:π1+π2
        for t in i:δ:π1+π2-i
            i ≤ π1 && push!(reqs1, KuMo.Request(j1, t))
            i ≤ π1 && push!(reqs2, KuMo.Request(j2, t))
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
            user(reqs1, 1),
            user(reqs2, 2),
			
		],
	    links=[
	    	(1, 3, 200.0), (2, 3, 200.0), (3, 4, 1000.0), (4, 2, 200.0),
	        (3, 1, 200.0), (3, 2, 200.0), (4, 3, 1000.0), (2, 4, 200.0),
	    ],
    )
end

# ╔═╡ 13e635db-a044-4c30-8643-8a0d34880488
# ╠═╡ show_logs = false
pc3, dfc3 = simulate_and_plot(scenario_c3(), ShortestPath()); pc3

# ╔═╡ b4730f03-6d61-45cb-8a8b-27372b087ddc
complex_network()

# ╔═╡ 244b96f0-9e91-4d5e-9da3-094e9215f475
function scenario_c4()
	scenario(;
        duration=10,
        nodes=[
			Node(100),
			Node(100),
			Node(1000),
			Node(1000),
		],
        links=[
	    	(1, 3, 200.0), (2, 3, 200.0), (3, 4, 1000.0), (4, 2, 200.0),
	        (3, 1, 200.0), (3, 2, 200.0), (4, 3, 1000.0), (2, 4, 200.0),
        ],
        users=100,
        job_distribution=Dict(
            :backend => 1:10,
            :container => 1:3,
            :data_location => 3:4,
            :duration => 1:5,
            :frontend => 1:2,
        ),
        request_rate=0.5
    )
end

# ╔═╡ 5a0dad14-0f30-4623-9e6e-4053ca818606
# ╠═╡ show_logs = false
pc4, dfc4 = simulate_and_plot(scenario_c4(), ShortestPath()); pc4

# ╔═╡ 22f080a3-eb4b-4c02-88e4-d301f4b97a85
CSV.write("complex4.csv", dfc4);

# ╔═╡ c0b1feb5-7aec-4310-8c55-c2350ce005f8
vcat(rand(2), rand(3))

# ╔═╡ ec276414-bd4e-4536-9307-ce773d49306e
function scenario_c5()
	duration = 100
	
	local_dc = 9:16
	large_dc = 17:18
	all_dc = 9:18

	users_loc = 1:8

	spike(j, t, intensity) = fill(Request(j, t), (intensity,))
	
	function smooth(j, δ, π1, π2)
		reqs = Vector{KuMo.Request{typeof(j)}}()
		for i in 0:π1+π2
	        for t in i:δ:π1+π2-i
	            i ≤ π1 && push!(reqs, KuMo.Request(j, t))
	        end
	    end
		return reqs
	end

	function steady(j, δ, π1, π2, intensity)
		reqs = Vector{KuMo.Request{typeof(j)}}()
		for t in 0:δ:π1+π2
			foreach(_ -> push!(reqs, KuMo.Request(j, t)), 1:intensity)
	    end
		return reqs
	end

	interactive() = job(1, 5, rand(all_dc), 10, 2)
	data_intensive() = job(5, 10, rand(all_dc), 10, 1)

	users = Vector{KuMo.User}()
	for i in 1:2:24
		reqs = Vector{Request{<:KuMo.AbstractJob}}()
		rang = sort!(rand(0:duration, 2))
		bounds = rang[1]:rang[2]
		types = Set()
		for _ in 1:(i % 8 + 1)
			j = rand([interactive, data_intensive])()
			push!(types, typeof(j))
			kind = rand([:spike, :smooth, :steady])
			if kind == :spike
				t = Float64(rand(bounds))
				intensity = rand(1:100)
				req = spike(j, t, intensity)
				reqs = vcat(reqs, req)
			elseif kind == :smooth
				inners = sort!(rand(bounds, 2))
				π1, π2 = inners[1], inners[2]
				req = smooth(j, j.duration, π1, π2)
				reqs = vcat(reqs, req)
			else
				inners = sort!(rand(bounds, 2))
				π1, π2 = inners[1], inners[2]				
				intensity = rand(1:10)
				req = steady(j, j.duration, π1, π2, intensity)
				reqs = vcat(reqs, req)
			end
		end
		UT = Union{collect(types)...}
		R = Vector{Request{UT}}()
		foreach(r -> push!(R, r), reqs)
		u = user(requests(R), i % 8 + 1)
		push!(users, u)		
	end

	scenario(;
        duration,
        nodes=[
			Node(100),
			Node(100),
			Node(100),
			Node(100),
			Node(100),
			Node(100),
			Node(100),
			Node(100),
			Node(500),
			Node(500),
			Node(500),
			Node(500),
			Node(500),
			Node(500),
			Node(500),
			Node(500),
			Node(5000),
			Node(5000),
		],
        links=[
			# MDC <-> DC
	    	(1, 9, 500.0),
	    	(2, 10, 500.0),
	    	(3, 11, 500.0),
	    	(4, 12, 500.0),
	    	(5, 13, 500.0),
	    	(6, 14, 500.0),
	    	(7, 15, 500.0),
	    	(8, 16, 500.0),
			(9, 1, 500.0),
			(10, 2, 500.0),
			(11, 3, 500.0),
			(12, 4, 500.0),
			(13, 5, 500.0),
			(14, 6, 500.0),
			(15, 7, 500.0),
			(16, 8, 500.0),
			# DC <-> DC
	    	(10, 9, 1000.0), (9, 10, 1000.0),
	    	(11, 10, 1000.0), (10, 11, 1000.0),
	    	(12, 11, 1000.0), (11, 12, 1000.0),
	    	(13, 12, 1000.0), (12, 13, 1000.0),
	    	(14, 13, 1000.0), (13, 14, 1000.0),
	    	(15, 14, 1000.0), (14, 15, 1000.0),
	    	(16, 15, 1000.0), (15, 16, 1000.0),
	    	(9, 16, 1000.0), (16, 9, 1000.0),
			# LargeDC <-> DC			
	    	(10, 17, 2000.0), (17, 10, 2000.0),
	    	(12, 17, 2000.0), (17, 12, 2000.0),
	    	(14, 17, 2000.0), (17, 14, 2000.0),
	    	(16, 17, 2000.0), (17, 16, 2000.0),
	    	(10, 18, 2000.0), (18, 10, 2000.0),
	    	(12, 18, 2000.0), (18, 12, 2000.0),
	    	(14, 18, 2000.0), (18, 14, 2000.0),
	    	(16, 18, 2000.0), (18, 16, 2000.0),
			# LargeDC <-> DC			
	    	(17, 18, 10000.0), (18, 17, 10000.0),		
        ],
        users = users,
    )
end

# ╔═╡ 4873983b-17e6-4889-8954-4989cc3923f5
# ╠═╡ show_logs = false
begin
	s = scenario_c5()
	
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
			3=>"fill=green!10",
			4=>"fill=green!10",
			5=>"fill=green!10",
			6=>"fill=green!10",
			7=>"fill=green!10",
			8=>"fill=green!10",
			17=>"fill=red!10",
			18=>"fill=red!10",
		),
		# edge_labels=capacities,
		# edge_styles=Dict((3,4)=>"blue"),
		options="scale=.1",
	)
	TikzPictures.save(PDF("3levelsnetwork"), t)
	t
end

# ╔═╡ dfc5b22a-5989-4912-a18b-719803ddcbd4
# ╠═╡ show_logs = false
pc5, dfc5 = simulate_and_plot(scenario_c5(), ShortestPath()); pc5

# ╔═╡ e23ae61e-f755-4cfc-8a57-b4cba9e47534
function scenario_c6()
	duration = 100
	
	local_dc = 9:16
	large_dc = 17:18
	all_dc = 9:18

	users_loc = 1:8

	spike(j, t, intensity) = fill(Request(j, t), (intensity,))
	
	function smooth(j, δ, π1, π2)
		reqs = Vector{KuMo.Request{typeof(j)}}()
		for i in 0:π1+π2
	        for t in i:δ:π1+π2-i
	            i ≤ π1 && push!(reqs, KuMo.Request(j, t))
	        end
	    end
		return reqs
	end

	function steady(j, δ, π1, π2, intensity)
		reqs = Vector{KuMo.Request{typeof(j)}}()
		for t in 0:δ:π1+π2
			foreach(_ -> push!(reqs, KuMo.Request(j, t)), 1:intensity)
	    end
		return reqs
	end

	interactive() = job(1, 5, rand(all_dc), 10, 2)
	data_intensive() = job(5, 10, rand(all_dc), 10, 1)

	users = Vector{KuMo.User}()
	for i in 1:8
		reqs = Vector{Request{<:KuMo.AbstractJob}}()
		rang = sort!(rand(0:duration, 2))
		bounds = rang[1]:rang[2]
		types = Set()
		for _ in 1:(i % 8 + 1)
			j = rand([interactive, data_intensive])()
			push!(types, typeof(j))
			kind = rand([:spike, :smooth, :steady])
			if kind == :spike
				t = Float64(rand(bounds))
				intensity = rand(1:100)
				req = spike(j, t, intensity)
				reqs = vcat(reqs, req)
			elseif kind == :smooth
				inners = sort!(rand(bounds, 2))
				π1, π2 = inners[1], inners[2]
				req = smooth(j, j.duration, π1, π2)
				reqs = vcat(reqs, req)
			else
				inners = sort!(rand(bounds, 2))
				π1, π2 = inners[1], inners[2]				
				intensity = rand(1:10)
				req = steady(j, j.duration, π1, π2, intensity)
				reqs = vcat(reqs, req)
			end
		end
		UT = Union{collect(types)...}
		R = Vector{Request{UT}}()
		foreach(r -> push!(R, r), reqs)
		u = user(requests(R), i % 8 + 1)
		push!(users, u)		
	end

	scenario(;
        duration,
        nodes=[
			Node(100),
			Node(100),
			Node(100),
			Node(100),
			Node(100),
			Node(100),
			Node(100),
			Node(100),
			Node(500),
			Node(500),
			Node(500),
			Node(500),
			Node(500),
			Node(500),
			Node(500),
			Node(500),
			Node(5000),
			Node(5000),
		],
        links=[
			# MDC <-> DC
	    	(1, 9, 500.0),
	    	(2, 10, 500.0),
	    	(3, 11, 500.0),
	    	(4, 12, 500.0),
	    	(5, 13, 500.0),
	    	(6, 14, 500.0),
	    	(7, 15, 500.0),
	    	(8, 16, 500.0),
			(9, 1, 500.0),
			(10, 2, 500.0),
			(11, 3, 500.0),
			(12, 4, 500.0),
			(13, 5, 500.0),
			(14, 6, 500.0),
			(15, 7, 500.0),
			(16, 8, 500.0),
			# DC <-> DC
	    	(10, 9, 1000.0), (9, 10, 1000.0),
	    	(11, 10, 1000.0), (10, 11, 1000.0),
	    	(12, 11, 1000.0), (11, 12, 1000.0),
	    	(13, 12, 1000.0), (12, 13, 1000.0),
	    	(14, 13, 1000.0), (13, 14, 1000.0),
	    	(15, 14, 1000.0), (14, 15, 1000.0),
	    	(16, 15, 1000.0), (15, 16, 1000.0),
	    	(9, 16, 1000.0), (16, 9, 1000.0),
			# LargeDC <-> DC			
	    	(10, 17, 2000.0), (17, 10, 2000.0),
	    	(12, 17, 2000.0), (17, 12, 2000.0),
	    	(14, 17, 2000.0), (17, 14, 2000.0),
	    	(16, 17, 2000.0), (17, 16, 2000.0),
	    	(10, 18, 2000.0), (18, 10, 2000.0),
	    	(12, 18, 2000.0), (18, 12, 2000.0),
	    	(14, 18, 2000.0), (18, 14, 2000.0),
	    	(16, 18, 2000.0), (18, 16, 2000.0),
			# LargeDC <-> DC			
	    	(17, 18, 10000.0), (18, 17, 10000.0),		
        ],
        users = users,
    )
end

# ╔═╡ f3e65a88-87f1-4619-87f6-d196dfd96305
# ╠═╡ show_logs = false
pc6, dfc6 = simulate_and_plot(scenario_c6(), ShortestPath()); pc6

# ╔═╡ 46e86b8e-2fba-4f16-bc71-91e1c05b00fd
function scenario_c7()
	duration = 100
	
	local_dc = 9:16
	large_dc = 17:18
	all_dc = 9:18

	users_loc = 1:8

	interactive() = job(1, 5, rand(all_dc), 10, 2)
	data_intensive() = job(5, 10, rand(local_dc), 10, 1)

	jobs = [data_intensive() for _ in 1:23]
	types = Set()
	reqs = Vector()
	for j in jobs
		push!(types, typeof(j))
		reqs = vcat(reqs, steady(j, j.duration, 1, 150, 15))
		reqs = vcat(reqs, steady(j, j.duration, 201, 800, 15))
	end
	j = data_intensive()
	push!(types, typeof(j))
	# reqs = vcat(reqs, Request(j, 200.))
	# reqs = vcat(reqs, Request(j, 1000.))
	reqs = vcat(reqs, spike(j, 250., 1000))
	UT = Union{collect(types)...}
	R = Vector{Request{UT}}()
	foreach(r -> push!(R, r), reqs)
	user1 = user(requests(R), 1)

	jobs = [data_intensive() for _ in 1:23]
	types = Set()
	reqs = Vector()
	for j in jobs
		push!(types, typeof(j))
		reqs = vcat(reqs, steady(j, j.duration, 51, 150, 15))
		reqs = vcat(reqs, steady(j, j.duration, 401, 800, 15))
	end
	j = data_intensive()
	push!(types, typeof(j))
	reqs = vcat(reqs, spike(j, 450., 1000))
	UT = Union{collect(types)...}
	R = Vector{Request{UT}}()
	foreach(r -> push!(R, r), reqs)
	user2 = user(requests(R), 2)

	jobs = [data_intensive() for _ in 1:23]
	types = Set()
	reqs = Vector()
	for j in jobs
		push!(types, typeof(j))
		reqs = vcat(reqs, steady(j, j.duration, 101, 150, 15))
		reqs = vcat(reqs, steady(j, j.duration, 601, 800, 15))
	end
	j = data_intensive()
	push!(types, typeof(j))
	reqs = vcat(reqs, spike(j, 650., 1000))
	UT = Union{collect(types)...}
	R = Vector{Request{UT}}()
	foreach(r -> push!(R, r), reqs)
	user3 = user(requests(R), 3)
	
	s1 = scenario(;
        duration,
        nodes=[
			Node(100),
			Node(100),
			Node(100),
			Node(100),
			Node(100),
			Node(100),
			Node(100),
			Node(100),
			Node(500),
			Node(500),
			Node(500),
			Node(500),
			Node(500),
			Node(500),
			Node(500),
			Node(500),
			Node(5000),
			Node(5000),
		],
        links=[
			# MDC <-> DC
	    	(1, 9, 500.0),
	    	(2, 10, 500.0),
	    	(3, 11, 500.0),
	    	(4, 12, 500.0),
	    	(5, 13, 500.0),
	    	(6, 14, 500.0),
	    	(7, 15, 500.0),
	    	(8, 16, 500.0),
			(9, 1, 500.0),
			(10, 2, 500.0),
			(11, 3, 500.0),
			(12, 4, 500.0),
			(13, 5, 500.0),
			(14, 6, 500.0),
			(15, 7, 500.0),
			(16, 8, 500.0),
			# DC <-> DC
	    	(10, 9, 1000.0), (9, 10, 1000.0),
	    	(11, 10, 1000.0), (10, 11, 1000.0),
	    	(12, 11, 1000.0), (11, 12, 1000.0),
	    	(13, 12, 1000.0), (12, 13, 1000.0),
	    	(14, 13, 1000.0), (13, 14, 1000.0),
	    	(15, 14, 1000.0), (14, 15, 1000.0),
	    	(16, 15, 1000.0), (15, 16, 1000.0),
	    	(9, 16, 1000.0), (16, 9, 1000.0),
			# LargeDC <-> DC			
	    	(10, 17, 2000.0), (17, 10, 2000.0),
	    	(12, 17, 2000.0), (17, 12, 2000.0),
	    	(14, 17, 2000.0), (17, 14, 2000.0),
	    	(16, 17, 2000.0), (17, 16, 2000.0),
	    	(10, 18, 2000.0), (18, 10, 2000.0),
	    	(12, 18, 2000.0), (18, 12, 2000.0),
	    	(14, 18, 2000.0), (18, 14, 2000.0),
	    	(16, 18, 2000.0), (18, 16, 2000.0),
			# LargeDC <-> DC			
	    	(17, 18, 10000.0), (18, 17, 10000.0),		
        ],
        users = [
			user1,
			user2,
			user3,
		],
    )

	s2 = scenario(;
        duration,
        nodes=[
			Node(100),
			Node(100),
			Node(100),
			Node(100),
			Node(100),
			Node(100),
			Node(100),
			Node(100),
			Node(500),
			Node(500),
			Node(500),
			Node(500),
			Node(500),
			Node(500),
			Node(500),
			Node(500),
			Node(5000),
			Node(5000),
		],
        links=(
			ConvexLink,
			[
				# MDC <-> DC
		    	(1, 9, 500.0),
		    	(2, 10, 500.0),
		    	(3, 11, 500.0),
		    	(4, 12, 500.0),
		    	(5, 13, 500.0),
		    	(6, 14, 500.0),
		    	(7, 15, 500.0),
		    	(8, 16, 500.0),
				(9, 1, 500.0),
				(10, 2, 500.0),
				(11, 3, 500.0),
				(12, 4, 500.0),
				(13, 5, 500.0),
				(14, 6, 500.0),
				(15, 7, 500.0),
				(16, 8, 500.0),
				# DC <-> DC
		    	(10, 9, 1000.0), (9, 10, 1000.0),
		    	(11, 10, 1000.0), (10, 11, 1000.0),
		    	(12, 11, 1000.0), (11, 12, 1000.0),
		    	(13, 12, 1000.0), (12, 13, 1000.0),
		    	(14, 13, 1000.0), (13, 14, 1000.0),
		    	(15, 14, 1000.0), (14, 15, 1000.0),
		    	(16, 15, 1000.0), (15, 16, 1000.0),
		    	(9, 16, 1000.0), (16, 9, 1000.0),
				# LargeDC <-> DC			
		    	(10, 17, 5000.0), (17, 10, 5000.0),
		    	(12, 17, 5000.0), (17, 12, 5000.0),
		    	(14, 17, 5000.0), (17, 14, 5000.0),
		    	(16, 17, 5000.0), (17, 16, 5000.0),
		    	(10, 18, 5000.0), (18, 10, 5000.0),
		    	(12, 18, 5000.0), (18, 12, 5000.0),
		    	(14, 18, 5000.0), (18, 14, 5000.0),
		    	(16, 18, 5000.0), (18, 16, 5000.0),
				# LargeDC <-> DC			
		    	(17, 18, 10000.0), (18, 17, 10000.0),		
	        ]
		),
        users = [
			user1,
			user2,
			user3,
		],
    )

		s3 = scenario(;
        duration,
        nodes=[
			EqualLoadBalancingNode(100),
			EqualLoadBalancingNode(100),
			EqualLoadBalancingNode(100),
			EqualLoadBalancingNode(100),
			EqualLoadBalancingNode(100),
			EqualLoadBalancingNode(100),
			EqualLoadBalancingNode(100),
			EqualLoadBalancingNode(100),
			EqualLoadBalancingNode(500),
			EqualLoadBalancingNode(500),
			EqualLoadBalancingNode(500),
			EqualLoadBalancingNode(500),
			EqualLoadBalancingNode(500),
			EqualLoadBalancingNode(500),
			EqualLoadBalancingNode(500),
			EqualLoadBalancingNode(500),
			EqualLoadBalancingNode(5000),
			EqualLoadBalancingNode(5000),
		],
        links=(
			ConvexLink,
			[
				# MDC <-> DC
		    	(1, 9, 500.0),
		    	(2, 10, 500.0),
		    	(3, 11, 500.0),
		    	(4, 12, 500.0),
		    	(5, 13, 500.0),
		    	(6, 14, 500.0),
		    	(7, 15, 500.0),
		    	(8, 16, 500.0),
				(9, 1, 500.0),
				(10, 2, 500.0),
				(11, 3, 500.0),
				(12, 4, 500.0),
				(13, 5, 500.0),
				(14, 6, 500.0),
				(15, 7, 500.0),
				(16, 8, 500.0),
				# DC <-> DC
		    	(10, 9, 1000.0), (9, 10, 1000.0),
		    	(11, 10, 1000.0), (10, 11, 1000.0),
		    	(12, 11, 1000.0), (11, 12, 1000.0),
		    	(13, 12, 1000.0), (12, 13, 1000.0),
		    	(14, 13, 1000.0), (13, 14, 1000.0),
		    	(15, 14, 1000.0), (14, 15, 1000.0),
		    	(16, 15, 1000.0), (15, 16, 1000.0),
		    	(9, 16, 1000.0), (16, 9, 1000.0),
				# LargeDC <-> DC			
		    	(10, 17, 5000.0), (17, 10, 5000.0),
		    	(12, 17, 5000.0), (17, 12, 5000.0),
		    	(14, 17, 5000.0), (17, 14, 5000.0),
		    	(16, 17, 5000.0), (17, 16, 5000.0),
		    	(10, 18, 5000.0), (18, 10, 5000.0),
		    	(12, 18, 5000.0), (18, 12, 5000.0),
		    	(14, 18, 5000.0), (18, 14, 5000.0),
		    	(16, 18, 5000.0), (18, 16, 5000.0),
				# LargeDC <-> DC			
		    	(17, 18, 10000.0), (18, 17, 10000.0),		
	        ]
		),
        users = [
			user1,
			user2,
			user3,
		],
    )
	return s1, s2, s3
end

# ╔═╡ c633899f-5719-44c8-ba8f-a71cdb2c3ab2
s7, s8, s9 = scenario_c7();

# ╔═╡ 545262b9-fc38-4ea6-b3a6-90e8b96584a3
# ╠═╡ show_logs = false
pc7, dfc7 = simulate_and_plot(s7, ShortestPath()); pc7

# ╔═╡ dbbcc0fe-7019-4d40-b477-3ba76b687cb6
pc7_nodes_areas = plot_nodes(dfc7; kind = :areaplot)

# ╔═╡ 29294762-c083-4461-a3cf-0789972b97a8
pc7_nodes_lines = plot_nodes(dfc7; kind = :plot)

# ╔═╡ 91f5a063-d799-46c6-888e-7112f80435e9
pc7_links_areas = plot_links(dfc7; kind = :areaplot)

# ╔═╡ 083b99e2-cafb-465c-9da1-c4c325ff6038
pc7_links_lines = plot_links(dfc7; kind = :plot)

# ╔═╡ 4aac2e0b-2b6c-4845-a7a9-92ef60f5a0ba
# ╠═╡ show_logs = false
pc8, dfc8 = simulate_and_plot(s8, ShortestPath()); pc8

# ╔═╡ 640e31ac-f2a3-4036-a064-618e840dc009
pc8_nodes_areas = plot_nodes(dfc8; kind = :areaplot)

# ╔═╡ 8881283e-93a8-4aa0-b0cf-39bf501b5847
pc8_nodes_lines = plot_nodes(dfc8; kind = :plot)

# ╔═╡ ceef39d0-185e-496f-a2c1-9bffd3c1f619
pc8_links_areas = plot_links(dfc8; kind = :areaplot)

# ╔═╡ fb370e9f-65c3-44e9-b30e-3efd778b345a
pc8_links_lines = plot_links(dfc8; kind = :plot)

# ╔═╡ 53ef9168-042d-48b5-bcda-61b77db1000c
# ╠═╡ show_logs = false
pc9, dfc9 = simulate_and_plot(s9, ShortestPath()); pc9

# ╔═╡ a1047cd7-5683-4d37-91db-daec3ee7ddb4
pc9_nodes_areas = plot_nodes(dfc9; kind = :areaplot)

# ╔═╡ dc9885c4-f003-4f25-ab30-0cccbb855f9f
pc9_nodes_lines = plot_nodes(dfc9; kind = :plot)

# ╔═╡ 8140f3c6-b711-469b-9d71-33fcb9361e91
pc9_links_areas = plot_links(dfc9; kind = :areaplot)

# ╔═╡ 722eb58c-aa69-4371-b737-fcead002aa51
pc9_links_lines = plot_links(dfc9; kind = :plot)

# ╔═╡ 92d177a0-3389-4da2-934c-a93d4311bd4a
# ╠═╡ show_logs = false
begin
	figures_c = [
		pc1 => "complex1.pdf",
		pc2 => "complex2.pdf",
		pc3 => "complex3.pdf",
		pc4 => "complex4.pdf",
		pc5 => "complex5.pdf",
		pc6 => "complex6.pdf",
		pc7 => "complex7.pdf",
		pc7_nodes_lines => "complex7_nodes_lines.pdf",
		pc7_nodes_areas => "complex7_nodes_areas.pdf",
		pc7_links_lines => "complex7_links_lines.pdf",
		pc7_links_areas => "complex7_links_areas.pdf",
		pc8 => "complex8.pdf",
		pc8_nodes_lines => "complex8_nodes_lines.pdf",
		pc8_nodes_areas => "complex8_nodes_areas.pdf",
		pc8_links_lines => "complex8_links_lines.pdf",
		pc8_links_areas => "complex8_links_areas.pdf",
		pc9 => "complex9.pdf",
		pc9_nodes_lines => "complex9_nodes_lines.pdf",
		pc9_nodes_areas => "complex9_nodes_areas.pdf",
		pc9_links_lines => "complex9_links_lines.pdf",
		pc9_links_areas => "complex9_links_areas.pdf",
	]
	foreach(p -> savefig(p.first, p.second), figures_c)
	TikzPictures.save(PDF("complex_network"), complex_network())
	CSV.write("complex7.csv", dfc7)
	CSV.write("complex8.csv", dfc8)
	CSV.write("complex9.csv", dfc9)
end;

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
CSV = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
Distributions = "31c24e10-a181-5473-b8eb-7969acd0382f"
Graphs = "86223c79-3864-5bf0-83f7-82e725a168b6"
KuMo = "b681f84e-bd48-4deb-8595-d3e0ff1e4a55"
LaTeXStrings = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
PGFPlotsX = "8314cec4-20b6-5062-9cdb-752b83310925"
StatsPlots = "f3b207a7-027a-5e70-b257-86293d7955fd"
TikzGraphs = "b4f28e30-c73f-5eaf-a395-8a9db949a742"
TikzPictures = "37f6aa50-8035-52d0-81c2-5a1d08754b2d"

[compat]
CSV = "~0.10.4"
DataFrames = "~1.3.4"
Distributions = "~0.25.62"
Graphs = "~1.7.1"
KuMo = "~0.1.23"
LaTeXStrings = "~1.3.0"
PGFPlotsX = "~1.5.0"
StatsPlots = "~0.14.34"
TikzGraphs = "~1.4.0"
TikzPictures = "~3.4.2"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.8.0-rc1"
manifest_format = "2.0"
project_hash = "15cf7b4145ecc6ab180ec05023b3b88f075a2780"

[[deps.AbstractFFTs]]
deps = ["ChainRulesCore", "LinearAlgebra"]
git-tree-sha1 = "6f1d9bc1c08f9f4a8fa92e3ea3cb50153a1b40d4"
uuid = "621f4979-c628-5d54-868e-fcf4e3e8185c"
version = "1.1.0"

[[deps.Adapt]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "af92965fb30777147966f58acb05da51c5616b5f"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.3.3"

[[deps.ArgCheck]]
git-tree-sha1 = "a3a402a35a2f7e0b87828ccabbd5ebfbebe356b4"
uuid = "dce04be8-c92d-5529-be00-80e4d2c0e197"
version = "2.3.0"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.ArnoldiMethod]]
deps = ["LinearAlgebra", "Random", "StaticArrays"]
git-tree-sha1 = "62e51b39331de8911e4a7ff6f5aaf38a5f4cc0ae"
uuid = "ec485272-7323-5ecc-a04f-4719b315124d"
version = "0.2.0"

[[deps.Arpack]]
deps = ["Arpack_jll", "Libdl", "LinearAlgebra", "Logging"]
git-tree-sha1 = "91ca22c4b8437da89b030f08d71db55a379ce958"
uuid = "7d9fca2a-8960-54d3-9f78-7d1dccf2cb97"
version = "0.5.3"

[[deps.Arpack_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "OpenBLAS_jll", "Pkg"]
git-tree-sha1 = "5ba6c757e8feccf03a1554dfaf3e26b3cfc7fd5e"
uuid = "68821587-b530-5797-8361-c406ea357684"
version = "3.5.1+1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.AxisAlgorithms]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "WoodburyMatrices"]
git-tree-sha1 = "66771c8d21c8ff5e3a93379480a2307ac36863f7"
uuid = "13072b0f-2c55-5437-9ae7-d433b7a33950"
version = "1.0.1"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.BenchmarkTools]]
deps = ["JSON", "Logging", "Printf", "Profile", "Statistics", "UUIDs"]
git-tree-sha1 = "4c10eee4af024676200bc7752e536f858c6b8f93"
uuid = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
version = "1.3.1"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "19a35467a82e236ff51bc17a3a44b69ef35185a2"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.8+0"

[[deps.CSV]]
deps = ["CodecZlib", "Dates", "FilePathsBase", "InlineStrings", "Mmap", "Parsers", "PooledArrays", "SentinelArrays", "Tables", "Unicode", "WeakRefStrings"]
git-tree-sha1 = "873fb188a4b9d76549b81465b1f75c82aaf59238"
uuid = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
version = "0.10.4"

[[deps.Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "4b859a208b2397a7a623a03449e4636bdb17bcf2"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.16.1+1"

[[deps.Calculus]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "f641eb0a4f00c343bbc32346e1217b86f3ce9dad"
uuid = "49dc2e85-a5d0-5ad3-a950-438e2897f1b9"
version = "0.5.1"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "9489214b993cd42d17f44c36e359bf6a7c919abf"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.15.0"

[[deps.ChangesOfVariables]]
deps = ["ChainRulesCore", "LinearAlgebra", "Test"]
git-tree-sha1 = "1e315e3f4b0b7ce40feded39c73049692126cf53"
uuid = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
version = "0.1.3"

[[deps.Clustering]]
deps = ["Distances", "LinearAlgebra", "NearestNeighbors", "Printf", "SparseArrays", "Statistics", "StatsBase"]
git-tree-sha1 = "75479b7df4167267d75294d14b58244695beb2ac"
uuid = "aaaa29a8-35af-508c-8bc3-b662a17a0fe5"
version = "0.14.2"

[[deps.CodecBzip2]]
deps = ["Bzip2_jll", "Libdl", "TranscodingStreams"]
git-tree-sha1 = "2e62a725210ce3c3c2e1a3080190e7ca491f18d7"
uuid = "523fee87-0ab8-5b00-afb7-3ecf72e48cfd"
version = "0.7.2"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "ded953804d019afa9a3f98981d99b33e3db7b6da"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.0"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "ColorVectorSpace", "Colors", "FixedPointNumbers", "Random"]
git-tree-sha1 = "1fd869cc3875b57347f7027521f561cf46d1fcd8"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.19.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "eb7f0f8307f71fac7c606984ea5fb2817275d6e4"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.4"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "SpecialFunctions", "Statistics", "TensorCore"]
git-tree-sha1 = "d08c20eef1f2cbc6e60fd3612ac4340b89fea322"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.9.9"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "417b0ed7b8b838aa6ca0a87aadf1bb9eb111ce40"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.8"

[[deps.CommonSubexpressions]]
deps = ["MacroTools", "Test"]
git-tree-sha1 = "7b8a93dba8af7e3b42fecabf646260105ac373f7"
uuid = "bbf7d656-a473-5ed7-a52c-81e309532950"
version = "0.3.0"

[[deps.Compat]]
deps = ["Base64", "Dates", "DelimitedFiles", "Distributed", "InteractiveUtils", "LibGit2", "Libdl", "LinearAlgebra", "Markdown", "Mmap", "Pkg", "Printf", "REPL", "Random", "SHA", "Serialization", "SharedArrays", "Sockets", "SparseArrays", "Statistics", "Test", "UUIDs", "Unicode"]
git-tree-sha1 = "9be8be1d8a6f44b96482c8af52238ea7987da3e3"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "3.45.0"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "0.5.2+0"

[[deps.Contour]]
deps = ["StaticArrays"]
git-tree-sha1 = "9f02045d934dc030edad45944ea80dbd1f0ebea7"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.5.7"

[[deps.Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[deps.DataAPI]]
git-tree-sha1 = "fb5f5316dd3fd4c5e7c30a24d50643b73e37cd40"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.10.0"

[[deps.DataFrames]]
deps = ["Compat", "DataAPI", "Future", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrettyTables", "Printf", "REPL", "Reexport", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "daa21eb85147f72e41f6352a57fccea377e310a9"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.3.4"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "d1fff3a548102f48987a52a2e0d114fa97d730f0"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.13"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.DataValues]]
deps = ["DataValueInterfaces", "Dates"]
git-tree-sha1 = "d88a19299eba280a6d062e135a43f00323ae70bf"
uuid = "e7dc6d0d-1eca-5fa6-8ad6-5aecde8b7ea5"
version = "0.4.13"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DefaultApplication]]
deps = ["InteractiveUtils"]
git-tree-sha1 = "c0dfa5a35710a193d83f03124356eef3386688fc"
uuid = "3f0dd361-4fe0-5fc6-8523-80b14ec94d85"
version = "1.1.0"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[deps.DensityInterface]]
deps = ["InverseFunctions", "Test"]
git-tree-sha1 = "80c3e8639e3353e5d2912fb3a1916b8455e2494b"
uuid = "b429d917-457f-4dbc-8f4c-0cc954292b1d"
version = "0.4.0"

[[deps.Dictionaries]]
deps = ["Indexing", "Random"]
git-tree-sha1 = "7669d53b75e9f9e2fa32d5215cb2af348b2c13e2"
uuid = "85a47980-9c8c-11e8-2b9f-f7ca1fa99fb4"
version = "0.3.21"

[[deps.DiffResults]]
deps = ["StaticArrays"]
git-tree-sha1 = "c18e98cba888c6c25d1c3b048e4b3380ca956805"
uuid = "163ba53b-c6d8-5494-b064-1a9d43ac40c5"
version = "1.0.3"

[[deps.DiffRules]]
deps = ["IrrationalConstants", "LogExpFunctions", "NaNMath", "Random", "SpecialFunctions"]
git-tree-sha1 = "28d605d9a0ac17118fe2c5e9ce0fbb76c3ceb120"
uuid = "b552c78f-8df3-52c6-915a-8e097449b14b"
version = "1.11.0"

[[deps.Distances]]
deps = ["LinearAlgebra", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "3258d0659f812acde79e8a74b11f17ac06d0ca04"
uuid = "b4f34e82-e78d-54a5-968a-f98e89d6e8f7"
version = "0.10.7"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.Distributions]]
deps = ["ChainRulesCore", "DensityInterface", "FillArrays", "LinearAlgebra", "PDMats", "Printf", "QuadGK", "Random", "SparseArrays", "SpecialFunctions", "Statistics", "StatsBase", "StatsFuns", "Test"]
git-tree-sha1 = "0ec161f87bf4ab164ff96dfacf4be8ffff2375fd"
uuid = "31c24e10-a181-5473-b8eb-7969acd0382f"
version = "0.25.62"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "b19534d1895d702889b219c382a6e18010797f0b"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.8.6"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.DrWatson]]
deps = ["Dates", "FileIO", "JLD2", "LibGit2", "MacroTools", "Pkg", "Random", "Requires", "Scratch", "UnPack"]
git-tree-sha1 = "67e9001646db6e45006643bf37716ecd831d37d2"
uuid = "634d3b9d-ee7a-5ddf-bec9-22491ea816e1"
version = "2.9.1"

[[deps.DualNumbers]]
deps = ["Calculus", "NaNMath", "SpecialFunctions"]
git-tree-sha1 = "5837a837389fccf076445fce071c8ddaea35a566"
uuid = "fa6b7ba4-c1ee-5f82-b5fc-ecf0adba8f74"
version = "0.6.8"

[[deps.EarCut_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "3f3a2501fa7236e9b911e0f7a588c657e822bb6d"
uuid = "5ae413db-bbd1-5e63-b57d-d24a61df00f5"
version = "2.2.3+0"

[[deps.Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "bad72f730e9e91c08d9427d5e8db95478a3c323d"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.4.8+0"

[[deps.FFMPEG]]
deps = ["FFMPEG_jll"]
git-tree-sha1 = "b57e3acbe22f8484b4b5ff66a7499717fe1a9cc8"
uuid = "c87230d0-a227-11e9-1b43-d7ebe4e7570a"
version = "0.4.1"

[[deps.FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "Pkg", "Zlib_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "d8a578692e3077ac998b50c0217dfd67f21d1e5f"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "4.4.0+0"

[[deps.FFTW]]
deps = ["AbstractFFTs", "FFTW_jll", "LinearAlgebra", "MKL_jll", "Preferences", "Reexport"]
git-tree-sha1 = "90630efff0894f8142308e334473eba54c433549"
uuid = "7a1cc6ca-52ef-59f5-83cd-3a7055c09341"
version = "1.5.0"

[[deps.FFTW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c6033cc3892d0ef5bb9cd29b7f2f0331ea5184ea"
uuid = "f5851436-0d7a-5f13-b9de-f02708fd171a"
version = "3.3.10+0"

[[deps.FileIO]]
deps = ["Pkg", "Requires", "UUIDs"]
git-tree-sha1 = "9267e5f50b0e12fdfd5a2455534345c4cf2c7f7a"
uuid = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
version = "1.14.0"

[[deps.FilePathsBase]]
deps = ["Compat", "Dates", "Mmap", "Printf", "Test", "UUIDs"]
git-tree-sha1 = "129b104185df66e408edd6625d480b7f9e9823a0"
uuid = "48062228-2e41-5def-b9a4-89aafe57970f"
version = "0.9.18"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FillArrays]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "Statistics"]
git-tree-sha1 = "246621d23d1f43e3b9c368bf3b72b2331a27c286"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "0.13.2"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "21efd19106a55620a188615da6d3d06cd7f6ee03"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.13.93+0"

[[deps.Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[deps.ForwardDiff]]
deps = ["CommonSubexpressions", "DiffResults", "DiffRules", "LinearAlgebra", "LogExpFunctions", "NaNMath", "Preferences", "Printf", "Random", "SpecialFunctions", "StaticArrays"]
git-tree-sha1 = "2f18915445b248731ec5db4e4a17e451020bf21e"
uuid = "f6369f11-7733-5829-9624-2563aa707210"
version = "0.10.30"

[[deps.FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "87eb71354d8ec1a96d4a7636bd57a7347dde3ef9"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.10.4+0"

[[deps.FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "aa31987c2ba8704e23c6c8ba8a4f769d5d7e4f91"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.10+0"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.GLFW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libglvnd_jll", "Pkg", "Xorg_libXcursor_jll", "Xorg_libXi_jll", "Xorg_libXinerama_jll", "Xorg_libXrandr_jll"]
git-tree-sha1 = "51d2dfe8e590fbd74e7a842cf6d13d8a2f45dc01"
uuid = "0656b61e-2033-5cc2-a64a-77c0f6c09b89"
version = "3.3.6+0"

[[deps.GR]]
deps = ["Base64", "DelimitedFiles", "GR_jll", "HTTP", "JSON", "Libdl", "LinearAlgebra", "Pkg", "Printf", "Random", "RelocatableFolders", "Serialization", "Sockets", "Test", "UUIDs"]
git-tree-sha1 = "c98aea696662d09e215ef7cda5296024a9646c75"
uuid = "28b8d3ca-fb5f-59d9-8090-bfdbd6d07a71"
version = "0.64.4"

[[deps.GR_jll]]
deps = ["Artifacts", "Bzip2_jll", "Cairo_jll", "FFMPEG_jll", "Fontconfig_jll", "GLFW_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pixman_jll", "Pkg", "Qt5Base_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "3a233eeeb2ca45842fe100e0413936834215abf5"
uuid = "d2c73de3-f751-5644-a686-071e5b155ba9"
version = "0.64.4+0"

[[deps.GeometryBasics]]
deps = ["EarCut_jll", "IterTools", "LinearAlgebra", "StaticArrays", "StructArrays", "Tables"]
git-tree-sha1 = "83ea630384a13fc4f002b77690bc0afeb4255ac9"
uuid = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
version = "0.4.2"

[[deps.Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

[[deps.Glib_jll]]
deps = ["Artifacts", "Gettext_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "a32d672ac2c967f3deb8a81d828afc739c838a06"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.68.3+2"

[[deps.Graphite2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "344bf40dcab1073aca04aa0df4fb092f920e4011"
uuid = "3b182d85-2403-5c21-9c21-1e1f0cc25472"
version = "1.3.14+0"

[[deps.Graphs]]
deps = ["ArnoldiMethod", "Compat", "DataStructures", "Distributed", "Inflate", "LinearAlgebra", "Random", "SharedArrays", "SimpleTraits", "SparseArrays", "Statistics"]
git-tree-sha1 = "db5c7e27c0d46fd824d470a3c32a4fc6c935fa96"
uuid = "86223c79-3864-5bf0-83f7-82e725a168b6"
version = "1.7.1"

[[deps.Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[deps.HTTP]]
deps = ["Base64", "Dates", "IniFile", "Logging", "MbedTLS", "NetworkOptions", "Sockets", "URIs"]
git-tree-sha1 = "0fa77022fe4b511826b39c894c90daf5fce3334a"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "0.9.17"

[[deps.HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg"]
git-tree-sha1 = "129acf094d168394e80ee1dc4bc06ec835e510a3"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "2.8.1+1"

[[deps.HypergeometricFunctions]]
deps = ["DualNumbers", "LinearAlgebra", "SpecialFunctions", "Test"]
git-tree-sha1 = "cb7099a0109939f16a4d3b572ba8396b1f6c7c31"
uuid = "34004b35-14d8-5ef3-9330-4cdb6864b03a"
version = "0.3.10"

[[deps.Indexing]]
git-tree-sha1 = "ce1566720fd6b19ff3411404d4b977acd4814f9f"
uuid = "313cdc1a-70c2-5d6a-ae34-0150d3930a38"
version = "1.1.1"

[[deps.Inflate]]
git-tree-sha1 = "f5fc07d4e706b84f72d54eedcc1c13d92fb0871c"
uuid = "d25df0c9-e2be-5dd7-82c8-3ad0b3e990b9"
version = "0.1.2"

[[deps.IniFile]]
git-tree-sha1 = "f550e6e32074c939295eb5ea6de31849ac2c9625"
uuid = "83e8ac13-25f8-5344-8a64-a9f2b223428f"
version = "0.5.1"

[[deps.InlineStrings]]
deps = ["Parsers"]
git-tree-sha1 = "61feba885fac3a407465726d0c330b3055df897f"
uuid = "842dd82b-1e85-43dc-bf29-5d0ee9dffc48"
version = "1.1.2"

[[deps.IntelOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "d979e54b71da82f3a65b62553da4fc3d18c9004c"
uuid = "1d5cc7b8-4909-519e-a0f8-d0f5ad9712d0"
version = "2018.0.3+2"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.Interpolations]]
deps = ["AxisAlgorithms", "ChainRulesCore", "LinearAlgebra", "OffsetArrays", "Random", "Ratios", "Requires", "SharedArrays", "SparseArrays", "StaticArrays", "WoodburyMatrices"]
git-tree-sha1 = "b7bc05649af456efc75d178846f47006c2c4c3c7"
uuid = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
version = "0.13.6"

[[deps.InverseFunctions]]
deps = ["Test"]
git-tree-sha1 = "b3364212fb5d870f724876ffcd34dd8ec6d98918"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.7"

[[deps.InvertedIndices]]
git-tree-sha1 = "bee5f1ef5bf65df56bdd2e40447590b272a5471f"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.1.0"

[[deps.IrrationalConstants]]
git-tree-sha1 = "7fd44fd4ff43fc60815f8e764c0f352b83c49151"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.1.1"

[[deps.IterTools]]
git-tree-sha1 = "fa6287a4469f5e048d763df38279ee729fbd44e5"
uuid = "c8e1da08-722c-5040-9ed9-7db0dc04731e"
version = "1.4.0"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLD2]]
deps = ["FileIO", "MacroTools", "Mmap", "OrderedCollections", "Pkg", "Printf", "Reexport", "TranscodingStreams", "UUIDs"]
git-tree-sha1 = "81b9477b49402b47fbe7f7ae0b252077f53e4a08"
uuid = "033835bb-8acc-5ee8-8aae-3f567f8a3819"
version = "0.4.22"

[[deps.JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "abc9885a7ca2052a736a600f7fa66209f96506e1"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.4.1"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "3c837543ddb02250ef42f4738347454f95079d4e"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.3"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b53380851c6e6664204efb2e62cd24fa5c47e4ba"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "2.1.2+0"

[[deps.JuMP]]
deps = ["Calculus", "DataStructures", "ForwardDiff", "LinearAlgebra", "MathOptInterface", "MutableArithmetics", "NaNMath", "OrderedCollections", "Printf", "SparseArrays", "SpecialFunctions"]
git-tree-sha1 = "534adddf607222b34a0a9bba812248a487ab22b7"
uuid = "4076af6c-e467-56ae-b986-b466b2749572"
version = "1.1.1"

[[deps.KernelDensity]]
deps = ["Distributions", "DocStringExtensions", "FFTW", "Interpolations", "StatsBase"]
git-tree-sha1 = "591e8dc09ad18386189610acafb970032c519707"
uuid = "5ab0869b-81aa-558d-bb23-cbf5423bbe9b"
version = "0.6.3"

[[deps.KuMo]]
deps = ["CSV", "DataFrames", "DataStructures", "Dictionaries", "Distributions", "DrWatson", "Graphs", "JuMP", "MathOptInterface", "PrettyTables", "ProgressMeter", "Random", "RecipesBase", "SimpleTraits", "SparseArrays", "StatsPlots"]
git-tree-sha1 = "a3f1ffc56b90b29481d8582dd0b3ec6e3ced63da"
uuid = "b681f84e-bd48-4deb-8595-d3e0ff1e4a55"
version = "0.1.23"

[[deps.LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "f6250b16881adf048549549fba48b1161acdac8c"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.1+0"

[[deps.LERC_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "bf36f528eec6634efc60d7ec062008f171071434"
uuid = "88015f11-f218-50d7-93a8-a6af411a945d"
version = "3.0.0+1"

[[deps.LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e5b909bcf985c5e2605737d2ce278ed791b89be6"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.1+0"

[[deps.LaTeXStrings]]
git-tree-sha1 = "f2355693d6778a178ade15952b7ac47a4ff97996"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.0"

[[deps.Latexify]]
deps = ["Formatting", "InteractiveUtils", "LaTeXStrings", "MacroTools", "Markdown", "Printf", "Requires"]
git-tree-sha1 = "46a39b9c58749eefb5f2dc1178cb8fab5332b1ab"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.15.15"

[[deps.LazyArtifacts]]
deps = ["Artifacts", "Pkg"]
uuid = "4af54fe1-eca0-43a8-85a7-787d91b784e3"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.3"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "7.81.0+0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.10.2+0"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "0b4a5d71f3e5200a7dff793393e09dfc2d874290"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.2.2+1"

[[deps.Libgcrypt_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgpg_error_jll", "Pkg"]
git-tree-sha1 = "64613c82a59c120435c067c2b809fc61cf5166ae"
uuid = "d4300ac3-e22c-5743-9152-c294e39db1e4"
version = "1.8.7+0"

[[deps.Libglvnd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll", "Xorg_libXext_jll"]
git-tree-sha1 = "7739f837d6447403596a75d19ed01fd08d6f56bf"
uuid = "7e76a0d4-f3c7-5321-8279-8d96eeed0f29"
version = "1.3.0+3"

[[deps.Libgpg_error_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c333716e46366857753e273ce6a69ee0945a6db9"
uuid = "7add5ba3-2f88-524e-9cd5-f83b8a55f7b8"
version = "1.42.0+0"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "42b62845d70a619f063a7da093d995ec8e15e778"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.16.1+1"

[[deps.Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9c30530bf0effd46e15e0fdcf2b8636e78cbbd73"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.35.0+0"

[[deps.Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "LERC_jll", "Libdl", "Pkg", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "3eb79b0ca5764d4799c06699573fd8f533259713"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.4.0+0"

[[deps.Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "7f3efec06033682db852f8b3bc3c1d2b0a0ab066"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.36.0+0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LittleCMS_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pkg"]
git-tree-sha1 = "110897e7db2d6836be22c18bffd9422218ee6284"
uuid = "d3a379c0-f9a3-5b72-a4c0-6bf4d2e8af0f"
version = "2.12.0+0"

[[deps.LogExpFunctions]]
deps = ["ChainRulesCore", "ChangesOfVariables", "DocStringExtensions", "InverseFunctions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "09e4b894ce6a976c354a69041a04748180d43637"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.15"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.MKL_jll]]
deps = ["Artifacts", "IntelOpenMP_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "Pkg"]
git-tree-sha1 = "e595b205efd49508358f7dc670a940c790204629"
uuid = "856f044c-d86e-5d09-b602-aeab76dc8ba7"
version = "2022.0.0+0"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "3d3e902b31198a27340d0bf00d6ac452866021cf"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.9"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MathOptInterface]]
deps = ["BenchmarkTools", "CodecBzip2", "CodecZlib", "DataStructures", "ForwardDiff", "JSON", "LinearAlgebra", "MutableArithmetics", "NaNMath", "OrderedCollections", "Printf", "SparseArrays", "SpecialFunctions", "Test", "Unicode"]
git-tree-sha1 = "c167b0d6d165ce49f35fbe2ee1aea8844e7c7cea"
uuid = "b8f27783-ece8-5eb3-8dc8-9495eed66fee"
version = "1.4.0"

[[deps.MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "Random", "Sockets"]
git-tree-sha1 = "1c38e51c3d08ef2278062ebceade0e46cefc96fe"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.0.3"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.0+0"

[[deps.Measures]]
git-tree-sha1 = "e498ddeee6f9fdb4551ce855a46f54dbd900245f"
uuid = "442fdcdd-2543-5da2-b0f3-8c86c306513e"
version = "0.3.1"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "bf210ce90b6c9eed32d25dbcae1ebc565df2687f"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.0.2"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2022.2.1"

[[deps.MultivariateStats]]
deps = ["Arpack", "LinearAlgebra", "SparseArrays", "Statistics", "StatsAPI", "StatsBase"]
git-tree-sha1 = "7008a3412d823e29d370ddc77411d593bd8a3d03"
uuid = "6f286f6a-111f-5878-ab1e-185364afe411"
version = "0.9.1"

[[deps.MutableArithmetics]]
deps = ["LinearAlgebra", "SparseArrays", "Test"]
git-tree-sha1 = "4e675d6e9ec02061800d6cfb695812becbd03cdf"
uuid = "d8a4904e-b15c-11e9-3269-09a3773c0cb0"
version = "1.0.4"

[[deps.NaNMath]]
git-tree-sha1 = "737a5957f387b17e74d4ad2f440eb330b39a62c5"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.0.0"

[[deps.NearestNeighbors]]
deps = ["Distances", "StaticArrays"]
git-tree-sha1 = "0e353ed734b1747fc20cd4cba0edd9ac027eff6a"
uuid = "b8a86587-4115-5ab1-83bc-aa920d37bbce"
version = "0.4.11"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.Observables]]
git-tree-sha1 = "dfd8d34871bc3ad08cd16026c1828e271d554db9"
uuid = "510215fc-4207-5dde-b226-833fc4488ee2"
version = "0.5.1"

[[deps.OffsetArrays]]
deps = ["Adapt"]
git-tree-sha1 = "ec2e30596282d722f018ae784b7f44f3b88065e4"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.12.6"

[[deps.Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "887579a3eb005446d514ab7aeac5d1d027658b8f"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.5+1"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.20+0"

[[deps.OpenJpeg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libtiff_jll", "LittleCMS_jll", "Pkg", "libpng_jll"]
git-tree-sha1 = "76374b6e7f632c130e78100b166e5a48464256f8"
uuid = "643b3616-a352-519d-856d-80112ee9badc"
version = "2.4.0+0"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.1+0"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9a36165cf84cff35851809a40a928e1103702013"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "1.1.16+0"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[deps.Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "51a08fb14ec28da2ec7a927c4337e4332c2a4720"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.3.2+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[deps.PCRE_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b2a7af664e098055a7529ad1a900ded962bca488"
uuid = "2f80f16e-611a-54ab-bc61-aa92de5b98fc"
version = "8.44.0+0"

[[deps.PDMats]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "ca433b9e2f5ca3a0ce6702a032fce95a3b6e1e48"
uuid = "90014a1f-27ba-587c-ab20-58faa44d9150"
version = "0.11.14"

[[deps.PGFPlotsX]]
deps = ["ArgCheck", "DataStructures", "Dates", "DefaultApplication", "DocStringExtensions", "MacroTools", "Parameters", "Requires", "Tables"]
git-tree-sha1 = "2d062d69f112ff8d67eddfa2804fee8eb279ad16"
uuid = "8314cec4-20b6-5062-9cdb-752b83310925"
version = "1.5.0"

[[deps.Parameters]]
deps = ["OrderedCollections", "UnPack"]
git-tree-sha1 = "34c0e9ad262e5f7fc75b10a9952ca7692cfc5fbe"
uuid = "d96e819e-fc66-5662-9728-84c9c7592b0a"
version = "0.12.3"

[[deps.Parsers]]
deps = ["Dates"]
git-tree-sha1 = "0044b23da09b5608b4ecacb4e5e6c6332f833a7e"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.3.2"

[[deps.Pixman_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b4f5d02549a10e20780a24fce72bea96b6329e29"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.40.1+0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.8.0"

[[deps.PlotThemes]]
deps = ["PlotUtils", "Statistics"]
git-tree-sha1 = "8162b2f8547bc23876edd0c5181b27702ae58dce"
uuid = "ccf2f8ad-2431-5c83-bf29-c5338b663b6a"
version = "3.0.0"

[[deps.PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "Printf", "Random", "Reexport", "Statistics"]
git-tree-sha1 = "9888e59493658e476d3073f1ce24348bdc086660"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.3.0"

[[deps.Plots]]
deps = ["Base64", "Contour", "Dates", "Downloads", "FFMPEG", "FixedPointNumbers", "GR", "GeometryBasics", "JSON", "Latexify", "LinearAlgebra", "Measures", "NaNMath", "Pkg", "PlotThemes", "PlotUtils", "Printf", "REPL", "Random", "RecipesBase", "RecipesPipeline", "Reexport", "Requires", "Scratch", "Showoff", "SparseArrays", "Statistics", "StatsBase", "UUIDs", "UnicodeFun", "Unzip"]
git-tree-sha1 = "93e82cebd5b25eb33068570e3f63a86be16955be"
uuid = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
version = "1.31.1"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "a6062fe4063cdafe78f4a0a81cfffb89721b30e7"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.2"

[[deps.Poppler_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "Glib_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "OpenJpeg_jll", "Pkg", "libpng_jll"]
git-tree-sha1 = "e11443687ac151ac6ef6699eb75f964bed8e1faa"
uuid = "9c32591e-4766-534b-9725-b71a8799265b"
version = "0.87.0+2"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "47e5f437cc0e7ef2ce8406ce1e7e24d44915f88d"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.3.0"

[[deps.PrettyTables]]
deps = ["Crayons", "Formatting", "Markdown", "Reexport", "Tables"]
git-tree-sha1 = "dfb54c4e414caa595a1f2ed759b160f5a3ddcba5"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "1.3.1"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.Profile]]
deps = ["Printf"]
uuid = "9abbd945-dff8-562f-b5e8-e1ebf5ef1b79"

[[deps.ProgressMeter]]
deps = ["Distributed", "Printf"]
git-tree-sha1 = "d7a7aef8f8f2d537104f170139553b14dfe39fe9"
uuid = "92933f4c-e287-5a05-a399-4b506db050ca"
version = "1.7.2"

[[deps.Qt5Base_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Fontconfig_jll", "Glib_jll", "JLLWrappers", "Libdl", "Libglvnd_jll", "OpenSSL_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libxcb_jll", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_keysyms_jll", "Xorg_xcb_util_renderutil_jll", "Xorg_xcb_util_wm_jll", "Zlib_jll", "xkbcommon_jll"]
git-tree-sha1 = "c6c0f690d0cc7caddb74cef7aa847b824a16b256"
uuid = "ea2cea3b-5b76-57ae-a6ef-0a8af62496e1"
version = "5.15.3+1"

[[deps.QuadGK]]
deps = ["DataStructures", "LinearAlgebra"]
git-tree-sha1 = "78aadffb3efd2155af139781b8a8df1ef279ea39"
uuid = "1fd47b50-473d-5c70-9696-f719f8f3bcdc"
version = "2.4.2"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Ratios]]
deps = ["Requires"]
git-tree-sha1 = "dc84268fe0e3335a62e315a3a7cf2afa7178a734"
uuid = "c84ed2f1-dad5-54f0-aa8e-dbefe2724439"
version = "0.4.3"

[[deps.RecipesBase]]
git-tree-sha1 = "6bf3f380ff52ce0832ddd3a2a7b9538ed1bcca7d"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.2.1"

[[deps.RecipesPipeline]]
deps = ["Dates", "NaNMath", "PlotUtils", "RecipesBase"]
git-tree-sha1 = "dc1e451e15d90347a7decc4221842a022b011714"
uuid = "01d81517-befc-4cb6-b9ec-a95719d0359c"
version = "0.5.2"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.RelocatableFolders]]
deps = ["SHA", "Scratch"]
git-tree-sha1 = "cdbd3b1338c72ce29d9584fdbe9e9b70eeb5adca"
uuid = "05181044-ff0b-4ac5-8273-598c1e38db00"
version = "0.1.3"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.Rmath]]
deps = ["Random", "Rmath_jll"]
git-tree-sha1 = "bf3188feca147ce108c76ad82c2792c57abe7b1f"
uuid = "79098fc4-a85e-5d69-aa6a-4863f24498fa"
version = "0.7.0"

[[deps.Rmath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "68db32dff12bb6127bac73c209881191bf0efbb7"
uuid = "f50d1b31-88e8-58de-be2c-1cc44531875f"
version = "0.3.0+0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "0b4b7f1393cff97c33891da2a0bf69c6ed241fda"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.1.0"

[[deps.SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "db8481cf5d6278a121184809e9eb1628943c7704"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.3.13"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[deps.Showoff]]
deps = ["Dates", "Grisu"]
git-tree-sha1 = "91eddf657aca81df9ae6ceb20b959ae5653ad1de"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.0.3"

[[deps.SimpleTraits]]
deps = ["InteractiveUtils", "MacroTools"]
git-tree-sha1 = "5d7e3f4e11935503d3ecaf7186eac40602e7d231"
uuid = "699a6c99-e7fa-54fc-8d76-47d257e15c1d"
version = "0.9.4"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "b3363d7460f7d098ca0912c69b082f75625d7508"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.0.1"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.SpecialFunctions]]
deps = ["ChainRulesCore", "IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "a9e798cae4867e3a41cae2dd9eb60c047f1212db"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.1.6"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "Random", "StaticArraysCore", "Statistics"]
git-tree-sha1 = "9f8a5dc5944dc7fbbe6eb4180660935653b0a9d9"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.5.0"

[[deps.StaticArraysCore]]
git-tree-sha1 = "6edcea211d224fa551ec8a85debdc6d732f155dc"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.0.0"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "8d7530a38dbd2c397be7ddd01a424e4f411dcc41"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.2.2"

[[deps.StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "642f08bf9ff9e39ccc7b710b2eb9a24971b52b1a"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.33.17"

[[deps.StatsFuns]]
deps = ["ChainRulesCore", "HypergeometricFunctions", "InverseFunctions", "IrrationalConstants", "LogExpFunctions", "Reexport", "Rmath", "SpecialFunctions"]
git-tree-sha1 = "5783b877201a82fc0014cbf381e7e6eb130473a4"
uuid = "4c63d2b9-4356-54db-8cca-17b64c39e42c"
version = "1.0.1"

[[deps.StatsPlots]]
deps = ["AbstractFFTs", "Clustering", "DataStructures", "DataValues", "Distributions", "Interpolations", "KernelDensity", "LinearAlgebra", "MultivariateStats", "Observables", "Plots", "RecipesBase", "RecipesPipeline", "Reexport", "StatsBase", "TableOperations", "Tables", "Widgets"]
git-tree-sha1 = "43a316e07ae612c461fd874740aeef396c60f5f8"
uuid = "f3b207a7-027a-5e70-b257-86293d7955fd"
version = "0.14.34"

[[deps.StructArrays]]
deps = ["Adapt", "DataAPI", "StaticArrays", "Tables"]
git-tree-sha1 = "ec47fb6069c57f1cee2f67541bf8f23415146de7"
uuid = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
version = "0.6.11"

[[deps.SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.0"

[[deps.TableOperations]]
deps = ["SentinelArrays", "Tables", "Test"]
git-tree-sha1 = "e383c87cf2a1dc41fa30c093b2a19877c83e1bc1"
uuid = "ab02a1b2-a7df-11e8-156e-fb1833f50b87"
version = "1.2.0"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits", "Test"]
git-tree-sha1 = "5ce79ce186cc678bbb5c5681ca3379d1ddae11a1"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.7.0"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.Tectonic]]
deps = ["Pkg"]
git-tree-sha1 = "0b3881685ddb3ab066159b2ce294dc54fcf3b9ee"
uuid = "9ac5f52a-99c6-489f-af81-462ef484790f"
version = "0.8.0"

[[deps.TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TikzGraphs]]
deps = ["Graphs", "LaTeXStrings", "TikzPictures"]
git-tree-sha1 = "e8f41ed9a2cabf6699d9906c195bab1f773d4ca7"
uuid = "b4f28e30-c73f-5eaf-a395-8a9db949a742"
version = "1.4.0"

[[deps.TikzPictures]]
deps = ["LaTeXStrings", "Poppler_jll", "Requires", "Tectonic"]
git-tree-sha1 = "4e75374d207fefb21105074100034236fceed7cb"
uuid = "37f6aa50-8035-52d0-81c2-5a1d08754b2d"
version = "3.4.2"

[[deps.TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "216b95ea110b5972db65aa90f88d8d89dcb8851c"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.6"

[[deps.URIs]]
git-tree-sha1 = "97bbe755a53fe859669cd907f2d96aee8d2c1355"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.3.0"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.UnPack]]
git-tree-sha1 = "387c1f73762231e86e0c9c5443ce3b4a0a9a0c2b"
uuid = "3a884ed6-31ef-47d7-9d2a-63182c4928ed"
version = "1.0.2"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.UnicodeFun]]
deps = ["REPL"]
git-tree-sha1 = "53915e50200959667e78a92a418594b428dffddf"
uuid = "1cfade01-22cf-5700-b092-accc4b62d6e1"
version = "0.4.1"

[[deps.Unzip]]
git-tree-sha1 = "34db80951901073501137bdbc3d5a8e7bbd06670"
uuid = "41fe7b60-77ed-43a1-b4f0-825fd5a5650d"
version = "0.1.2"

[[deps.Wayland_jll]]
deps = ["Artifacts", "Expat_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "3e61f0b86f90dacb0bc0e73a0c5a83f6a8636e23"
uuid = "a2964d1f-97da-50d4-b82a-358c7fce9d89"
version = "1.19.0+0"

[[deps.Wayland_protocols_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4528479aa01ee1b3b4cd0e6faef0e04cf16466da"
uuid = "2381bf8a-dfd0-557d-9999-79630e7b1b91"
version = "1.25.0+0"

[[deps.WeakRefStrings]]
deps = ["DataAPI", "InlineStrings", "Parsers"]
git-tree-sha1 = "b1be2855ed9ed8eac54e5caff2afcdb442d52c23"
uuid = "ea10d353-3f73-51f8-a26c-33c1cb351aa5"
version = "1.4.2"

[[deps.Widgets]]
deps = ["Colors", "Dates", "Observables", "OrderedCollections"]
git-tree-sha1 = "fcdae142c1cfc7d89de2d11e08721d0f2f86c98a"
uuid = "cc8bc4a8-27d6-5769-a93b-9d913e69aa62"
version = "0.6.6"

[[deps.WoodburyMatrices]]
deps = ["LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "de67fa59e33ad156a590055375a30b23c40299d3"
uuid = "efce3f68-66dc-5838-9240-27a6d6f5f9b6"
version = "0.5.5"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "58443b63fb7e465a8a7210828c91c08b92132dff"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.9.14+0"

[[deps.XSLT_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgcrypt_jll", "Libgpg_error_jll", "Libiconv_jll", "Pkg", "XML2_jll", "Zlib_jll"]
git-tree-sha1 = "91844873c4085240b95e795f692c4cec4d805f8a"
uuid = "aed1982a-8fda-507f-9586-7b0439959a61"
version = "1.1.34+0"

[[deps.Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "5be649d550f3f4b95308bf0183b82e2582876527"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.6.9+4"

[[deps.Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4e490d5c960c314f33885790ed410ff3a94ce67e"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.9+4"

[[deps.Xorg_libXcursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXfixes_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "12e0eb3bc634fa2080c1c37fccf56f7c22989afd"
uuid = "935fb764-8cf2-53bf-bb30-45bb1f8bf724"
version = "1.2.0+4"

[[deps.Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fe47bd2247248125c428978740e18a681372dd4"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.3+4"

[[deps.Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "b7c0aa8c376b31e4852b360222848637f481f8c3"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.4+4"

[[deps.Xorg_libXfixes_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "0e0dc7431e7a0587559f9294aeec269471c991a4"
uuid = "d091e8ba-531a-589c-9de9-94069b037ed8"
version = "5.0.3+4"

[[deps.Xorg_libXi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXfixes_jll"]
git-tree-sha1 = "89b52bc2160aadc84d707093930ef0bffa641246"
uuid = "a51aa0fd-4e3c-5386-b890-e753decda492"
version = "1.7.10+4"

[[deps.Xorg_libXinerama_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll"]
git-tree-sha1 = "26be8b1c342929259317d8b9f7b53bf2bb73b123"
uuid = "d1454406-59df-5ea1-beac-c340f2130bc3"
version = "1.1.4+4"

[[deps.Xorg_libXrandr_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "34cea83cb726fb58f325887bf0612c6b3fb17631"
uuid = "ec84b674-ba8e-5d96-8ba1-2a689ba10484"
version = "1.5.2+4"

[[deps.Xorg_libXrender_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "19560f30fd49f4d4efbe7002a1037f8c43d43b96"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.10+4"

[[deps.Xorg_libpthread_stubs_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "6783737e45d3c59a4a4c4091f5f88cdcf0908cbb"
uuid = "14d82f49-176c-5ed1-bb49-ad3f5cbd8c74"
version = "0.1.0+3"

[[deps.Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "XSLT_jll", "Xorg_libXau_jll", "Xorg_libXdmcp_jll", "Xorg_libpthread_stubs_jll"]
git-tree-sha1 = "daf17f441228e7a3833846cd048892861cff16d6"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.13.0+3"

[[deps.Xorg_libxkbfile_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "926af861744212db0eb001d9e40b5d16292080b2"
uuid = "cc61e674-0454-545c-8b26-ed2c68acab7a"
version = "1.1.0+4"

[[deps.Xorg_xcb_util_image_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "0fab0a40349ba1cba2c1da699243396ff8e94b97"
uuid = "12413925-8142-5f55-bb0e-6d7ca50bb09b"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll"]
git-tree-sha1 = "e7fd7b2881fa2eaa72717420894d3938177862d1"
uuid = "2def613f-5ad1-5310-b15b-b15d46f528f5"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_keysyms_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "d1151e2c45a544f32441a567d1690e701ec89b00"
uuid = "975044d2-76e6-5fbe-bf08-97ce7c6574c7"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_renderutil_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "dfd7a8f38d4613b6a575253b3174dd991ca6183e"
uuid = "0d47668e-0667-5a69-a72c-f761630bfb7e"
version = "0.3.9+1"

[[deps.Xorg_xcb_util_wm_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "e78d10aab01a4a154142c5006ed44fd9e8e31b67"
uuid = "c22f9ab0-d5fe-5066-847c-f4bb1cd4e361"
version = "0.4.1+1"

[[deps.Xorg_xkbcomp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxkbfile_jll"]
git-tree-sha1 = "4bcbf660f6c2e714f87e960a171b119d06ee163b"
uuid = "35661453-b289-5fab-8a00-3d9160c6a3a4"
version = "1.4.2+4"

[[deps.Xorg_xkeyboard_config_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xkbcomp_jll"]
git-tree-sha1 = "5c8424f8a67c3f2209646d4425f3d415fee5931d"
uuid = "33bec58e-1273-512f-9401-5d533626f822"
version = "2.27.0+4"

[[deps.Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "79c31e7844f6ecf779705fbc12146eb190b7d845"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.4.0+3"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.12+3"

[[deps.Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e45044cd873ded54b6a5bac0eb5c971392cf1927"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.2+0"

[[deps.libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "5982a94fcba20f02f42ace44b9894ee2b140fe47"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.15.1+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.1.0+0"

[[deps.libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "daacc84a041563f965be61859a36e17c4e4fcd55"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "2.0.2+0"

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "94d180a6d2b5e55e447e2d27a29ed04fe79eb30c"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.38+0"

[[deps.libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll", "Pkg"]
git-tree-sha1 = "b910cb81ef3fe6e78bf6acee440bda86fd6ae00c"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.7+1"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.41.0+1"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+0"

[[deps.x264_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fea590b89e6ec504593146bf8b988b2c00922b2"
uuid = "1270edf5-f2f9-52d2-97e9-ab00b5d0237a"
version = "2021.5.5+0"

[[deps.x265_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "ee567a171cce03570d77ad3a43e90218e38937a9"
uuid = "dfaa095f-4041-5dcd-9319-2fabd8486b76"
version = "3.5.0+0"

[[deps.xkbcommon_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Wayland_jll", "Wayland_protocols_jll", "Xorg_libxcb_jll", "Xorg_xkeyboard_config_jll"]
git-tree-sha1 = "ece2350174195bb31de1a63bea3a41ae1aa593b6"
uuid = "d8fb68d0-12a3-5cfd-a85a-d49703b185fd"
version = "0.9.1+5"
"""

# ╔═╡ Cell order:
# ╟─d3221f99-adcc-457c-82f5-95aaa2a9e197
# ╠═61189540-e578-11ec-3030-c3ebb611c28b
# ╟─21639215-1463-46ff-80a0-f1f2028c7558
# ╟─bc72d307-12f7-47c6-b90a-062814186978
# ╠═217a9755-f4d6-4b13-b47b-9ad08430cffd
# ╠═a575616a-81d4-4829-ae89-41eee625ad9b
# ╟─6eff9ab6-620a-4a31-833d-8b8ec2b399a6
# ╟─698ef7c5-1be3-43fe-bbf0-6c5fa1afef6f
# ╟─12169dd2-6ea2-43a3-b6fd-94d55e23a568
# ╠═d3da1adc-91a8-4a97-bb23-586582a31ad7
# ╟─c1a3e0fe-c63d-41eb-9ef4-6a9c68246dc0
# ╠═015b87d8-c652-41ea-8bd8-0634383afea9
# ╟─cd893c83-7f8d-486e-af73-e411e154e631
# ╠═63f15cd5-fb1b-4f74-a287-8e2265ad5d9e
# ╟─e2144b8b-6b09-4f99-8bf3-819d0a7704f1
# ╠═83f8c3e1-9a29-4e86-9125-ace58b0ad794
# ╟─971d2a6e-72bb-4875-aee7-aeab10878dec
# ╠═4fbcbb5d-f320-432f-b6df-df5c72bb10a5
# ╟─2d603282-70c8-4a36-ada3-2459a6877e88
# ╠═2454e123-aedc-4b7f-871f-4707e7c76b5c
# ╟─f62e4864-8690-411a-b1c0-0c5d42f73dc1
# ╠═50b84495-921d-42c8-91fb-8b933cf3d7be
# ╟─69cda46a-380f-45c2-b5f8-a491f7d362d6
# ╠═e318bb27-bc9b-40c1-af63-9feccb5fcda7
# ╟─73ab86d3-7ab6-4288-a1d0-ca30432da9fc
# ╟─101246ef-1753-4174-ab16-109b425adbec
# ╟─1c7238b6-6a2c-4123-8f9b-061820e74c98
# ╠═9ba5c4d2-6197-46ab-a2b6-ff81dd5175d5
# ╠═3ee399d2-40fd-4994-b98b-7cb81c2fbf0e
# ╠═6e597df8-6b06-4ef8-8f9f-212f72022f48
# ╟─8fb3400b-bd36-4cb4-a466-3b7f75c07e6b
# ╟─21fc0470-2c99-45fb-a3d2-e9cd40b01835
# ╠═dbd801ce-d8fe-4d68-9493-088295b4f663
# ╟─22f9488e-73c4-4d0b-8d42-abd654b99795
# ╟─4541deee-dfa5-462c-a797-b221637baf64
# ╠═2a9aadf8-cbd3-43ab-b8a6-14025d551208
# ╟─a61fb19f-3e94-4097-844f-72ec845d55b2
# ╟─6cc00479-e1d3-4b88-a0b6-28a50d12d610
# ╠═ba99d317-87ae-4405-9237-f60748cec26f
# ╟─fda02e26-8425-4ceb-93e5-7101b7acb8be
# ╠═b8b4ebbe-0443-4471-b062-4605e4504702
# ╠═13e635db-a044-4c30-8643-8a0d34880488
# ╟─b4730f03-6d61-45cb-8a8b-27372b087ddc
# ╠═244b96f0-9e91-4d5e-9da3-094e9215f475
# ╠═5a0dad14-0f30-4623-9e6e-4053ca818606
# ╠═22f080a3-eb4b-4c02-88e4-d301f4b97a85
# ╠═c0b1feb5-7aec-4310-8c55-c2350ce005f8
# ╠═ec276414-bd4e-4536-9307-ce773d49306e
# ╟─4873983b-17e6-4889-8954-4989cc3923f5
# ╠═dfc5b22a-5989-4912-a18b-719803ddcbd4
# ╠═e23ae61e-f755-4cfc-8a57-b4cba9e47534
# ╠═f3e65a88-87f1-4619-87f6-d196dfd96305
# ╠═46e86b8e-2fba-4f16-bc71-91e1c05b00fd
# ╠═c633899f-5719-44c8-ba8f-a71cdb2c3ab2
# ╠═545262b9-fc38-4ea6-b3a6-90e8b96584a3
# ╠═dbbcc0fe-7019-4d40-b477-3ba76b687cb6
# ╠═29294762-c083-4461-a3cf-0789972b97a8
# ╠═91f5a063-d799-46c6-888e-7112f80435e9
# ╠═083b99e2-cafb-465c-9da1-c4c325ff6038
# ╠═4aac2e0b-2b6c-4845-a7a9-92ef60f5a0ba
# ╠═640e31ac-f2a3-4036-a064-618e840dc009
# ╠═8881283e-93a8-4aa0-b0cf-39bf501b5847
# ╠═ceef39d0-185e-496f-a2c1-9bffd3c1f619
# ╠═fb370e9f-65c3-44e9-b30e-3efd778b345a
# ╠═53ef9168-042d-48b5-bcda-61b77db1000c
# ╠═a1047cd7-5683-4d37-91db-daec3ee7ddb4
# ╠═dc9885c4-f003-4f25-ab30-0cccbb855f9f
# ╠═8140f3c6-b711-469b-9d71-33fcb9361e91
# ╠═722eb58c-aa69-4371-b737-fcead002aa51
# ╠═92d177a0-3389-4da2-934c-a93d4311bd4a
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
