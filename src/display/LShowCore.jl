"""
    L_show_core(obj; kwargs...) -> String

Render a single object into a LaTeX fragment without math delimiters.
"""
function L_show_core(obj; setstyle=:Barray, arraystyle=:parray, color=nothing, separator=", ",
                     number_formatter=nothing, per_element_style=nothing,
                     factor_out=true, symopts=NamedTuple())
    symopts = normalize_symopts(symopts)
    if obj isa Group
        return L_show_set(obj;
            setstyle=setstyle,
            arraystyle=arraystyle,
            color=color,
            separator=separator,
            number_formatter=number_formatter,
            per_element_style=per_element_style,
            factor_out=factor_out,
            symopts=symopts,
        )
    end

    if obj isa LinearCombination
        return L_show_lc(obj; setstyle=setstyle, arraystyle=arraystyle, color=color,
                         number_formatter=number_formatter, per_element_style=per_element_style,
                         factor_out=factor_out, symopts=symopts)
    end

    if obj isa Cases
        return L_show_cases(obj; arraystyle=arraystyle, color=color,
                            number_formatter=number_formatter, per_element_style=per_element_style,
                            factor_out=factor_out, symopts=symopts)
    end

    if obj isa Aligned
        return L_show_aligned(obj; arraystyle=arraystyle, color=color,
                              number_formatter=number_formatter, per_element_style=per_element_style,
                              factor_out=factor_out, symopts=symopts)
    end

    if obj isa Tuple && isempty(obj)
        _, _, left_delim, right_delim = parse_arraystyle(arraystyle)
        return style_wrapper("$(left_delim) $(right_delim)", color)
    end

    if obj isa NamedTuple
        formatting_keys = [:setstyle, :arraystyle, :color, :separator, :number_formatter, :per_element_style, :factor_out]
        formatting_options = Dict(k => v for (k, v) in pairs(obj) if k in formatting_keys)
        content_values = Tuple(v for (k, v) in pairs(obj) if !(k in formatting_keys))

        combined_options = merge(Dict(
            :setstyle => setstyle,
            :arraystyle => arraystyle, :color => color, :separator => separator,
            :number_formatter => number_formatter, :per_element_style => per_element_style,
            :factor_out => factor_out
        ), formatting_options)

        combined_options[:symopts] = symopts
        formatted_entries = [L_show_core(entry; combined_options...) for entry in content_values]
        separator_str = normalize_separator(combined_options[:separator])
        return join(formatted_entries, separator_str)
    end

    if obj isa Tuple
        formatted_entries = [L_show_core(entry;
            setstyle=setstyle,
            arraystyle=arraystyle,
            color=color,
            separator=separator,
            number_formatter=number_formatter,
            per_element_style=per_element_style,
            factor_out=factor_out,
            symopts=symopts,
        ) for entry in obj]
        separator_str = normalize_separator(separator)
        return join(formatted_entries, separator_str)
    end

    if obj isa UniformScaling{Bool}
        return L_show_string(obj.λ ? "I" : "0"; color=color)
    end

    if obj isa UniformScaling
        λ = obj.λ
        if λ == 0
            return L_show_string("0"; color=color)
        elseif λ == 1
            return L_show_string("I"; color=color)
        else
            return L_show_string("$(to_latex(λ)) I"; color=color)
        end
    end

    if obj isa AbstractString
        return L_show_string(obj; color=color)
    end

    if obj isa Char
        return L_show_string(string(obj); color=color)
    end

    if obj isa Transpose{<:Any, <:String} || obj isa Adjoint{<:Any, <:String} ||
       obj isa Transpose{<:Any, <:Char} || obj isa Adjoint{<:Any, <:Char} ||
       obj isa Transpose{<:Any, <:LaTeXString} || obj isa Adjoint{<:Any, <:LaTeXString}
        return L_show_string(parent(obj); color=color)
    end

    if obj isa AbstractVector || obj isa Transpose{<:Any, <:AbstractVector} || obj isa Adjoint{<:Any, <:AbstractVector} ||
       obj isa AbstractMatrix || obj isa Transpose{<:Any, <:AbstractMatrix} || obj isa Adjoint{<:Any, <:AbstractMatrix} ||
       obj isa BlockMatrix || obj isa Transpose{<:Any, <:BlockMatrix} || obj isa Adjoint{<:Any, <:BlockMatrix} ||
       obj isa BlockArray || obj isa Transpose{<:Any, <:BlockArray} || obj isa Adjoint{<:Any, <:BlockArray}
        is_block_array = obj isa BlockArray || obj isa Transpose{<:BlockArray} || obj isa Adjoint{<:BlockArray} ||
                         obj isa BlockMatrix || obj isa Transpose{<:BlockMatrix} || obj isa Adjoint{<:BlockMatrix}
        return L_show_matrix(obj; arraystyle=arraystyle, is_block_array=is_block_array,
                             color=color, number_formatter=number_formatter,
                             per_element_style=per_element_style, factor_out=factor_out,
                             symopts=symopts)
    end

    if obj isa Symbol || obj isa Symbolics.Num
        return style_wrapper(_to_latex_scalar(symbolic_transform(obj; symopts...)) * " ", color)
    elseif _is_sympy_py(obj)
        pc = _pythoncall_module()
        if pc !== nothing
            # Prefer rendering SymPy matrices via L_show_matrix so arraystyle applies.
            try
                tolist = Base.invokelatest(pc.pygetattr, obj, "tolist")
                shape = Base.invokelatest(pc.pygetattr, obj, "shape")
                shp = Base.invokelatest(pc.pyconvert, Tuple, shape)
                if length(shp) == 2
                    pyrows = Base.invokelatest(pc.pycall, tolist)
                    rows = Base.invokelatest(pc.pyconvert, Vector, pyrows)
                    m = length(rows)
                    n = m == 0 ? 0 : length(Base.invokelatest(pc.pyconvert, Vector, rows[1]))
                    A = Matrix{Any}(undef, m, n)
                    for i in 1:m
                        row = Base.invokelatest(pc.pyconvert, Vector, rows[i])
                        for j in 1:n
                            A[i, j] = row[j]
                        end
                    end
                    return L_show_matrix(A; arraystyle=arraystyle, color=color,
                                         number_formatter=number_formatter,
                                         per_element_style=per_element_style,
                                         factor_out=factor_out, symopts=symopts)
                end
            catch
                # Fallback to sympy.latex below.
            end
        end
        return style_wrapper(to_latex(obj), color)
    elseif obj isa Number || _is_pythoncall_py(obj)
        return L_show_number(symbolic_transform(obj; symopts...); color=color, number_formatter=number_formatter)
    end

    error("Unsupported argument type: $(typeof(obj))")
end
