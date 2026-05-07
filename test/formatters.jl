    @testset "Formatters" begin
        LAlatex.set_backend!(:symbolics)
        @test LAlatex.bold_formatter(1, 1, 1, "x") == "\\boldsymbol{x}"
        @test LAlatex.italic_formatter(1, 1, 1, "x") == "\\mathit{x}"
        @test LAlatex.color_formatter(1, 1, 1, "x"; color="blue") == "\\textcolor{blue}{x}"
        @test LAlatex.conditional_color_formatter(2, 1, 1, "x") == "\\textcolor{green}{x}"
        @test LAlatex.conditional_color_formatter(-2, 1, 1, "x") == "\\textcolor{red}{x}"
        @test LAlatex.conditional_color_formatter(0, 1, 1, "x") == "x"
        @test LAlatex.highlight_large_values(11, 1, 1, "x"; threshold=10) == "\\boxed{x}"
        @test LAlatex.underline_formatter(1, 1, 1, "x") == "\\underline{x}"
        @test LAlatex.overline_formatter(1, 1, 1, "x") == "\\overline{x}"

        combined = LAlatex.combine_formatters([LAlatex.bold_formatter, LAlatex.color_formatter], 1, 1, 1, "x")
        @test combined == "\\textcolor{red}{\\boldsymbol{x}}"

        @test LAlatex.scientific_formatter(100.0; digits=1) == "1.0e2"
        @test LAlatex.scientific_formatter(-0.0123; digits=2) == "-1.23e-2"
        @test LAlatex.scientific_formatter(0.0; digits=1) == "0.0e0"
        @test LAlatex.percentage_formatter(0.125; digits=1) == 12.5
        @test LAlatex.exponential_formatter(10000.0; digits=1) == "1.0e4"
        @test LAlatex.exponential_formatter(0.00012; digits=2) == "1.2e-4"
        @test LAlatex.exponential_formatter(0.0; digits=1) == 0.0
        @test LAlatex.exponential_formatter(12.345; digits=2) == 12.34

        bold_number = LAlatex.L_show("42 bold -> ", 42; number_formatter=x -> "\\textbf{$x}")
        @test bold_number == "\$\\text{42 bold -> } \\textbf{42}\$\n"

        bold_float = LAlatex.L_show(4.2; number_formatter=x -> LaTeXString("\\mathbf{$x}"))
        @test bold_float == "\$\\mathbf{4.2}\$\n"

        @test LAlatex.tril_formatter(1, 2, 1, "x") == "\\textcolor{red}{x}"
        @test LAlatex.block_formatter(1, 2, 2, "x"; r1=2, r2=3, c1=2, c2=3) == "\\textcolor{red}{x}"
        @test LAlatex.block_formatter(1, 1, 1, "x"; r1=2, r2=3, c1=2, c2=3) == "x"

        blocks = [2, -1, 2]
        colors = ["red", "blue"]
        @test LAlatex.diagonal_blocks_formatter(1, 1, 1, "x"; blocks=blocks, colors=colors) == "\\textcolor{red}{x}"
        @test LAlatex.diagonal_blocks_formatter(1, 3, 3, "x"; blocks=blocks, colors=colors) == "x"
        @test LAlatex.diagonal_blocks_formatter(1, 4, 4, "x"; blocks=blocks, colors=colors) == "\\textcolor{red}{x}"

        pivots = [1, 3]
        @test LAlatex.rowechelon_formatter(1, 1, 1, "x"; pivots=pivots) == "\\textcolor{red}{x}"
        @test LAlatex.rowechelon_formatter(1, 1, 2, "x"; pivots=pivots) == "\\textcolor{red}{x}"
        @test LAlatex.rowechelon_formatter(1, 2, 2, "x"; pivots=pivots) == "x"
        @test LAlatex.rowechelon_formatter(1, 2, 3, "x"; pivots=pivots) == "\\textcolor{red}{x}"
    end
