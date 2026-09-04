@testset "Static quality checks" begin
    if optional_test_dependency("Aqua", "static quality checks")
        import Aqua

        # Aqua stale-dependency check launches a fresh Julia subprocess. In
        # the PythonCall test environment that subprocess can block while
        # initializing the interop runtime; explicit integration tests already
        # exercise this dependency.
        Aqua.test_all(LAlatex; stale_deps = false)
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
