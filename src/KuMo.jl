module KuMo

# SECTION - usings and imports

using DataFrames
using Distributions
using DrWatson
using PrettyTables
using Random

# SECTION - exports
export make_df
export scenario
export simulate

# SECTION - includes
include("data.jl")
include("resource.jl")
include("user.jl")
include("job.jl")
include("scenario.jl")
include("simulate.jl")

end
