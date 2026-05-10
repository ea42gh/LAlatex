@testset "Symbolic display policy" begin
    LAlatex.set_backend!(:symbolics)
    @variables x y t n

    @testset "Backend parity checklist" begin
        sx, sy = x, y
        symbolics_scalar = LAlatex.to_latex(sx + sy)
        symbolics_matrix = LAlatex.L_show([sx sy; sy sx])
        @test occursin("x", symbolics_scalar)
        @test occursin("y", symbolics_scalar)
        @test LAlatex._to_latex_matrix_entry(sx) == LAlatex.to_latex(sx)
        @test occursin("x", symbolics_matrix)
        @test occursin("y", symbolics_matrix)
        @test LAlatex._symbolics_issym(Symbolics.unwrap(sx))
        @test LAlatex._symbolics_iscall(Symbolics.unwrap(sx + sy))
        @test LAlatex._symbolics_operation(Symbolics.unwrap(sx + sy)) == (+)
        @test length(LAlatex._symbolics_arguments(Symbolics.unwrap(sx + sy))) == 2
        @test LAlatex._symbolics_is_literal_number(Symbolics.unwrap(Num(3//4)))
        @test LAlatex._symbolics_unwrap_const(Symbolics.unwrap(Num(3//4))) == 3//4
        @test LAlatex._symbolics_mul_coefficient(Symbolics.unwrap(2sx)) !== nothing
        @test LAlatex._symbolics_isadd(Symbolics.unwrap(sx + sy))
        @test LAlatex._symbolics_ismul(Symbolics.unwrap(2sx))
        @test LAlatex._symbolics_expand_expr(Symbolics.unwrap((sx + sy)^2)) !==
              Symbolics.unwrap((sx + sy)^2)
        ok_rat, rat_coeff =
            LAlatex._symbolics_rat_coefficient(Symbolics.unwrap((3//4) * sx))
        @test ok_rat
        @test rat_coeff == 3//4

        symbolics_expanded = LAlatex.L_show((sx + sy)^2; symopts = (expand = true,))
        @test occursin("x", symbolics_expanded)
        @test occursin("y", symbolics_expanded)
        symbolics_factored_transform =
            LAlatex.L_show(sx^2 + sx * sy; symopts = (factor = true,))
        @test occursin("x \\left", symbolics_factored_transform) ||
              occursin("\\right) x", symbolics_factored_transform)
        @test occursin("y + x", symbolics_factored_transform) ||
              occursin("x + y", symbolics_factored_transform)

        symbolics_collected_transform =
            LAlatex.L_show(sx^2 + sx * sy + sx + 1; symopts = (collect = sx,))
        @test occursin("x \\left", symbolics_collected_transform) ||
              occursin("\\right) x", symbolics_collected_transform)
        @test occursin("1 + y", symbolics_collected_transform) ||
              occursin("y + 1", symbolics_collected_transform)
        @test occursin("x^{2}", symbolics_collected_transform) ||
              occursin("x^2", symbolics_collected_transform)

        symbolics_factor, symbolics_factored = LAlatex.factor_out_denominator([sx / 2 sx])
        @test symbolics_factor == 2
        @test isequal(symbolics_factored[1, 1], sx)
        @test isequal(symbolics_factored[1, 2], 2sx)

        symbolics_lc = LAlatex.L_show(LAlatex.lc([-(sx + sy), sx - sy], [sx sy]))
        @test occursin("-  \\left", symbolics_lc)
        @test occursin("\\left(x + y\\right)", symbolics_lc) ||
              occursin("\\left(y + x\\right)", symbolics_lc)
        @test occursin("\\left(x - y\\right)", symbolics_lc) ||
              occursin("\\left(-y + x\\right)", symbolics_lc)

        if ok
            LAlatex.set_backend!(:sympy)
            sympy = LAlatex.import_sympy()
            px, py = LAlatex.syms(:px, :py)
            sympy_scalar = LAlatex.to_latex(px + py)
            sympy_matrix = LAlatex.L_show([px py; py px])
            @test occursin("px", sympy_scalar)
            @test occursin("py", sympy_scalar)
            @test LAlatex._to_latex_matrix_entry(px) == LAlatex.to_latex(px)
            @test occursin("px", sympy_matrix)
            @test occursin("py", sympy_matrix)

            sympy_expanded = LAlatex.L_show((px + py)^2; symopts = (expand = true,))
            @test occursin("px", sympy_expanded)
            @test occursin("py", sympy_expanded)

            sympy_factor, sympy_factored = LAlatex.factor_out_denominator([px / 2 px])
            @test sympy_factor == 2
            @test LAlatex.to_latex(sympy_factored[1, 1]) == LAlatex.to_latex(px)
            @test LAlatex.to_latex(sympy_factored[1, 2]) == LAlatex.to_latex(2 * px)

            sympy_power = sympy.Rational(3, 10)^px
            sympy_power_factor, _ = LAlatex.factor_out_denominator([sympy_power px])
            @test sympy_power_factor == 1

            sympy_lc = LAlatex.L_show(LAlatex.lc([-(px + py), px - py], [px py]))
            @test occursin("-  \\left", sympy_lc)
            @test occursin("+  \\left", sympy_lc)
            LAlatex.set_backend!(:symbolics)
        end
    end

    alpha = LAlatex.syms("α_1")
    latex_alpha = LAlatex.to_latex(alpha)
    @test occursin("\\alpha", latex_alpha) || occursin("α", latex_alpha)
    @test occursin("_1", latex_alpha)

    pi_over_3 = Num(π) / 3
    latex_pi_over_3 = LAlatex.to_latex(pi_over_3)
    @test occursin("\\pi", latex_pi_over_3)
    @test occursin("3", latex_pi_over_3)
    @test !occursin("1.047", latex_pi_over_3)

    latex_cos = LAlatex.to_latex(cos(pi_over_3))
    @test occursin("\\cos\\left(", latex_cos)
    @test occursin("\\pi", latex_cos)
    @test occursin("3", latex_cos)

    latex_sin = LAlatex.to_latex(sin(pi_over_3))
    @test occursin("\\sin\\left(", latex_sin)
    @test occursin("\\pi", latex_sin)
    @test occursin("3", latex_sin)

    latex_exp = LAlatex.to_latex(exp(-3t))
    @test occursin("e^{", latex_exp)
    @test !occursin("\\begin{equation}", latex_exp)
    @variables α[1:4]
    norm2_x_s = (13189//36) - (440//9) * α[3] + (25//9) * (α[3]^2) + α[4]^2
    latex_norm2_x_s = LAlatex.L_show(L"\\Vert x_p + x_h \\Vert^2 = ", norm2_x_s)
    @test !occursin("\\begin{equation}", latex_norm2_x_s)
    @test occursin("\\alpha_{3}", latex_norm2_x_s)
    @test occursin("\\alpha_{4}", latex_norm2_x_s)
    exp_vec =
        Num[(6//1)-(5//1)*exp(-3t), (18//1)-(19//1)*exp(-3t), (18//1)-(16//1)*exp(-3t)]
    exp_vec_latex = LAlatex.L_show(exp_vec)
    @test occursin("e^{", exp_vec_latex)
    @test !occursin("\\begin{equation}", exp_vec_latex)
    @test exp_vec_latex ==
          "\$\\left(\\begin{array}{r}\n6 - 5 e^{-3 t} \\\\\n18 - 19 e^{-3 t} \\\\\n18 - 16 e^{-3 t} \\\\\n\\end{array}\\right)\$\n"

    matrix_latex = LAlatex.L_show([x y; y x])
    @test occursin("x", matrix_latex)
    @test occursin("y", matrix_latex)
    @test !occursin(" &  &", matrix_latex)
    @test LAlatex._to_latex_scalar(x) == LAlatex.to_latex(x)
    @test LAlatex._to_latex_matrix_entry(x) == LAlatex.to_latex(x)

    rational_power = LAlatex.L_show((3//10)^n)
    @test occursin("\\left(\\frac{3}{10}\\right)^{n}", rational_power)
    @test rational_power == "\$\\left(\\frac{3}{10}\\right)^{n} \$\n"

    for (f, latex_name) in (
        (log, "\\log"),
        (asin, "\\arcsin"),
        (acos, "\\arccos"),
        (atan, "\\arctan"),
        (sinh, "\\sinh"),
        (cosh, "\\cosh"),
        (tanh, "\\tanh"),
        (asinh, "\\operatorname{asinh}"),
        (acosh, "\\operatorname{acosh}"),
        (atanh, "\\operatorname{atanh}"),
    )
        rendered = LAlatex.to_latex(f(t))
        @test occursin(latex_name * "\\left(", rendered)
        @test !occursin("\\begin{equation}", rendered)
    end

    expr = (x + y)^2
    expanded = LAlatex.L_show(expr; symopts = (expand = true,))
    @test occursin("x^2", expanded) || occursin("x^{2}", expanded)

    complex_expr = (x + y)^2 + im * ((x + y)^2)
    complex_expanded = LAlatex.L_show(complex_expr; symopts = (expand = true,))
    @test !occursin("\\left(y + x\\right)^{2}", complex_expanded)
    @test occursin("x^{2}", complex_expanded) || occursin("x^2", complex_expanded)

    complex_matrix_expanded =
        LAlatex.L_show(LAlatex.mixed_matrix((complex_expr,)); symopts = (expand = true,))
    @test !occursin("\\left(y + x\\right)^{2}", complex_matrix_expanded)
    @test occursin("x^{2}", complex_matrix_expanded) ||
          occursin("x^2", complex_matrix_expanded)

    @test LAlatex.to_latex(-x) == "-x"
    @test !occursin("-1", LAlatex.to_latex(-(x + y)))
    lc_signed = LAlatex.L_show(LAlatex.lc([-(x + y), x - y, 1], [x y x + y]))
    @test occursin("-  \\left", lc_signed)
    @test occursin("\\left(x + y\\right)", lc_signed) ||
          occursin("\\left(y + x\\right)", lc_signed)
    @test occursin("\\left(x - y\\right)", lc_signed) ||
          occursin("\\left(-y + x\\right)", lc_signed)
    @test !occursin("\\left(1 ", lc_signed)
    @test !occursin(" -  \\left(1 ", lc_signed)
    @test occursin("\\left(\\begin{array}{r}\nx \\\\\n\\end{array}\\right)", lc_signed)
    @test occursin("\\left(\\begin{array}{r}\ny \\\\\n\\end{array}\\right)", lc_signed)
    @test occursin("\\left(\\begin{array}{r}\n", lc_signed)
    @test occursin("\\left(x + y\\right)", lc_signed) ||
          occursin("\\left(y + x\\right)", lc_signed)

    symA = [1//2 x; 3//4 y]
    factor, symA_out = LAlatex.factor_out_denominator(symA)
    @test factor == 4
    @test symA_out[1, 1] == 2
    @test isequal(symA_out[1, 2], 4 * x)
    @test symA_out[2, 1] == 3
    @test isequal(symA_out[2, 2], 4 * y)

    symB = LAlatex.mixed_matrix((1//2, x), ((1 + im)//3, y))
    factorB, symB_out = LAlatex.factor_out_denominator(symB)
    @test factorB == 6
    @test symB_out[1, 1] == 3
    @test isequal(symB_out[1, 2], 6 * x)
    @test symB_out[2, 1] == 2 + 2im
    @test isequal(symB_out[2, 2], 6 * y)

    symC = LAlatex.mixed_matrix((x / 2, 1//3), (x, y))
    factorC, symC_out = LAlatex.factor_out_denominator(symC)
    @test factorC == 6
    @test isequal(symC_out[1, 1], 3 * x)
    @test symC_out[1, 2] == 2

    complex_symbolic_matrix = LAlatex.mixed_matrix((x / 2 + im * (y / 3), 1//5), (x, y))
    factor_complex_symbolic, out_complex_symbolic =
        LAlatex.factor_out_denominator(complex_symbolic_matrix)
    @test factor_complex_symbolic == 30
    complex_symbolic_latex = LAlatex.L_show(out_complex_symbolic)
    @test !occursin("\\begin{equation}", complex_symbolic_latex)
    @test occursin("15 x", complex_symbolic_latex)
    @test occursin("10 y", complex_symbolic_latex)
    @test occursin("\\mathit{i}", complex_symbolic_latex)

    empty_rational_vector = Rational{Int}[]
    factor_empty_vector, out_empty_vector =
        LAlatex.factor_out_denominator(empty_rational_vector)
    @test factor_empty_vector == 1
    @test out_empty_vector === empty_rational_vector

    empty_rational_matrix = Matrix{Rational{Int}}(undef, 0, 2)
    factor_empty_matrix, out_empty_matrix =
        LAlatex.factor_out_denominator(empty_rational_matrix)
    @test factor_empty_matrix == 1
    @test out_empty_matrix === empty_rational_matrix
    @test size(out_empty_matrix) == (0, 2)

    big_rational_vector = [big(1)//big(2), big(2)//big(3)]
    factor_big_vector, out_big_vector = LAlatex.factor_out_denominator(big_rational_vector)
    @test factor_big_vector == big(6)
    @test out_big_vector == BigInt[3, 4]

    big_rational_matrix = [big(1)//big(2) big(1)//big(5); big(2)//big(3) big(3)//big(4)]
    factor_big_matrix, out_big_matrix = LAlatex.factor_out_denominator(big_rational_matrix)
    @test factor_big_matrix == big(60)
    @test out_big_matrix == BigInt[30 12; 40 45]

    big_complex_vector = Complex{Rational{BigInt}}[big(1)//big(2)+im*(big(1)//big(3))]
    factor_big_complex, out_big_complex = LAlatex.factor_out_denominator(big_complex_vector)
    @test factor_big_complex == big(6)
    @test out_big_complex == Complex{BigInt}[3+2im]

    @test sort(LAlatex._symbolics_denominators(x / 2 + 1//3)) == [2, 3]
    @test LAlatex._symbolics_denominators((x + 1) / 2) == [2]
    @test isempty(LAlatex._symbolics_denominators(x / (2y)))
    @test isempty(LAlatex._symbolics_denominators((x / 2)^n))

    p = (3//10)^n
    @test isempty(LAlatex._symbolics_denominators(p))
    power_matrix = [-6p p p; -21p 4p 3p; -21p 3p 4p]
    factorP, power_out = LAlatex.factor_out_denominator(power_matrix)
    @test factorP == 1
    @test isequal(power_out, power_matrix)
    power_latex = LAlatex.L_show("A10n=", power_matrix)
    @test !occursin("\\frac{1}{10} \\left", power_latex)
    @test occursin("\\left(\\frac{3}{10}\\right)^{n}", power_latex)
    @test power_latex ==
          "\$\\text{A10n=} \\left(\\begin{array}{rrr}\n-6 \\left(\\frac{3}{10}\\right)^{n} & \\left(\\frac{3}{10}\\right)^{n} & \\left(\\frac{3}{10}\\right)^{n} \\\\\n-21 \\left(\\frac{3}{10}\\right)^{n} & 4 \\left(\\frac{3}{10}\\right)^{n} & 3 \\left(\\frac{3}{10}\\right)^{n} \\\\\n-21 \\left(\\frac{3}{10}\\right)^{n} & 3 \\left(\\frac{3}{10}\\right)^{n} & 4 \\left(\\frac{3}{10}\\right)^{n} \\\\\n\\end{array}\\right)\$\n"

    block_matrix = BlockArray([1//2 1//3; 1//4 1//5], [1, 1], [1, 1])
    factor_block_matrix, out_block_matrix = LAlatex.factor_out_denominator(block_matrix)
    @test factor_block_matrix == 60
    @test out_block_matrix isa BlockArray
    @test axes(out_block_matrix) == axes(block_matrix)
    @test Array(out_block_matrix) == [30 20; 15 12]

    block_vector = BlockArray([1//2, 1//3, 1//4], [1, 2])
    factor_block_vector, out_block_vector = LAlatex.factor_out_denominator(block_vector)
    @test factor_block_vector == 12
    @test out_block_vector isa BlockArray
    @test axes(out_block_vector) == axes(block_vector)
    @test Array(out_block_vector) == [6, 4, 3]
    block_vector_latex = LAlatex.L_show(block_vector)
    @test block_vector_latex ==
          "\$\\frac{1}{12} \\left(\\begin{array}{r}\n6 \\\\ \\hline\n4 \\\\\n3 \\\\\n\\end{array}\\right)\$\n"

    formatted_factored = LAlatex.L_show(
        [1//2 1//3];
        number_formatter = x -> x isa Real ? round(Float64(x); digits = 1) : x,
    )
    @test occursin("\\frac{1}{6} \\left", formatted_factored)
    @test occursin("3.0 & 2.0", formatted_factored)

    disabled_pythoncall_cmd = setenv(
        `$(Base.julia_cmd()) --project=$(dirname(Base.active_project())) -e "using LAlatex; print(LAlatex._ensure_pythoncall() === nothing)"`,
        "LALATEX_DISABLE_PYTHONCALL" => "1",
    )
    @test readchomp(disabled_pythoncall_cmd) == "true"

    if ok
        pc = getfield(LAlatex, :PythonCall)
        LAlatex.set_backend!(:sympy)
        a_py, b_py = LAlatex.syms(:a, :b)
        latex_py = LAlatex.L_show(a_py, " + ", b_py)
        @test occursin("a", latex_py)
        @test occursin("b", latex_py)

        expr_py = (a_py + b_py)^2
        expanded_py = LAlatex.L_show(expr_py; symopts = (expand = true,))
        @test occursin("a", expanded_py)
        @test occursin("b", expanded_py)

        lc_py = LAlatex.L_show(
            LAlatex.lc([-(a_py + b_py), a_py - b_py, -a_py], [a_py b_py a_py]),
        )
        @test occursin("-  \\left", lc_py)
        @test occursin("+  \\left", lc_py)
        @test occursin("-  a", lc_py)

        sympy = LAlatex.import_sympy()
        @test strip(LAlatex.L_show(sympy.I)) == "\$i\$"
        @test LAlatex._to_latex_scalar(sympy.I) == LAlatex.to_latex(sympy.I)
        @test LAlatex._to_latex_matrix_entry(2 * a_py) == LAlatex.to_latex(2 * a_py)
        @test LAlatex._sympy_matrix_to_julia_matrix(a_py) === nothing

        builtins = pc.pyimport("builtins")
        non_sympy_py = builtins.object()
        @test LAlatex._is_pythoncall_py(non_sympy_py)
        @test !LAlatex._is_sympy_py(non_sympy_py)
        @test_throws ArgumentError LAlatex.L_show(non_sympy_py)
        @test_throws ArgumentError LAlatex.to_latex(non_sympy_py)
        denoms_non_sympy = Int[]
        LAlatex._push_sympy_denominator!(denoms_non_sympy, non_sympy_py)
        @test isempty(denoms_non_sympy)

        non_sympy_mixed = Any[non_sympy_py 1//2]
        factor_non_sympy, factored_non_sympy =
            LAlatex.factor_out_denominator(non_sympy_mixed)
        @test factor_non_sympy == 1
        @test factored_non_sympy === non_sympy_mixed

        python_coeffs = pc.pylist([1, -2])
        python_vectors = pc.pylist([[1, 0], [0, 1]])
        python_lc = LAlatex.L_show(LAlatex.lc(python_coeffs, python_vectors))
        @test occursin("\\left(\\begin{array}{r}\n1", python_lc)
        @test occursin("-  2", python_lc)

        unsupported_python_lc = LAlatex.lc(non_sympy_py, python_vectors)
        @test_throws ArgumentError LAlatex.L_show(unsupported_python_lc)

        direct_sympy_matrix = sympy.Matrix(2, 2, pc.pylist([a_py, b_py, b_py, a_py]))
        converted_sympy_matrix = LAlatex._sympy_matrix_to_julia_matrix(direct_sympy_matrix)
        @test converted_sympy_matrix isa Matrix{Any}
        @test size(converted_sympy_matrix) == (2, 2)

        direct_sympy_bmatrix = LAlatex.L_show(direct_sympy_matrix; arraystyle = :bmatrix)
        @test occursin("\\begin{bmatrix}", direct_sympy_bmatrix)
        @test occursin("a", direct_sympy_bmatrix)
        @test occursin("b", direct_sympy_bmatrix)

        non_square_sympy_matrix =
            sympy.Matrix(2, 3, pc.pylist([a_py, b_py, 1, 2, a_py + b_py, 3]))
        converted_non_square =
            LAlatex._sympy_matrix_to_julia_matrix(non_square_sympy_matrix)
        @test converted_non_square isa Matrix{Any}
        @test size(converted_non_square) == (2, 3)

        non_square_latex = LAlatex.L_show(non_square_sympy_matrix; arraystyle = :bmatrix)
        @test occursin("\\begin{bmatrix}", non_square_latex)
        @test occursin("a + b", non_square_latex) || occursin("b + a", non_square_latex)

        empty_sympy_matrix = sympy.zeros(0, 0)
        converted_empty = LAlatex._sympy_matrix_to_julia_matrix(empty_sympy_matrix)
        @test converted_empty isa Matrix{Any}
        @test size(converted_empty) == (0, 0)
        @test occursin(
            "\\begin{bmatrix}",
            LAlatex.L_show(empty_sympy_matrix; arraystyle = :bmatrix),
        )

        denoms_py = Int[]
        LAlatex._push_sympy_denominator!(denoms_py, sympy.Rational(1, 3))
        @test denoms_py == [3]

        factor_a_half, out_a_half = LAlatex.factor_out_denominator([a_py / 2 a_py])
        @test factor_a_half == 2
        @test LAlatex.to_latex(out_a_half[1, 1]) == LAlatex.to_latex(a_py)
        @test LAlatex.to_latex(out_a_half[1, 2]) == LAlatex.to_latex(2 * a_py)

        factor_sum_half, out_sum_half =
            LAlatex.factor_out_denominator([(a_py + 1) / 2 a_py])
        @test factor_sum_half == 2
        @test LAlatex.to_latex(out_sum_half[1, 1]) == LAlatex.to_latex(a_py + 1)
        @test LAlatex.to_latex(out_sum_half[1, 2]) == LAlatex.to_latex(2 * a_py)

        p_py = sympy.Rational(3, 10)^a_py
        factor_power_py, out_power_py = LAlatex.factor_out_denominator([p_py a_py])
        @test factor_power_py == 1
        @test LAlatex.to_latex(out_power_py[1, 1]) == LAlatex.to_latex(p_py)
        @test LAlatex.to_latex(out_power_py[1, 2]) == LAlatex.to_latex(a_py)

        large_den_py = big(typemax(Int)) + 2
        large_expr_py = sympy.Rational(1, string(large_den_py)) * a_py
        factor_large_py, out_large_py = LAlatex.factor_out_denominator([large_expr_py a_py])
        @test factor_large_py == large_den_py
        @test LAlatex.to_latex(out_large_py[1, 1]) == LAlatex.to_latex(a_py)

        f_py =
            LAlatex.mixed_matrix((sympy.Rational(1, 2), a_py), (sympy.Rational(1, 3), b_py))
        factor_py, out_py = LAlatex.factor_out_denominator(f_py)
        @test factor_py == 6
        @test pc.pyconvert(Int, out_py[1, 1]) == 3
        @test pc.pyconvert(Int, out_py[2, 1]) == 2
        @test LAlatex.to_latex(out_py[1, 2]) == LAlatex.to_latex(6 * a_py)
        @test LAlatex.to_latex(out_py[2, 2]) == LAlatex.to_latex(6 * b_py)
    end
end
