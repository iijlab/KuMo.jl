module KuMo

## SECTION - usings and imports

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

# SECTION - improts from Base
using Base.Threads

# SECTION - exports
export execute
export simulate
export simulation

export data!
export job!
export link!
export node!
export stop!
export user!

export user_location

export Node
export AdditiveNode
export EqualLoadBalancingNode
export FlatNode
export IdleStateNode
export MultiplicativeNode
export PremiumNode

export Link
export ConvexLink
export FreeLink
export FlatLink

export BatchSimulation
export InteractiveRun

export results

export figures
export show_interactive_run
export show_pseudo_costs
export show_simulation
export simulate_and_plot

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

# extras
include("flock.jl")

# scenarii (dictionaries)
include("scenarii/basic.jl")

# functions definition for extensions
function show_interactive_run end
function show_pseudo_costs end
function show_simulation end
function simulate_and_plot end
function figures end

end
