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

# Auxiliary function
## function for reading basins from txt file into Vector{Int}
function get_basin_list(basins_file::String)
    basins_list = Int64[]
    file = open(joinpath(basins_file))
    for line in eachline(file)
        push!(basins_list, parse(Int64, line))
    end
    close(file)

    return basins_list
end

function calculate_streamflow(
    river_state::RS,
    env::E,
) where {RS <: RiverState, E <: Environment}

    output_dir = env.dynamic_env.output_dir

    all_basin_ids =
        get_basin_list(joinpath(env.static_env.basins_dir, "all_basin_ids.txt"))

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

# Specific hillslope-channel models loaded here:
# include("MizurouteV1.jl")
