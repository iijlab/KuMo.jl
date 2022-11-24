using DrWatson
@quickactivate

using Pkg
Pkg.instantiate()

using KuMo
using StatsPlots
using PGFPlotsX

pgfplotsx()
latexengine!(PGFPlotsX.LUALATEX)

figuresdir() = joinpath(findproject(), "..", "..", "figures", "conext2022")
