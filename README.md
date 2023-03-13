# KuMo: Towards Cloud Morphing

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://Azzaare.github.io/KuMo.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://Azzaare.github.io/KuMo.jl/dev)
[![Build Status](https://github.com/Azzaare/KuMo.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/Azzaare/KuMo.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![codecov](https://codecov.io/gh/Azzaare/KuMo.jl/branch/main/graph/badge.svg?token=rlJUxj3NkP)](https://codecov.io/gh/Azzaare/KuMo.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)
<!-- [![ColPrac: Contributor's Guide on Collaborative Practices for Community Packages](https://img.shields.io/badge/ColPrac-Contributor's%20Guide-blueviolet)](https://github.com/SciML/ColPrac) -->
<!-- [![PkgEval](https://JuliaCI.github.io/NanosoldierReports/pkgeval_badges/K/KuMo.svg)](https://JuliaCI.github.io/NanosoldierReports/pkgeval_badges/report.html) -->


## Reproducing the experimental results of any related paper

We recommend any user, specially if unfamiliar with the Julia language, to follow the small guide below.

### Installing Julia

We recommend any user, specially if unfamiliar with the Julia language, to use [juliaup](https://github.com/JuliaLang/juliaup). Among other things, `juliaup` will install the latest release of Julia and it to the path.

Do not use the `julia` version available on most repositories (such as `apt`) as it tends to not be maintained. Either install through `juliaup` or by downloading the binaries on the Julia language website.

### How to use the scripts to generate the figures in the article

**Clone the repository**

Either clone this repository using, for instance the following command within the Julia REPL

```julia
] dev https://github.com/Azzaare/KuMo.jl.git
```

or in a shell

```shell
git clone https://github.com/Azzaare/KuMo.jl.git
```

Note that the first command will download and install the package at the following path  `~/.julia/dev/KuMo`.

**Change directory**

Please open a terminal in `path_to_KuMo/scripts` (or `cd` into it).

**Run the script**

If one has LaTeX installed, running the script is as simple as using

```shell
julia main.jl
```

If no LaTeX engine are available, one needs to comment line 18-22 in `main.jl` before running the script:

```julia
begin
    using PGFPlotsX
    pgfplotsx()
    latexengine!(PGFPlotsX.LUALATEX)
end
```

The output is generated in `path_to_KuMo/figures`. Note that if LaTeX is not used, the figures might not appear as in the original paper.

<!-- ## Citing

See [`CITATION.bib`](CITATION.bib) for the relevant reference(s). -->