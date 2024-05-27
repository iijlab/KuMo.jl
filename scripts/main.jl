## Script to execute to reproduce all the figures in the paper (see README.md)

using Pkg
Pkg.activate(; temp = true)
Pkg.update()

try
    using DrWatson
catch e
    @warn "Installing DrWatson (catching package missing error)" exception = (e, catch_backtrace())
    Pkg.add("DrWatson")
    using DrWatson
end

try
    using StatsPlots
catch e
    @warn "Installing StatsPlots (catching package missing error)" exception = (e, catch_backtrace())
    Pkg.add("FileIO")
    Pkg.add("Plots")
    Pkg.add("StatsPlots")
    using StatsPlots
end

try
    using KuMo
catch e
    @warn "Installing KuMo (catching package missing error)" exception = (e, catch_backtrace())
    Pkg.add(url="https://github.com/Azzaare/KuMo.jl")
    using KuMo
end

const LATEX = "--nolatex" ∉ ARGS

if LATEX
    # Requires luatex (installed by most LaTeX distributions)
    begin
        try
            using PGFPlotsX
        catch e
            @warn "Installing PGFPlotsX (catching package missing error)" exception = (e, catch_backtrace())
            Pkg.add("PGFPlotsX")
            using PGFPlotsX
        end
        pgfplotsx()
        latexengine!(PGFPlotsX.LUALATEX)
    end
end

@quickactivate

function main(; title = true, latex = true)
    F = [
        # :figure_3,
        :figure_4,
        :figure_5        # :figure_6,        # :figure_7,        # :figure_8,
    ]

    # foreach(f -> figures(f; title, latex), F)

    figures(:figure_3; select=:standard, title, latex)
    figures(:figure_3; select=:variants, output=joinpath(pwd(), "..", "figures", "figure3_pseudocosts_variants.pdf"), title, latex)

    return nothing
end

# main(; title=true, latex=LATEX) # with titles for review
main(; title=false, latex=LATEX) # without titles for integration in the paper
