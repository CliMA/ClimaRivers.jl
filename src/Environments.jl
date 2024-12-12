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
"""
$(TYPEDEF)

Stores the static features that describe the river basin network.

$(TYPEDFIELDS)
"""
struct StaticEnvironment{AV <: AbstractVector}
    "Vector of basin identifiers"
    basin_ids::AV
    "Dataframe of static basin attributes"
    attributes::DataFrame
    "Dictionary of pairs `(basin_id => basin_ids of direct upstream neighbours)`"
    graph_dict::Dict
end

"""
$(TYPEDSIGNATURES)

Constructor of `StaticEnvironment` from three strings holding files for basin id (txt), attributes (csv) and the graph (JSON).
"""
function StaticEnvironment(
    basin_ids_file::AS1,
    attributes_file::AS2,
    graph_file::AS3,
) where {AS1 <: AbstractString, AS2 <: AbstractString, AS3 <: AbstractString}

    # create basin
    basin_ids = get_basin_list(basin_ids_file)

    # create attributes
    attributes = CSV.read(attributes_file, DataFrame)

    # create graph
    graph_dict = JSON.parsefile(graph_file)

    return StaticEnvironment(basin_ids, attributes, graph_dict)
end

# Dynamic Data Objects
"""
$(TYPEDEF)

Stores the dynamic features that apply to the river network over a dated time period.

$(TYPEDFIELDS)
"""
struct DynamicEnvironment
    "Dictionary of pairs `(basin_id => forcing timeseries [DataFrame] at basin_id)`"
    forcing_timeseries::Dict
    "Directory to store simulation results"
    output_dir::String
end

"""
$(TYPEDSIGNATURES)

Constructor of `DynamicEnvironment` from a vector of `basin_id`s, and a vector of `forcing_timeseries_files` files (CSV).
"""
function DynamicEnvironment(
    basin_ids::AV1,
    forcing_timeseries_files::AV2,
    output_dir::String,
) where {AV1 <: AbstractVector, AV2 <: AbstractVector}

    # build forcing timeseries
    forcing_timeseries_array = []
    for file in forcing_timeseries_files
        push!(forcing_timeseries_array, CSV.read(file, DataFrame))
    end
    forcing_timeseries = Dict(eachrow([basin_ids forcing_timeseries_array])) # creates id => timeseries dictionary

    return DynamicEnvironment(forcing_timeseries, output_dir)
end


"""
$(TYPEDEF)

Stores both the static and dynamic environments

$(TYPEDFIELDS)
"""
struct Environment{SE <: StaticEnvironment, DE <: DynamicEnvironment}
    "StaticEnvironment data objects"
    static_env::SE
    "DynamicEnvironment data objects"
    dynamic_env::DE
end

"""
$(TYPEDSIGNATURES)

Constructor of `Enviroment` using a list of forcing timeseries files. See constructors for StaticEnvironment and DynamicEnvironment for more details on other inputs.
"""
function Environment(
    basin_ids_file::AS1,
    attributes_file::AS2,
    graph_file::AS3,
    forcing_timeseries_files::AV,
    output_dir::AS4;
) where {
    AS1 <: AbstractString,
    AS2 <: AbstractString,
    AS3 <: AbstractString,
    AS4 <: AbstractString,
    AV <: AbstractVector,
}

    static_env = StaticEnvironment(basin_ids_file, attributes_file, graph_file)
    basin_ids = static_env.basin_ids
    dynamic_env =
        DynamicEnvironment(basin_ids, forcing_timeseries_files, output_dir)

    return Environment(static_env, dynamic_env)

end

"""
$(TYPEDSIGNATURES)

Constructor of `Enviroment` using a directory of the forcing timeseries, and inferring the files as
```forcing_timeseries_dir/forcing_timeseries_file_prefix*\$(basin_id).csv```.
See constructors for StaticEnvironment and DynamicEnvironment for more details on other inputs.
"""
function Environment(
    basin_ids_file::AS1,
    attributes_file::AS2,
    graph_file::AS3,
    forcing_timeseries_dir::AS4,
    output_dir::AS5;
    forcing_timeseries_file_prefix = "basin_",
) where {
    AS1 <: AbstractString,
    AS2 <: AbstractString,
    AS3 <: AbstractString,
    AS4 <: AbstractString,
    AS5 <: AbstractString,
}
    static_env = StaticEnvironment(basin_ids_file, attributes_file, graph_file)

    basin_ids = static_env.basin_ids
    forcing_timeseries_files = [
        joinpath(
            forcing_timeseries_dir,
            forcing_timeseries_file_prefix * "$(id).csv",
        ) for id in basin_ids
    ]
    dynamic_env =
        DynamicEnvironment(basin_ids, forcing_timeseries_files, output_dir)

    return Environment(static_env, dynamic_env)

end

"""
$(TYPEDSIGNATURES)

Constructor based on keywords, where users must provide either `forcing_timeseries_dir` or `forcing_timeseries_files`.
"""
function Environment(;
    basin_ids_file::Union{AS1, Nothing} = nothing,
    attributes_file::Union{AS2, Nothing} = nothing,
    graph_file::Union{AS3, Nothing} = nothing,
    forcing_timeseries_dir::Union{AS4, Nothing} = nothing,
    output_dir::Union{AS5, Nothing} = nothing,
    forcing_timeseries_file_prefix::AS6 = "basin_",
    forcing_timeseries_files::Union{AS7, Nothing} = nothing,
) where {
    AS1 <: AbstractString,
    AS2 <: AbstractString,
    AS3 <: AbstractString,
    AS4 <: AbstractString,
    AS5 <: AbstractString,
    AS6 <: AbstractString,
    AS7 <: AbstractString,
}
    if isnothing(forcing_timeseries_dir)
        return Environment(
            basin_ids_file,
            attributes_file,
            graph_file,
            forcing_timeseries_files,
            output_dir,
        )
    elseif isnothing(forcing_timeseries_files)
        return Environment(
            basin_ids_file,
            attributes_file,
            graph_file,
            forcing_timeseries_dir,
            output_dir,
            forcing_timeseries_file_prefix = forcing_timeseries_file_prefix,
        )
    end

end
