using Test
using LaTeXStrings

using BlockArrays
using LAlatex
using Symbolics

"""
Return (ok, sympy, exe) where `ok` is true if SymPy is importable via PythonCall.
`exe` is the Python executable reported by PythonCall when available.
"""
function _sympy_available()
    try
        exe = try
            LAlatex._python_exe_hint()
        catch
            nothing
        end
        sympy = LAlatex.import_sympy()
        return true, sympy, exe
    catch
        return false, nothing, nothing
    end
end

ok, sympy, pyexe = _sympy_available()

@testset "LAlatex" begin
    include("public_exports.jl")
    include("display_contracts.jl")
    include("backends.jl")
    include("html_helpers.jl")
    include("latex_helpers.jl")
    include("symbolic_display.jl")
    include("formatters.jl")
    include("l_show_helpers.jl")
end
