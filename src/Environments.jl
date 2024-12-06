# Contains the structs that define the static and dynamic environment that configures/forces the river model.
export StaticEnvironment, DynamicEnvironment, Environment

# Static Data Objects
struct StaticEnvironment
    "Directory containing list of all basins"
    basins_dir::String
    "Directory containing attribute csv"
    attributes_dir::String
    "Basin mapping dictionary"
    graph_dict::Dict
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
