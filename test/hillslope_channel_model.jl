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
    slope1 = MizurouteHillslopeV1(shape, timescale)
    slope2 = MizurouteHillslopeV1{FT}()
    @test slope1.shape == slope2.shape
    @test slope1.timescale == slope2.timescale
    @test slope1 == slope2

    # Channel
    FT = Float64
    wave_velocity = FT(1.5 * 86400)
    diffusivity = FT(8000 * 86400)
    channel1 = MizurouteChannelV1(wave_velocity, diffusivity)
    channel2 = MizurouteChannelV1{FT}()
    @test channel1.wave_velocity == channel2.wave_velocity
    @test channel1.diffusivity == channel2.diffusivity
    @test channel1 == channel2



end
