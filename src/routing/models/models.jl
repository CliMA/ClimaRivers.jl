using Flux

abstract type AbstractHillslopeModel end
abstract type AbstractChannelModel end

struct MizuRouteV1Hillslope{FT <: AbstractFloat} <: AbstractHillslopeModel
    a::FT
    θ::FT
    function MizuRouteV1Hillslope{FT}(a,θ) where {FT <: AbstractFloat}
        new(FT(a), FT(θ))
    end
end

function MizuRouteV1Hillslope{FT}() where {FT <: AbstractFloat}
    a = 1.5
    θ = 1
    return MizuRouteV1Hillslope{FT}(a,θ)
end

# x = MizuRouteV1Hillslope{Float64}(1.5, 2)

struct MizuRouteV1Channel{FT <: Real} <: AbstractChannelModel
    C::FT
    D::FT
end


struct MizuRoute
    hillslope::MizuRouteV1Hillslope
    channel::MizuRouteV1Channel
end

### in example file:
# using ClimaRivers # gives access to all the structs
# alpha = 1.0
# beta = 1.0
# hillslope = MizuRouteV1Hillslope(alpha, beta)
# C = 1.0
# D = 1.0
# channel = MizuRouteV1Channel(C,D)
# routing_model = MizuRoute(hillslope,channel)

function calculate_streamflow(routing_model::MizuRoute, environmental_conditions::EC)
    channel_source = calculate_channel_source(routing_model.hillslope, environmental_conditions)
    streamflow = calculate_streamflow_from_channel(routing_model.channel, channel_source, environmental_conditions)
    return streamflow
end





struct AbstractPhysicalModel <: AbstractModel
    model::Function
    params::Vector{AbstractFloat}
end