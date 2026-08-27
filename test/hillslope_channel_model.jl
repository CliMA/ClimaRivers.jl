using Test
using ClimaRivers #(gather up the exported functions and structs for use in this scope)
using CSV, DataFrames

include("test_gamma_IRF.jl")

@testset "Mizuroute tests" begin

    # build hillslope
    FT = Float32
    shape = FT(1.5)
    timescale = FT(1.0)
    t_max_hs = 60
    slope1 = MizurouteHillslopeV1(shape, timescale, t_max_hs)
    slope2 = MizurouteHillslopeV1{FT}()
    @test slope1.shape == slope2.shape
    @test slope1.timescale == slope2.timescale
    @test slope1.t_max == slope2.t_max
    @test slope1 == slope2


    # Channel
    FT = Float64
    wave_velocity = FT(1.5 * 86400)
    diffusivity = FT(800 * 86400)
    t_max_ch = 120
    channel1 = MizurouteChannelV1(wave_velocity, diffusivity, t_max_ch)
    channel2 = MizurouteChannelV1{FT}()
    @test channel1.wave_velocity == channel2.wave_velocity
    @test channel1.diffusivity == channel2.diffusivity
    @test channel1.t_max == channel2.t_max
    @test channel1 == channel2

end

@testset "DateWindow Tests" begin
    # Test functions concerning the DateWindow Struct
    start_date = Date("1996-01-01", "yyy-mm-dd")
    end_date = Date("1996-01-10", "yyy-mm-dd")
    date_step = Day(1)
    dw = DateWindow(
        start_date = start_date,
        end_date = end_date,
        date_step = date_step,
    )
    # Initializing DateWindow Test
    @test start_date == dw.start_date
    @test end_date == dw.end_date
    @test date_step == dw.date_step

    # get_all_dates() Test
    all_dates = get_all_dates(dw)
    @test all_dates == collect((dw.start_date):(dw.date_step):(dw.end_date))

    # iterate window Test
    next_dw = iterate(dw)
    true_next_dw = DateWindow(
        start_date = Date("1996-01-02", "yyy-mm-dd"),
        end_date = Date("1996-01-11", "yyy-mm-dd"),
        date_step = Day(1),
    )
    @test next_dw == true_next_dw
end

@testset "Environment Tests" begin
    # Test functions for environment structs found in Evironments.jl
    data_file_path = joinpath(@__DIR__, "..", "mini_data", "routing")

    # Static Environment Files
    basin_ids_file = joinpath(
        data_file_path,
        "routing_lvs",
        "routing_lvs_lv05",
        "all_basin_ids.txt",
    )
    attributes_file = joinpath(
        data_file_path,
        "attributes",
        "attributes_lv05",
        "attributes.csv",
    )
    graph_file = joinpath(data_file_path, "graphs", "graph_lv05.json")

    # Dynamic Environment Files
    forcing_timeseries_dir =
        joinpath(data_file_path, "timeseries", "timeseries_lv05")
    output_dir =
        joinpath(data_file_path, "simulations", "simulations_lv05", "gamma_IRF")
    if !isdir(output_dir)
        mkpath(output_dir)
    end

    # Date information
    data_start_date = Date("1996-01-01", "yyyy-mm-dd")
    data_end_date = Date("1996-01-10", "yyyy-mm-dd") # of entire simulation
    data_step = Day(1)
    data_date_window = DateWindow(
        start_date = data_start_date,
        end_date = data_end_date,
        date_step = data_step,
    )

    # Compare static env constructors
    basin_ids = get_basin_list(basin_ids_file)
    attributes = CSV.read(attributes_file, DataFrame)
    graph_dict = JSON.parsefile(graph_file)
    static_env_fields = StaticEnvironment(basin_ids, attributes, graph_dict)

    static_env_signature =
        StaticEnvironment(basin_ids_file, attributes_file, graph_file)

    @test static_env_fields.basin_ids == static_env_signature.basin_ids
    @test static_env_fields.attributes == static_env_signature.attributes
    @test static_env_fields.graph_dict == static_env_signature.graph_dict

    # Compare dynmaic env constructors
    forcing_timeseries_file_prefix = "basin_"
    forcing_timeseries_files = [
        joinpath(
            forcing_timeseries_dir,
            forcing_timeseries_file_prefix * "$(id).csv",
        ) for id in basin_ids
    ]
    dynamic_env_signature = DynamicEnvironment(
        basin_ids,
        forcing_timeseries_files,
        data_date_window,
        output_dir,
    )

    forcing_timeseries_array = []
    for file in forcing_timeseries_files
        push!(forcing_timeseries_array, CSV.read(file, DataFrame))
    end
    forcing_timeseries = Dict(eachrow([basin_ids forcing_timeseries_array]))
    dynamic_env_fields =
        DynamicEnvironment(forcing_timeseries, data_date_window, output_dir)

    @test Set(keys(dynamic_env_signature.forcing_timeseries)) ==
          Set(keys(dynamic_env_fields.forcing_timeseries))
    @test dynamic_env_signature.date_window == dynamic_env_fields.date_window
    @test dynamic_env_signature.output_dir == dynamic_env_fields.output_dir

    # Compare environment constructors
    env_signature = Environment(
        basin_ids_file = basin_ids_file,
        attributes_file = attributes_file,
        graph_file = graph_file,
        forcing_timeseries_dir = forcing_timeseries_dir,
        date_window = data_date_window,
        output_dir = output_dir,
        forcing_timeseries_file_prefix = "basin_",
    )

    env_fields = Environment(static_env_fields, dynamic_env_fields)

    @test env_fields.static_env.basin_ids == env_signature.static_env.basin_ids
    @test env_fields.static_env.attributes ==
          env_signature.static_env.attributes
    @test env_fields.static_env.graph_dict ==
          env_signature.static_env.graph_dict

    @test Set(keys(env_fields.dynamic_env.forcing_timeseries)) ==
          Set(keys(env_signature.dynamic_env.forcing_timeseries))
    @test env_fields.dynamic_env.date_window ==
          env_signature.dynamic_env.date_window
    @test env_fields.dynamic_env.output_dir ==
          env_signature.dynamic_env.output_dir
