export MizurouteHillslopeV1, MizurouteChannelV1

# Contains the Mizuroute model    
struct MizurouteHillslopeV1{FT <: AbstractFloat} <: AbstractHillslopeModel
    "Shape factor, a (adjusted)"
    shape::FT
    "Timescale factor, θ [day]"
    timescale::FT
    "Max time (days)"
    t_max::FT
end
# MizurouteHillslopeV1(x,y) 

function MizurouteHillslopeV1{FT}() where {FT <: AbstractFloat}
    shape = FT(1.5)
    timescale = FT(1.0)
    t_max = FT(60.0)
    return MizurouteHillslopeV1(shape, timescale, t_max)
end

struct MizurouteChannelV1{FT <: AbstractFloat} <: AbstractChannelModel
    "Wave velocity, C [m/day]"
    wave_velocity::FT
    "Diffusivity, D [m²/day] (adjusted)"
    diffusivity::FT
    "Max time (days)"
    t_max::FT
end

function MizurouteChannelV1{FT}() where {FT <: AbstractFloat}
    wave_velocity = FT(1.5 * 86400)
    diffusivity = FT(800 * 86400)
    t_max = FT(120.0)
    return MizurouteChannelV1(wave_velocity, diffusivity, t_max)
end
