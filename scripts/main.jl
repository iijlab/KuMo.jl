# Add this file to ~/.julia/config/ (mkdir config if necessary)

try
    using Revise
catch e
    @warn "Error initializing Revise: trying install" exception=(e, catch_backtrace())
    using Pkg
    Pkg.add("Revise")
end

try
    using LocalRegistry
catch e
    @warn "Error initializing LocalRegistry: trying install" exception=(e, catch_backtrace())
    using Pkg
    Pkg.add("LocalRegistry")
end

try
    using PackageCompatUI
catch e
    @warn "Error initializing PackageCompatUI: trying install" exception=(e, catch_backtrace())
    using Pkg
    Pkg.add("PackageCompatUI")
end

try
    using Term
    install_term_repr()
catch e
    @warn "Error initializing Term: trying install" exception=(e, catch_backtrace())
    using Pkg
    Pkg.add("Term")
end

try
    using OhMyREPL
catch e
    @warn "Error initializing OhMyREPL: trying install" exception=(e, catch_backtrace())
    using Pkg
    Pkg.add("OhMyREPL")
end

try
    using DrWatson
catch e
    @warn "Error initializing DrWatson: trying install" exception=(e, catch_backtrace())
    using Pkg
    Pkg.add("DrWatson")
end

try
    using Coverage

catch e
    @error "Error initializing Coverage" exception=(e, catch_backtrace())
    using Pkg
    Pkg.add("Coverage")
end

function analyze_mallocs(dirs::V) where {S <: AbstractString, V <: AbstractVector{S}}
    mallocs = collect(Iterators.flatten(map(analyze_malloc, dirs)))
    sort!(mallocs, lt = Coverage.sortbybytes)
    return mallocs
end

function subtype_tree(root_type;
    level = 1, indent = 4, lasts = Dict(1 => true), ancestor = 0
)
    if ancestor > 0
        return subtype_tree(supertype(root_type); indent, ancestor = ancestor - 1)
    end
    # Root type printing
    level == 1 && println(root_type)

    # Determine the correct vertival character
    vc(lvl) = get!(lasts, lvl, false) ? " " : "│"

    st = subtypes(root_type)
    for (i, s) in enumerate(st)
        # Markers for entering and leaving levels
        i == 1 && setindex!(lasts, false, level)
        i == length(st) && setindex!(lasts, true, level)

        # Horizontal character
        hc = get!(lasts, level, false) ? "└" : "├"

        # Actual printing
        lines = mapreduce(l -> vc(l) * repeat(" ", indent), *, 1:(level-1); init = "")
        println(lines * hc * "───" * string(s))

        # Next child
        subtype_tree(s; level = level + 1, indent, lasts)
    end
end
