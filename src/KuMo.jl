module KuMo

# SECTION - usings and imports

using CSV
using DataFrames
using DataStructures
using Dictionaries
using Distributions
using DrWatson
using Graphs
# using JuMP
# using MathOptInterface
using PrettyTables
using ProgressMeter
using Random
using SimpleTraits
using SparseArrays
using TestItemRunner
using TestItems

# SECTION - exports
export figures
export job
export job_distributions
export make_df
export make_links
export make_nodes
export marks
# export mincost_flow
# export plot_links
# export plot_nodes
# export plot_resources
export predict_cost
export predict_best_cost
export pseudo_cost
export requests
export scenario
export simulate
export simulate_and_plot
export show_pseudo_costs
export show_simulation
export smooth
export spike
export steady
export user

export Scenario

export MinCostFlow
export ShortestPath

export Request
export Requests
export PeriodicRequests

export Link
export ConvexLink
export FlatLink
export FreeLink

export Node
export AdditiveNode
export EqualLoadBalancingNode
export FlatNode
export IdleStateNode
export MultiplicativeNode
export PremiumNode

export SCENARII


## SECTION - includes

# utilities
include("utilities.jl")

# defines structure for data items
include("data.jl")

# defines resources and list of generic and specialized pseudo-cost functions for those
include("pseudocosts.jl")
include("resource.jl")

# defines jobs, requests, and users
include("job.jl")
include("request.jl")
include("user.jl")

# algorithms to compute paths (shortest, mincostflow) in the network
include("paths.jl")

# network topology and scenario
include("topology.jl")
include("scenario.jl")

# scenarii (dictionaries)
include("scenarii/basic.jl")

# simulation
include("simulate.jl")

# # visualization
# include("visualization/statsplots.jl")
# include("visualization/makie.jl")

# using .VizStatsPlots: simulate_and_plot, plot_links, plot_nodes, plot_resources
# using .VizMakie: show_pseudo_costs, show_simulation

function show_pseudo_costs end
function show_simulation end
function simulate_and_plot end
function figures end

end
