#SECTION 3 - Figure 8 - Mixed load with 2 DCs and 2 MDCs

function figure_8(; output=joinpath(figuresdir(), "figure8_mixed_load.pdf"))
    df = DataFrame(CSV.File("../data/figure8.csv"))

    df_no_norm = deepcopy(df)
    df_no_norm[!, 6:7] = df[!, 6:7] .* 1
    df_no_norm[!, 8:9] = df[!, 8:9] .* 10

    p1 = @df df plot(
        :instant,
        cols(6:9);
        ylabel="load",
        w=1,
        xticks=0:120:1000,
        ylims=(0, 1),
        yticks=0:0.25:1,
        lab=["MDC0" "MDC1" "DC2" "DC3"]
    )

    p2 = @df df plot(
        :instant,
        cols(10:13);
        # seriestype = :steppre,
        ylabel="links load",
        xticks=0:120:1000,
        ylims=(0, 1),
        yticks=0:0.25:1,
        w=1,
        lab=["MDC0-DC2" "MDC1-DC3" "MDC1-DC2" "DC2-DC3"]
    )

    p3 = @df df_no_norm areaplot(
        :instant,
        cols(6:9);
        ylabel="total load",
        xlabel="time",
        xticks=0:120:1000,
        yticks=0:4:12,
        w=1,
        lab=["MDC0" "MDC1" "DC2" "DC3"]
    )

    p = plot(
        p1,
        p2,
        p3;
        layout=(3, 1),
        plot_title="\\bf Figure 8: Mixed load",
        plot_titlefontsize=10,
        thickness_scaling=2,
        w=0.5,
        size=(600, 600)
    )

    splitdir(output)[1] |> mkpath
    savefig(p, output)

    return p
end

# Uncomment to generate the plots independently of the main function
# figure_8()
