# SECTION - Script to simualte and analyse results for KuMo.jl

using KuMo
using GLMakie
using DataFrames



function interactive_analysis(df)
    set_theme!(backgroundcolor=:gray90)
    fontsize_theme = Theme(fontsize=20)
    update_theme!(fontsize_theme)

    fig = Figure(resolution=(1200, 1000))

    Axis(
        fig[1, 1];
        title="Interactive analysis",
        xlabel="Time",
        ylabel="Resource load",
    )

    a, b, _, d = marks(df)
    δ = d === nothing ? b : d
    _lines = Vector{Any}(fill(nothing, length(a:δ)))
    toggles = [Toggle(fig, active = i ≤ b) for i in a:δ]
    labels = map(l -> Label(fig, l), names(df)[a:δ])
    fig[1, 2] = grid!(hcat(toggles, labels), tellheight = false)

    for c in a:δ
        γ = c - a + 1
        _lines[γ] = scatter!(df[!,:instant], df[!, c])
        connect!(_lines[γ].visible, toggles[γ].active)
    end

    return fig
end

function interactive_analysis(s::Scenario = SCENARII[:four_nodes])
    df = simulate(s, ShortestPath())[2]
    return interactive_analysis(df)
end

# function scenario1(;)
# 	Δ1 = 120
# 	Δ2 = 180
# 	δ = 4.
# 	σ = δ / 4
# 	norm_dist = truncated(Normal(δ, σ); lower = eps())
# 	# jd() = rand(norm_dist)
# 	jd() = 4

# 	λ = .1
# 	fish = Poisson(λ)
# 	# ji() = rand(fish)
# 	ji() = λ

# 	interactive(data) = job(1, 1, data, jd(), 2)
# 	data_intensive(data) = job(2, 1, data, jd(), 1)

# 	reqs = Vector{Request{<:KuMo.AbstractJob}}()
# 	types = Set()
# 	k1 = 38
# 	# user1 - wave 1
# 	t = 0.0
# 	r = Float64(Δ1)
# 	for i in 1:Δ1/2
# 		k = k1*sin(i*π/Δ1)
# 		while t ≤ i
# 			t += ji()
# 			j = rand() < 1/3 ? interactive(4) : data_intensive(4)
# 			push!(types, typeof(j))
# 			foreach(_ -> push!(reqs, Request(j, t)), 1:k)
# 		end
# 		i + δ < Δ1/2 && while r ≥ Δ1 - i
# 			r -= ji()
# 			j = rand() < 1/3 ? interactive(4) : data_intensive(4)
# 			push!(types, typeof(j))
# 			foreach(_ -> push!(reqs, Request(j, r - δ/2)), 1:k)
# 		end
# 	end

# 	# user1 - wave 2
# 	t = 0.0
# 	r = Float64(Δ1)
# 	for i in 1:Δ1/2
# 		k = k1*sin(i*π/Δ1)
# 		while t ≤ i
# 			t += ji()
# 			j = rand() < 1/3 ? interactive(4) : data_intensive(4)
# 			push!(types, typeof(j))
# 			foreach(_ -> push!(reqs, Request(j, t + Δ1)), 1:k)
# 		end
# 		i + δ < Δ1/2 && while r ≥ Δ1 - i
# 			r -= ji()
# 			j = rand() < 1/3 ? interactive(4) : data_intensive(4)
# 			push!(types, typeof(j))
# 			foreach(_ -> push!(reqs, Request(j, r - δ/2 + Δ1)), 1:k)
# 		end
# 	end

# 	# user1 - wave 3
# 	t = 0.0
# 	r = Float64(Δ1)
# 	for i in 1:Δ1/2
# 		k = k1*sin(i*π/Δ1)
# 		while t ≤ i
# 			t += ji()
# 			j = rand() < 1/3 ? interactive(4) : data_intensive(4)
# 			push!(types, typeof(j))
# 			foreach(_ -> push!(reqs, Request(j, t + 2Δ1)), 1:k)
# 		end
# 		i + δ < Δ1/2 && while r ≥ Δ1 - i
# 			r -= ji()
# 			j = rand() < 1/3 ? interactive(4) : data_intensive(4)
# 			push!(types, typeof(j))
# 			foreach(_ -> push!(reqs, Request(j, r - δ/2 + 2Δ1)), 1:k)
# 		end
# 	end

# 	# user1 - wave 4
# 	t = 0.0
# 	r = Float64(Δ1)
# 	for i in 1:Δ1/2
# 		k = k1*sin(i*π/Δ1)
# 		while t ≤ i
# 			t += ji()
# 			j = rand() < 1/3 ? interactive(4) : data_intensive(4)
# 			push!(types, typeof(j))
# 			foreach(_ -> push!(reqs, Request(j, t + 3Δ1)), 1:k)
# 		end
# 		i + δ < Δ1/2 && while r ≥ Δ1 - i
# 			r -= ji()
# 			j = rand() < 1/3 ? interactive(4) : data_intensive(4)
# 			push!(types, typeof(j))
# 			foreach(_ -> push!(reqs, Request(j, r - δ/2 + 3Δ1)), 1:k)
# 		end
# 	end

# 	# user1 - wave 5
# 	t = 0.0
# 	r = Float64(Δ1)
# 	for i in 1:Δ1/2
# 		k = k1*sin(i*π/Δ1)
# 		while t ≤ i
# 			t += ji()
# 			j = rand() < 1/3 ? interactive(4) : data_intensive(4)
# 			push!(types, typeof(j))
# 			foreach(_ -> push!(reqs, Request(j, t + 4Δ1)), 1:k)
# 		end
# 		i + δ < Δ1/2 && while r ≥ Δ1 - i
# 			r -= ji()
# 			j = rand() < 1/3 ? interactive(4) : data_intensive(4)
# 			push!(types, typeof(j))
# 			foreach(_ -> push!(reqs, Request(j, r - δ/2 + 4Δ1)), 1:k)
# 		end
# 	end

