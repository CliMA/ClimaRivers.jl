```@eval
using Pkg
io = IOBuffer()
v = Pkg.installed()["ClimaRivers"]
print(io, """
    # ClimaRivers.jl Documentation (v$(v))

    """)
import Markdown
Markdown.parse(String(take!(io)))
```

## Introduction

ClimaRivers is the surface routing model of the Climate Modeling Alliance (CliMA) Earth System Model, which
also contains other components ([atmosphere](https://github.com/CliMA/ClimaAtmos.jl), [ocean](https://github.com/CliMA/ClimaOcean.jl), [sea-ice](https://github.com/CliMA/ClimaSeaIce.jl)). It is meant to be used with the [ClimaLand model](https://github.com/CliMA/ClimaLand.jl).

## Important Links

- [CliMA Homepage](https://clima.caltech.edu/)
- [CliMA GitHub Organisation](https://github.com/CliMA)
- [ClimaCoupler](https://github.com/CliMA/ClimaCoupler.jl)
- [ClimaAnalysis](https://github.com/CliMA/ClimaAnalysis.jl)
- [Julia Homepage](https://julialang.org)