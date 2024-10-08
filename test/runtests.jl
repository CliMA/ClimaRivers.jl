using SafeTestsets
# Performance and code quality tests
@safetestset "Aqua tests" begin
    include("aqua.jl")
end

@safetestset "Fake test" begin
    include("fake_test.jl")
end
