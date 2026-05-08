@testset "LaTeX helpers" begin
    LAlatex.set_backend!(:symbolics)
    @test LAlatex.to_latex("a_b") == "\\text{a\\_b}"
    @test LAlatex.to_latex("50% & # {x} \\") ==
          "\\text{50\\% \\& \\# \\{x\\} \\textbackslash{}}"
    @test LAlatex.to_latex("x~y^z") == "\\text{x\\textasciitilde{}y\\textasciicircum{}z}"
    @test LAlatex.to_latex("= 0") == "= 0"
    @test LAlatex.to_latex(LaTeXString("\\alpha + 1")) == "\\alpha + 1"
    @test LAlatex.to_latex('x') == "\\text{x}"
    @test LAlatex.to_latex(3//4) == "\\frac{3}{4}"
    @test LAlatex.to_latex(2 + 0im) == "2"
    @test LAlatex.to_latex(0 + 1im) == "\\mathit{i}"
    @test LAlatex.to_latex(0 + -1im) == "-\\mathit{i}"
    @test LAlatex.to_latex(:alpha) == "alpha"
    @test LAlatex.to_latex([1, 2, 3]) == ["1", "2", "3"]
    @test LAlatex.to_latex([1 2; 3 4]) == ["1" "2"; "3" "4"]
    @test LAlatex.to_latex([[[1 2]], [[3 4]]]) == [[["1" "2"]], [["3" "4"]]]

    LAlatex.@syms z
    latex_z = LAlatex.to_latex(z)
    @test occursin("z", latex_z)

    block_vector_latex = LAlatex.to_latex(BlockArray([1//2, 1//3, 1//4], [1, 2]))
    @test block_vector_latex == ["\\frac{1}{2}", "\\frac{1}{3}", "\\frac{1}{4}"]

    if ok
        sp = LAlatex.syms(:sp; backend = :sympy, real = true)
        latex_sp = LAlatex.to_latex(sp)
        @test occursin("sp", latex_sp)
    end

    quad_render = LAlatex.l_show(L"\\quad")
    @test quad_render isa LaTeXString
    @test getfield(quad_render, :s) == "\$" * strip(getfield(L"\\quad", :s), '$') * "\$"
    matrix_render = LAlatex.l_show([1 2; 3 4])
    @test matrix_render isa LaTeXString
    @test startswith(getfield(matrix_render, :s), "\$\\left(")
    @test endswith(getfield(matrix_render, :s), "\\right)\$")

end
