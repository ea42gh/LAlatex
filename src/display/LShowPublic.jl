function _validate_inline_value(inline)
    inline isa Bool && return inline
    throw(
        ArgumentError(
            "inline must be a Bool; got $(repr(inline)) of type $(typeof(inline)).",
        ),
    )
end

function _validate_equation_tag(tag)
    tag === nothing && return nothing
    tag isa Integer && return string(tag)
    if tag isa LaTeXString
        tag_value = to_latex(tag)
    elseif tag isa Symbol
        tag_value = sanitize_text(String(tag))
    elseif tag isa AbstractString
        tag_value = sanitize_text(tag)
    else
        throw(
            ArgumentError(
                "tag must be nothing, an integer, a string, a symbol, or a LaTeXString; got $(repr(tag)) of type $(typeof(tag)).",
            ),
        )
    end
    isempty(strip(tag_value)) && throw(ArgumentError("tag must not be empty."))
    return tag_value
end

function _validate_equation_label(label)
    label === nothing && return nothing
    if label isa Symbol || label isa AbstractString
        label_value = String(label)
    else
        throw(
            ArgumentError(
                "label must be nothing, a string, or a symbol; got $(repr(label)) of type $(typeof(label)).",
            ),
        )
    end
    isempty(label_value) && throw(ArgumentError("label must not be empty."))
    if !occursin(r"^[A-Za-z0-9:_./-]+$", label_value)
        throw(
            ArgumentError(
                "label may contain only letters, digits, ':', '_', '.', '/', and '-'.",
            ),
        )
    end
    return label_value
end

function _equation_annotation_suffix(tag, label)
    pieces = String[]
    tag === nothing || push!(pieces, "\\tag{$tag}")
    label === nothing || push!(pieces, "\\label{$label}")
    return isempty(pieces) ? "" : " " * join(pieces, " ")
end

function _validate_equation_annotation_context(inline, tag, label)
    if inline && (tag !== nothing || label !== nothing)
        throw(ArgumentError("equation tag and label options require inline=false."))
    end
    return nothing
end

function L_show(
    objs...;
    setstyle = DISPLAY_OPTION_UNSET,
    arraystyle = DISPLAY_OPTION_UNSET,
    separator = DISPLAY_OPTION_UNSET,
    color = DISPLAY_OPTION_UNSET,
    number_formatter = DISPLAY_OPTION_UNSET,
    per_element_style = DISPLAY_OPTION_UNSET,
    factor_out = DISPLAY_OPTION_UNSET,
    inline = true,
    tag = nothing,
    label = nothing,
    symopts = DISPLAY_OPTION_UNSET,
)
    inline = _validate_inline_value(inline)
    tag = _validate_equation_tag(tag)
    label = _validate_equation_label(label)
    _validate_equation_annotation_context(inline, tag, label)
    options = DisplayOptions(;
        setstyle = setstyle,
        arraystyle = arraystyle,
        color = color,
        separator = separator,
        number_formatter = number_formatter,
        per_element_style = per_element_style,
        factor_out = factor_out,
        symopts = symopts,
    )
    formatted_objs = [L_show_core(obj, options) for obj in objs]

    styled_content = join(formatted_objs, " ") * _equation_annotation_suffix(tag, label)
    return inline ? "\$" * styled_content * "\$\n" : "\$\$\n" * styled_content * "\n\$\$\n"
end

"""
    L_show(objs::SubString{String}; kwargs...) -> String

Allow SubString inputs in L_show.
"""
L_show(objs::SubString{String}; kwargs...) = L_show(String(objs); kwargs...)

"""
    L_show_core(obj::SubString{String}; kwargs...) -> String

Allow SubString inputs in L_show_core.
"""
L_show_core(obj::SubString{String}; kwargs...) = L_show_core(String(obj); kwargs...)

function l_show(args...; kwargs...)
    rendered = L_show(args...; kwargs...)
    if startswith(strip(rendered), "\$\$")
        return LaTeXString(strip(rendered))
    end
    return latexstring(strip_math_delims(rendered))
end

@doc raw"""
    L_show(objs...; inline=true, tag=nothing, label=nothing, kwargs...) -> String

Render objects into a complete LaTeX math string.

With the default `inline=true`, the result is wrapped in `$...$` and ends with
a newline. With `inline=false`, the result is wrapped in Jupyter-Markdown-
compatible `$$...$$` display-math delimiters.

Equation annotations are available for display-math output:

```julia
L_show(expr; inline=false, tag="2.1", label="eq:main")
```

`tag` and `label` require `inline=false`. Plain string and symbol tags are
escaped as text; pass a `LaTeXString` tag for raw LaTeX inside `\tag{...}`.
Labels must be nonempty label keys containing letters, digits, `:`, `_`, `.`,
`/`, or `-`.
""" L_show

@doc raw"""
    l_show(args...; inline=true, tag=nothing, label=nothing, kwargs...) -> LaTeXString

Return a LaTeXString for display in notebook environments.

`l_show` calls `L_show`. With `inline=true`, it strips the outer inline math
delimiters before constructing the display value. With `inline=false`, it
preserves the `$$...$$` display block. Equation `tag` and `label` options are
accepted when `inline=false`.
""" l_show
