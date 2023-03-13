# KuMo: Towards Cloud Morphing

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://Azzaare.github.io/KuMo.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://Azzaare.github.io/KuMo.jl/dev)
[![Build Status](https://github.com/Azzaare/KuMo.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/Azzaare/KuMo.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![codecov](https://codecov.io/gh/Azzaare/KuMo.jl/branch/main/graph/badge.svg?token=rlJUxj3NkP)](https://codecov.io/gh/Azzaare/KuMo.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)
<!-- [![ColPrac: Contributor's Guide on Collaborative Practices for Community Packages](https://img.shields.io/badge/ColPrac-Contributor's%20Guide-blueviolet)](https://github.com/SciML/ColPrac) -->
<!-- [![PkgEval](https://JuliaCI.github.io/NanosoldierReports/pkgeval_badges/K/KuMo.svg)](https://JuliaCI.github.io/NanosoldierReports/pkgeval_badges/report.html) -->

**Table of contents**

- [Visualization Tools](https://github.com/Azzaare/KuMo.jl#visualization-tools)
- [Reproducing the experimental results of any related paper](https://github.com/Azzaare/KuMo.jl#reproducing-the-experimental-results-of-any-related-paper)

## Installing KuMo

In a Julia REPL (command-line interface for julia), please use the following code snippet to install KuMo.

```julia
using Pkg
Pkg.add(url="https://github.com/Azzaare/KuMo.jl")
```

## Visualization Tools

We provide an interface to two popular visualization tools in the Julia ecosystem:
- (GL)Makie.jl for an interactive plot analysis
- (Stats)Plots.jl for generating figures in LaTeX/PDF fashion

We recommend using the Makie interface first when designing or analyzing a scenario.

### Pseudo costs selection and manipulation

Using efficiently our Cloud Morphing system, KuMo, is mainly done by selecting appropriate pseudo costs function for each resource. We implemented a small tool available within KuMo to help users with standard and usual variants of monotonic and convex pseudo costs.

In the julia REPL (command-line interface for julia), please use the following code snippet.

```julia
using KuMo, GLMakie

show_pseudo_costs()
```

### Interactive plot analysis with Makie

With our Makie interface, we provide a simple way to visualize the results of a scenario. The following code snippet will generate a plot of a default scenario.

```julia
using KuMo, GLMakie

show_simulation()
```

Note that by default, `show_simulation()` will use a simple four convex nodes' scenario available in a small scenario collection called `SCENARII`.

At the time of writing, the user can try out-of-the-box the following scenario through

```julia
show_simulation(SCENARII[:four_nodes]) # default scenario for show_simulation()

show_simulation(SCENARII[:four_nodes_four_users])

show_simulation(SCENARII[:square])
```

### Generating quality plots with Plots

Users can generate high quality plots with the goal of a LaTeX formatted PDF output in the following fashion.

```julia
using KuMo, Plots

scenario = SCENARII[:four_nodes]

simulate_and_plot!(scenario; plot_type = :all, target=:all)
```

The `plot_type` argument can be either `:all` or `:plot` or `:areaplot`. The `target` argument can be either `:all` or `:nodes` or `:links`.

Please read the documentation (WIP) for more information.

## Reproducing the experimental results of any related paper

### Installing Julia

We recommend any user, specially if unfamiliar with the Julia language, to use [juliaup](https://github.com/JuliaLang/juliaup). Among other things, `juliaup` will install the latest release of Julia and add it to the path.

Do not use the `julia` version available on most repositories (such as `apt`) as it tends to not be maintained. Either install through `juliaup` or by downloading the binaries on the Julia language website.

Note that this package requires at least Julia 1.8 (the latest release at the time of writing).
### How to use the scripts to generate the figures in the article

**Clone the repository**

Either clone this repository using, for instance the following command line in a shell

```shell
git clone https://github.com/Azzaare/KuMo.jl.git
```

or in a Julia REPL

```julia
using Pkg
Pkg.develop(url="https://github.com/Azzaare/KuMo.jl.git")
```

Note that the last command will download and install the package at the following path `~/.julia/dev/KuMo`.

**Change directory**

Please open a terminal anywhere within the cloned repository (or `cd` into it).

**Run the script**

If one has LaTeX installed, running the script is as simple as using

```shell
julia scripts/main.jl

# or from anywhere within the repository
julia path/to/main.jl
```

If no LaTeX engine are available, please add the `--nolatex` flag.

```shell
julia scripts/main.jl --nolatex
```

The output is generated in `/figures`.

Note that the first execution of the script will take a while as it will download and install all the dependencies.

<!-- ## Citing

See [`CITATION.bib`](CITATION.bib) for the relevant reference(s). -->
