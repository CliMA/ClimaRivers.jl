# general methods for routing rivers
export compute_streamflow!,
    update_state_from_hillslope!, update_state_from_channel!

using CSV, DataFrames, Dates, DSP, SpecialFunctions

# methods
function compute_streamflow!(
    river_state::RS,
    river_model::HCM,
    environment::E,
    start_date::Date,
    end_date::Date,
) where {RS <: RiverState, HCM <: HillslopeChannelRiverModel, E <: Environment}
    update_state!(river_state, river_model, environment, start_date, end_date)
    return calculate_streamflow(river_state, environment)
end

function update_state!(
    river_state::RS,
    river_model::HCM,
    environment::E,
    start_date::Date,
    end_date::Date,
) where {RS <: RiverState, HCM <: HillslopeChannelRiverModel, E <: Environment}
    update_state_from_hillslope!(
        river_state,
        river_model.hillslope_model,
        environment,
        start_date,
        end_date,
    )
    update_state_from_channel!(
        river_state,
        river_model.channel_model,
        environment,
        start_date,
        end_date,
    )
end

# Auxiliary function
## function for reading basins from txt file into Vector{Int}
# function get_basin_list(basins_file::String)
#     basins_file = Int64[]
#     file = open(joinpath(basins_file))
#     for line in eachline(file)
#         push!(basins_file, parse(Int64, line))
#     end
#     close(file)

#     return basins_file
# end

# only for one routing lv
function update_state_from_hillslope!(
    river_state::RS,
    hillslope_model::HM,
    env::E,
    start_date::Date,
    end_date::Date,
) where {RS <: RiverState, HM <: AbstractHillslopeModel, E <: Environment}
    println("Starting hillslope update")

    # Constants
    day_to_s = 86400
    km²_to_m² = 1000000

    forcing_timeseries_dir = env.dynamic_env.forcing_timeseries_dir
    output_dir = env.dynamic_env.output_dir
    dates = collect(start_date:Day(1):end_date)

    basins_dir = env.static_env.basins_dir
    attributes_df = CSV.read(
        joinpath(env.static_env.attributes_dir, "attributes.csv"),
        DataFrame,
    )

    a, θ = hillslope_model.shape, hillslope_model.timescale
    t_max = hillslope_model.t_max

    distribution = [
        (t^(a - 1) * exp(-t / θ)) / (θ^a * SpecialFunctions.gamma(a)) for
        t in 0:(t_max - 1)
    ]

    all_basin_ids = get_basin_list(joinpath(basins_dir, "all_basin_ids.txt"))

    for basin_id in all_basin_ids
        timeseries_df = CSV.read(
            joinpath(forcing_timeseries_dir, "basin_$basin_id.csv"),
            DataFrame,
        )
        filtered_df =
            filter(row -> start_date <= row[:date] <= end_date, timeseries_df)
        basin_area =
            attributes_df[attributes_df.HYBAS_ID .== basin_id, :area][1]
        runoff =
            (filtered_df[:, :sro_sum] .+ filtered_df[:, :ssro_sum]) .*
            basin_area ./ day_to_s .* km²_to_m²

        streamflow = DSP.conv(runoff, distribution)[1:size(runoff)[1], :][:]

        output_df = DataFrame(date = dates, streamflow = streamflow)

        CSV.write(
            joinpath(output_dir, "hillslope_basin_$basin_id.csv"),
            output_df,
        )
    end
end

# Recursive function to get a list of all upstream basins
function get_upstream_basins(basin_id::String, graph_dict::Dict{String, Any})
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

function update_state_from_channel!(
    river_state::RS,
    channel_model::CM,
    env::E,
    start_date::Date,
    end_date::Date,
) where {RS <: RiverState, CM <: AbstractChannelModel, E <: Environment}
    println("Starting channel update")

    km_to_m = 1e3

    output_dir = env.dynamic_env.output_dir
    forcing_timeseries_dir = env.dynamic_env.forcing_timeseries_dir

    graph_dict = env.static_env.graph_dict
    basins_dir = env.static_env.basins_dir
    attributes_df = CSV.read(
        joinpath(env.static_env.attributes_dir, "attributes.csv"),
        DataFrame,
    )

    C, D = channel_model.wave_velocity, channel_model.diffusivity
    t_max = channel_model.t_max

    all_basin_ids = get_basin_list(joinpath(basins_dir, "all_basin_ids.txt"))

    # Iterate over basins in the given routing level
    for basin_id in all_basin_ids
        # Get current streamflow in the basin
        timeseries_df = CSV.read(
            joinpath(output_dir, "hillslope_basin_$basin_id.csv"),
            DataFrame,
        )

        # Allocate streamflow from upstreams
        up_streamflow = zeros(length(timeseries_df[:, :streamflow]))

        # Iterate over upstreams
        upstream_basin_list = get_upstream_basins(string(basin_id), graph_dict)
        for up_basin in upstream_basin_list
            # Read DataFrame with inputs from upstream
            up_timeseries_df = CSV.read(
                joinpath(output_dir, "hillslope_basin_$up_basin.csv"),
                DataFrame,
            )

            # Get riverine distance until the outlet of the basin from HydroATLAS
            dist =
                attributes_df[
                    attributes_df.HYBAS_ID .== up_basin,
                    :DIST_MAIN,
                ][1] -
                attributes_df[attributes_df.HYBAS_ID .== basin_id, :DIST_MAIN][1]
            dist *= km_to_m

            # Get upstream streamflow
            up_q = up_timeseries_df[:, :streamflow]
            up_q = reshape(up_q, :, 1)

            # Allocate streamflow array
            streamflow = similar(up_q)

            # Generate the h(dist,t) function values
            x = dist[1]
            distribution = [
                x / (2 * t * sqrt(π * D * t)) *
                exp(-((C * t - x)^2 / (4 * D * t))) for t in 1:t_max
            ]

            # perform convolution
            streamflow[:, 1] =
                DSP.conv(up_q[:, 1], distribution)[1:size(up_q)[1]]

            up_streamflow += streamflow
        end

        # Get dates array
        dates = timeseries_df.date

        channel_streamflow_df =
            DataFrame(date = dates, streamflow = up_streamflow[:, 1])

        # Override streamflow timeseries
        CSV.write(
            joinpath(output_dir, "channel_basin_$basin_id.csv"),
            channel_streamflow_df,
        )
    end
end
