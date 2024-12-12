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


function compute_streamflow(
    river_state::RS,
    static_env::SE,
    dynamic_env::DE,
) where {RS <: RiverState, SE <: StaticEnvironment, DE <: DynamicEnvironment}

    output_dir = dynamic_env.output_dir

    all_basin_ids = static_env.basin_ids

    for basin_id in all_basin_ids
        channel_file = joinpath(output_dir, "channel_basin_$basin_id.csv")
        hillslope_file = joinpath(output_dir, "hillslope_basin_$basin_id.csv")
        total_file = joinpath(output_dir, "basin_$basin_id.csv")

        # Check if files exist
        if !(isfile(channel_file) && isfile(hillslope_file))
            println("One or more files for basin_id $basin_id are missing.")
            return nothing
        end

        channel_df = CSV.read(channel_file, DataFrame)
        hillslope_df = CSV.read(hillslope_file, DataFrame)

        # Compute the sum of hillslope and channel streamflows
        total_streamflow = hillslope_df.streamflow .+ channel_df.streamflow

        # Create a new DataFrame with the results
        result_df = DataFrame(
            date = channel_df.date,
            total_streamflow = total_streamflow,
        )

        # Save the DataFrame to a new CSV
        CSV.write(total_file, result_df)
        println("Results saved to $total_file")
    end
end

function compute_streamflow(
    river_state::RS,
    env::E,
) where {RS <: RiverState, E <: Environment}
    return compute_streamflow(river_state, env.static_env, env.dynamic_env)
end


# Specific hillslope-channel models loaded here:
# include("MizurouteV1.jl")
