module ClimaRivers

#using deps:
using LinearAlgebra,
    Statistics, Random, DocStringExtensions, Dates, JSON, SpecialFunctions

# includes
include("Environments.jl")
include("RiverModels.jl")
include("States.jl")
include("Routing.jl")
include("MizurouteV1.jl")
include("show.jl")

end # module ClimaRivers
