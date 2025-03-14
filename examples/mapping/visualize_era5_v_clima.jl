using JSON
using Plots
using NetCDF

"""
    standard_longitudes!(longitudes)

Transforms an array of longitudes to the [-180,180] limit range.
"""
function standard_longitudes!(longitudes::Vector{<:Real})
    for i in 1:length(longitudes)
        if longitudes[i] > 180
            longitudes[i] -= 360
        end
    end
end

# Function to read JSON files and plot the lat, lon coordinates with a proper legend
function plot_lat_lon(
    json_paths::Vector{String},
    nc_paths::Vector{String},
    basin_id::String,
    output_file::String,
)
    # Initialize plot
    p = plot(
        xlabel = "Longitude",
        ylabel = "Latitude",
        title = "Lat/Lon Coordinates",
        legend = :topright,  # Position legend in the top right
    )

    # Generate distinct colors for each dataset
    colors = [:lightblue, :darkblue, :orange]

    # Loop through each file and basin ID
    for (i, (json_path, nc_path)) in enumerate(zip(json_paths, nc_paths))
        # Read the JSON file
        json_data = JSON.parsefile(json_path)
        basin_data = json_data[basin_id]

        # Read the netCDF file
        dataset = NetCDF.open(nc_path)

        # Select correct longitude/latitude variable names
        if (
            nc_path == joinpath(
                data_file_path,
                "source_data",
                "era5",
                "globe_year_month",
                "era5_1990_01.nc",
            )
        ) || (
            nc_path == joinpath(
                data_file_path,
                "source_data",
                "era5",
                "globe_year_month",
                "thinned_era5_1990_01.nc",
            )
        )
            longitudes = dataset["longitude"][:]
            latitudes = dataset["latitude"][:]
        else
            longitudes = dataset["lon"][:]
            latitudes = dataset["lat"][:]
        end
        standard_longitudes!(longitudes)

        # Extract lat, lon coordinates and opacities
        lon_vals = []
        lat_vals = []
        opacities = []

        for value in values(basin_data)
            push!(lon_vals, longitudes[value[1]])
            push!(lat_vals, latitudes[value[2]])
            push!(opacities, value[3])
        end

        # Scatter plot with explicit colors and invisible points for legend
        scatter!(
            p,
            lon_vals,
            lat_vals,
            alpha = opacities,
            color = colors[i],
            label = "",
        )

        # Add invisible scatter points to properly display legend colors
        scatter!(p, [NaN], [NaN], color = colors[i], label = basename(nc_path))
    end

    # Save the plot as a PNG file
    savefig(p, output_file)
end

# Example usage
data_file_path = joinpath(@__DIR__, "..", "..", "data")
output_dir = joinpath(data_file_path, "midway_data", "mapping_dicts")
era5_json_path = joinpath(output_dir, "lv04_era5_grid_to_basin_dict.json")
era5_nc_path = joinpath(
    data_file_path,
    "source_data",
    "era5",
    "globe_year_month",
    "era5_1990_01.nc",
)
thinned_era5_json_path =
    joinpath(output_dir, "lv04_thinned_era5_grid_to_basin_dict.json")
thinned_era5_nc_path = joinpath(
    data_file_path,
    "source_data",
    "era5",
    "globe_year_month",
    "thinned_era5_1990_01.nc",
)
# clima_json_path = joinpath(output_dir, "climaland_grid_to_basin_dict.json")
# clima_nc_path =
#     joinpath(data_file_path, "source_data", "ClimaLand", "sr_1M_average.nc")
output_file = joinpath(@__DIR__, "thin_lat_lon_plot.png")

basin_id = "9040008450" #"1050040260" #"1050014490"

# Plot the lat, lon coordinates from the JSON files and save as PNG
plot_lat_lon(
    [era5_json_path, thinned_era5_json_path], #, clima_json_path],
    [era5_nc_path, thinned_era5_nc_path], #, clima_nc_path],
    basin_id,
    output_file,
)
