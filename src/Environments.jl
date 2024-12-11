# Contains the structs that define the static and dynamic environment that configures/forces the river model.
using JSON, CSV, DataFrames
export StaticEnvironment, DynamicEnvironment, Environment

## Auxiliary functions
# function for reading basins from txt file into Vector{Int}
function get_basin_list(basins_file::String)
    basins_list = Int64[]
    file = open(joinpath(basins_file))
    for line in eachline(file)
        push!(basins_list, parse(Int64, line))
    end
    close(file)

    return basins_list
end


# Static Data Objects
struct StaticEnvironment{AV <: AbstractVector}
    "Vector of basin identifiers"
    basin_ids::AV
    "Data frame of static basin attributes"
    attributes::DataFrame
    "Dictionary representing the network (basin_id => direct upstream neighbours)"
    graph_dict::Dict
end

function StaticEnvironment(
    basin_ids_file::AS1,
    attributes_file::AS2,
    graph_file::AS3,
    ) where {
        AS1 <: AbstractString,
        AS2 <: AbstractString,
        AS3 <: AbstractString,
    }
    
    # create basin
    basin_ids = get_basin_list(basin_ids_file)
    
    # create attributes
    attributes = CSV.read(attributes_file, DataFrame)

    # create graph
    graph_dict = JSON.parsefile(graph_file)
    
    return StaticEnvironment(basin_ids, attributes, graph_dict)
end

# Dynamic Data Objects
struct DynamicEnvironment
    "Directory containing forcing timeseries csv"
    forcing_timeseries_dir::String
    "Directory to store simulation results"
    output_dir::String
end




struct Environment{SE <: StaticEnvironment, DE <: DynamicEnvironment}
    "Static data objects"
    static_env::SE
    "Dynamic data objects"
    dynamic_env::DE
end
