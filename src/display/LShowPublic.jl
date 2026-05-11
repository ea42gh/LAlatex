"""
    L_show(objs...; inline=true, tag=nothing, label=nothing, kwargs...) -> String

Render objects into a LaTeX string with optional inline delimiters.
"""
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

"""
    l_show(args...; kwargs...) -> LaTeXString

Return a LaTeXString for display in notebook environments.
"""
function l_show(args...; kwargs...)
    rendered = L_show(args...; kwargs...)
    if startswith(strip(rendered), "\$\$")
        return LaTeXString(strip(rendered))
    end
    return latexstring(strip_math_delims(rendered))
end
