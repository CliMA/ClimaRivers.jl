export MizurouteHillslopeV1, MizurouteChannelV1

# Contains the Mizuroute model    
"""
    MizurouteHillslopeV1

Mizuroute v1 hillslope model.

Transforms basin runoff into lateral inflow by convolving with a gamma distribution lag kernel
parameterized by a shape factor and a timescale.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct MizurouteHillslopeV1{FT <: AbstractFloat} <: AbstractHillslopeModel
    "Shape factor, a (adjusted)"
    shape::FT
    "Timescale factor, θ [day]"
    timescale::FT
    "Max lag length [day]"
    t_max::Int
end

"""
$(TYPEDSIGNATURES)

Return a `MizurouteHillslopeV1` with default parameters: shape = 1.5, timescale = 1.0 [day], t_max = 60 [day].

# Examples
```jldoctest
julia> MizurouteHillslopeV1{Float64}()
MizurouteHillslopeV1{Float64}
  shape     : 1.5
  timescale : 1.0 day
  t_max     : 60 day
```
"""
function MizurouteHillslopeV1{FT}() where {FT <: AbstractFloat}
    shape = FT(1.5)
    timescale = FT(1.0)
    t_max = 60
    return MizurouteHillslopeV1(shape, timescale, t_max)
end

"""
    MizurouteChannelV1

Mizuroute v1 channel routing model.

Routes hillslope outflow downstream using a diffusive wave transfer function parameterized by
a wave velocity and a diffusivity.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct MizurouteChannelV1{FT <: AbstractFloat} <: AbstractChannelModel
    "Wave velocity, C [m/day]"
    wave_velocity::FT
    "Diffusivity, D [m²/day] (adjusted)"
    diffusivity::FT
    "Max routing lag [day]"
    t_max::Int
end

"""
$(TYPEDSIGNATURES)

Return a `MizurouteChannelV1` with default parameters: wave_velocity = 1.5 × 86400 [m/day], diffusivity = 800 × 86400 [m²/day], t_max = 120 [day].

# Examples
```julia
julia> MizurouteChannelV1{Float64}()
MizurouteChannelV1{Float64}
  wave_velocity : 129600.0 m/day
  diffusivity   : 6.912e7 m²/day
  t_max         : 120 day
```
"""
function MizurouteChannelV1{FT}() where {FT <: AbstractFloat}
    wave_velocity = FT(1.5 * 86400)
    diffusivity = FT(800 * 86400)
    t_max = 120
    return MizurouteChannelV1(wave_velocity, diffusivity, t_max)
end
