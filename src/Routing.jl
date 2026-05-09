# general methods for routing rivers
export compute_streamflow,
    compute_river_state,
    compute_channel_state,
    compute_hillslope_state,
    get_upstream_basins

using CSV, DataFrames, Dates, DSP, SpecialFunctions

# methods
"""
$(TYPEDSIGNATURES)

Advance `initial_date_window` one step at a time until `end_date`, computing a `HillslopeChannelRiverState`
and total streamflow at each step. Returns `(streamflows, river_states)` as parallel vectors.

# Arguments
- `initial_date_window`: starting date window for the first simulation step
- `river_model`: hillslope-channel model defining the delay distributions
- `env`: environment containing basin network and forcing data
- `end_date`: simulation stops when `date_window.end_date` exceeds this date
"""
function compute_streamflow(
    initial_date_window::DateWindow,
    river_model::HCM,
    env::E,
    end_date::Date,
) where {HCM <: HillslopeChannelRiverModel, E <: Environment}

    date_window = initial_date_window
    river_states = []
    streamflows = []

    while date_window.end_date <= end_date
        # @info "computing streamflow over window [$(date_window.start_date),$(date_window.end_date)]"
        river_state = compute_river_state(date_window, river_model, env)
        push!(river_states, river_state)
        push!(streamflows, compute_streamflow(river_state, env))
        date_window = iterate(date_window)
    end

    return streamflows, river_states
end

"""
$(TYPEDSIGNATURES)

Compute and return the `HillslopeChannelRiverState` for `date_window`.

# Arguments
- `date_window`: time window for which to compute hillslope and channel states
- `river_model`: hillslope-channel model defining the delay distributions
- `env`: environment containing basin network and forcing data
"""
function compute_river_state(
    date_window::DateWindow,
    river_model::HCM,
    env::E,
) where {HCM <: HillslopeChannelRiverModel, E <: Environment}

    new_hillslope_state =
        compute_hillslope_state(date_window, river_model.hillslope_model, env)

    new_channel_state = compute_channel_state(
        new_hillslope_state,
        date_window,
        river_model.channel_model,
        env,
    )
    return HillslopeChannelRiverState(
        new_hillslope_state,
        new_channel_state,
        date_window,
    )

end

"""
$(TYPEDSIGNATURES)

Convolve each basin's runoff timeseries with the gamma delay distribution defined by `hillslope_model`
over `date_window`, and return a `Dict` mapping basin ID to convolved streamflow timeseries [m³/s].

# Arguments
- `date_window`: time window to extract forcing data and compute the convolution over
- `hillslope_model`: gamma distribution parameters (shape, timescale, t_max)
- `static_env`: basin network description providing IDs, attributes, and graph
- `dynamic_env`: per-basin forcing timeseries and output directory
"""
function compute_hillslope_state(
    date_window::DateWindow,
    hillslope_model::HM,
    static_env::SE,
    dynamic_env::DE,
) where {
    HM <: AbstractHillslopeModel,
    SE <: StaticEnvironment,
    DE <: DynamicEnvironment,
}
    # Constants
    day_to_s = 86400
    km²_to_m² = 1000000

    forcing_timeseries = dynamic_env.forcing_timeseries
    output_dir = dynamic_env.output_dir

    start_date = date_window.start_date
    end_date = date_window.end_date
    window_length = end_date - start_date

    all_basin_ids = static_env.basin_ids
    attributes_df = static_env.attributes

    a, θ = hillslope_model.shape, hillslope_model.timescale
    t_max = hillslope_model.t_max
    if window_length < Day(t_max)
        throw(
            ArgumentError(
                "`DateWindow` length must exceed `HillslopeModel.t_max`.
\n Instead, received length $(window_length) and t_max $(t_max) (days)",
            ),
        )
    end
    distribution = [
        (t^(a - 1) * exp(-t / θ)) / (θ^a * SpecialFunctions.gamma(a)) for
        t in 0:(t_max - 1)
    ]

    new_state =
        Dict(eachrow([all_basin_ids repeat([[NaN]], length(all_basin_ids))])) # id -> vector{Float64}}  

    date_set = Set(get_all_dates(date_window))
    # convert to column table to get row indices [MUCH faster than filtering the DF directly]
    timeseries_df = forcing_timeseries[all_basin_ids[1]]
    tbl = Tables.columntable(timeseries_df)
    idx_dates = in(date_set).(tbl.date) # bottleneck, but only call once for all basins

    for basin_id in all_basin_ids
        timeseries_df = forcing_timeseries[basin_id]
        tbl = Tables.columntable(timeseries_df)

        basin_area =
            attributes_df[attributes_df.HYBAS_ID .== basin_id, :area][1]
        runoff =
            (tbl.sro_sum[idx_dates] .+ tbl.ssro_sum[idx_dates]) .* basin_area ./
            day_to_s .* km²_to_m²

        streamflow = DSP.conv(runoff, distribution)[1:size(runoff)[1], :][:]

        new_state[basin_id] = streamflow
    end

    return new_state

