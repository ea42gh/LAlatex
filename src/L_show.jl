using BlockArrays: BlockArray, BlockMatrix
using LaTeXStrings: LaTeXString, latexstring
using LinearAlgebra: Adjoint, Diagonal, Transpose
using SparseArrays: SparseMatrixCSC
raw"""
    L_interp(template::LaTeXString, substitutions::Dict) -> LaTeXString

Interpolate values into a LaTeXString template using `$(key)` placeholders.
"""
function L_interp(template::LaTeXString, substitutions::Dict)
    str = String(template)
    for (key, value) in substitutions
        str = replace(str, "\$($key)" => string(value))
    end
    return LaTeXString(str)
end

"""
    apply_function(f, matrices) -> Vector

Apply a function elementwise to a list of lists of matrices, skipping `:none`/`nothing`.
"""
function apply_function(f, matrices)
    return [[is_none_val(mat) ? nothing : f.(mat) for mat in row] for row in matrices]
end

"""
    round_value(x, digits::Int=0)

Round a numeric value, returning `Int` when `digits == 0`.
"""
function round_value(x, digits::Int = 0)
    v = round(x, digits = digits)
    return digits == 0 ? Int(v) : v
end

"""
    round_value(x::Complex, digits::Int=0) -> Complex

Round complex values elementwise.
"""
function round_value(x::Complex, digits::Int = 0)
    return Complex(round_value(real(x), digits), round_value(imag(x), digits))
end

"""
    round_matrices(matrices; digits=0) -> Vector

Round each numeric entry in a list of lists of matrices.
"""
function round_matrices(matrices; digits = 0)
    return apply_function(x -> round_value(x, digits), matrices)
end

"""
    round_matrices(matrices, digits::Int) -> Vector

Positional `digits` overload for rounding nested matrix collections.
"""
function round_matrices(matrices, digits::Int)
    return round_matrices(matrices; digits = digits)
end

"""
    print_np_array_def(A; nm="A") -> String

Return a NumPy array definition string for display or copy/paste.

`nm` must be a Python identifier.
"""
function print_np_array_def(A; nm = "A")
    if nm isa Symbol
        name = String(nm)
    elseif nm isa AbstractString
        name = String(nm)
    else
        throw(
            ArgumentError(
                "nm must be a String or Symbol Python identifier; got $(repr(nm)).",
            ),
        )
    end
    if !occursin(r"^[A-Za-z_][A-Za-z0-9_]*$", name)
        throw(ArgumentError("nm must be a Python identifier; got $(repr(nm))."))
    end

    function format_element(x)
        if x isa Rational
            return string(numerator(x)) * "//" * string(denominator(x))
        elseif x isa Complex
            real_part = real(x)
            imag_part = imag(x)
            if imag_part < 0
                return string(format_element(real_part)) *
                       " - " *
                       string(abs(imag_part)) *
                       "j"
            else
                return string(format_element(real_part)) * " + " * string(imag_part) * "j"
            end
        elseif x isa Real
            return string(x)
        elseif x isa Integer
            return string(x)
        else
            throw(
                ArgumentError("Unsupported type for printing as NumPy array: $(typeof(x))"),
            )
        end
    end
    if ndims(A) == 1
        return name * " = np.array([" * join(format_element.(A), ", ") * "])"
    else
        M, N = size(A)
        rows = ["[" * join(format_element.(A[i, :]), ", ") * "]" for i = 1:M]
        return name * " = np.array([\n" * join(rows, ",\n") * "\n])"
    end
end
"""
    style_wrapper(content; color_opt=nothing) -> String

Optionally wrap LaTeX content in a `\\textcolor{}` block.
"""
function style_wrapper(content::Any, color_opt = nothing)
    str_content = string(content)
    str_content = strip(str_content, ['$', '\n'])
    if color_opt !== nothing
        color = validate_latex_color_value(color_opt)
        return "\\textcolor{$color}{$str_content}"
    end
    return str_content
end

