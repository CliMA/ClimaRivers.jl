using SafeTestsets
# Performance and code quality tests
@safetestset "Aqua tests" begin
    include("aqua.jl")
end

@safetestset "Hillslope channel model tests" begin
    include("hillslope_channel_model.jl")
end

@safetestset "Base.show tests" begin
    include("show.jl")
end
