# Contains the structs that are evolved by the river model, and methods to instantiate them
export RiverState, HillslopeChannelRiverState

abstract type RiverState end

struct HillslopeChannelRiverState <: RiverState
    "Hillslope state history [Dict(id -> Vector: time-within-lag (end=current)]"
    hillslope_state::Dict
    "Channel state [Dict(id -> Float)]"
    channel_state::Dict
    "Date window [DateWindow] of the state history"
    date_window::DateWindow
end
