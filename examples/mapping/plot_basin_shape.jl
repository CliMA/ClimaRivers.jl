# ----------------------------------------------------------------------------
# Plots the shape of the first basin in a given shapefile.
# ----------------------------------------------------------------------------

using Shapefile, DataFrames, Plots

# Observing the contents of the shape file

# Load the shapefile
data_file_path = joinpath(@__DIR__, "..", "..", "data")
shp_file = joinpath(data_file_path, "source_data", "BasinATLAS_v10_shp", "BasinATLAS_v10_lev05.shp")
shape_df = Shapefile.Table(shp_file) |> DataFrame

select!(shape_df, [:geometry, :HYBAS_ID])

first_polygon = shape_df.geometry[1]

if first_polygon isa Shapefile.Polygon
    # Get lat / lon values
    lon_vals = [p.x for p in first_polygon.points]
    lat_vals = [p.y for p in first_polygon.points]

    # Scatter plot of polygon points
    plot(lat_vals, lon_vals)
    xlabel!("Longitude")
    ylabel!("Latitude")
    title!("First Polygon Plot from Shapefile")

    # Save the plot
    savefig("first_basin_shape.png")
else
    println("The first geometry is not a Polygon.")
end
