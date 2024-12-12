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

# Some time information of the data
export DateWindow

"""
$(TYPEDEF)

Stores a dated time period with an iterator.

$(TYPEDFIELDS)
"""
struct DateWindow
    "beginning of date window [Date]"
    start_date::Date
    "end of date window [Date]"
    end_date::Date
    "size of iteration in date window [DatePeriod]"
    date_step::DatePeriod
end

"""
$(TYPEDSIGNATURES)

build a DateWindow with keyword arguments.
"""
function DateWindow(;
    start_date::Union{Date,Nothing} = nothing,
    end_date::Union{Date,Nothing} = nothing,
    date_step::Union{DatePeriod,Nothing} = nothing,
    )
    return DateWindow(start_date, end_date, date_step)
    
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
    "Window over which the forcing timeseries is defined [DateWindow]"
    date_window::DateWindow
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
    date_window::DateWindow,
    output_dir::String,
) where {AV1 <: AbstractVector, AV2 <: AbstractVector}

    # build forcing timeseries
    forcing_timeseries_array = []
    for file in forcing_timeseries_files
        push!(forcing_timeseries_array, CSV.read(file, DataFrame))
    end
    forcing_timeseries = Dict(eachrow([basin_ids forcing_timeseries_array])) # creates id => timeseries dictionary

    return DynamicEnvironment(forcing_timeseries, date_window, output_dir)
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
    date_window::DateWindow,
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
        DynamicEnvironment(basin_ids, forcing_timeseries_files, date_window, output_dir)
    
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
    date_window::DateWindow,
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
        DynamicEnvironment(basin_ids, forcing_timeseries_files, date_window, output_dir)

    return Environment(static_env, dynamic_env)
    
end

"""
$(TYPEDSIGNATURES)

Constructor based on keywords, where users must provide either `forcing_timeseries_dir` or `forcing_timeseries_files`.
"""
function Environment(;
                     basin_ids_file::Union{String, Nothing} = nothing,
                     attributes_file::Union{String, Nothing} = nothing,
                     graph_file::Union{String, Nothing} = nothing,
                     forcing_timeseries_dir::Union{String, Nothing} = nothing,
                     output_dir::Union{String, Nothing} = nothing,
                     date_window::Union{DateWindow, Nothing} = nothing,
                     forcing_timeseries_file_prefix::String = "basin_",
                     forcing_timeseries_files::Union{<:Vector{String}, Nothing} = nothing,
                     ) # union with nothing is not allowed a "where" statement, see detect_unbound_args in Aqua.jl
    arg_list_one = [basin_ids_file, attributes_file, graph_file, output_dir]
    any_nothing = any([isnothing(x) for x in arg_list_one])
    if any_nothing
        throw(
            ArgumentError(
                """
Environment must be built with values for all these keywords. But received:\n
    basin_ids_file  = $(arg_list_one[1]), 
    attributes_file = $(arg_list_one[2]), 
    graph_file      = $(arg_list_one[3]), 
    output_dir      = $(arg_list_one[4]),
""",
            ),
        )
    end

    arg_list_two = [forcing_timeseries_files, forcing_timeseries_dir]
    all_nothing = all([isnothing(x) for x in arg_list_two])
    if all_nothing
        throw(ArgumentError("""
                Environment must be built with values for either keywords:
                    forcing_timeseries_files,
                    forcing_timeseries_dir,
                Received neither.
                """))
    end



    if isnothing(forcing_timeseries_dir)
        return Environment(
            basin_ids_file,
            attributes_file,
            graph_file,
            forcing_timeseries_files,
            date_window,
            output_dir,
        )
    elseif isnothing(forcing_timeseries_files)
        return Environment(
            basin_ids_file,
            attributes_file,
            graph_file,
            forcing_timeseries_dir,
            date_window,
            output_dir,
            forcing_timeseries_file_prefix = forcing_timeseries_file_prefix,
        )
    else

    end

end
