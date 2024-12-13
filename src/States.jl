# Contains the structs that are evolved by the river model, and methods to instantiate them
export RiverState, HillslopeChannelRiverState

abstract type RiverState end

struct HillslopeChannelRiverState <: RiverState
    "Hillslope state history [Dict(id -> Matrix: time-within-lag (end=current) x basin)]"
    hillslope_state::Dict
    "Channel state [Dict(id -> Matrix: 1 x basin)]"
    channel_state::Dict
    "Date window [DateWindow] of the state history"
    date_window::DateWindow
end
