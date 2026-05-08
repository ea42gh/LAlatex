@testset "Display options" begin
    LAlatex.set_backend!(:symbolics)
    @variables x y

    @testset "top-level options propagate into containers" begin
        grouped_matrix = LAlatex.L_show(LAlatex.set([1//2 1//3]); factor_out = false)
        @test occursin("\\frac{1}{2}", grouped_matrix)
        @test occursin("\\frac{1}{3}", grouped_matrix)
        @test !occursin("\\frac{1}{6} \\left", grouped_matrix)

        expanded_cases = LAlatex.L_show(
            LAlatex.cases((x + y)^2 => "otherwise");
            symopts = (expand = true,),
        )
        @test occursin("x^{2}", expanded_cases) || occursin("x^2", expanded_cases)
        @test !occursin("\\left(y + x\\right)^{2}", expanded_cases)

        aligned_matrix =
            LAlatex.L_show(LAlatex.aligned(L"A" => [1 2; 3 4]); arraystyle = :bmatrix)
        @test occursin("\\begin{bmatrix}", aligned_matrix)
    end

    @testset "container-local options override top-level options" begin
        grouped_matrix =
            LAlatex.L_show(LAlatex.set([1//2 1//3]; factor_out = false); factor_out = true)
        @test occursin("\\frac{1}{2}", grouped_matrix)
        @test occursin("\\frac{1}{3}", grouped_matrix)
        @test !occursin("\\frac{1}{6} \\left", grouped_matrix)

        grouped_bmatrix = LAlatex.L_show(
            LAlatex.set([1 2; 3 4]; arraystyle = :bmatrix);
            arraystyle = :parray,
        )
        @test occursin("\\begin{bmatrix}", grouped_bmatrix)

        cases_bmatrix = LAlatex.L_show(
            LAlatex.cases([1, 2] => "otherwise"; arraystyle = :bmatrix);
            arraystyle = :parray,
        )
        @test occursin("\\begin{bmatrix}", cases_bmatrix)
    end

    @testset "formatter and color options propagate" begin
        formatted_group =
            LAlatex.L_show(LAlatex.set(42); number_formatter = n -> "\\textbf{$n}")
        @test occursin("\\textbf{42}", formatted_group)

        styled_cases = LAlatex.L_show(
            LAlatex.cases([1 2; 3 4] => "otherwise");
            per_element_style = (x, i, j, s) -> i == j ? "\\boxed{$s}" : s,
        )
        @test occursin("\\boxed{1}", styled_cases)
        @test occursin("\\boxed{4}", styled_cases)

        colored_aligned = LAlatex.L_show(LAlatex.aligned(L"A" => [1, 2]); color = "red")
        @test occursin("\\textcolor{red}{\\begin{aligned}", colored_aligned)
    end

    @testset "symopts compatibility and validation" begin
        expanded_from_dict = LAlatex.L_show((x + y)^2; symopts = Dict(:expand => true))
        @test occursin("x^{2}", expanded_from_dict) || occursin("x^2", expanded_from_dict)

        expanded_direct_pair = LAlatex.L_show((x + y)^2; symopts = :expand => true)
        @test occursin("x^{2}", expanded_direct_pair) ||
              occursin("x^2", expanded_direct_pair)

        expanded_from_pair =
            LAlatex.L_show(LAlatex.set((x + y)^2); symopts = :expand => true)
        @test occursin("x^{2}", expanded_from_pair) || occursin("x^2", expanded_from_pair)

        local_expanded = LAlatex.L_show(
            LAlatex.set((x + y)^2; symopts = :expand => true);
            symopts = NamedTuple(),
        )
        @test occursin("x^{2}", local_expanded) || occursin("x^2", local_expanded)

        @test LAlatex.L_show((x + y)^2; symopts = nothing) isa String

        @test_throws ArgumentError LAlatex.L_show((x + y)^2; symopts = true)
        @test_throws ArgumentError LAlatex.L_show(
            LAlatex.cases((x + y)^2 => "otherwise");
            symopts = true,
        )
        @test_throws ArgumentError LAlatex.L_show(
            LAlatex.aligned((x + y)^2 => x);
            symopts = true,
        )
    end

    @testset "container option merge compatibility" begin
        unknown_option = LAlatex.L_show(LAlatex.set(1; not_an_option = true))
        @test occursin("1", unknown_option)

        local_separator =
            LAlatex.L_show(LAlatex.set(1, 2; separator = L";"); separator = L",")
        @test occursin("1 ; 2", local_separator)
    end

    @testset "top-level and core option plumbing" begin
        default_setstyle = LAlatex.L_show(LAlatex.set())
        @test occursin("\\left\\{", default_setstyle)

        explicit_setstyle = LAlatex.L_show(LAlatex.set(); setstyle = :parray)
        @test occursin("\\left(", explicit_setstyle)

        direct_bmatrix = LAlatex.L_show([1 2; 3 4]; arraystyle = :bmatrix)
        @test occursin("\\begin{bmatrix}", direct_bmatrix)

        direct_separator = LAlatex.L_show((1, 2, 3); separator = L";")
        @test occursin("1;2;3", direct_separator)

        direct_color = LAlatex.L_show(42; color = "red")
        @test occursin("\\textcolor{red}{42}", direct_color)

        xcolor_expression = LAlatex.L_show(42; color = "red!50!black")
        @test occursin("\\textcolor{red!50!black}{42}", xcolor_expression)

        symbol_color = LAlatex.L_show(42; color = :blue)
        @test occursin("\\textcolor{blue}{42}", symbol_color)

        local_named_tuple = LAlatex.L_show(
            (value = [1 2; 3 4], arraystyle = :bmatrix);
            arraystyle = :parray,
        )
        @test occursin("\\begin{bmatrix}", local_named_tuple)

        local_symopts = LAlatex.L_show(
            (value = (x + y)^2, symopts = (expand = true,));
            symopts = NamedTuple(),
        )
        @test occursin("x^{2}", local_symopts) || occursin("x^2", local_symopts)
        @test !occursin(",true", local_symopts)
        @test !occursin("expand", local_symopts)

        core_fragment = LAlatex.L_show_core((1, 2); separator = L";")
        @test core_fragment == "1;2"
    end

    @testset "style option validation" begin
        @test_throws ArgumentError LAlatex.L_show([1 2; 3 4]; arraystyle = :not_a_style)
        @test_throws ArgumentError LAlatex.L_show([1 2; 3 4]; arraystyle = "bmatrix")
        @test_throws ArgumentError LAlatex.L_show(
            LAlatex.set(1, 2);
            setstyle = :not_a_style,
        )
        @test_throws ArgumentError LAlatex.L_show(
            LAlatex.set([1 2; 3 4]; arraystyle = :not_a_style),
        )
    end

    @testset "factor_out option validation" begin
        @test_throws ArgumentError LAlatex.L_show([1//2 1//3]; factor_out = :not_bool)
        @test_throws ArgumentError LAlatex.L_show(
            LAlatex.set([1//2 1//3]; factor_out = "false"),
        )
        @test_throws ArgumentError LAlatex.L_show(
            LAlatex.lc([1], [[1//2, 1//3]]; factor_out = 0),
        )
        @test_throws ArgumentError LAlatex.L_show_core([1//2 1//3]; factor_out = nothing)
    end

    @testset "color option validation" begin
        @test_throws ArgumentError LAlatex.L_show(42; color = "red}{\\bad")
        @test_throws ArgumentError LAlatex.L_show(42; color = "\\red")
        @test_throws ArgumentError LAlatex.L_show(42; color = "")
        @test_throws ArgumentError LAlatex.L_show(42; color = 1)
        @test_throws ArgumentError LAlatex.L_show(LAlatex.set(42; color = "red}"))
    end
end
