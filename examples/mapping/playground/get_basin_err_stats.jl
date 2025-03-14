using CSV, DataFrames, JSON, Statistics, Plots

data_file_path = joinpath(@__DIR__, "..", "..", "..", "data")
attr_file = joinpath(
    data_file_path,
    "routing",
    "attributes",
    "attributes_lv05",
    "attributes.csv",
)
json_file = joinpath(@__DIR__, "lv04_large_diff_values.json")

attr_data = CSV.read(attr_file, DataFrame)
err_data = JSON.parsefile(json_file)

basin_list = keys(err_data)

# Convert basin_list to a Set for fast lookup
basin_set = Set(parse(Int64, b) for b in basin_list)

# Filter attr_data to only include rows where HYBAS_ID is in basin_set
filtered_attr_data = filter(row -> row.HYBAS_ID in basin_set, attr_data)

# Compute statistics function
function compute_stats(data, col_name)
    return Dict(
        "Mean" => mean(data[!, col_name]),
        "Median" => median(data[!, col_name]),
        "Min" => minimum(data[!, col_name]),
        "Max" => maximum(data[!, col_name]),
        "Std Dev" => std(data[!, col_name]),
    )
end

# Compute statistics for attr_data and filtered_attr_data
attr_stats = compute_stats(attr_data, :area)
filtered_stats = compute_stats(filtered_attr_data, :area)

# Print statistics
println("Statistics for attr_data:")
for (key, value) in attr_stats
    println("$key: $value")
end

println("\nStatistics for filtered_attr_data:")
for (key, value) in filtered_stats
    println("$key: $value")
end

# Plot histogram
plt = histogram(
    attr_data.area,
    bins = 30,
    alpha = 0.5,
    label = "attr_data",
    color = :blue,
    normalize = true,
)
histogram!(
    plt,
    filtered_attr_data.area,
    bins = 30,
    alpha = 0.5,
    label = "filtered_attr_data",
    color = :red,
    normalize = true,
)
title!("Area Distribution")
xlabel!("Area")
ylabel!("Density")

# Save the plot as a PNG file
output_file = joinpath(@__DIR__, "lv04_area_distribution.png")
savefig(output_file)

# Find the row index of the minimum area in the filtered dataset
min_area_index = argmin(filtered_attr_data.area)

# Retrieve the corresponding basin (HYBAS_ID)
min_area_basin = filtered_attr_data[min_area_index, :HYBAS_ID]

# Retrieve the minimum area value
min_area_value = filtered_attr_data[min_area_index, :area]

# Print results
println("Basin with the minimum area: ", min_area_basin)
println("Minimum area value: ", min_area_value)