end

@testset "Routing Tests" begin
    # Test functions inside of Routing.jl

    # Test get_upstream_basins()
    graph_dict =
        Dict("1" => [], "2" => [], "3" => [], "4" => [1, 2], "5" => [3, 4])
    graph_dict = Dict{String, Any}(graph_dict)
    upstream1 = get_upstream_basins("1", graph_dict)
    upstream4 = get_upstream_basins("4", graph_dict)
    upstream5 = get_upstream_basins("5", graph_dict)
    @test sort(upstream1) == []
    @test sort(upstream4) == [1, 2]
    @test sort(upstream5) == [1, 2, 3, 4]


    # Test compute_river_state() for first iteration
    initial_window, river_model, env, data_end_date, _ =
        test_run_init("mini_data")

    ## Test compute_hillslope_state() for first iteration
    hillslope_model = river_model.hillslope_model
    @test compute_hillslope_state(initial_window, hillslope_model, env) ==
          compute_hillslope_state(
        initial_window,
        hillslope_model,
        env.static_env,
        env.dynamic_env,
    )
    test_hillslope_state = Dict(
        1051435100 => [
            0.0,
            0.035439303584852255,
            0.1905465441033857,
            0.6751661202561486,
            1.7829556456086615,
            0.04980338135579768,
            0.025206284982074403,
        ],
        1051460430 => [
            0.0,
            0.5060926684030579,
            6.910638305980686,
            3.492561727421671,
            2.372223373444184,
            2.665645525151745,
            1.3144312787009682,
        ],
        1051429580 => [
            0.0,
            4.4867776860648405,
            7.271272713687931,
            81.21104724160986,
            140.28430833650683,
            3.454363710447497,
            3.2802861748654233,
        ],
        1051435110 => [
            0.0,
            2.448720542746908,
            3.515228283652492,
            16.919120633235252,
            9.019503502568712,
            1.5564862036684188,
            1.0678032450972879,
        ],
        1051429650 => [
            0.0,
            2.1587076841542343,
            5.065957391924057,
            197.59232958729942,
            334.0443321729353,
            2.2784358096987174,
            1.9678077832149603,
        ],
    )

    new_hillslope_state =
        compute_hillslope_state(initial_window, hillslope_model, env)


    @test all(
        k -> isapprox(
            new_hillslope_state[k],
            test_hillslope_state[k];
            atol = 1e-10,
        ),
        keys(new_hillslope_state),
    )

    ## Test compute_channel_state() for first iteration
    channel_model = river_model.channel_model
    @test compute_channel_state(
        new_hillslope_state,
        initial_window,
        channel_model,
        env,
    ) == compute_channel_state(
        new_hillslope_state,
        initial_window,
        channel_model,
        env.static_env,
        env.dynamic_env,
    )

    test_channel_state = Dict(
        1.0514351e9 => 1.570786462965263e-11,
        1.05146043e9 => 1.2034753217945104,
        1.05142958e9 => 0.0,
        1.05143511e9 => 0.0,
        1.05142965e9 => 0.0,
    )

    new_channel_state = compute_channel_state(
        new_hillslope_state,
        initial_window,
        channel_model,
        env,
    )

    @test all(
        k ->
            isapprox(new_channel_state[k], test_channel_state[k]; atol = 1e-10),
        keys(new_channel_state),
    )

    # Test compute_streamflow() for first iteration
    new_river_state = HillslopeChannelRiverState(
        new_hillslope_state,
        new_channel_state,
        initial_window,
    )
    @test compute_streamflow(new_river_state, env) ==
          compute_streamflow(new_river_state, env.static_env, env.dynamic_env)
    streamflow = compute_streamflow(new_river_state, env)
    test_streamflow = Dict(
        1.0514351e9 => 0.02520628499778227,
        1.05146043e9 => 2.5179066004954787,
        1.05142958e9 => 3.2802861748654233,
        1.05143511e9 => 1.0678032450972879,
        1.05142965e9 => 1.9678077832149603,
    )

    @test all(
        k -> isapprox(streamflow[k], test_streamflow[k]; atol = 1e-10),
        keys(streamflow),
    )
end

@testset "Mini Tests" begin
    # Run entire small sample set example (10 day span, window size 6)
    streamflows, river_states = test_run_full("mini_data")
    expected_streamflows = Dict(
        1.0514351e9 => 0.2039086137122073,
        1.05146043e9 => 90.49170178310422,
        1.05142958e9 => 49.470987755680916,
        1.05143511e9 => 10.760441661469335,
        1.05142965e9 => 70.16964778305211,
    )
    @test all(
        k -> isapprox(streamflows[end][k], expected_streamflows[k]),
        keys(expected_streamflows),
    )
end

@testset "Short and Wide Tests" begin
    # Run entire small sample set example (10 day span, window size 6)
    streamflows, river_states = test_run_full("shallow_data")
    expected_streamflows = Dict(7.05005406e9 => 50.8404041898554)
    @test isapprox(
        streamflows[end][7.05005406e9],
        expected_streamflows[7.05005406e9],
    )
end
