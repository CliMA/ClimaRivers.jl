using CSV
using DataFrames
using Statistics

# Define paths
basin_path = "/groups/esm/achiang/ClimaRivers.jl/data/routing/simulations/simulations_lv05/simulation_gamma-IRF"
channel_path = "/groups/esm/achiang/ClimaRivers.jl/data/routing/simulations/simulations_lv05/gamma_IRF"
hillslope_path = "/groups/esm/achiang/ClimaRivers.jl/data/routing/simulations/simulations_lv05/gamma_IRF"
output_path = "/groups/esm/achiang/ClimaRivers.jl/examples/routing/csv_files"  # Directory to save output CSVs

# Function to check the streamflow relationship and save results
function check_basin_streamflow(basin_id::String)
    # Construct file paths
    basin_file = joinpath(basin_path, "basin_$basin_id.csv")
    channel_file = joinpath(channel_path, "channel_basin_$basin_id.csv")
    hillslope_file = joinpath(hillslope_path, "hillslope_basin_$basin_id.csv")
    output_file = joinpath(output_path, "comparison_basin_$basin_id.csv")

    # Check if files exist
    if !(isfile(basin_file) && isfile(channel_file) && isfile(hillslope_file))
        println("One or more files for basin_id $basin_id are missing.")
        return nothing
    end

    # Load data
    basin_df = CSV.read(basin_file, DataFrame)
    channel_df = CSV.read(channel_file, DataFrame)
    hillslope_df = CSV.read(hillslope_file, DataFrame)

    # Check if the date columns align
    if !all(basin_df.date .== channel_df.date) ||
       !all(basin_df.date .== hillslope_df.date)
        println("Date mismatch for basin_id $basin_id.")
        return nothing
    end

    # Compute the sum of hillslope and channel streamflows
    summed_streamflow = hillslope_df.streamflow .+ channel_df.streamflow

    # Compute the difference
    diff = summed_streamflow .- basin_df.streamflow

    # Create a new DataFrame with the results
    result_df = DataFrame(
        date = basin_df.date,
        summed_streamflow = summed_streamflow,
        basin_streamflow = basin_df.streamflow,
        difference = diff,
    )

    # Save the DataFrame to a new CSV
    CSV.write(output_file, result_df)
    println("Results saved to $output_file")

    # Return basic statistics
    max_diff = maximum(abs.(diff))
    mean_diff = mean(abs.(diff))
    println("Basin ID: $basin_id")
    println("Maximum absolute difference: $max_diff")
    println("Mean absolute difference: $mean_diff")

    return (max_diff, mean_diff)
end

# Example usage
basin_id_to_check = "1051315930"  # Replace with the specific basin_id you want to check
check_basin_streamflow(basin_id_to_check)
