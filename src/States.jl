# Contains the structs that are evolved by the river model, and methods to instantiate them
export RiverState, HillslopeChannelRiverState

"""
    RiverState

Abstract base type for all river state containers.

$(TYPEDEF)
"""
abstract type RiverState end

"""
    HillslopeChannelRiverState

Snapshot of the hillslope convolution history and channel routing state for every basin in the network, paired with the `DateWindow` over which that history was computed.

$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct HillslopeChannelRiverState <: RiverState
    "Mapping of basin ID to convolved runoff timeseries within the lag window (last entry is the current time step) [m³/s]"
    hillslope_state::Dict
    "Mapping of basin ID to routed channel streamflow at the end of the window [m³/s]"
    channel_state::Dict
    "Date window over which the state history was computed"
    date_window::DateWindow
end
