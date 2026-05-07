    @testset "Symbolics default" begin
        LAlatex.set_backend!(:symbolics)
        @test LAlatex.get_backend() isa LAlatex.Backend.SymbolicsBackend
        @test LAlatex.Backend.backend_usable(LAlatex.Backend.SymbolicsBackend)

        x = LAlatex.syms(:x)
        @test x isa Symbolics.Num
        @test string(x) == "x"

        y = LAlatex.syms("y")
        @test y isa Symbolics.Num
        @test string(y) == "y"

        a, b = LAlatex.syms(:a, :b)
        @test a isa Symbolics.Num
        @test b isa Symbolics.Num

        LAlatex.@syms u v
        @test u isa Symbolics.Num
        @test v isa Symbolics.Num

        xr = LAlatex.syms(:xr; real=true, positive=true)
        @test LAlatex.assumptions(xr)[:real] == true
        @test LAlatex.assumptions(xr)[:positive] == true

        LAlatex.@syms q :real => true
        @test LAlatex.assumptions(q)[:real] == true
    end

    if ok
        @testset "SymPy integration" begin
            LAlatex.set_backend!(:sympy)
            @test LAlatex.Backend.backend_usable(LAlatex.Backend.SymPyBackend)
            xs = LAlatex.syms_sympy(:x)
            ys = LAlatex.syms_sympy(:y; real=true, positive=true)
            @test string(xs) == "x"
            @test string(ys) == "y"
            m, n = LAlatex.syms_sympy(:m, :n)
            @test string(m) == "m"
            @test string(n) == "n"
            @test string(LAlatex.syms(:u)) == "u"

            LAlatex.@syms_sympy p :real => true :positive => true
            @test string(p) == "p"
            @test Bool(sympy.ask(sympy.Q.real(p)))
            @test Bool(sympy.ask(sympy.Q.positive(p)))

            LAlatex.set_backend!(LAlatex.Backend.SymPyBackend())
            LAlatex.@syms s :real => true
            @test string(s) == "s"
            @test Bool(sympy.ask(sympy.Q.real(s)))

            LAlatex.set_backend!(:symbolics)
            LAlatex.@syms t
            @test t isa Symbolics.Num
        end
    else
        @info "SymPy not available in the current PythonCall environment; skipping SymPy integration tests."
    end
