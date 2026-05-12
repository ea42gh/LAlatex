using LAlatex
using LaTeXStrings
using Symbolics
using LinearAlgebra
using BlockArrays

LAlatex.set_backend!(:symbolics)
LAlatex.reset_display_defaults!()
@variables x y t

function warmup_lalatex_binder()
    A = [1 2 3; 4 5 6]
    v = [1, 2, 3]
    row = [4 5 6]
    M = mixed_matrix((1//2, x), ((1 + im)//3, 2y))
    N = @mixed_matrix [1//3 x + y; x*y 2]
    B = BlockArray([1 2 4; 3 4 5], [1, 1], [2, 1])
    R = [1//2 1//3; 2//3 3//4]
    coeffs = [1, -2, 0, 3]
    vectors = [[1, 0], [0, 1], [1, 1], [2, -1]]

    color_odd_entries(value, i, j, latex) =
        isodd(value) ? "\\textcolor{red}{$latex}" : latex

    L_show(L"A = ", A, L",\quad A^T A = ", transpose(A) * A; arraystyle = :bmatrix)
    l_show(L"A = ", A, L",\quad A^T A = ", transpose(A) * A; arraystyle = :bmatrix)
    L_show(L"A = ", A; inline = false, arraystyle = :bmatrix)
    l_show(L"v = ", v, L",\quad r = ", row; arraystyle = :bmatrix)
    l_show("Tuple with custom separator: ", (:alpha, :beta, 2//3); separator = L";\quad ")
    l_show(L"M = ", M, L",\quad N = ", N; arraystyle = :bmatrix)
    l_show(L"B = ", set(L"e_1", L"e_2", L"e_3"; separator = L",\;"))
    l_show(
        "Matrix set: ",
        set([1, 0], [0, 1]; arraystyle = :bmatrix, separator = L",\quad "),
    )
    l_show(L"S = ", set(x; such_that = (L"x > 0", L"x < 1"), separator = L",\;"))
    l_show(
        L"T = ",
        set(
            (value = x, color = :blue);
            such_that = ((value = L"x \ne 0", color = :red),),
            such_that_separator = L":",
        ),
    )
    l_show(
        L"u = ",
        lc(coeffs, vectors; sign_policy = :signed, omit_one = true, drop_zero = true);
        arraystyle = :bmatrix,
    )
    l_show("Keep zeros: ", lc(coeffs, vectors; drop_zero = false); arraystyle = :bmatrix)
    l_show(
        L"T(v) = ",
        cases([x, 0] => L"v \in \operatorname{span}\{e_1\}", ([0, y], "otherwise"));
        arraystyle = :bmatrix,
    )
    l_show(
        aligned(
            L"Ax" => L"b",
            (L"x", L"\in", L"\mathcal{N}(A)"),
            L"\dim\mathcal{N}(A)" => L"n - \operatorname{rank}(A)",
        ),
    )
    l_show(
        aligned(L"Ax" => L"b", (L"x", L"\in", L"\mathcal{N}(A)"));
        inline = false,
        tag = "1",
        label = "eq:binder-demo",
    )
    expr = x^2 + x*y + x + y
    l_show(L"expanded: ", (x + y)^2; symopts = (expand = true,))
    l_show(L"factored: ", x^2 + x*y; symopts = (factor = true,))
    l_show(L"collected: ", expr; symopts = (collect = x,))

    den, scaled = factor_out_denominator(R)
    l_show(L"R = ", R, L",\quad d = ", den, L",\quad dR = ", scaled; arraystyle = :bmatrix)
    l_show(L"unfactored: ", R; factor_out = false, arraystyle = :bmatrix)
    l_show(L"B = ", B; per_element_style = color_odd_entries)
    with_display_defaults(arraystyle = :bmatrix, separator = L";\quad ") do
        l_show(L"defaults in scope: ", [1 2; 3 4], (1, 2, 3))
    end
    l_show(L"defaults restored: ", [1 2; 3 4])
    l_show(
        L"rounded: ",
        [pi 0.125; exp(1) 2//3];
        number_formatter = value -> round_value(value, 2),
        arraystyle = :bmatrix,
    )
    l_show(L"percent: ", 0.125; number_formatter = percentage_formatter)

    return nothing
end

warmup_lalatex_binder()
println("LAlatex Binder warmup completed.")
