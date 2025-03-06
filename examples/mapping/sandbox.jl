using NCDatasets, Statistics

# File paths
data_file_path = joinpath(@__DIR__, "..", "..", "data")
nc_file = joinpath(data_file_path, "source_data", "era5", "globe_year_month", "era5_1990_01.nc")

# Open NetCDF dataset
ds = Dataset(nc_file)

# Select the 'sro' variable
sro = ds["sro"]

# Extract scale factor and offset from attributes
scale_factor = sro.attrib["scale_factor"]
add_offset = sro.attrib["add_offset"]

# Print shape and dimensions
println("Shape of 'sro': ", size(sro))  # Shape of 'sro': (3600, 1801, 31)
println("Dimensions: ", dimnames(sro))  # Dimensions: ("longitude", "latitude", "time")

# Print attributes (metadata)
println("\nAttributes of 'sro':")
for attr in keys(sro.attrib)
    println("  ", attr, ": ", sro.attrib[attr])
end

# Compute basic statistics
sro_data = sro[:, :, :]  # Extract entire dataset
# print type of sro_Data
println("Type of sro_data: ", eltype(sro_data))
# get dimensions of sro_data
println("Dimensions of sro_data: ", size(sro_data))
# get sample values of sro_data
println("Sample values of sro_data: ", sro_data[1:2, 1:2, 1])

non_missing_indices = findall(!ismissing, sro_data)
println("Total non-missing values: ", length(non_missing_indices))

valid_sro_values = skipmissing(sro_data)  # Returns an iterator over non-missing values
valid_sro_array = collect(valid_sro_values)  # Converts to standard array
sro_data_clean = coalesce.(sro_data, NaN)  # Replace missing with NaN

println("Min: ", minimum(valid_sro_array))
println("Max: ", maximum(valid_sro_array))
println("Mean: ", mean(valid_sro_array))

# sro_real = (sro_data_clean .* scale_factor) .+ add_offset

# # Compute statistics on adjusted values
# valid_sro_real = sro_real[.!isnan.(sro_real)]  # Remove NaNs
# println("\nStatistics for adjusted 'sro':")
# println("  Min: ", minimum(valid_sro_real))
# println("  Max: ", maximum(valid_sro_real))
# println("  Mean: ", mean(valid_sro_real))

# Close dataset
close(ds)
