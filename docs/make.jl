using KuMo
using Documenter

DocMeta.setdocmeta!(KuMo, :DocTestSetup, :(using KuMo); recursive = true)

makedocs(;
    modules = [KuMo],
    authors = "azzaare <jf@baffier.fr> and contributors",
    repo = "https://github.com/iijlab/KuMo.jl/blob/{commit}{path}#{line}",
    sitename = "KuMo.jl",
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://iijlab.github.io/KuMo.jl",
        assets = String[]
    ),
    pages = [
        "Home" => "index.md"
    ]
)

deploydocs(;
    repo = "github.com/iijlab/KuMo.jl",
    devbranch = "main"
)
