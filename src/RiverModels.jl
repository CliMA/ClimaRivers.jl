# Contains the abstract river model types, structs and methods
export HillslopeChannelRiverModel, get_basin_list

using CSV, DataFrames, Statistics

#general model level
"""
    AbstractRiverModel

Abstract base type for all river routing models.

$(TYPEDEF)
"""
abstract type AbstractRiverModel end

# hillslope-channel model
"""
    AbstractHillslopeModel

Abstract base type for hillslope sub-models that transform basin runoff into lateral inflow.

$(TYPEDEF)
"""
abstract type AbstractHillslopeModel end

"""
    AbstractChannelModel

Abstract base type for channel sub-models that route lateral inflow downstream along river reaches.

$(TYPEDEF)
"""
abstract type AbstractChannelModel end

"""
    HillslopeChannelRiverModel

Composite river model pairing a hillslope sub-model with a channel sub-model.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct HillslopeChannelRiverModel{
    HS <: AbstractHillslopeModel,
    CH <: AbstractChannelModel,
} <: AbstractRiverModel
    "Hillslope sub-model"
    hillslope_model::HS
    "Channel sub-model"
    channel_model::CH
end


# Specific hillslope-channel models loaded here:
# include("MizurouteV1.jl")
