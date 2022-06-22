# utility function
function marks(df)
	a = 6
	b = findfirst(map(x -> occursin("(", x), names(df))) - 1
	c = b + 1
	d = length(names(df))
	return a, b, c, d
end

function plot_nodes(df)
    a, b, _, _ = marks(df)
    p = @df df plot(:instant,
        cols(a:b), tex_output_standalone=true, xlabel="time",
        ylabel="load", title="Resources allocations using basic pseudo-cost functions",
        w=1.25,
    )
    return p
end

function plot_links(df)
    _, _, c, d = marks(df)
    p = @df df plot(:instant,
        cols(c:d), tex_output_standalone=true, xlabel="time",
        ylabel="load", title="Resources allocations using basic pseudo-cost functions",
        w=1.25,
    )
    return p
end

function plot_resources(df; layout = grid(2,1))
    return plot(plot_nodes(df), plot_nodes(df), layout)
end
