@testset "Display invariants" begin
    LAlatex.set_backend!(:symbolics)
    @variables x y t

    function assert_balanced_math_delimiters(rendered)
        @test count(==('$'), rendered) == 2
        @test startswith(rendered, "\$")
        @test endswith(rendered, "\$\n")
    end

    function assert_no_matrix_entry_artifacts(rendered)
        @test !occursin("\\begin{equation}", rendered)
        @test !occursin("\\end{equation}", rendered)
        @test !occursin(" &  & ", rendered)
        @test !occursin(" & & ", rendered)
    end

    representative_outputs = [
        LAlatex.L_show(3//4),
        LAlatex.L_show(2 + 3im),
        LAlatex.L_show([1, 2, 3]),
        LAlatex.L_show(LAlatex.mixed_matrix((1//2, x), (y, 2 + 3im))),
        LAlatex.L_show(BlockArray([1//2 1//3; 1//4 1//5], [1, 1], [1, 1])),
        LAlatex.L_show(LAlatex.set(1, [x, y], 3//4)),
        LAlatex.L_show(LAlatex.lc([1, -2, 0], [x y x + y])),
        LAlatex.L_show(LAlatex.cases([x, 0] => L"x > 0", [0, y] => "otherwise")),
        LAlatex.L_show(LAlatex.aligned(L"Ax" => [x, y], (L"x", L"\in", L"\mathcal{N}(A)"))),
        LAlatex.L_show([(x + y)^2, exp(-3t)]; symopts = (expand = true,)),
    ]

    for rendered in representative_outputs
        assert_balanced_math_delimiters(rendered)
        assert_no_matrix_entry_artifacts(rendered)
    end

    for arraystyle in (:parray, :bmatrix, :Bmatrix, :vmatrix, :Vmatrix, :array)
        rendered = LAlatex.L_show([1 2; 3 4]; arraystyle = arraystyle)
        assert_balanced_math_delimiters(rendered)
        assert_no_matrix_entry_artifacts(rendered)
        @test !occursin("\\[", rendered)
        @test !occursin("\\]", rendered)
    end

    for symopts in ((expand = true,), (factor = true,), (collect = x,))
        rendered = LAlatex.L_show(x^2 + x * y + x; symopts = symopts)
        assert_balanced_math_delimiters(rendered)
        assert_no_matrix_entry_artifacts(rendered)
        @test occursin("x", rendered)
    end

    unfactored = LAlatex.L_show([1//2 1//3]; factor_out = false)
    @test occursin("\\frac{1}{2}", unfactored)
    @test occursin("\\frac{1}{3}", unfactored)
    @test !occursin("\\frac{1}{6} \\left", unfactored)
    assert_balanced_math_delimiters(unfactored)
    assert_no_matrix_entry_artifacts(unfactored)

    drop_zero_lc = LAlatex.L_show(LAlatex.lc([0, 1, -2], [x y x + y]; drop_zero = true))
    @test !occursin("0\\left", drop_zero_lc)
    @test occursin("\\left(\\begin{array}{r}\ny", drop_zero_lc)
    @test occursin("-  2", drop_zero_lc)
    assert_balanced_math_delimiters(drop_zero_lc)
    assert_no_matrix_entry_artifacts(drop_zero_lc)

    formatted = LAlatex.L_show(
        [1 2; 3 4];
        number_formatter = n -> "\\mathrm{$n}",
        per_element_style = (x, i, j, s) -> i == j ? "\\boxed{$s}" : s,
    )
    @test occursin("\\boxed{\\mathrm{1}}", formatted)
    @test occursin("\\boxed{\\mathrm{4}}", formatted)
    @test occursin("\\mathrm{2}", formatted)
    @test occursin("\\mathrm{3}", formatted)
    assert_balanced_math_delimiters(formatted)
    assert_no_matrix_entry_artifacts(formatted)
end
