@testset "Static quality checks" begin
    if optional_test_dependency("Aqua", "static quality checks")
        import Aqua

        Aqua.test_all(LAlatex; stale_deps = (; ignore = [:PythonCall]))
    end

    if optional_test_dependency("JuliaFormatter", "formatter checks")
        import JuliaFormatter

        package_root = pkgdir(LAlatex)
        @test JuliaFormatter.format(
            [joinpath(package_root, "src"), joinpath(package_root, "test")];
            overwrite = false,
            verbose = false,
        )
    end
end
