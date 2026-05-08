@testset "Static quality checks" begin
    if Base.find_package("Aqua") === nothing
        @info "Aqua is not available in the active project; run `Pkg.test()` to execute static quality checks."
    else
        import Aqua

        Aqua.test_all(
            LAlatex;
            ambiguities=false,
            stale_deps=false,
            deps_compat=false,
            persistent_tasks=false,
        )
    end
end
