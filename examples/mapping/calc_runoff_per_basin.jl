using JSON
using NCDatasets

# File paths
data_file_path = joinpath(@__DIR__, "..", "..", "data")

thin_json_file = joinpath(
    data_file_path,
    "midway_data",
    "mapping_dicts",
    "thinned_era5_grid_to_basin_dict.json",
)
thin_nc_file = joinpath(
    data_file_path,
    "source_data",
    "era5",
    "globe_year_month",
    "thinned_era5_1990_01.nc",
)

base_json_file = joinpath(
    data_file_path,
    "midway_data",
    "mapping_dicts",
    "era5_grid_to_basin_dict.json",
)
base_nc_file = joinpath(
    data_file_path,
    "source_data",
    "era5",
    "globe_year_month",
    "era5_1990_01.nc",
)

json_files = [thin_json_file, base_json_file]
nc_files = [thin_nc_file, base_nc_file]

thin_basin_sro_sums = Dict()
base_basin_sro_sums = Dict()

sro_dicts = [thin_basin_sro_sums, base_basin_sro_sums]

for i in 1:2
    json_file = json_files[i]
    nc_file = nc_files[i]

    # Load JSON data
    basin_data = JSON.parsefile(json_file)

    # Open NetCDF file
    ds = Dataset(nc_file, "r")

    # Extract the 'sro' variable (Surface Runoff)
    sro_data = ds["sro"][:, :, :]  # Dimensions: ("longitude", "latitude", "time")

    # Dictionary to store weighted normalized sums
    basin_sro_sums = sro_dicts[i]

    last_t = size(sro_data, 3)

    # Process each basin
    for (basin_id, values) in basin_data
        weighted_sum = 0.0
        total_weight = 0.0

        for (lon_idx, lat_idx, weight) in values
            sro_value = sro_data[lon_idx, lat_idx, last_t]

            # Ignore missing values (_FillValue in NetCDF)
            if !ismissing(sro_value)
                weighted_sum += sro_value * weight
                total_weight += weight
            end
            # for t in 1:size(sro_data, 3)  # Iterate over time steps
            #     sro_value = sro_data[lon_idx, lat_idx, t]

            #     # Ignore missing values (_FillValue in NetCDF)
            #     if !ismissing(sro_value)
            #         weighted_sum += sro_value * weight
            #         total_weight += weight
            #     end
            # end
        end

        # Compute normalized weighted sum
        normalized_sro = weighted_sum / total_weight

        # Store in dictionary
        basin_sro_sums[basin_id] = normalized_sro
    end

    # Close NetCDF file
    close(ds)
end

using Plots
using Statistics

# Function to calculate RMSE
function calculate_diff_per_basin(thin_sums, base_sums)
    diff_values = Dict()
    max_thin = maximum(filter(x -> !isnan(x), collect(values(thin_sums))))
    max_base = maximum(filter(x -> !isnan(x), collect(values(base_sums))))
    max_value = max(max_thin, max_base)
    @info "max_value: $max_value"
    large_diff_values = Dict()
    for basin_id in keys(thin_sums)
        if haskey(base_sums, basin_id)
            thin_value = thin_sums[basin_id]
            base_value = base_sums[basin_id]
            diff = abs(thin_value - base_value) / max_value #max(thin_value, base_value)
            diff_values[basin_id] = diff
            if diff >= 0.8
                large_diff_values[basin_id] = diff
            end
        end
    end
    return diff_values, large_diff_values
end

# Calculate RMSE values
diff_values, large_diff_values =
    calculate_diff_per_basin(thin_basin_sro_sums, base_basin_sro_sums)

# Plot the distribution of diff values
diff_list = collect(values(diff_values))
histogram(
    diff_list,
    bins = 30,
    label = "Diff Values",
    alpha = 0.7,
    legend = :topright,
)
xlabel!("Diff")
ylabel!("Frequency")
title!("Distribution of Diff Values")

# Save the plot
savefig("diff_distribution.png")

# Save large_diff_values as a JSON file
output_file = joinpath(@__DIR__, "playground", "large_diff_values.json")
open(output_file, "w") do io
    JSON.print(io, large_diff_values)
end
# plot a histogram of the normalized weighted sums for the thinned and base basin data
# thinned_sums = collect(values(thin_basin_sro_sums))
# base_sums = collect(values(base_basin_sro_sums))

# histogram(thinned_sums, bins=30, label="Thinned Basin SRO Sums", alpha=0.5, legend=:topright)
# histogram!(base_sums, bins=30, label="Base Basin SRO Sums", alpha=0.5)

# xlabel!("Normalized Weighted SRO Sum")
# ylabel!("Frequency")
# title!("Histogram of Normalized Weighted SRO Sums")

# savefig("normalized_weighted_sro_sums_histogram.png")