end

"""
$(TYPEDSIGNATURES)

Computes the hillslope state, by convolving a weighted `forcing_timeseries` and `hillslope_model` delay distribution over the `date_window`.
"""
function compute_hillslope_state(
    date_window::DateWindow,
    hillslope_model::HM,
    env::EE,
) where {HM <: AbstractHillslopeModel, EE <: Environment}
    return compute_hillslope_state(
        date_window,
        hillslope_model,
        env.static_env,
        env.dynamic_env,
    )
end

"""
$(TYPEDSIGNATURES)

Recursively collect all basin IDs upstream of `basin_id` in `graph_dict` and return a
deduplicated list. Returns an empty list if `basin_id` has no upstream neighbours.

# Arguments
- `basin_id`: string ID of the target basin
- `graph_dict`: adjacency mapping from basin ID to its list of direct upstream neighbour IDs (as in `StaticEnvironment.graph_dict`)

# Examples
```jldoctest
julia> using ClimaRivers

julia> graph = Dict("outlet" => ["A", "B"], "A" => ["C"], "B" => [], "C" => []);

julia> get_upstream_basins("outlet", graph)
3-element Vector{Any}:
 "A"
 "C"
 "B"
```
"""
function get_upstream_basins(basin_id::String, graph_dict::Dict)
    # Base case: if the current basin has no upstream basins, return an empty list
    if isempty(graph_dict[basin_id])
        return []
    end

    # Initialize the list of upstream basins
    upstream_basin_list = []

    # Iterate over the direct upstream basins of the current basin
    for up_basin in graph_dict[basin_id]
        # Add the current upstream basin
        push!(upstream_basin_list, up_basin)

        # Recursively collect upstream basins of this upstream basin
        append!(
            upstream_basin_list,
            get_upstream_basins(string(up_basin), graph_dict),
        )
    end

    # Remove duplicates to ensure each basin appears only once
    return unique(upstream_basin_list)
end

