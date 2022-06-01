module KuMo

# SECTION - usings and imports

using CSV
using DataFrames
using Dictionaries
using Distributions
using DrWatson
using Graphs
using JuMP
using MathOptInterface
using PrettyTables
using ProgressMeter
using Random
using SimpleTraits
using SparseArrays

# SECTION - exports
export make_df
export mincost_flow
export predict_cost
export predict_best_cost
export pseudo_cost
export scenario
export simulate

export MinCostFlow
export ShortestPath

export default_scenario
export scenario_1
export scenario_2

# SECTION - includes
include("data.jl")
include("resource.jl")
include("paths.jl")
include("topology.jl")
include("job.jl")
include("user.jl")
include("scenario.jl")
include("simulate.jl")

include("scenarii/default_scenario.jl")
include("scenarii/scenario1.jl")
include("scenarii/scenario2.jl")

end
