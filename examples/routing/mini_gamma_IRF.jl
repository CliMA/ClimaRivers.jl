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

# files for static environment
@info "reading data files from $(data_file_path)"
graph_file = joinpath(data_file_path, "graphs", "graph_lv05.json")
basin_ids_file = joinpath(
    data_file_path,
    "routing_lvs",
    "routing_lvs_lv05",
    "all_basin_ids.txt",
)
attributes_file =
    joinpath(data_file_path, "attributes", "attributes_lv05", "attributes.csv")

# files for dynamic environment
forcing_timeseries_dir =
    joinpath(data_file_path, "timeseries", "timeseries_lv05")
output_dir =
    joinpath(data_file_path, "simulations", "simulations_lv05", "gamma_IRF")
@info "creating output path"
if !isdir(output_dir)
    mkpath(output_dir)
end

# data information
data_start_date = Date("1996-01-01", "yyyy-mm-dd")
data_end_date = Date("2014-12-31", "yyyy-mm-dd") # of entire simulation
data_step = Day(1)
data_date_window = DateWindow(start_date=data_start_date, end_date=data_end_date, date_step=data_step)

# build environment
env = Environment(
    basin_ids_file = basin_ids_file,
    attributes_file = attributes_file,
    graph_file = graph_file,
    forcing_timeseries_dir = forcing_timeseries_dir,
    date_window = data_date_window,
    output_dir = output_dir,
    forcing_timeseries_file_prefix = "basin_",
)


## evolutionary model, evolving a state over time
model_types = ["instant"]
model_type = model_types[1]



# River state loaded into csv files currently, placehodler variable
hillslope_data = zeros(10, 10)
channel_data = zeros(10, 10)

river_state = HillslopeChannelRiverState(hillslope_data, channel_data)

if model_type == "instant"
    ## full-timeseries model, predicts all states at once
    compute_streamflow!(river_state, river_model, env, data_start_date, data_end_date)
end
