@testset "Golden LaTeX snapshots" begin
    LAlatex.set_backend!(:symbolics)
    @variables x y

    @test LAlatex.L_show(3//4) == "\$\\frac{3}{4}\$\n"
    @test LAlatex.L_show(2 + 3im) == "\$2+3\\mathit{i}\$\n"

    @test LAlatex.L_show([1, 2, 3]) ==
          "\$\\left(\\begin{array}{r}\n" *
          "1 \\\\\n" *
          "2 \\\\\n" *
          "3 \\\\\n" *
          "\\end{array}\\right)\$\n"

    @test LAlatex.L_show([1 2; 3 4]) ==
          "\$\\left(\\begin{array}{rr}\n" *
          "1 & 2 \\\\\n" *
          "3 & 4 \\\\\n" *
          "\\end{array}\\right)\$\n"

    @test LAlatex.L_show(BlockArray([1 2; 3 4], [1, 1], [1, 1])) ==
          "\$\\left(\\begin{array}{r|r}\n" *
          "1 & 2 \\\\ \\hline\n" *
          "3 & 4 \\\\\n" *
          "\\end{array}\\right)\$\n"

    @test LAlatex.L_show(LAlatex.set(1, 2, 3)) ==
          "\$\\left\\{ 1 , 2 , 3 \\right\\}\$\n"

    @test LAlatex.L_show(LAlatex.lc([1, -2], [[1, 0], [0, 1]])) ==
          "\$ \\left(\\begin{array}{r}\n" *
          "1 \\\\\n" *
          "0 \\\\\n" *
          "\\end{array}\\right)  -  2\\left(\\begin{array}{r}\n" *
          "0 \\\\\n" *
          "1 \\\\\n" *
          "\\end{array}\\right) \$\n"

    @test LAlatex.L_show(
        LAlatex.cases([x, 0] => L"x > 0", [0, y] => "otherwise")
    ) ==
          "\$\\begin{cases}\n" *
          "\\left(\\begin{array}{r}\n" *
          "x \\\\\n" *
          "0 \\\\\n" *
          "\\end{array}\\right), & x > 0 \\\\\n" *
          "\\left(\\begin{array}{r}\n" *
          "0 \\\\\n" *
          "y \\\\\n" *
          "\\end{array}\\right), & \\text{otherwise} \\\\\n" *
          "\\end{cases}\$\n"

    @test LAlatex.L_show(
        LAlatex.aligned(L"Ax" => [x, y], (L"x", L"\in", L"\mathcal{N}(A)"))
    ) ==
          "\$\\begin{aligned}\n" *
          "Ax & = & \\left(\\begin{array}{r}\n" *
          "x \\\\\n" *
          "y \\\\\n" *
          "\\end{array}\\right) \\\\\n" *
          "x & \\in & \\mathcal{N}(A) \\\\\n" *
          "\\end{aligned}\$\n"
end
