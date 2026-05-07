_matrix_num_cols(A) = ndims(A) == 1 ? 1 : size(A, 2)
_matrix_entry(A, i, j) = ndims(A) == 1 ? A[i] : A[i, j]

function _block_dividers(A)
    axes_A = axes(A)
    row_blocks = axes_A[1]
    col_blocks = ndims(A) == 1 ? nothing : axes_A[2]

    row_dividers = hasproperty(row_blocks, :lasts) && !isempty(row_blocks.lasts) ?
                   collect(row_blocks.lasts[1:end-1]) : Int[]
    col_dividers = col_blocks !== nothing && hasproperty(col_blocks, :lasts) && !isempty(col_blocks.lasts) ?
                   collect(col_blocks.lasts[1:end-1]) : Int[]

    row_dividers = filter(d -> 1 <= d < size(A, 1), row_dividers)
    col_dividers = filter(d -> 1 <= d < _matrix_num_cols(A), col_dividers)
    return row_dividers, col_dividers
end

"""
    format_matrix_row(A, i, per_element_style, row_dividers) -> String

Format a single matrix row for LaTeX output.
"""
function format_matrix_row(A, i, per_element_style, row_dividers, number_formatter=nothing)
    row = join(
        [begin
            x = _matrix_entry(A, i, j)
            formatted_x = _to_latex_matrix_entry(x; number_formatter=number_formatter)
            per_element_style !== nothing ? per_element_style(x, i, j, formatted_x) : formatted_x
        end for j in 1:_matrix_num_cols(A)], " & "
    )

    if i in row_dividers && i < size(A, 1)
        return row * " \\\\ \\hline"
    end
    return row * " \\\\"
end

"""
    construct_latex_matrix_body(A, arraystyle, is_block_array, per_element_style,
                                factor_out, number_formatter, is_transposed, is_hermitian) -> String

Construct a LaTeX matrix body with optional block dividers and formatting.
"""
function construct_latex_matrix_body(A, arraystyle, is_block_array, per_element_style,
                                     factor_out, number_formatter,
                                     is_transposed, is_hermitian)
    arraystyle, matrix_env, left_bracket, right_bracket = parse_arraystyle(arraystyle, is_block_array)

    row_dividers, col_dividers = Int[], Int[]
    if is_block_array
        row_dividers, col_dividers = _block_dividers(A)
    end

    col_format_str = matrix_env == "array" ? construct_col_format(_matrix_num_cols(A), col_dividers) : ""

    factor, intA = process_array(A, factor_out)

    matrix_rows = [format_matrix_row(intA, i, per_element_style, row_dividers, number_formatter) for i in 1:size(A, 1)]
    matrix_body = left_bracket * "\\begin{$matrix_env}$col_format_str\n" *
                  join(matrix_rows, "\n") * "\n\\end{$matrix_env}" * right_bracket

    one_over_factor_str = factor == 1 ? "" : to_latex(1//factor)
    return isempty(one_over_factor_str) ? matrix_body : "$one_over_factor_str $matrix_body"
end

"""
    L_show_matrix(A; arraystyle=:parray, is_block_array=false, color=nothing,
                  number_formatter=nothing, per_element_style=nothing, factor_out=true) -> String

Render a matrix-like object as LaTeX.
"""
function L_show_matrix(A; arraystyle=:parray, is_block_array=false, color=nothing,
                       number_formatter=nothing, per_element_style=nothing,
                       factor_out=true, symopts=NamedTuple())
    return L_show_matrix(A, DisplayOptions(;
        arraystyle=arraystyle,
        color=color,
        number_formatter=number_formatter,
        per_element_style=per_element_style,
        factor_out=factor_out,
        symopts=symopts,
    ); is_block_array=is_block_array)
end

function L_show_matrix(A, options::DisplayOptions; is_block_array=false)
    is_transposed = A isa Transpose{<:Any, <:AbstractMatrix} ||
                    A isa Transpose{<:Any, <:BlockArray} ||
                    A isa Transpose{<:Any, <:AbstractVector}
    is_hermitian = A isa Adjoint{<:Any, <:AbstractMatrix} ||
                   A isa Adjoint{<:Any, <:BlockArray} ||
                   A isa Adjoint{<:Any, <:AbstractVector}

    if A isa Transpose{<:Any, <:AbstractVector} || A isa Adjoint{<:Any, <:AbstractVector}
        A = reshape(A, 1, :)
    end

    if A isa SparseMatrixCSC
        A = Matrix(A)
    elseif A isa Transpose{<:Any, <:BlockArray} || A isa Adjoint{<:Any, <:BlockArray}
        is_block_array = true
    elseif A isa Diagonal
        A = Matrix(A)
    end

    if any(_contains_symbolic_value, A)
        A = map(x -> symbolic_transform(x; options.symopts...), A)
    end

    latex_output = construct_latex_matrix_body(A, options.arraystyle, is_block_array, options.per_element_style,
                                               options.factor_out, options.number_formatter,
                                               is_transposed, is_hermitian)
    return style_wrapper(latex_output, options.color)
end