"""
$(TYPEDSIGNATURES)

Route hillslope outflows through the channel network using the diffusive wave kernel of
`channel_model`, accumulating upstream contributions at each basin outlet over `date_window`.
Returns a `Dict` mapping basin ID to routed channel streamflow [m³/s] at the end of the window.

# Arguments
- `new_hillslope`: Dict mapping basin ID to convolved hillslope streamflow timeseries [m³/s] (output of `compute_hillslope_state`)
- `date_window`: time window over which the hillslope state was computed
- `channel_model`: diffusive wave parameters (wave velocity, diffusivity, t_max)
- `static_env`: basin network description providing IDs, attributes with `DIST_MAIN`, and graph
- `dynamic_env`: provides the output directory
"""
function compute_channel_state(
    new_hillslope::Dict,
    date_window::DateWindow,
    channel_model::CM,
    static_env::SE,
    dynamic_env::DE,
) where {
    CM <: AbstractChannelModel,
    SE <: StaticEnvironment,
    DE <: DynamicEnvironment,
}
    km_to_m = 1e3

    output_dir = dynamic_env.output_dir

    graph_dict = static_env.graph_dict
    all_basin_ids = static_env.basin_ids
    attributes_df = static_env.attributes

    start_date = date_window.start_date
    end_date = date_window.end_date
    window_length = (end_date - start_date)

    C, D = channel_model.wave_velocity, channel_model.diffusivity
    t_max = channel_model.t_max
    if window_length < Day(t_max)
        throw(
            ArgumentError(
                "`DateWindow` length must exceed `ChannelModel.t_max`.
\n Instead, received length $(window_length) and t_max $(t_max) (days)",
            ),
        )
    end
    # Iterate over basins in the given routing level
    new_state = Dict(eachrow([all_basin_ids zeros(length(all_basin_ids))])) # id -> 0.0  
    for basin_id in all_basin_ids

        timeseries_df = new_hillslope[basin_id]

        # Iterate over upstreams
        upstream_basin_list = get_upstream_basins(string(basin_id), graph_dict)
        for up_basin in upstream_basin_list

            up_timeseries = new_hillslope[up_basin]

            # Get riverine distance until the outlet of the basin from HydroATLAS
            dist =
                attributes_df[
                    attributes_df.HYBAS_ID .== up_basin,
                    :DIST_MAIN,
                ][1] -
                attributes_df[attributes_df.HYBAS_ID .== basin_id, :DIST_MAIN][1]
            dist *= km_to_m

            # Get upstream hillslope state
            up_q = up_timeseries
            up_q = reshape(up_q, :, 1)

            # Allocate streamflow array
            streamflow = similar(up_q)

            # Generate the h(dist,t) function values
            x = dist[1]
            distribution = [
                x / (2 * t * sqrt(π * D * t)) *
                exp(-((C * t - x)^2 / (4 * D * t))) for t in 1:t_max
            ]

            streamflow =
                dot(up_q[(end - t_max + 1):end], distribution[end:-1:1]) # q(t) = sum(q(s)*dist(t-s))

            new_state[basin_id] += streamflow # get final streamflow
        end

    end
    return new_state

end


"""
$(TYPEDSIGNATURES)

Computes the channel state at the end of the `date_window`, using the `new_hillslope` state history.
"""
function compute_channel_state(
    new_hillslope::Dict,
    date_window::DateWindow,
    channel_model::CM,
    env::EE,
) where {CM <: AbstractChannelModel, EE <: Environment}
    compute_channel_state(
        new_hillslope,
        date_window,
        channel_model,
        env.static_env,
        env.dynamic_env,
    )
end

"""
$(TYPEDSIGNATURES)

Sum the hillslope and channel contributions from `river_state` to produce total streamflow [m³/s]
at each basin outlet. Returns a `Dict` mapping basin ID to total streamflow.

# Arguments
- `river_state`: computed hillslope and channel states for the current date window
- `static_env`: provides the list of basin IDs
- `dynamic_env`: provides the output directory
"""
function compute_streamflow(
    river_state::RS,
    static_env::SE,
    dynamic_env::DE,
) where {
    RS <: HillslopeChannelRiverState,
    SE <: StaticEnvironment,
    DE <: DynamicEnvironment,
}

    output_dir = dynamic_env.output_dir
    all_basin_ids = static_env.basin_ids

    hillslope_state = river_state.hillslope_state
    channel_state = river_state.channel_state

    total_streamflow =
        Dict(eachrow([all_basin_ids repeat([NaN], length(all_basin_ids))]))
    for basin_id in all_basin_ids
        total_streamflow[basin_id] =
            hillslope_state[basin_id][end] + channel_state[basin_id]
    end
    return total_streamflow
end

"""
$(TYPEDSIGNATURES)

Compute the streamflow from an `Environment` and a computed `HillslopeChannelRiverState`
"""
function compute_streamflow(
    river_state::RS,
    env::EE,
) where {RS <: HillslopeChannelRiverState, EE <: Environment}
    return compute_streamflow(river_state, env.static_env, env.dynamic_env)
end
