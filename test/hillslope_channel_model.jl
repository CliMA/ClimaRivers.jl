using Test
using JLD2
using ClimaRivers #(gather up the exported functions and structs for use in this scope)

@testset "Hillslope channel model tests" begin

    # @test A == B
    # @test_throws ErrorType f(x) 


end


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

@testset "Routing Tests" begin
    graph_dict =
        Dict("1" => [], "2" => [], "3" => [], "4" => [1, 2], "5" => [3, 4])
    graph_dict = Dict{String, Any}(graph_dict)
    upstream1 = get_upstream_basins("1", graph_dict)
    upstream4 = get_upstream_basins("4", graph_dict)
    upstream5 = get_upstream_basins("5", graph_dict)
    @test sort(upstream1) == []
    @test sort(upstream4) == [1, 2]
    @test sort(upstream5) == [1, 2, 3, 4]
end

@testset "Small Example Tests" begin
    # test running of mini test to make sure output is correct
    # can use small chunk of time 2-10 days or can adjust t_max to be like 25
    data_file_path = joinpath(@__DIR__, "..", "mini_data", "routing")
    @info "reading data files from $(data_file_path)"
    simulation_file = joinpath(data_file_path, "simulations", "simulations_lv05", "gamma_IRF", "streamflow_history6 days.jld2")
    file = jldopen(simulation_file, "r")  
    streamflow = file["streamflows"] 
    close(file) 
    expected_streamflows = Dict(
        1.0514351e9 => 0.1681771926595176,
        1.05146043e9 => 9.439266521834611,
        1.05142958e9 => 80.04636704743433,
        1.05143511e9 => 4.791551273615758,
        1.05142965e9 => 133.05341709808118
    )
    @test streamflow[end] == expected_streamflows
end