"""
    Cases(entries, options)

Container for LaTeX `cases` rendering in `L_show`.
"""
struct Cases
    entries::Tuple
    options::NamedTuple
end

"""
    cases(entries...; kwargs...) -> Cases

Create a piecewise/cases display. Each entry may be a two-tuple
`(value, condition)` or a pair `value => condition`.
"""
function cases(entries...; kwargs...)
    return Cases(entries, (; kwargs...))
end

"""
    Aligned(rows, options)

Container for LaTeX `aligned` rendering in `L_show`.
"""
struct Aligned
    rows::Tuple
    options::NamedTuple
end

"""
    aligned(rows...; kwargs...) -> Aligned

Create an aligned display. Each row may be a vector, tuple, or pair. Users
provide row cells; `aligned` inserts LaTeX alignment markers between cells.
Pairs render as `left &= right`.
"""
function aligned(rows...; kwargs...)
    return Aligned(rows, (; kwargs...))
end

"""
    Group(entries, options)

Container for grouped LaTeX rendering.
"""
struct Group
    entries::Tuple
    options::NamedTuple
end

"""
    set(entries...; kwargs...) -> Group

Create a grouped collection of entries for `L_show`.
"""
function set(entries...; kwargs...)
    return Group(entries, (; kwargs...))
end

"""
    L_show_set(obj_group; kwargs...) -> String

Render a `Group` with delimiters and separators.
"""
function L_show_set(
    obj_group;
    setstyle = :Barray,
    arraystyle = :parray,
    color = nothing,
    separator = ", ",
    number_formatter = nothing,
    per_element_style = nothing,
    factor_out = true,
    symopts = NamedTuple(),
)
    if !(obj_group isa Group)
        error("L_show_set expected a Group, got: $(typeof(obj_group))")
    end

    base_options = DisplayOptions(;
        setstyle = setstyle,
        arraystyle = arraystyle,
        color = color,
        separator = separator,
        number_formatter = number_formatter,
        per_element_style = per_element_style,
        factor_out = factor_out,
        symopts = symopts,
    )
    combined_options = merge_display_options(base_options, obj_group.options)

    clean_separator = normalize_separator(combined_options.separator)
    _, _, left_delim, right_delim = parse_arraystyle(combined_options.setstyle)

    obj_latex = map(obj -> L_show_core(obj, combined_options), obj_group.entries)

    joined_latex = join(obj_latex, " " * clean_separator * " ")

    formatted_group = LaTeXString("$(left_delim) " * joined_latex * " $(right_delim)")
    return style_wrapper(formatted_group, combined_options.color)
end

function _case_entry_parts(entry)
    if entry isa Pair
        return first(entry), last(entry)
    elseif entry isa Tuple && length(entry) == 2
        return entry[1], entry[2]
    end
    throw(ArgumentError("cases entries must be pairs or two-tuples; got $(typeof(entry))"))
end

function _render_display_cell(x, options)
    cell_options = DisplayOptions(;
        setstyle = options.setstyle,
        arraystyle = options.arraystyle,
        color = nothing,
        separator = options.separator,
        number_formatter = options.number_formatter,
        per_element_style = options.per_element_style,
        factor_out = options.factor_out,
        symopts = options.symopts,
    )
    return strip(L_show_core(x, cell_options))
end

"""
    L_show_cases(case_group; kwargs...) -> String

Render a `Cases` group as a LaTeX `cases` environment.
"""
function L_show_cases(
    case_group::Cases;
    arraystyle = :parray,
    color = nothing,
    number_formatter = nothing,
    per_element_style = nothing,
    factor_out = true,
    symopts = NamedTuple(),
)
    base_options = DisplayOptions(;
        arraystyle = arraystyle,
        color = color,
        number_formatter = number_formatter,
        per_element_style = per_element_style,
        factor_out = factor_out,
        symopts = symopts,
    )
    return L_show_cases(case_group, base_options)
end

function L_show_cases(case_group::Cases, options::DisplayOptions)
    combined_options = merge_display_options(options, case_group.options)

    rows = map(case_group.entries) do entry
        value, condition = _case_entry_parts(entry)
        value_latex = _render_display_cell(value, combined_options)
        condition_latex = _render_display_cell(condition, combined_options)
        "$value_latex, & $condition_latex \\\\"
    end

    formatted_cases = "\\begin{cases}\n" * join(rows, "\n") * "\n\\end{cases}"
    return style_wrapper(formatted_cases, combined_options.color)
end

function _aligned_row_cells(row)
    if row isa Pair
        return (first(row), L"=", last(row))
    elseif row isa Tuple
        isempty(row) && throw(ArgumentError("aligned rows must contain at least one cell"))
        return row
    elseif row isa AbstractVector
        isempty(row) && throw(ArgumentError("aligned rows must contain at least one cell"))
        return Tuple(row)
    end
    throw(
        ArgumentError("aligned rows must be pairs, tuples, or vectors; got $(typeof(row))"),
    )
end

"""
    L_show_aligned(aligned_group; kwargs...) -> String

Render an `Aligned` group as a LaTeX `aligned` environment.
"""
function L_show_aligned(
    aligned_group::Aligned;
    arraystyle = :parray,
    color = nothing,
    number_formatter = nothing,
    per_element_style = nothing,
    factor_out = true,
    symopts = NamedTuple(),
)
    base_options = DisplayOptions(;
        arraystyle = arraystyle,
        color = color,
        number_formatter = number_formatter,
        per_element_style = per_element_style,
        factor_out = factor_out,
        symopts = symopts,
    )
    return L_show_aligned(aligned_group, base_options)
end

function L_show_aligned(aligned_group::Aligned, options::DisplayOptions)
    combined_options = merge_display_options(options, aligned_group.options)

    rows = map(aligned_group.rows) do row
        cells = _aligned_row_cells(row)
        rendered = [_render_display_cell(cell, combined_options) for cell in cells]
        join(rendered, " & ") * " \\\\"
    end

    formatted_aligned = "\\begin{aligned}\n" * join(rows, "\n") * "\n\\end{aligned}"
    return style_wrapper(formatted_aligned, combined_options.color)
end
