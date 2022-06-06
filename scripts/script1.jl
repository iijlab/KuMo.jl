using KuMo, DataFrames, StatsPlots, CSV, PGFPlotsX
pgfplotsx()
latexengine!(PGFPlotsX.PDFLATEX)

include("concept_scenarii.jl")

times, snaps = simulate(four_nodes(), ShortestPath(); speed=100, output="4nodes-shortestpath.csv")

df1 = DataFrame(CSV.File("data/4nodes-shortestpath.csv"))

begin
    p = @df df1 plot(
        cols(6:9), legend=:topright, tex_output_standalone=true, xlabel="time",
        ylabel="load", title="Resources allocations using basic pseudo-cost functions",
        w=1.25,
    );
    vline!([76, 152, 228, 304], w=0.75, color=:pink, style=:dash, legend=:none);
end
