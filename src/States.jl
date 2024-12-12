# Contains the structs that are evolved by the river model, and methods to instantiate them
export RiverState, HillslopeChannelRiverState

abstract type RiverState end


struct HillslopeChannelRiverState{AM <: AbstractMatrix} <: RiverState
    hillslope::AM # instantaneous
    channel::AM # instantaneous
end

# initialize method

function construct_initial_river_state(environment::EE, river_model::HCRM, date_window::DateWindow) where {HCRM <: HillslopeChannelRiverModel, EE <: Environment}
    
    static_env = environment.static_env
    basin_ids = static_env.basin_ids
    n_basins = length(basin_ids)
    
    # compute times
    
    # hillslope_state
    hillslope_state = zeros(buffer,n_basins)
    
    
    # channel_state
    channel_state = zeros(1,n_basins)
    
    return HillslopeChannelRiverState(hillslope_state, channel_state)
end




