using CSV
using DataFrames
using Statistics

# build environment
data_file_path = joinpath(@__DIR__, "..", "..", "data", "routing")

# build static environment
@info "reading data files from $(data_file_path)"
reference_path = joinpath(
    data_file_path,
    "simulations",
    "simulations_lv05",
    "simulation_gamma-IRF",
)
new_path =
    joinpath(data_file_path, "simulations", "simulations_lv05", "gamma_IRF")
output_path = joinpath(@__DIR__, "csv_files")

# Function to check the streamflow relationship and save results
function check_basin_streamflow(basin_id::String)
    # Construct file paths
    reference_file = joinpath(reference_path, "basin_$basin_id.csv")
    new_file = joinpath(new_path, "basin_$basin_id.csv")
    output_file = joinpath(output_path, "comparison_basin_$basin_id.csv")

    # Check if files exist
    if !(isfile(reference_file) && isfile(new_file))
        println("One or more files for basin_id $basin_id are missing.")
        return nothing
    end

    # Load data
    reference_df = CSV.read(reference_file, DataFrame)
    new_df = CSV.read(new_file, DataFrame)

    # Check if the date columns align
    if !all(reference_df.date .== new_df.date)
        println("Date mismatch for basin_id $basin_id.")
        return nothing
    end

    # Compute the difference
    diff = reference_df.streamflow .- new_df.total_streamflow

    # Create a new DataFrame with the results
    result_df = DataFrame(
        date = new_df.date,
        new_q = new_df.total_streamflow,
        reference_q = reference_df.streamflow,
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
