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

    
    # Test compute_river_state()
    initial_window, river_model, env, data_end_date, _ = test_run_init()
    
    ## compute_hillslope_state()
    hillslope_model = river_model.hillslope_model
    @test compute_hillslope_state(initial_window, hillslope_model, env) == compute_hillslope_state(initial_window, hillslope_model, env.static_env, env.dynamic_env)
    # new_state = compute_hillslope_state(initial_window, river_model, env)
    


    ## computer_channel_state()

end

@testset "Small Example Tests" begin
    # Run entire small sample set example (10 day span, window size 6)
    streamflows, river_states = test_run_full()
    expected_streamflows = Dict(
        1.0514351e9 => 0.1681771926595176,
        1.05146043e9 => 9.439266521834611,
        1.05142958e9 => 80.04636704743433,
        1.05143511e9 => 4.791551273615758,
        1.05142965e9 => 133.05341709808118
    )
    @test streamflows[end] == expected_streamflows
end