function optional_test_dependency(name::AbstractString, purpose::AbstractString)
    if Base.find_package(name) !== nothing
        return true
    end
    @info(
        "$name is not available in the active project; run `Pkg.test()` to execute $purpose.",
    )
    return false
end
