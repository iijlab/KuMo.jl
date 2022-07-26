using DataFrames
using GLMakie

import Makie

@recipe(DfPlot, df, δ) do scene
    Attributes(
        x = :A,
        y = :B,
    )
end

function Makie.plot!(p::DfPlot{<:Tuple{<:DataFrame}})
    df = p[:df][]
    x = getproperty(df, p[:x][])
    y = getproperty(df, p[:y][])
    lines!(p, x, y)
    return p
end

df_recipe = DataFrame(A=sort!(randn(10)), B=randn(10))

fig, ax, obj = dfplot(df_recipe; label = "test")
fig
