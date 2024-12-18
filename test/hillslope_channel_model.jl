using Test
using ClimaRivers #(gather up the exported functions and structs for use in this scope)
import ClimaRivers: MizurouteHillslopeV1

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
    # can be example mad eup solutions, get edge cases
    upstream_basins = ClimaRivers.Routing.get_upstream_basins("1", {1:[]}) # get edge cases
    @test upstream_basins == []

    # test running of mini test to make sure output is correct
    # can use small chunk of time 2-10 days or can adjust t_max to be like 25
end
