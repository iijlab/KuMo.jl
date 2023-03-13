## Script to execute to reproduce all the figures in the paper (see README.md)

using Pkg
Pkg.update()

try
    using DrWatson
catch e
    @warn "Installing DrWatson" exception = (e, catch_backtrace())
    Pkg.add("DrWatson")
    using DrWatson
end

@quickactivate

#SECTION - Load packages
using CSV
using DataFrames
using KuMo
using StatsPlots

#NOTE - Define figures directory
figuresdir() = joinpath(findproject(), "figures")

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

function main(; title=true, latex=true)
    F = [
        figure_3,
        figure_4,
        figure_5,
        figure_6,
        figure_7,
        figure_8,
    ]

    for (i, f) in enumerate(F)
        @debug "Plotting figure $(i+2) ∈ [3, $(length(F)+2)]" title
        f(; title, latex)
    end

    return nothing
end

const LATEX = "--nolatex" ∉ ARGS

if LATEX
    # Requires luatex (installed by most LaTeX distributions)
    begin
        using PGFPlotsX
        pgfplotsx()
        latexengine!(PGFPlotsX.LUALATEX)
    end
end

# Comment both if excuting each figure individually
main(; latex=LATEX) # with titles for review
# main(;title = false, latex=LATEX) # without titles for integration in the paper