"""
    validate_latex_color_value(color) -> String

Validate a LaTeX color name/expression used inside `\\textcolor{...}{...}`.
"""
function validate_latex_color_value(color)
    if color isa Symbol
        color = String(color)
    elseif color isa AbstractString
        color = String(color)
    else
        throw(
            ArgumentError(
                "color must be a String, Symbol, or nothing; got $(repr(color)) of type $(typeof(color)).",
            ),
        )
    end

    if isempty(strip(color))
        throw(ArgumentError("color must not be empty."))
    end
    if occursin(r"[{}\\\n\r\t%$&#^~]", color)
        throw(
            ArgumentError(
                "color must be a LaTeX color name or xcolor expression without braces, backslashes, control characters, or LaTeX special characters.",
            ),
        )
    end
    return color
end

"""
    parse_arraystyle(arraystyle, is_block_array=false) -> (arraystyle, env, left, right)

Normalize an arraystyle and return the LaTeX environment and brackets.
"""
const VALID_ARRAYSTYLES = (
    :bmatrix,
    :Bmatrix,
    :pmatrix,
    :vmatrix,
    :Vmatrix,
    :array,
    :barray,
    :Barray,
    :parray,
    :varray,
    :Varray,
)

function validate_arraystyle_value(arraystyle, option_name = "arraystyle/setstyle")
    if !(arraystyle isa Symbol) || !(arraystyle in VALID_ARRAYSTYLES)
        throw(
            ArgumentError(
                "Unsupported $(option_name): $(repr(arraystyle)). Expected one of $(join(VALID_ARRAYSTYLES, ", ")).",
            ),
        )
    end
    return arraystyle
end

function parse_arraystyle(arraystyle, is_block_array = false)
    arraystyle = validate_arraystyle_value(arraystyle)

    if is_block_array
        arraystyle_map = Dict(
            :bmatrix => :barray,
            :Bmatrix => :Barray,
            :pmatrix => :parray,
            :vmatrix => :varray,
            :Vmatrix => :Varray,
            :array => :array,
        )
        arraystyle = get(arraystyle_map, arraystyle, arraystyle)
    end

    env_map = Dict(
        :bmatrix => "bmatrix",
        :Bmatrix => "Bmatrix",
        :pmatrix => "pmatrix",
        :vmatrix => "vmatrix",
        :Vmatrix => "Vmatrix",
        :array => "array",
        :barray => "array",
        :Barray => "array",
        :parray => "array",
        :varray => "array",
        :Varray => "array",
    )
    matrix_env = get(env_map, arraystyle, "array")

    bracket_format = Dict(
        :barray => ("\\left[", "\\right]"),
        :Barray => ("\\left\\{", "\\right\\}"),
        :parray => ("\\left(", "\\right)"),
        :varray => ("\\left|", "\\right|"),
        :Varray => ("\\left\\|", "\\right\\|"),
        :array => ("", ""),
    )
    left_bracket, right_bracket = get(bracket_format, arraystyle, ("", ""))
    return arraystyle, matrix_env, left_bracket, right_bracket
end

"""
    construct_col_format(num_cols, col_dividers; alignment="r") -> String

Construct a LaTeX column alignment string with optional dividers.
"""
function construct_col_format(num_cols, col_dividers, alignment = "r")
    clean_dividers = filter(d -> d < num_cols, col_dividers)
    col_format =
        join(["$alignment" * (j in clean_dividers ? "|" : "") for j = 1:num_cols], "")
    return "{$col_format}"
end

"""
    process_array(A; factor_out=true) -> (factor, A_factored)

Apply denominator factorization for rational arrays when requested.
"""
function process_array(A, factor_out = true)
    if !factor_out
        return 1, A
    end
    return factor_out_denominator(A)
end

"""
    L_show_number(x; color=nothing, number_formatter=nothing) -> String

Render a number as LaTeX, with optional formatting and color.
"""
function L_show_number(x; color = nothing, number_formatter = nothing)
    formatted = _to_latex_scalar(x; number_formatter = number_formatter)
    return style_wrapper(formatted, color)
end

"""
    L_show_string(s; color=nothing) -> String

Render a string or LaTeXString with optional color.
"""
function L_show_string(s; color = nothing)
    formatted = to_latex(s)
    return style_wrapper(formatted, color)
end

include("display/DisplayOptions.jl")
include("display/MatrixDisplay.jl")
include("display/Containers.jl")
include("display/LinearCombinationDisplay.jl")
include("display/LShowCore.jl")
include("display/LShowPublic.jl")
