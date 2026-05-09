@testset "Performance guardrails" begin
    LAlatex.set_backend!(:symbolics)
    LAlatex.reset_display_defaults!()
    @variables x y

    strict_guardrails = lowercase(get(ENV, "LALATEX_STRICT_PERF_GUARDRAILS", "false")) in
    ("1", "true", "yes")

    guardrails = (
        (
            name = "numeric matrix render",
            advisory_limit = 100_000,
            hard_limit = 500_000,
            render = () -> LAlatex.L_show([1 2 3; 4 5 6]),
        ),
        (
            name = "rational matrix render",
            advisory_limit = 120_000,
            hard_limit = 600_000,
            render = () -> LAlatex.L_show([1//2 1//3; 2//3 3//4]),
        ),
        (
            name = "linear combination render",
            advisory_limit = 300_000,
            hard_limit = 1_500_000,
            render = () ->
                LAlatex.L_show(LAlatex.lc([1, -2, 3], [[1, 0], [0, 1], [1, 1]])),
        ),
        (
            name = "symbolic expansion render",
            advisory_limit = 500_000,
            hard_limit = 2_500_000,
            render = () -> LAlatex.L_show((x + y)^2; symopts = (expand = true,)),
        ),
        (
            name = "scoped display defaults render",
            advisory_limit = 140_000,
            hard_limit = 700_000,
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
            @test allocated <= case.hard_limit
            if strict_guardrails
                @test allocated <= case.advisory_limit
            elseif allocated > case.advisory_limit
                @info "Allocation exceeded advisory limit" case.name allocated case.advisory_limit
            end
        end
    end

    LAlatex.reset_display_defaults!()
end
