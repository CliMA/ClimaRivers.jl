using NCDatasets

# File paths
data_file_path = joinpath(@__DIR__, "..", "..", "data")
input_file = joinpath(data_file_path, "source_data", "era5", "globe_year_month", "era5_1990_01.nc")
output_file = joinpath(data_file_path, "source_data", "era5", "globe_year_month", "thinned_era5_1990_01.nc")

# Open the input NetCDF file
ds = Dataset(input_file, "r")

# Get longitude and latitude indices
lon_indices = 1:6:length(ds["longitude"])
lat_indices = 1:6:length(ds["latitude"])

# Create the output NetCDF file
NCDataset(output_file, "c") do ds_out
    # Define dimensions
    defDim(ds_out, "longitude", length(lon_indices))
    defDim(ds_out, "latitude", length(lat_indices))
    defDim(ds_out, "time", length(ds["time"]))

    # Define coordinate variables with correct data types
    defVar(ds_out, "longitude", Float32, ("longitude",), attrib = Dict(
        "units" => "degrees_east",
        "long_name" => "longitude"
    ))
    defVar(ds_out, "latitude", Float32, ("latitude",), attrib = Dict(
        "units" => "degrees_north",
        "long_name" => "latitude"
    ))
    defVar(ds_out, "time", Int32, ("time",), attrib = Dict(
        "units" => "hours since 1900-01-01 00:00:00.0",
        "long_name" => "time",
        "calendar" => "gregorian"
    ))

    # Copy and subsample coordinate variables
    ds_out["longitude"][:] .= ds["longitude"][lon_indices]
    ds_out["latitude"][:] .= ds["latitude"][lat_indices]
    ds_out["time"][:] .= ds["time"][:]


    # Copy attributes for coordinate variables
    for var in ["longitude", "latitude", "time"]
        for attr in keys(ds[var].attrib)
            ds_out[var].attrib[attr] = ds[var].attrib[attr]
        end
    end

    # Copy and subsample data variables
    for var in keys(ds)
        if var in ["longitude", "latitude", "time"]
            continue
        end
        
        # Get variable attributes
        attrs = Dict(attr => ds[var].attrib[attr] for attr in keys(ds[var].attrib))
        
        # Ensure _FillValue matches Float32 type
        if "_FillValue" in keys(attrs)
            attrs["_FillValue"] = Float32(attrs["_FillValue"])
        end

        # Get variable shape and dimension names
        var_shape = size(ds[var])
        var_dims = dimnames(ds[var])  # Get actual dimension order

        println("Processing variable: ", var, " with shape ", var_shape, " and dimensions ", var_dims)

        # Define the variable in the output NetCDF file
        defVar(ds_out, var, Float32, ["longitude", "latitude", "time"], attrib = attrs)

        ds_out[var][:, :, :] .= ds[var][lon_indices, lat_indices, :]
 
    end
end

println("Thinned NetCDF file saved as: ", output_file)