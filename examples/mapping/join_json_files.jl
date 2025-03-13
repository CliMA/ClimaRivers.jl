using JSON

function merge_json_files(output_file::String, input_files::Vector{String})
    merged_data = Dict()

    for file in input_files
        data = JSON.parsefile(file)
        merge!(merged_data, data)
    end

    open(output_file, "w") do io
        JSON.print(io, merged_data)
    end
end

# Example usage:
data_file_path = joinpath(@__DIR__, "..", "..", "data")
input_files = [
    joinpath(
        data_file_path,
        "midway_data",
        "mapping_dicts",
        "dict$(i).json",
        # "dict$(lpad(i, 2, '0')).json",
    ) for i in 1:32
]

# Combined JSON file name
file_name = "lv04_era5_grid_to_basin_dict.json"
output_file =
    joinpath(data_file_path, "midway_data", "mapping_dicts", file_name)
merge_json_files(output_file, input_files)
