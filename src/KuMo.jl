module KuMo

# SECTION - usings and imports

using CSV
using DataFrames
using DataStructures
using Dictionaries
using Distributions
using DrWatson
using Graphs
using PrettyTables
using ProgressMeter
using Random
using ResizableArrays
using SparseArrays
using TestItemRunner
using TestItems

# SECTION - exports
# export figures
# export job
# export job_distributions
# export make_df
# export make_links
# export make_nodes
# export marks
# export predict_cost
# export predict_best_cost
# export pseudo_cost
# # export requests
# export scenario
# export simulate
# export simulate_and_plot
# export show_pseudo_costs
# export show_simulation
# export smooth
# export spike
# export steady
# export user

# export node!

# export Scenario

# export MinCostFlow
# export ShortestPath

# export Request
# export Requests
# export PeriodicRequests

# export Link
# export ConvexLink
# export FlatLink
# export FreeLink

# export Node
# export AdditiveNode
# export EqualLoadBalancingNode
# export FlatNode
# export IdleStateNode
# export MultiplicativeNode
# export PremiumNode

# export SCENARII


## SECTION - includes

# utilities
include("utilities.jl")

# defines resources and list of generic and specialized pseudo-cost functions for those
include("pseudocosts.jl")
include("resource.jl")

# defines infrastructure, and entities
include("entity.jl")
include("topology.jl")
include("infrastructure.jl")



# defines jobs, requests, and actions
include("job.jl")
include("request.jl")
include("action.jl")

# algorithms to compute paths (shortest, mincostflow [extension]) in the network
include("paths.jl")

# execution
include("state.jl")
include("snapshot.jl")
include("execute.jl")

# scenarii (dictionaries)
include("scenarii/basic.jl")

# functions definition for extensions
function show_pseudo_costs end
function show_simulation end
function simulate_and_plot end
function figures end

end
