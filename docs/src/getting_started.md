# Getting Started

You can install ClimaRivers using Julia's built-in package manager.

!!! info "Julia version requirement"
    ClimaRivers requires Julia 1.10 or higher. Check your version with `julia --version`,
    or download the latest release from [https://julialang.org/downloads/](https://julialang.org/downloads/).

### Installation

Install ClimaRivers from the Julia package manager:

```julia
using Pkg
Pkg.add("ClimaRivers")
```

To load the package in a Julia session:

```julia
using ClimaRivers
```

### Cloning the repository

If you want to develop or contribute to ClimaRivers, clone the repository and register it as a
development package:

```sh
git clone https://github.com/CliMA/ClimaRivers.jl
cd ClimaRivers.jl
```

```julia
using Pkg
Pkg.develop(path = ".")
```

### Running the test suite

To verify your installation, run the package tests:

```julia
using Pkg
Pkg.test("ClimaRivers")
```

### Building the documentation locally

First instantiate the docs environment, then run the build script:

```sh
julia --project=docs/ -e 'using Pkg; Pkg.instantiate()'
julia --project=docs/ docs/make.jl
```
