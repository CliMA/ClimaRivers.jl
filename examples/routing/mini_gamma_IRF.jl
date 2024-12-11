using ClimaRivers
using JSON, Dates

# build hillslope model
hillslope = MizurouteHillslopeV1{Float64}()

# build channel model
channel = MizurouteChannelV1{Float64}()

# build model
river_model = HillslopeChannelRiverModel(hillslope, channel)

# build environment
data_file_path = joinpath(@__DIR__, "..", "..", "mini_data", "routing")

# build static environment
@info "reading data files from $(data_file_path)"
graph_file = joinpath(data_file_path, "graphs", "graph_lv05.json")
basin_id_file = joinpath(data_file_path, "routing_lvs", "routing_lvs_lv05", "all_basin_ids.txt")
attributes_file = joinpath(data_file_path, "attributes", "attributes_lv05", "attributes.csv")
static_env = StaticEnvironment(basin_id_file, attributes_file, graph_file)

# build dynamic environment
forcing_timeseries_dir =
    joinpath(data_file_path, "timeseries", "timeseries_lv05")
forcing_timeseries_files = [joinpath(forcing_timeseries_dir, "basin_$(id).csv") for id in static_env.basin_ids]
output_dir =
    joinpath(data_file_path, "simulations", "simulations_lv05", "gamma_IRF")
@info "creating output"
if !isdir(output_dir)
    mkpath(output_dir)
end
dynamic_env = DynamicEnvironment(static_env.basin_ids, forcing_timeseries_files, output_dir)

env = Environment(static_env, dynamic_env)

## evolutionary model, evolving a state over time
model_types = ["instant"]
model_type = model_types[1]

start_date = Date("1996-01-01", "yyyy-mm-dd")
end_date = Date("2014-12-31", "yyyy-mm-dd")

# River state loaded into csv files currently, placehodler variable
hillslope_data = zeros(10, 10)
channel_data = zeros(10, 10)

river_state = RiverState(hillslope_data, channel_data)

if model_type == "instant"
    ## full-timeseries model, predicts all states at once
    compute_streamflow!(river_state, river_model, env, start_date, end_date)
end
