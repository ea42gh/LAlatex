@testset "Display defaults" begin
    LAlatex.set_backend!(:symbolics)
    @variables x y

    LAlatex.reset_display_defaults!()
    try
        @test LAlatex.display_defaults() == NamedTuple()

        global_defaults = LAlatex.set_display_defaults!(
            arraystyle = :bmatrix,
            separator = L";",
            symopts = (expand = true,),
        )
        @test global_defaults.arraystyle == :bmatrix
        @test global_defaults.separator == L";"
        @test global_defaults.symopts == (expand = true,)

        global_matrix = LAlatex.L_show([1 2; 3 4])
        @test occursin("\\begin{bmatrix}", global_matrix)

        explicit_matrix = LAlatex.L_show([1 2; 3 4]; arraystyle = :pmatrix)
        @test occursin("\\begin{pmatrix}", explicit_matrix)
        @test !occursin("\\begin{bmatrix}", explicit_matrix)

        global_separator = LAlatex.L_show((1, 2, 3))
        @test occursin("1;2;3", global_separator)

        expanded = LAlatex.L_show((x + y)^2)
        @test occursin("x^{2}", expanded) || occursin("x^2", expanded)

        lshow_payload = sprint(show, MIME("text/latex"), LAlatex.l_show([1 2; 3 4]))
        @test occursin("\\begin{bmatrix}", lshow_payload)

        scoped_result = LAlatex.with_display_defaults(arraystyle = :vmatrix) do
            LAlatex.L_show([1 2; 3 4])
        end
        @test occursin("\\begin{vmatrix}", scoped_result)

        after_scope = LAlatex.L_show([1 2; 3 4])
        @test occursin("\\begin{bmatrix}", after_scope)

        local_container = LAlatex.with_display_defaults(arraystyle = :vmatrix) do
            LAlatex.L_show(LAlatex.set([1 2; 3 4]; arraystyle = :pmatrix))
        end
        @test occursin("\\begin{pmatrix}", local_container)
        @test !occursin("\\begin{vmatrix}", local_container)

        explicit_no_color = LAlatex.with_display_defaults(color = "red") do
            LAlatex.L_show((value = 42, color = nothing))
        end
        @test explicit_no_color == "\$42\$\n"

        @test_throws ArgumentError LAlatex.set_display_defaults!(not_an_option = true)
        @test_throws ArgumentError LAlatex.set_display_defaults!(factor_out = "false")
        @test_throws ArgumentError LAlatex.with_display_defaults(
            () -> LAlatex.L_show([1//2 1//3]);
            factor_out = 1,
        )
        @test_throws ArgumentError LAlatex.L_show([1 2; 3 4]; arraystyle = :not_a_style)
    finally
        LAlatex.reset_display_defaults!()
    end

    @test occursin("\\begin{array}", LAlatex.L_show([1 2; 3 4]))
end
