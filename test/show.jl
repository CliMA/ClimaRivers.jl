using Test
using ClimaRivers
using DataFrames
using Dates

@testset "DateWindow show" begin
    dw = DateWindow(
        start_date = Date("1996-01-01"),
        end_date = Date("1996-01-10"),
        date_step = Day(1),
    )
    out = sprint(show, MIME("text/plain"), dw)
    @test occursin("DateWindow", out)
    @test count(==('\n'), out) <= 10
end

@testset "DateWindow summary" begin
    dw = DateWindow(
        start_date = Date("1996-01-01"),
        end_date = Date("1996-01-10"),
        date_step = Day(1),
    )
    out = sprint(summary, dw)
    @test occursin("DateWindow", out)
    @test !occursin('\n', out)
end

@testset "StaticEnvironment show" begin
    se = StaticEnvironment(
        [1, 2, 3],
        DataFrame(a = [1, 2, 3], b = [4, 5, 6]),
        Dict("1" => [], "2" => [1], "3" => [1, 2]),
    )
    out = sprint(show, MIME("text/plain"), se)
    @test occursin("StaticEnvironment", out)
    @test count(==('\n'), out) <= 10
end

@testset "StaticEnvironment summary" begin
    se = StaticEnvironment(
        [1, 2, 3],
        DataFrame(a = [1, 2, 3], b = [4, 5, 6]),
        Dict("1" => [], "2" => [1], "3" => [1, 2]),
    )
    out = sprint(summary, se)
    @test occursin("StaticEnvironment", out)
    @test !occursin('\n', out)
end

@testset "DynamicEnvironment show" begin
    dw = DateWindow(
        start_date = Date("1996-01-01"),
        end_date = Date("1996-01-10"),
        date_step = Day(1),
    )
    de = DynamicEnvironment(
        Dict(1 => DataFrame(), 2 => DataFrame()),
        dw,
        tempdir(),
    )
    out = sprint(show, MIME("text/plain"), de)
    @test occursin("DynamicEnvironment", out)
    @test count(==('\n'), out) <= 10
end

@testset "DynamicEnvironment summary" begin
    dw = DateWindow(
        start_date = Date("1996-01-01"),
        end_date = Date("1996-01-10"),
        date_step = Day(1),
    )
    de = DynamicEnvironment(
        Dict(1 => DataFrame(), 2 => DataFrame()),
        dw,
        tempdir(),
    )
    out = sprint(summary, de)
    @test occursin("DynamicEnvironment", out)
    @test !occursin('\n', out)
end

@testset "Environment show" begin
    dw = DateWindow(
        start_date = Date("1996-01-01"),
        end_date = Date("1996-01-10"),
        date_step = Day(1),
    )
    se = StaticEnvironment(
        [1, 2],
        DataFrame(a = [1, 2]),
        Dict("1" => [], "2" => [1]),
    )
    de = DynamicEnvironment(
        Dict(1 => DataFrame(), 2 => DataFrame()),
        dw,
        tempdir(),
    )
    env = Environment(se, de)
    out = sprint(show, MIME("text/plain"), env)
    @test occursin("Environment", out)
    @test count(==('\n'), out) <= 10
end

@testset "Environment summary" begin
    dw = DateWindow(
        start_date = Date("1996-01-01"),
        end_date = Date("1996-01-10"),
        date_step = Day(1),
    )
    se = StaticEnvironment(
        [1, 2],
        DataFrame(a = [1, 2]),
        Dict("1" => [], "2" => [1]),
    )
    de = DynamicEnvironment(
        Dict(1 => DataFrame(), 2 => DataFrame()),
        dw,
        tempdir(),
    )
    env = Environment(se, de)
    out = sprint(summary, env)
    @test occursin("Environment", out)
    @test !occursin('\n', out)
end

@testset "MizurouteHillslopeV1 show" begin
    hs = MizurouteHillslopeV1{Float32}()
    out = sprint(show, MIME("text/plain"), hs)
    @test occursin("MizurouteHillslopeV1", out)
    @test count(==('\n'), out) <= 10
end

@testset "MizurouteHillslopeV1 summary" begin
    hs = MizurouteHillslopeV1{Float32}()
    out = sprint(summary, hs)
    @test occursin("MizurouteHillslopeV1", out)
    @test !occursin('\n', out)
end

@testset "MizurouteChannelV1 show" begin
    ch = MizurouteChannelV1{Float64}()
    out = sprint(show, MIME("text/plain"), ch)
    @test occursin("MizurouteChannelV1", out)
    @test count(==('\n'), out) <= 10
end

@testset "MizurouteChannelV1 summary" begin
    ch = MizurouteChannelV1{Float64}()
    out = sprint(summary, ch)
    @test occursin("MizurouteChannelV1", out)
    @test !occursin('\n', out)
end

@testset "HillslopeChannelRiverModel show" begin
    model = HillslopeChannelRiverModel(
        MizurouteHillslopeV1{Float32}(),
        MizurouteChannelV1{Float64}(),
    )
    out = sprint(show, MIME("text/plain"), model)
    @test occursin("HillslopeChannelRiverModel", out)
    @test count(==('\n'), out) <= 10
end

@testset "HillslopeChannelRiverModel summary" begin
    model = HillslopeChannelRiverModel(
        MizurouteHillslopeV1{Float32}(),
        MizurouteChannelV1{Float64}(),
    )
    out = sprint(summary, model)
    @test occursin("HillslopeChannelRiverModel", out)
    @test !occursin('\n', out)
end

@testset "HillslopeChannelRiverState show" begin
    dw = DateWindow(
        start_date = Date("1996-01-01"),
        end_date = Date("1996-01-10"),
        date_step = Day(1),
    )
    state = HillslopeChannelRiverState(
        Dict(1 => [0.1, 0.2, 0.3]),
        Dict(1 => 0.5),
        dw,
    )
    out = sprint(show, MIME("text/plain"), state)
    @test occursin("HillslopeChannelRiverState", out)
    @test count(==('\n'), out) <= 10
end

@testset "HillslopeChannelRiverState summary" begin
    dw = DateWindow(
        start_date = Date("1996-01-01"),
        end_date = Date("1996-01-10"),
        date_step = Day(1),
    )
    state = HillslopeChannelRiverState(
        Dict(1 => [0.1, 0.2, 0.3]),
        Dict(1 => 0.5),
        dw,
    )
    out = sprint(summary, state)
    @test occursin("HillslopeChannelRiverState", out)
    @test !occursin('\n', out)
end

@testset "HillslopeChannelRiverState show (empty dicts)" begin
    dw = DateWindow(
        start_date = Date("1996-01-01"),
        end_date = Date("1996-01-10"),
        date_step = Day(1),
    )
    state = HillslopeChannelRiverState(Dict(), Dict(), dw)
    out = sprint(show, MIME("text/plain"), state)
    @test occursin("HillslopeChannelRiverState", out)
    @test count(==('\n'), out) <= 10
end

@testset "HillslopeChannelRiverState summary (empty)" begin
    dw = DateWindow(
        start_date = Date("1996-01-01"),
        end_date = Date("1996-01-10"),
        date_step = Day(1),
    )
    state = HillslopeChannelRiverState(Dict(), Dict(), dw)
    out = sprint(summary, state)
    @test occursin("HillslopeChannelRiverState", out)
    @test !occursin('\n', out)
end
