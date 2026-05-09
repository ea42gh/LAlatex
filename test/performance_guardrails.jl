@testset "Performance guardrails" begin
    LAlatex.set_backend!(:symbolics)
    LAlatex.reset_display_defaults!()
    @variables x y

    guardrails = (
        (
            name = "numeric matrix render",
            limit = 100_000,
            render = () -> LAlatex.L_show([1 2 3; 4 5 6]),
        ),
        (
            name = "rational matrix render",
            limit = 120_000,
            render = () -> LAlatex.L_show([1//2 1//3; 2//3 3//4]),
        ),
        (
            name = "linear combination render",
            limit = 300_000,
            render = () ->
                LAlatex.L_show(LAlatex.lc([1, -2, 3], [[1, 0], [0, 1], [1, 1]])),
        ),
        (
            name = "symbolic expansion render",
            limit = 500_000,
            render = () -> LAlatex.L_show((x + y)^2; symopts = (expand = true,)),
        ),
        (
            name = "scoped display defaults render",
            limit = 140_000,
            render = () -> LAlatex.with_display_defaults(arraystyle = :bmatrix) do
                LAlatex.L_show([1 2 3; 4 5 6])
            end,
        ),
    )

    for case in guardrails
        @testset "$(case.name)" begin
            case.render()
            case.render()
            allocated = @allocated case.render()
            @test allocated <= case.limit
        end
    end

    LAlatex.reset_display_defaults!()
end
