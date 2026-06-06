using LinearAlgebra

@testset "Display contracts" begin
    LAlatex.set_backend!(:symbolics)

    latex_payload(x) = sprint(show, MIME("text/latex"), x)

    function assert_lshow_math(obj; kwargs...)
        rendered = LAlatex.L_show(obj; kwargs...)
        @test rendered isa String
        @test endswith(rendered, "\n")
        @test startswith(rendered, get(kwargs, :inline, true) ? "\$" : "\$\$")
        @test endswith(chomp(rendered), get(kwargs, :inline, true) ? "\$" : "\$\$")
        @test !startswith(rendered, "\\[")
        @test !endswith(chomp(rendered), "\\]")
        return rendered
    end

    function assert_lshow_display_math(obj; kwargs...)
        rendered = LAlatex.l_show(obj; kwargs...)
        @test rendered isa LaTeXString
        payload = latex_payload(rendered)
        @test !isempty(payload)
        if get(kwargs, :inline, true)
            @test startswith(payload, "\$")
            @test endswith(payload, "\$")
            @test !startswith(strip(payload, '$'), "\$\$")
            @test !endswith(strip(payload, '$'), "\$\$")
        else
            @test startswith(payload, "\$\$\n")
            @test endswith(payload, "\n\$\$")
        end
        delimited_payload = strip(payload, ['$', '\n'])
        @test !startswith(delimited_payload, "\\[")
        @test !endswith(delimited_payload, "\\]")
        return payload
    end

    @testset "public wrappers" begin
        @test occursin("\\left(", assert_lshow_math([1 2; 3 4]))
        @test occursin("\\left(", assert_lshow_display_math([1 2; 3 4]))
        block_payload = assert_lshow_math([1 2; 3 4]; inline = false)
        @test startswith(block_payload, "\$\$\n")
        @test endswith(block_payload, "\n\$\$\n")
        @test occursin("\\left(", block_payload)
        block_display_payload = assert_lshow_display_math([1 2; 3 4]; inline = false)
        @test occursin("\\left(", block_display_payload)
        @test startswith(block_display_payload, "\$\$\n")
        @test endswith(block_display_payload, "\n\$\$")
        @test_throws ArgumentError LAlatex.L_show([1 2; 3 4]; inline = 1)
        @test_throws ArgumentError LAlatex.L_show([1 2; 3 4]; inline = "false")
        @test_throws ArgumentError LAlatex.l_show([1 2; 3 4]; inline = nothing)
        err = try
            LAlatex.L_show([1 2; 3 4]; inline = 1, color = "red}{\\bad")
        catch e
            e
        end
        @test err isa ArgumentError
        @test occursin("inline must be a Bool", sprint(showerror, err))
        unsupported_err = try
            LAlatex.L_show(Ref(1))
        catch e
            e
        end
        @test unsupported_err isa ArgumentError
        @test occursin(
            "Unsupported argument type for L_show",
            sprint(showerror, unsupported_err),
        )
    end

    @testset "equation tags and labels" begin
        tagged = LAlatex.L_show(L"x = y"; inline = false, tag = "1")
        @test startswith(tagged, "\$\$\n")
        @test occursin("\\tag{1}", tagged)
        @test endswith(tagged, "\n\$\$\n")

        labeled = LAlatex.L_show(L"A x = b"; inline = false, label = "eq:linear-system")
        @test occursin("\\label{eq:linear-system}", labeled)

        annotated = LAlatex.L_show(
            L"A^T A x = A^T b";
            inline = false,
            tag = L"\ast",
            label = :eq_normal,
        )
        @test occursin("\\tag{\\ast} \\label{eq_normal}", annotated)

        escaped_tag = LAlatex.L_show(L"x"; inline = false, tag = "A_1")
        @test occursin("\\tag{A\\_1}", escaped_tag)

        display_payload = latex_payload(
            LAlatex.l_show(L"x = y"; inline = false, tag = 2, label = "eq:two"),
        )
        @test startswith(display_payload, "\$\$\n")
        @test occursin("\\tag{2} \\label{eq:two}", display_payload)
        @test endswith(display_payload, "\n\$\$")

        @test_throws ArgumentError LAlatex.L_show(L"x"; tag = "1")
        @test_throws ArgumentError LAlatex.L_show(L"x"; label = "eq:x")
        @test_throws ArgumentError LAlatex.L_show(L"x"; inline = false, tag = "")
        @test_throws ArgumentError LAlatex.L_show(L"x"; inline = false, label = "")
        @test_throws ArgumentError LAlatex.L_show(L"x"; inline = false, label = "bad label")
        @test_throws ArgumentError LAlatex.L_show(
            L"x";
            inline = false,
            label = "bad{label}",
        )
        @test_throws ArgumentError LAlatex.L_show(L"x"; inline = false, tag = true)
        @test_throws ArgumentError LAlatex.L_show(L"x"; inline = false, tag = [])
        @test_throws ArgumentError LAlatex.L_show(L"x"; inline = false, label = [])
    end

    @testset "strings and scalars" begin
        @test occursin("\\text{plain text}", assert_lshow_math("plain text"))
        @test occursin("\\alpha", assert_lshow_math(L"\\alpha"))
        @test occursin("\\frac{3}{4}", assert_lshow_math(3//4))
        @test occursin("\\mathit{i}", assert_lshow_math(2 + 3im))
        @test LAlatex.strip_math_delims("\$π\$") == "π"
        @test LAlatex.strip_math_delims("\$\$π\$\$") == "π"
        @test LAlatex.strip_math_delims("\\[π\\]") == "π"

        @test occursin("\\text{plain text}", assert_lshow_display_math("plain text"))
        @test occursin("\\alpha", assert_lshow_display_math(L"\\alpha"))
        @test occursin("\\frac{3}{4}", assert_lshow_display_math(3//4))
        @test occursin("\\mathit{i}", assert_lshow_display_math(2 + 3im))

        mixed_tuple = (π, :beta, :my_var, 2.71, 2//3, 4im//5)
        mixed_payload = latex_payload(
            LAlatex.l_show("Change the separator: ", mixed_tuple; separator = "; "),
        )
        @test occursin("π", mixed_payload)
        @test occursin(";\\beta", mixed_payload)
        @test occursin("\\frac{2}{3}", mixed_payload)
    end

    @testset "uniform scaling" begin
        identity_payload = assert_lshow_math(I)
        @test occursin("I", identity_payload)
        @test !occursin("\\text{I}", identity_payload)

        zero_payload = assert_lshow_math(0I)
        @test occursin("\$0\$", zero_payload)
        @test !occursin("\\text{0}", zero_payload)

        scaled_payload = assert_lshow_math(2I)
        @test occursin("2 I", scaled_payload)
        @test !occursin("\\text{2 I}", scaled_payload)

        colored_payload = assert_lshow_math(I; color = "blue")
        @test occursin("\\textcolor{blue}{I}", colored_payload)
        @test !occursin("\\textcolor{blue}{\\text{I}}", colored_payload)

        display_payload = assert_lshow_display_math(2I)
        @test occursin("2 I", display_payload)
        @test !occursin("\\text{2 I}", display_payload)
    end

    @testset "arrays and block arrays" begin
        vector_payload = assert_lshow_display_math([1, 2, 3])
        @test occursin("\\begin{array}{r}", vector_payload)

        matrix_payload = assert_lshow_display_math([1 2; 3 4])
        @test occursin("\\begin{array}{rr}", matrix_payload)
        @test !occursin(" &  & ", matrix_payload)

        outlined_payload = assert_lshow_display_math([1 2; 3 4]; block_sizes = [1, 1])
        @test occursin("\\hline", outlined_payload)
        @test occursin("|", outlined_payload)

        jordan_payload = assert_lshow_display_math(
            [2 1 0 0 0; 0 2 0 0 0; 0 0 2 0 0; 0 0 0 3 0; 0 0 0 0 3];
            per_element_style =
                LAlatex.jordanblock_formatter([2, 1, 2], colors = ["red", "red", "blue"]),
            block_sizes = [2, 1, 2],
        )
        @test occursin("\\textcolor{red}", jordan_payload)
        @test occursin("\\hline", jordan_payload)
        @test occursin("|", jordan_payload)

        block_matrix = BlockArray([1 2; 3 4], [1, 1], [1, 1])
        block_payload = assert_lshow_display_math(block_matrix)
        @test occursin("\\hline", block_payload)
        @test occursin("|", block_payload)

        block_vector = BlockArray([1, 2, 3], [1, 2])
        block_vector_payload = assert_lshow_display_math(block_vector)
        @test occursin("\\hline", block_vector_payload)
    end

    @testset "display containers" begin
        @variables x y

        set_payload = assert_lshow_display_math(LAlatex.set(1, 2, 3))
        @test occursin("\\left", set_payload)
        @test occursin("\\right", set_payload)

        lc_payload = assert_lshow_display_math(LAlatex.lc([1, -2], [x y]))
        @test occursin("\\left(\\begin{array}{r}", lc_payload)
        @test occursin(" - ", lc_payload)

        cases_payload = assert_lshow_display_math(
            LAlatex.cases([x, 0] => L"x > 0", ([0, y], "otherwise")),
        )
        @test occursin("\\begin{cases}", cases_payload)
        @test occursin("\\text{otherwise}", cases_payload)

        aligned_payload = assert_lshow_display_math(
            LAlatex.aligned(L"Ax" => [x, y], (L"x", L"\in", L"\mathcal{N}(A)")),
        )
        @test occursin("\\begin{aligned}", aligned_payload)
        @test occursin("Ax & =", aligned_payload)
        @test occursin("x & \\in", aligned_payload)
    end

    @testset "option propagation" begin
        @variables x y

        expanded = assert_lshow_math((x + y)^2; symopts = (expand = true,))
        @test occursin("x^{2}", expanded) || occursin("x^2", expanded)

        unfactored = assert_lshow_math([1//2 1//3]; factor_out = false)
        @test occursin("\\frac{1}{2}", unfactored)
        @test !occursin("\\frac{1}{6} \\left", unfactored)

        formatted = assert_lshow_math(42; number_formatter = n -> "\\textbf{$n}")
        @test occursin("\\textbf{42}", formatted)

        styled = assert_lshow_math(
            [1 2; 3 4];
            per_element_style = (x, i, j, s) -> i == j ? "\\boxed{$s}" : s,
        )
        @test occursin("\\boxed{1}", styled)
        @test occursin("\\boxed{4}", styled)
    end
end