# 	# user1 - wave 6
# 	t = 0.0
# 	r = Float64(Δ1)
# 	for i in 1:Δ1/2
# 		k = k1*sin(i*π/Δ1)
# 		while t ≤ i
# 			t += ji()
# 			j = rand() < 1/3 ? interactive(4) : data_intensive(4)
# 			push!(types, typeof(j))
# 			foreach(_ -> push!(reqs, Request(j, t + 5Δ1)), 1:k)
# 		end
# 		i + δ < Δ1/2 && while r ≥ Δ1 - i
# 			r -= ji()
# 			j = rand() < 1/3 ? interactive(4) : data_intensive(4)
# 			push!(types, typeof(j))
# 			foreach(_ -> push!(reqs, Request(j, r - δ/2 + 5Δ1)), 1:k)
# 		end
# 	end

# 	UT = Union{collect(types)...}
# 	R = Vector{Request{UT}}()
# 	foreach(r -> push!(R, r), reqs)

# 	u1 = user(R, 1)


# 	reqs = Vector{Request{<:KuMo.AbstractJob}}()
# 	types = Set()
# 	k2 = 23
# 	# user2 - wave 1
# 	t = 0.0
# 	r = Float64(Δ2)
# 	for i in 1:Δ2/2
# 		k = k2*sin(i*π/Δ2)
# 		while t ≤ i
# 			t += ji()
# 			j = rand() < 1/3 ? interactive(3) : data_intensive(3)
# 			push!(types, typeof(j))
# 			foreach(_ -> push!(reqs, Request(j, t)), 1:k)
# 		end
# 		i + δ < Δ2/2 && while r ≥ Δ2 - i
# 			r -= ji()
# 			j = rand() < 1/3 ? interactive(3) : data_intensive(3)
# 			push!(types, typeof(j))
# 			foreach(_ -> push!(reqs, Request(j, r - δ/2)), 1:k)
# 		end
# 	end

# 	# user2 - wave 2
# 	t = 0.0
# 	r = Float64(Δ2)
# 	for i in 1:Δ2/2
# 		k = k2*sin(i*π/Δ2)
# 		while t ≤ i
# 			t += ji()
# 			j = rand() < 1/3 ? interactive(3) : data_intensive(3)
# 			push!(types, typeof(j))
# 			foreach(_ -> push!(reqs, Request(j, t + Δ2)), 1:k)
# 		end
# 		i + δ < Δ2/2 && while r ≥ Δ2 - i
# 			r -= ji()
# 			j = rand() < 1/3 ? interactive(3) : data_intensive(3)
# 			push!(types, typeof(j))
# 			foreach(_ -> push!(reqs, Request(j, r - δ/2 + Δ2)), 1:k)
# 		end
# 	end

# 	# user2 - wave 3
# 	t = 0.0
# 	r = Float64(Δ2)
# 	for i in 1:Δ2/2
# 		k = k2*sin(i*π/Δ2)
# 		while t ≤ i
# 			t += ji() / 2
# 			j = rand() < 1/3 ? interactive(3) : data_intensive(3)
# 			push!(types, typeof(j))
# 			foreach(_ -> push!(reqs, Request(j, t + 2Δ2)), 1:k)
# 		end
# 		i + δ/2 < Δ2/2 && while r ≥ Δ2 - i
# 			r -= ji() / 2
# 			j = rand() < 1/3 ? interactive(3) : data_intensive(3)
# 			push!(types, typeof(j))
# 			foreach(_ -> push!(reqs, Request(j, r - δ/3+ 2Δ2)), 1:k)
# 		end
# 	end

# 	# user2 - wave 4
# 	t = 0.0
# 	r = Float64(Δ2)
# 	for i in 1:Δ2/2
# 		k = k2*sin(i*π/Δ2)
# 		while t ≤ i
# 			t += ji() / 10
# 			j = rand() < 1/3 ? interactive(3) : data_intensive(3)
# 			push!(types, typeof(j))
# 			foreach(_ -> push!(reqs, Request(j, t + 3Δ2)), 1:k)
# 		end
# 		i + δ/10 < Δ2/2 && while r ≥ Δ2 - i
# 			r -= ji() / 10
# 			j = rand() < 1/3 ? interactive(3) : data_intensive(3)
# 			push!(types, typeof(j))
# 			foreach(_ -> push!(reqs, Request(j, r - δ/10 + 3Δ2)), 1:k)
# 		end
# 	end

# 	UT = Union{collect(types)...}
# 	R = Vector{Request{UT}}()
# 	foreach(r -> push!(R, r), reqs)

# 	u2 = user(R, 2)


#     scenario(;
#         duration=1000,
#         nodes=[
# 			Node(100),
# 			Node(100),
# 			Node(1000),
# 			Node(1000),
# 		],
#         users=[
#             u1,
# 			u2,
# 		],
# 	    links=[
# 	    	(1, 3, 300.0), (2, 3, 300.0), (3, 4, 3000.0), (4, 2, 3000.0),
# 	        (3, 1, 300.0), (3, 2, 300.0), (4, 3, 3000.0), (2, 4, 3000.0),
# 	    ],
#     )
# end

# using StatsPlots, CSV, Distributions, PGFPlotsX

# s = scenario1()

# df = simulate(s, ShortestPath())[2]
