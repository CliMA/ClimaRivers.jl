# Contains the structs that define the static and dynamic environment that configures/forces the river model.
using JSON, CSV, DataFrames

import Base.iterate

export StaticEnvironment, DynamicEnvironment, Environment
export DateWindow
export get_all_dates, iterate, get_basin_list

## Auxiliary functions
"""
$(TYPEDSIGNATURES)

Read a newline-delimited text file of integer basin IDs and return them as a `Vector{Int64}`.
"""
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

Construct a `StaticEnvironment` from file paths for the basin ID list, attribute table, and network graph.

# Arguments
- `basin_ids_file`: path to a newline-delimited text file of integer basin IDs
- `attributes_file`: path to a CSV file of basin attributes (must include `HYBAS_ID` and `DIST_MAIN` columns)
- `graph_file`: path to a JSON file mapping each basin ID (as string) to its list of direct upstream neighbour IDs
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

"""
$(TYPEDEF)

Stores a dated time period with an iterator.

$(TYPEDFIELDS)
"""
struct DateWindow
    "start of the date window"
    start_date::Date
    "end of the date window"
    end_date::Date
    "step size for iteration over the window"
    date_step::DatePeriod
end

"""
$(TYPEDSIGNATURES)

Construct a `DateWindow` from keyword arguments.

# Arguments
- `start_date`: start of the date window
- `end_date`: end of the date window
- `date_step`: step size for iteration over the window

# Examples
```jldoctest
julia> using Dates, ClimaRivers

julia> DateWindow(start_date=Date(2000,1,1), end_date=Date(2000,1,31), date_step=Day(1))
DateWindow
  start : 2000-01-01
  end   : 2000-01-31
  step  : 1 day
```
"""
function DateWindow(;
    start_date::Union{Date, Nothing} = nothing,
    end_date::Union{Date, Nothing} = nothing,
    date_step::Union{DatePeriod, Nothing} = nothing,
)
    return DateWindow(start_date, end_date, date_step)

end

"""
$(TYPEDSIGNATURES)

Return a `Vector{Date}` of every date spanned by `dw`, stepping by `dw.date_step`.

# Examples
```jldoctest
julia> using Dates, ClimaRivers

julia> dw = DateWindow(start_date=Date(2000,1,1), end_date=Date(2000,1,4), date_step=Day(2));

julia> get_all_dates(dw)
2-element Vector{Date}:
 2000-01-01
 2000-01-03
```
"""
function get_all_dates(dw::DateWindow)
    return collect((dw.start_date):(dw.date_step):(dw.end_date))
end

"""
$(TYPEDSIGNATURES)

Advance `dw` forward by `n_steps` steps of `dw.date_step` and return the shifted `DateWindow`.

# Examples
```jldoctest
julia> using Dates, ClimaRivers

julia> dw = DateWindow(start_date=Date(2000,1,1), end_date=Date(2000,1,4), date_step=Day(2));

julia> iterate(dw)
DateWindow
  start : 2000-01-03
  end   : 2000-01-06
  step  : 2 days
```
"""
function Base.iterate(dw::DateWindow; n_steps::Int = 1)
    date_step = dw.date_step
    return DateWindow(
        dw.start_date + n_steps * date_step,
        dw.end_date + n_steps * date_step,
        date_step,
    )
end
# Dynamic Data Objects

"""
$(TYPEDEF)

Stores the dynamic features that apply to the river network over a dated time period.

$(TYPEDFIELDS)
"""
struct DynamicEnvironment
    "Mapping of basin ID to its forcing timeseries"
    forcing_timeseries::Dict
    "Date window over which the forcing timeseries is defined"
    date_window::DateWindow
    "Directory to store simulation results"
    output_dir::String
end

"""
$(TYPEDSIGNATURES)

Construct a `DynamicEnvironment` from parallel vectors of basin IDs and forcing timeseries file paths.

# Arguments
- `basin_ids`: vector of basin IDs in the same order as `forcing_timeseries_files`
- `forcing_timeseries_files`: vector of paths to per-basin CSV forcing files (must contain `date`, `sro_sum`, `ssro_sum` columns)
- `date_window`: date window over which the forcing timeseries is defined
- `output_dir`: directory to write simulation output
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
    "Static basin network description"
    static_env::SE
    "Dynamic forcing data and output configuration"
    dynamic_env::DE
end

"""
$(TYPEDSIGNATURES)

Construct an `Environment` from file paths and an explicit list of per-basin forcing timeseries files.

# Arguments
- `basin_ids_file`: path to the basin ID list (see `StaticEnvironment`)
- `attributes_file`: path to the basin attributes CSV (see `StaticEnvironment`)
- `graph_file`: path to the network graph JSON (see `StaticEnvironment`)
- `forcing_timeseries_files`: vector of paths to per-basin forcing CSV files (see `DynamicEnvironment`)
- `date_window`: date window for the forcing data
- `output_dir`: directory to write simulation output
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
    dynamic_env = DynamicEnvironment(
        basin_ids,
        forcing_timeseries_files,
        date_window,
        output_dir,
    )

    return Environment(static_env, dynamic_env)

end

"""
$(TYPEDSIGNATURES)

Construct an `Environment` by inferring per-basin forcing file paths from a directory.

File paths are resolved as `forcing_timeseries_dir / forcing_timeseries_file_prefix * "\$(basin_id).csv"`.

# Arguments
- `basin_ids_file`: path to the basin ID list (see `StaticEnvironment`)
- `attributes_file`: path to the basin attributes CSV (see `StaticEnvironment`)
- `graph_file`: path to the network graph JSON (see `StaticEnvironment`)
- `forcing_timeseries_dir`: directory containing per-basin forcing CSV files
- `date_window`: date window for the forcing data
- `output_dir`: directory to write simulation output
- `forcing_timeseries_file_prefix`: filename prefix prepended to each basin ID (default: `"basin_"`)
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
    dynamic_env = DynamicEnvironment(
        basin_ids,
        forcing_timeseries_files,
        date_window,
        output_dir,
    )

    return Environment(static_env, dynamic_env)

end

"""
$(TYPEDSIGNATURES)

Construct an `Environment` using keyword arguments. Exactly one of `forcing_timeseries_dir` or
`forcing_timeseries_files` must be provided.

# Arguments
- `basin_ids_file`: path to the basin ID list
- `attributes_file`: path to the basin attributes CSV
- `graph_file`: path to the network graph JSON
- `output_dir`: directory to write simulation output
- `date_window`: date window for the forcing data
- `forcing_timeseries_files`: explicit list of per-basin forcing CSV paths (alternative to `forcing_timeseries_dir`)
- `forcing_timeseries_dir`: directory of per-basin forcing CSV files (alternative to `forcing_timeseries_files`)
- `forcing_timeseries_file_prefix`: filename prefix prepended to each basin ID (default: `"basin_"`)
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
