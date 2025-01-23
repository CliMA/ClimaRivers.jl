using ClimaRivers
using JSON, Dates, JLD2
export test_run_init, test_run_compute, test_run_full

# Used to create Test dataset, different t_max and window date size from mini_gamma_IRF.jl

function test_run_init()
    # build hillslope model
    hillslope = MizurouteHillslopeV1{Float64}(1.5, 1.0, 2)

    # build channel model
    channel = MizurouteChannelV1{Float64}(1.5 * 86400, 800 * 86400, 4)

    # build model
    river_model = HillslopeChannelRiverModel(hillslope, channel)

    # build environment
    data_file_path = joinpath(@__DIR__, "..", "mini_data", "routing")

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
    @info "output path: $output_dir"
    if !isdir(output_dir)
        mkpath(output_dir)
    end

    # data information
    data_start_date = Date("1996-01-01", "yyyy-mm-dd")
    data_end_date = Date("1996-01-10", "yyyy-mm-dd") # of entire simulation
    data_step = Day(1)
    data_date_window = DateWindow(
        start_date = data_start_date,
        end_date = data_end_date,
        date_step = data_step,
    )

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

    # River state loaded into csv files currently, placehodler variable
    history_length = 6 * Day(1)
    @info "using history length $(history_length)"
    initial_window = DateWindow(
        start_date = data_start_date,
        end_date = data_start_date + history_length,
        date_step = data_step,
    )
    return initial_window, river_model, env, data_end_date, history_length
end

function test_run_compute(initial_window, river_model, env, data_end_date, history_length)
    ## full-timeseries model, predicts all states at once
    @info "computing streamflow over network $(history_length)"
    ttt = @elapsed begin
        streamflows, river_states =
            compute_streamflow(initial_window, river_model, env, data_end_date)
    end
    @info "Complete. Time taken: $ttt"

    return streamflows, river_states
end

function test_run_full()
    initial_window, river_model, env, data_end_date, history_length = test_run_init()
    streamflows, river_states = test_run_compute(initial_window, river_model, env, data_end_date, history_length)
    return streamflows, river_states
end
