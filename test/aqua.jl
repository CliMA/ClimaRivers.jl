using Test
using ClimaRivers
using Aqua

@testset "Aqua tests (performance)" begin
    ua = Aqua.detect_unbound_args_recursively(ClimaRivers)
    @test length(ua) == 0
    ambs = Aqua.detect_ambiguities(ClimaRivers; recursive = true)
    pkg_match(pkgname, pkdir::Nothing) = false
    pkg_match(pkgname, pkdir::AbstractString) = occursin(pkgname, pkdir)
    filter!(x -> pkg_match("ClimaRivers", pkgdir(last(x).module)), ambs)

    # Uncomment for debugging:
    # for method_ambiguity in ambs
    #     @show method_ambiguity
    # end
    @test length(ambs) == 0
end
@testset "Aqua tests (additional)" begin
    Aqua.test_undefined_exports(ClimaRivers)
    # Insolation is a direct dependency for the package extension
    Aqua.test_stale_deps(ClimaRivers)
    Aqua.test_deps_compat(ClimaRivers)
    Aqua.test_project_extras(ClimaRivers)
    Aqua.test_piracies(ClimaRivers)
end

nothing
