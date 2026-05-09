@testset "Static quality checks" begin
    if Base.find_package("Aqua") === nothing
        @info "Aqua is not available in the active project; run `Pkg.test()` to execute static quality checks."
    else
        import Aqua

        Aqua.test_all(
            LAlatex;
            stale_deps = (; ignore = [:PythonCall, :Aqua, :JET, :JuliaFormatter]),
        )
    end

    if Base.find_package("JuliaFormatter") === nothing
        @info "JuliaFormatter is not available in the active project; run `Pkg.test()` to execute formatter checks."
    else
        import JuliaFormatter

        package_root = pkgdir(LAlatex)
        @test JuliaFormatter.format(
            [joinpath(package_root, "src"), joinpath(package_root, "test")];
            overwrite = false,
            verbose = false,
        )
    end
end
