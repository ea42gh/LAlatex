using Test
using LaTeXStrings

using BlockArrays
using LAlatex
using Symbolics

const TEST_SUITE = get(ENV, "LALATEX_TEST_SUITE", "all")
if !(TEST_SUITE in ("all", "core"))
    throw(ArgumentError("LALATEX_TEST_SUITE must be `all` or `core`; got `$TEST_SUITE`"))
end
const RUN_SYMPY_TESTS = TEST_SUITE == "all"

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

ok, sympy, pyexe = RUN_SYMPY_TESTS ? _sympy_available() : (false, nothing, nothing)

@testset "LAlatex" begin
    include("public_exports.jl")
    include("display_contracts.jl")
    include("display_options.jl")
    include("display_defaults.jl")
    include("backends.jl")
    include("html_helpers.jl")
    include("latex_helpers.jl")
    include("symbolic_display.jl")
    include("golden_snapshots.jl")
    include("display_invariants.jl")
    include("formatters.jl")
    include("l_show_helpers.jl")
    include("performance_guardrails.jl")
    include("quality_checks.jl")
end
