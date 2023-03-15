## Script to execute to reproduce all the figures in the paper (see README.md)

using Pkg
Pkg.activate(; temp=true)
Pkg.update()

try
    using DrWatson
catch e
    @warn "Installing DrWatson" exception = (e, catch_backtrace())
    Pkg.add("DrWatson")
    using DrWatson
end

try
    using StatsPlots
catch e
    @warn "Installing StatsPlots" exception = (e, catch_backtrace())
    Pkg.add("StatsPlots")
    using StatsPlots
end

try
    using KuMo
catch e
    @warn "Installing KuMo" exception = (e, catch_backtrace())
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
            @warn "Installing PGFPlotsX" exception = (e, catch_backtrace())
            Pkg.add("PGFPlotsX")
            using PGFPlotsX
        end
        pgfplotsx()
        latexengine!(PGFPlotsX.LUALATEX)
    end
end

@quickactivate

function main(; title=true, latex=true)
    F = [
        :figure_3,
        :figure_4,
        :figure_5,
        :figure_6,
        :figure_7,
        :figure_8,
    ]

    foreach(f -> figures(f; title, latex), F)

    return nothing
end

main(; latex=LATEX) # with titles for review
# main(;title = false, latex=LATEX) # without titles for integration in the paper
