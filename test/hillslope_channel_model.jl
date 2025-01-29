using Test
using ClimaRivers #(gather up the exported functions and structs for use in this scope)

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
    initial_window, river_model, env, data_end_date, _ = test_run_init()

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
            0.0020499191015790758,
            0.010452984693913786,
            0.04126935527573286,
            0.19083161063516876,
            0.17075762060905167,
            0.1804893760599954,
        ],
        1051460430 => [
            0.0,
            0.16464777031959082,
            0.16687127747327474,
            0.45440395874751704,
            1.0728691978019544,
            6.413658520862648,
            4.723755298164256,
        ],
        1051429580 => [
            3.552713678800501e-15,
            30.01377540496592,
            25.81356016324419,
            49.27790306817931,
            75.49193129565366,
            33.09285601118408,
            35.60239021729076,
        ],
        1051435110 => [
            -2.220446049250313e-16,
            1.9228093083301891,
            1.578095249309317,
            1.658213104150694,
            4.023195942893823,
            5.03492062653842,
            2.571851681460489,
        ],
        1051429650 => [
            3.552713678800501e-15,
            29.9487620429082,
            51.16449376760788,
            66.3174109253273,
            177.26668413371624,
            69.81683649526752,
            86.90268747602767,
        ],
    )
    new_hillslope_state =
        compute_hillslope_state(initial_window, hillslope_model, env)
    @test new_hillslope_state == test_hillslope_state

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
        1.0514351e9 => 3.510632085989178e-10,
        1.05146043e9 => 21.415229895931486,
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
    @test new_channel_state == test_channel_state

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
        1.0514351e9 => 0.1804893764110586,
        1.05146043e9 => 26.138985194095742,
        1.05142958e9 => 35.60239021729076,
        1.05143511e9 => 2.571851681460489,
        1.05142965e9 => 86.90268747602767,
    )
    # change to get approx equals for floating types for each basin specifically
    @test streamflow == test_streamflow
end

@testset "Small Example Tests" begin
    # Run entire small sample set example (10 day span, window size 6)
    streamflows, river_states = test_run_full()
    expected_streamflows = Dict(
        1.0514351e9 => 0.1681771926595176,
        1.05146043e9 => 9.439266521834611,
        1.05142958e9 => 80.04636704743433,
        1.05143511e9 => 4.791551273615758,
        1.05142965e9 => 133.05341709808118,
    )
    @test streamflows[end] == expected_streamflows
end
