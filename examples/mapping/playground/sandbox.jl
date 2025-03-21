using NCDatasets, Dates

data_file_path = joinpath(@__DIR__, "..", "..", "..", "data")
file_path = joinpath(data_file_path, "source_data", "ClimaLand", "sr_1M_average.nc")

# Read the time variable
ds = Dataset(file_path)
time_values = ds["time"][:]  # Extract time values

# Close dataset
close(ds)

# Print results
println("Extracted time values (seconds): ", time_values)

using NCDatasets, Dates

# Define reference time (assuming NetCDF time counts from 2008-01-01T00:00:00)
ref_time = DateTime("2008-01-01T00:00:00")

# Extract time values
time_seconds = [
    2.6784e6, 5.184e6, 7.8624e6, 1.04544e7, 1.31328e7, 1.57248e7,
    1.84032e7, 2.10816e7, 2.36736e7, 2.6352e7, 2.8944e7, 3.16224e7,
    3.43008e7, 3.672e7, 3.93984e7, 4.19904e7, 4.46688e7, 4.72608e7,
    4.99392e7, 5.26176e7, 5.52096e7, 5.7888e7, 6.048e7, 6.31584e7
]

# Convert to DateTime format
actual_dates = ref_time .+ Second.(Int.(time_seconds))

# Print converted dates
println("Converted dates: ", actual_dates)
