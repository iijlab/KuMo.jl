"""
    marks(df::DataFrame)

Returns a 4-tuple `(a, b, c, d)` that marks the start and end of the `nodes` and `links` columns in the dataframe.
- `(a, b)` mark the start and end indices of the `nodes` columns
- `(c, d)` mark the start and end indices of the `links` columns
"""
function marks(df)
    a, b, c, d = 6, 0, 0, 0
    b0 = findfirst(map(x -> occursin("(", x), names(df)))
    if b0 === nothing
        b = length(names(df))
        c = nothing
        d = nothing
    else
        b = b0 - 1
        c = b0
        d = length(names(df))
    end
    return a, b, c, d
end

"""
    cond_minmax(x, y, b)

Return the min of `x` and `y` if `b` is `false`, and the max of `x` and `y` otherwise.
"""
cond_minmax(x, y, b) = b ? (x, y) : minmax(x, y)
