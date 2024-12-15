# general methods for routing rivers
export compute_streamflow,
    compute_river_state,
    compute_channel_state,
    compute_hillslope_state

using CSV, DataFrames, Dates, DSP, SpecialFunctions

# methods
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
    dates = get_all_dates(date_window)

    all_basin_ids = static_env.basin_ids
    attributes_df = static_env.attributes

    a, θ = hillslope_model.shape, hillslope_model.timescale
    t_max = hillslope_model.t_max

    distribution = [
        (t^(a - 1) * exp(-t / θ)) / (θ^a * SpecialFunctions.gamma(a)) for
        t in 0:(t_max - 1)
    ]

    new_state =
        Dict(eachrow([all_basin_ids repeat([[NaN]], length(all_basin_ids))])) # id -> vector{Float64}}  
    for basin_id in all_basin_ids
        timeseries_df = forcing_timeseries[basin_id]
        filtered_df =
            filter(row -> start_date <= row[:date] <= end_date, timeseries_df)
        basin_area =
            attributes_df[attributes_df.HYBAS_ID .== basin_id, :area][1]
        runoff =
            (filtered_df[:, :sro_sum] .+ filtered_df[:, :ssro_sum]) .*
            basin_area ./ day_to_s .* km²_to_m²

        streamflow = DSP.conv(runoff, distribution)[1:size(runoff)[1], :][:]

        new_state[basin_id] = streamflow
    end

    return new_state

end

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

# Recursive function to get a list of all upstream basins
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
    dates = get_all_dates(date_window)

    C, D = channel_model.wave_velocity, channel_model.diffusivity
    t_max = channel_model.t_max

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
                exp(-((C * t - x)^2 / (4 * D * t))) for
                t in 1:min(t_max, length(up_timeseries))
            ]

            streamflow = dot(up_q[:], distribution[end:-1:1]) # q(t) = sum(q(s)*dist(t-s))

            new_state[basin_id] += streamflow # get final streamflow
        end

    end
    return new_state

end


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

function compute_streamflow(
    river_state::RS,
    static_env::SE,
    dynamic_env::DE,
) where {RS <: RiverState, SE <: StaticEnvironment, DE <: DynamicEnvironment}

    output_dir = dynamic_env.output_dir
    all_basin_ids = static_env.basin_ids

    hillslope_state = river_state.hillslope_state
    channel_state = river_state.channel_state
    date_window = river_state.date_window

    total_streamflow =
        Dict(eachrow([all_basin_ids repeat([NaN], length(all_basin_ids))]))
    for basin_id in all_basin_ids
        total_streamflow[basin_id] =
            hillslope_state[basin_id][end] + channel_state[basin_id]
    end
    return total_streamflow
end

function compute_streamflow(
    river_state::RS,
    env::EE,
) where {RS <: RiverState, EE <: Environment}
    return compute_streamflow(river_state, env.static_env, env.dynamic_env)
end
