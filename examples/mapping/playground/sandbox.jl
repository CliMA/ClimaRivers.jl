using Shapefile, DataFrames

data_file_path = joinpath(@__DIR__, "..", "..", "..", "data")
shape_file_05 = joinpath(
    data_file_path,
    "source_data",
    "BasinATLAS_v10_shp",
    "BasinATLAS_v10_lev05.shp",
)
shape_file_04 = joinpath(
    data_file_path,
    "source_data",
    "BasinATLAS_v10_shp",
    "BasinATLAS_v10_lev04.shp",
)

shp_file05 = Shapefile.Table(shape_file_05)
shp_file04 = Shapefile.Table(shape_file_04)

println("Summary of shapefile attributes:")
describe(DataFrame(shp_file05))

# println("Summary of shapefile attributes:")
# describe(DataFrame(shp_file04))
