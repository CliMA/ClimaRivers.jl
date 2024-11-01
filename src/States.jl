# Contains the structs that are evolved by the river model, and methods to instantiate them
export RiverState

struct RiverState{AM <: AbstractMatrix}
    hillslope::AM # instantaneous
    channel::AM # instantaneous
end

# initialize method
# initialize_state(river_model::HCRM) where {HCRM <: HillslopChannelRiverModel} end
