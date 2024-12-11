using ClimaRivers
using JSON, Dates

# build hillslope model
hillslope = MizurouteHillslopeV1{Float64}()

# build channel model
channel = MizurouteChannelV1{Float64}()

# build model
river_model = HillslopeChannelRiverModel(hillslope, channel)

# build environment
data_file_path = joinpath(@__DIR__, "..", "..", "data", "routing")

# build static environment
@info "reading data files from $(data_file_path)"
graph_file = joinpath(data_file_path, "graphs", "graph_lv05.json")
basin_id_file = joinpath(data_file_path, "routing_lvs", "routing_lvs_lv05", "all_basin_ids.txt")
attributes_file = joinpath(data_file_path, "attributes", "attributes_lv05", "attributes.csv")
static_env = StaticEnvironment(basin_id_file, attributes_file, graph_file)

# build dynamic environment
forcing_timeseries_dir =
    joinpath(data_file_path, "timeseries", "timeseries_lv05")
output_dir =
    joinpath(data_file_path, "simulations", "simulations_lv05", "gamma_IRF")
@info "creating output"
if !isdir(output_dir)
    mkpath(output_dir)
end
dynamic_env = DynamicEnvironment(forcing_timeseries_dir, output_dir)

env = Environment(static_env, dynamic_env)

## evolutionary model, evolving a state over time
model_types = ["instant"]
model_type = model_types[1]

start_date = Date("1996-01-01", "yyyy-mm-dd")
end_date = Date("2014-12-31", "yyyy-mm-dd")
dates = collect(start_date:Day(1):end_date)

# streamflow = zeros(dates,basins)
hillslope_data = zeros(10, 10)  # Replace with actual data once implemented
channel_data = zeros(10, 10)   # Replace with actual data once implemented

river_state = RiverState(hillslope_data, channel_data)

if model_type == "instant"
    ## full-timeseries model, predicts all states at once
    compute_streamflow!(river_state, river_model, env, start_date, end_date)
end
