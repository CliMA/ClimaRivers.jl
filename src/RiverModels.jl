# Contains the abstract river model types, structs and methods
export HillslopeChannelRiverModel, get_basin_list

using CSV, DataFrames, Statistics

#general model level
abstract type AbstractRiverModel end

# hillslope-channel model
abstract type AbstractHillslopeModel end
abstract type AbstractChannelModel end

struct HillslopeChannelRiverModel{
    HS <: AbstractHillslopeModel,
    CH <: AbstractChannelModel,
} <: AbstractRiverModel
    hillslope_model::HS
    channel_model::CH
end


# Specific hillslope-channel models loaded here:
# include("MizurouteV1.jl")
