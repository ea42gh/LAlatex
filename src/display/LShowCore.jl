"""
    L_show_core(obj; kwargs...) -> String

Render a single object into a LaTeX fragment without math delimiters.
"""
function _sympy_shape_tuple(obj)
    pc = _pythoncall_module()
    pc === nothing && return nothing
    try
        shape = Base.invokelatest(pc.pygetattr, obj, "shape")
        return Base.invokelatest(pc.pyconvert, Tuple, shape)
    catch
        return nothing
    end
end

function _sympy_rows(obj)
    pc = _pythoncall_module()
    pc === nothing && return nothing
    try
        tolist = Base.invokelatest(pc.pygetattr, obj, "tolist")
        pyrows = Base.invokelatest(pc.pycall, tolist)
        return Base.invokelatest(pc.pyconvert, Vector, pyrows)
    catch
        return nothing
    end
end

function _sympy_matrix_to_julia_matrix(obj)
    pc = _pythoncall_module()
    pc === nothing && return nothing

    shp = _sympy_shape_tuple(obj)
    shp === nothing && return nothing
    length(shp) == 2 || return nothing

    rows = _sympy_rows(obj)
    rows === nothing && return nothing

    m = length(rows)
    n = 0
    if m > 0
        first_row = try
            Base.invokelatest(pc.pyconvert, Vector, rows[1])
        catch
            return nothing
        end
        n = length(first_row)
    end

    A = Matrix{Any}(undef, m, n)
    for i = 1:m
        row = try
            Base.invokelatest(pc.pyconvert, Vector, rows[i])
        catch
            return nothing
        end
        length(row) == n || return nothing
        for j = 1:n
            A[i, j] = row[j]
        end
    end
    return A
end

function L_show_core(
    obj;
    setstyle = DISPLAY_OPTION_UNSET,
    arraystyle = DISPLAY_OPTION_UNSET,
    color = DISPLAY_OPTION_UNSET,
    separator = DISPLAY_OPTION_UNSET,
    number_formatter = DISPLAY_OPTION_UNSET,
    per_element_style = DISPLAY_OPTION_UNSET,
    factor_out = DISPLAY_OPTION_UNSET,
    symopts = DISPLAY_OPTION_UNSET,
)
    return L_show_core(
        obj,
        DisplayOptions(;
            setstyle = setstyle,
            arraystyle = arraystyle,
            color = color,
            separator = separator,
            number_formatter = number_formatter,
            per_element_style = per_element_style,
            factor_out = factor_out,
            symopts = symopts,
        ),
    )
end

function L_show_core(obj, options::DisplayOptions)
    if obj isa Group
        return L_show_set(
            obj;
            setstyle = options.setstyle,
            arraystyle = options.arraystyle,
            color = options.color,
            separator = options.separator,
            number_formatter = options.number_formatter,
            per_element_style = options.per_element_style,
            factor_out = options.factor_out,
            symopts = options.symopts,
        )
    end

    if obj isa LinearCombination
        return L_show_lc(obj, options)
    end

    if obj isa Cases
        return L_show_cases(obj, options)
    end

    if obj isa Aligned
        return L_show_aligned(obj, options)
    end

    if obj isa Tuple && isempty(obj)
        _, _, left_delim, right_delim = parse_arraystyle(options.arraystyle)
        return style_wrapper("$(left_delim) $(right_delim)", options.color)
    end

    if obj isa NamedTuple
        formatting_keys = [
            :setstyle,
            :arraystyle,
            :color,
            :separator,
            :number_formatter,
            :per_element_style,
            :factor_out,
            :symopts,
        ]
        formatting_options =
            (; (k => v for (k, v) in pairs(obj) if k in formatting_keys)...)
        content_values = Tuple(v for (k, v) in pairs(obj) if !(k in formatting_keys))

        combined_options = merge_display_options(options, formatting_options)
        formatted_entries =
            [L_show_core(entry, combined_options) for entry in content_values]
        separator_str = normalize_separator(combined_options.separator)
        return join(formatted_entries, separator_str)
    end

    if obj isa Tuple
        formatted_entries = [L_show_core(entry, options) for entry in obj]
        separator_str = normalize_separator(options.separator)
        return join(formatted_entries, separator_str)
    end

    if obj isa UniformScaling{Bool}
        return style_wrapper(obj.λ ? "I" : "0", options.color)
    end

    if obj isa UniformScaling
        λ = obj.λ
        if λ == 0
            return style_wrapper("0", options.color)
        elseif λ == 1
            return style_wrapper("I", options.color)
        else
            return style_wrapper("$(to_latex(λ)) I", options.color)
        end
    end

    if obj isa AbstractString
        return L_show_string(obj; color = options.color)
    end

    if obj isa Char
        return L_show_string(string(obj); color = options.color)
    end

    if obj isa Transpose{<:Any,<:String} ||
       obj isa Adjoint{<:Any,<:String} ||
       obj isa Transpose{<:Any,<:Char} ||
       obj isa Adjoint{<:Any,<:Char} ||
       obj isa Transpose{<:Any,<:LaTeXString} ||
       obj isa Adjoint{<:Any,<:LaTeXString}
        return L_show_string(parent(obj); color = options.color)
    end

    if obj isa AbstractVector ||
       obj isa Transpose{<:Any,<:AbstractVector} ||
       obj isa Adjoint{<:Any,<:AbstractVector} ||
       obj isa AbstractMatrix ||
       obj isa Transpose{<:Any,<:AbstractMatrix} ||
       obj isa Adjoint{<:Any,<:AbstractMatrix} ||
       obj isa BlockMatrix ||
       obj isa Transpose{<:Any,<:BlockMatrix} ||
       obj isa Adjoint{<:Any,<:BlockMatrix} ||
       obj isa BlockArray ||
       obj isa Transpose{<:Any,<:BlockArray} ||
       obj isa Adjoint{<:Any,<:BlockArray}
        is_block_array =
            obj isa BlockArray ||
            obj isa Transpose{<:BlockArray} ||
            obj isa Adjoint{<:BlockArray} ||
            obj isa BlockMatrix ||
            obj isa Transpose{<:BlockMatrix} ||
            obj isa Adjoint{<:BlockMatrix}
        return L_show_matrix(obj, options; is_block_array = is_block_array)
    end

    if obj isa Symbol || obj isa Symbolics.Num
        return style_wrapper(
            _to_latex_scalar(symbolic_transform(obj; options.symopts...)) * " ",
            options.color,
        )
    elseif _is_sympy_py(obj)
        A = _sympy_matrix_to_julia_matrix(obj)
        A !== nothing && return L_show_matrix(A, options)
        return style_wrapper(to_latex(obj), options.color)
    elseif obj isa Number
        return L_show_number(
            symbolic_transform(obj; options.symopts...);
            color = options.color,
            number_formatter = options.number_formatter,
        )
    elseif _is_pythoncall_py(obj)
        throw(ArgumentError("Unsupported Python object type for L_show: $(typeof(obj))"))
    end

    throw(ArgumentError("Unsupported argument type for L_show: $(typeof(obj))"))
end
