"""
    L_show(objs...; inline=true, kwargs...) -> String

Render objects into a LaTeX string with optional inline delimiters.
"""
function L_show(
    objs...;
    setstyle = :Barray,
    arraystyle = :parray,
    separator = ", ",
    color = nothing,
    number_formatter = nothing,
    per_element_style = nothing,
    factor_out = true,
    inline = true,
    symopts = NamedTuple(),
)
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

    styled_content = join(formatted_objs, " ")
    return inline ? "\$" * styled_content * "\$\n" : "\\[" * styled_content * "\\]\n"
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
    return latexstring(strip_math_delims(rendered))
end
