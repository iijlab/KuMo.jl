module KuMo

# SECTION - usings and imports

using DataFrames
using Dictionaries
using Distributions
using DrWatson
using Graphs
using JuMP
using PrettyTables
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

export DEFAULT_SCENARIO
export SCENARIO_1
export SCENARIO_2

# SECTION - includes
include("data.jl")
include("resource.jl")
include("job.jl")
include("user.jl")
include("scenario.jl")
include("mincostflow.jl")
include("shortest_paths.jl")
include("simulate.jl")

include("scenarii/default_scenario.jl")
include("scenarii/scenario1.jl")
include("scenarii/scenario2.jl")

end
