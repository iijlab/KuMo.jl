## Script to execute to reproduce all the figures in the paper (see README.md)

#SECTION - Load packages
using CSV
using DataFrames
using KuMo
using StatsPlots

#NOTE - (Un-)Comment the following block to use default/PGFPlotsX backend
begin
    using PGFPlotsX
    pgfplotsx()
    latexengine!(PGFPlotsX.LUALATEX)
end

#NOTE - Define figures directory
figuresdir() = joinpath(findproject(), "..", "figures")

#SECTION Includes

# figure 3
include("pseudocosts.jl")

# figure 4
include("equivalent_nodes.jl")

# figure 5
include("proportional_nodes.jl")

# figure 6
include("edge.jl")

# figure 7
include("cost_manipulations.jl")

# figure 8
include("mixed_load.jl")

function main(title=true)
    F = [
        figure_3,
        figure_4,
        figure_5,
        figure_6,
        figure_7,
        figure_8,
    ]

    for (i, f) in enumerate(F)
        println("Figure $i")
        f(; title)
    end

    return nothing
end

main() # with titles for review
# main(false) # without titles for integration in the paper
