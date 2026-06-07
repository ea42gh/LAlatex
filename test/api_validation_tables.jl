@testset "API validation tables" begin
    package_root = normpath(joinpath(@__DIR__, ".."))
    display_policy =
        read(joinpath(package_root, "docs", "src", "display-policy.md"), String)

    expected_display_options = (
        :setstyle,
        :arraystyle,
        :color,
        :separator,
        :number_formatter,
        :per_element_style,
        :factor_out,
        :boxes,
        :symopts,
    )
    expected_cell_container_options =
        (:arraystyle, :color, :number_formatter, :per_element_style, :factor_out, :boxes, :symopts)
    expected_set_options = (expected_display_options..., :such_that, :such_that_separator)

    @test LAlatex.DISPLAY_OPTION_KEYS == expected_display_options
    @test LAlatex.CELL_CONTAINER_OPTION_KEYS == expected_cell_container_options
    @test LAlatex.SET_OPTION_KEYS == expected_set_options

    for key in expected_set_options
        @test occursin("- `$key`", display_policy)
    end
    for key in expected_cell_container_options
        @test occursin("- `$key`", display_policy)
    end

    option_examples = (
        :setstyle => :Barray,
        :arraystyle => :bmatrix,
        :color => :blue,
        :separator => L";",
        :number_formatter => (x -> x),
        :per_element_style => ((x, i, j, latex) -> latex),
        :factor_out => false,
        :boxes => [(rows = 1:1, cols = 1:1)],
        :symopts => (expand = true,),
    )

    for (key, value) in option_examples
        @testset "DisplayOptions accepts $key" begin
            @test LAlatex.DisplayOptions(; key => value) isa LAlatex.DisplayOptions
        end
    end

    for (key, value) in option_examples
        @testset "set accepts $key" begin
            @test LAlatex.set(1; key => value) isa LAlatex.Group
        end
    end

    for (key, value) in option_examples
        key == :setstyle && continue
        key == :separator && continue
        @testset "cell containers accept $key" begin
            @test LAlatex.cases(1 => 2; key => value) isa LAlatex.Cases
            @test LAlatex.aligned(1 => 2; key => value) isa LAlatex.Aligned
        end
    end

    @test LAlatex.set(1; such_that = L"x > 0") isa LAlatex.Group
    @test LAlatex.set(1; such_that = L"x > 0", such_that_separator = L":") isa LAlatex.Group

    @test_throws MethodError LAlatex.DisplayOptions(; not_an_option = true)

    invalid_calls = (
        () -> LAlatex.set(1; not_an_option = true),
        () -> LAlatex.cases(1 => 2; separator = L";"),
        () -> LAlatex.aligned(1 => 2; setstyle = :Barray),
        () -> LAlatex.set(1; such_that_separator = L":"),
    )

    for call in invalid_calls
        @test_throws ArgumentError call()
    end
end
