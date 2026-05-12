@testset "Release notes cover documented features" begin
    package_root = normpath(joinpath(@__DIR__, ".."))
    changelog = read(joinpath(package_root, "CHANGELOG.md"), String)
    display_policy =
        read(joinpath(package_root, "docs", "src", "display-policy.md"), String)

    documented_release_terms = (
        ("equation annotations", ("tag", "label")),
        ("set-builder notation", ("such_that", "such_that_separator")),
    )

    for (feature_name, terms) in documented_release_terms
        @testset "$feature_name" begin
            for term in terms
                @test occursin(term, display_policy)
                @test occursin(term, changelog)
            end
        end
    end
end
