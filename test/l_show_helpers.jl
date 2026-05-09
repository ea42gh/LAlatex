@testset "L_show helpers" begin
    LAlatex.set_backend!(:symbolics)
    template = LaTeXString("\\mathbb{R}^{" * "\$(n)" * "}")
    tpl = LAlatex.L_interp(template, Dict("n" => 3))
    @test occursin("\\mathbb{R}^{3}", string(tpl))

    @variables x y
    @test LAlatex.L_show_core(x) == "x "

    mixed = LAlatex.mixed_matrix((1//2, x), ((1 + im)//3, 2*y))
    @test size(mixed) == (2, 2)
    @test isequal(mixed[1, 2], x)
    @test isequal(mixed[2, 1], (1 + im)//3)
    mixed_literal = LAlatex.@mixed_matrix [1//2 x; (1 + im)//3 2*y]
    @test mixed_literal[1, 1] == 1//2
    @test isequal(mixed_literal[2, 2], 2*y)

    mats = [[reshape(1:4, 2, 2), :none], [nothing, reshape(5:8, 2, 2)]]
    rounded = LAlatex.round_matrices(mats; digits = 0)
    @test rounded[1][1] == [1 3; 2 4]
    @test rounded[1][2] === nothing

    np = LAlatex.print_np_array_def([1, 2, 3]; nm = "v")
    @test occursin("np.array([1, 2, 3])", np)

    joined = LAlatex.L_show((:x, :y); separator = L",\\quad")
    @test occursin("\\quad", joined)

    empty_group = LAlatex.L_show(LAlatex.set())
    @test occursin("\\left\\{", empty_group)
    @test occursin("\\right\\}", empty_group)
    @test_throws ArgumentError LAlatex.L_show_set(1)

    unfactored_group = LAlatex.L_show(LAlatex.set([1//2 1//3]; factor_out = false))
    @test occursin("\\frac{1}{2}", unfactored_group)
    @test !occursin("\\frac{1}{6} \\left", unfactored_group)

    unfactored_lc = LAlatex.L_show(LAlatex.lc([1], [[1//2, 1//3]]; factor_out = false))
    @test occursin("\\frac{1}{2}", unfactored_lc)
    @test occursin("\\frac{1}{3}", unfactored_lc)
    @test !occursin("\\frac{1}{6} \\left", unfactored_lc)

    expanded_group = LAlatex.L_show(LAlatex.set((x + y)^2; symopts = (expand = true,)))
    @test !occursin("\\left(y + x\\right)^{2}", expanded_group)
    @test occursin("x^{2}", expanded_group) || occursin("x^2", expanded_group)

    cases_latex = LAlatex.L_show(
        "T(v) = ",
        LAlatex.cases([x, 0] => L"v \in \operatorname{span}\{e_1\}", ([0, y], "otherwise")),
    )
    @test occursin("\\begin{cases}", cases_latex)
    @test occursin(
        "\\left(\\begin{array}{r}\nx \\\\\n0 \\\\\n\\end{array}\\right), & v \\in \\operatorname{span}\\{e_1\\}",
        cases_latex,
    )
    @test occursin("\\text{otherwise}", cases_latex)

    expanded_cases =
        LAlatex.L_show(LAlatex.cases((x + y)^2 => L"x > 0"); symopts = (expand = true,))
    @test !occursin("\\left(y + x\\right)^{2}", expanded_cases)
    @test occursin("x^{2}", expanded_cases) || occursin("x^2", expanded_cases)
    @test_throws ArgumentError LAlatex.L_show(LAlatex.cases(x))

    aligned_latex = LAlatex.L_show(
        LAlatex.aligned(
            [L"Ax", L"=", [x, y]],
            (L"x", L"\in", L"\mathcal{N}(A)"),
            L"\dim\mathcal{N}(A)" => L"n - \operatorname{rank}(A)",
        ),
    )
    @test occursin("\\begin{aligned}", aligned_latex)
    @test occursin(
        "Ax & = & \\left(\\begin{array}{r}\nx \\\\\ny \\\\\n\\end{array}\\right)",
        aligned_latex,
    )
    @test occursin("x & \\in & \\mathcal{N}(A)", aligned_latex)
    @test occursin("\\dim\\mathcal{N}(A) & = & n - \\operatorname{rank}(A)", aligned_latex)

    expanded_aligned =
        LAlatex.L_show(LAlatex.aligned([(x + y)^2, L"=", x]); symopts = (expand = true,))
    @test !occursin("\\left(y + x\\right)^{2}", expanded_aligned)
    @test occursin("x^{2}", expanded_aligned) || occursin("x^2", expanded_aligned)
    @test_throws ArgumentError LAlatex.L_show(LAlatex.aligned(x))
    @test_throws ArgumentError LAlatex.L_show(LAlatex.aligned([]))

    @test_throws ArgumentError LAlatex.L_show(LAlatex.lc([1], [x y]))
    @test_throws ArgumentError LAlatex.L_show(LAlatex.lc([1, 2, 3], [x y]))
    @test_throws ArgumentError LAlatex.L_show(
        LAlatex.lc([1, -2], [x y]; sign_policy = :unknown),
    )
    @test_throws ArgumentError LAlatex.L_show(
        LAlatex.lc([1, -2], [x y]; sign_policy = "signed"),
    )
    custom_plus =
        LAlatex.L_show(LAlatex.lc([1, 2], [x y]; sign_policy = :plus, plus = L" \\oplus "))
    @test occursin("\\oplus", custom_plus)

    no_omit_one = LAlatex.L_show(LAlatex.lc([1], [x]; omit_one = false))
    @test occursin("1x", replace(no_omit_one, r"\s" => ""))

    keep_zero = LAlatex.L_show(LAlatex.lc([0, 1], [x y]; drop_zero = false))
    @test occursin("0", keep_zero)

    @test_throws ArgumentError LAlatex.L_show(LAlatex.lc([1], [x]; drop_zero = 1))
    @test_throws ArgumentError LAlatex.L_show(LAlatex.lc([1], [x]; omit_one = "true"))
    @test_throws ArgumentError LAlatex.L_show(LAlatex.lc([1], [x]; parens_coeff = nothing))
    @test_throws ArgumentError LAlatex.L_show(LAlatex.lc([1], [x]; plus = 1))
    @test_throws ArgumentError LAlatex.L_show(LAlatex.lc([1], [x]; pos = :plus))
    @test_throws ArgumentError LAlatex.L_show(LAlatex.lc([-1], [x]; neg = false))
end
