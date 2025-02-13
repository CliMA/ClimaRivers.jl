using CSV, DataFrames, Dates

# Define file paths
data_file_path = joinpath(@__DIR__, "..", "..", "shallow_data", "routing")
basin_ids_file = joinpath(data_file_path, "routing_lvs", "routing_lvs_lv05", "all_basin_ids.txt")
shallow_data_dir = joinpath(data_file_path, "timeseries", "timeseries_lv05")
data_dir = joinpath(data_file_path, "..", "..", "data", "routing", "timeseries", "timeseries_lv05")

# Read basin IDs and strip newline characters
basin_ids = strip.(readlines(basin_ids_file))

# Define the date range to keep
start_date = Date("1990-01-01")
end_date = Date("1990-06-30")

# Process each basin file
for basin_id in basin_ids
    basin_file = joinpath(data_dir, "basin_$(basin_id).csv")
    shallow_basin_file = joinpath(shallow_data_dir, "basin_$(basin_id).csv")

    if isfile(basin_file)
        # Load the data
        df = CSV.read(basin_file, DataFrame, stringtype=String)  # Ensure dates are read as strings

        # Filter to keep only first 6 months
        df_filtered = filter(row -> start_date ≤ row.date ≤ end_date, df)

        # Overwrite the file with the filtered data
        CSV.write(shallow_basin_file, df_filtered)
        println("Updated: $shallow_basin_file")
    else
        println("File not found: $basin_file")
    end
end

println("Processing complete.")
