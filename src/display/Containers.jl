"""
    Cases(entries, options)

Container for LaTeX `cases` rendering in `L_show`.
"""
struct Cases
    entries::Tuple
    options::NamedTuple
end

const SET_OPTION_KEYS = (DISPLAY_OPTION_KEYS..., :such_that, :such_that_separator)
const CELL_CONTAINER_OPTION_KEYS =
    (:arraystyle, :color, :number_formatter, :per_element_style, :factor_out, :boxes, :symopts)

function _validate_container_option_keys(
    options,
    allowed_keys,
    container_name::AbstractString,
)
    for key in keys(options)
        if !(key in allowed_keys)
            throw(ArgumentError("Unsupported $container_name option: $(repr(key))."))
        end
    end
    return options
end

"""
    cases(entries...; kwargs...) -> Cases

Create a piecewise/cases display. Each entry may be a two-tuple
`(value, condition)` or a pair `value => condition`.
"""
function cases(entries...; kwargs...)
    options =
        _validate_container_option_keys((; kwargs...), CELL_CONTAINER_OPTION_KEYS, "cases")
    return Cases(entries, options)
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
    options = _validate_container_option_keys(
        (; kwargs...),
        CELL_CONTAINER_OPTION_KEYS,
        "aligned",
    )
    return Aligned(rows, options)
end

"""
    Group(entries, options)

Container for grouped LaTeX rendering.
"""
struct Group
    entries::Tuple
    options::NamedTuple
end

function _validate_set_separator_value(value, option_name::AbstractString)
    (value isa AbstractString || value isa LaTeXString) && return value
    throw(
        ArgumentError(
            "$option_name must be a String or LaTeXString; got $(repr(value)) of type $(typeof(value)).",
        ),
    )
end

@doc raw"""
    set(entries...; such_that=nothing, such_that_separator=L"\mid", kwargs...) -> Group

Create a grouped collection of entries for `L_show`.

With the default `such_that=nothing`, `set(a, b, c)` renders a finite set. Pass
`such_that` to render set-builder notation:

```julia
set(x; such_that=L"x > 0")
set(x; such_that=(L"x > 0", L"x < 1"), separator=L",\;")
set(x; such_that=L"x > 0", such_that_separator=L":")
```

`such_that` mode requires exactly one leading entry. A tuple or vector of
conditions is rendered without extra enclosing delimiters; conditions are
separated by `separator`. `such_that_separator` separates the leading entry from
the conditions and must be a `String` or `LaTeXString`. Existing per-entry
`NamedTuple` display options may be used on the leading entry and on each
condition.
""" function set(
    entries...;
    such_that = DISPLAY_OPTION_UNSET,
    such_that_separator = DISPLAY_OPTION_UNSET,
    kwargs...,
)
    if (such_that === DISPLAY_OPTION_UNSET || such_that === nothing) &&
       such_that_separator !== DISPLAY_OPTION_UNSET
        throw(ArgumentError("set such_that_separator requires such_that."))
    end
    if such_that_separator !== DISPLAY_OPTION_UNSET
        such_that_separator =
            _validate_set_separator_value(such_that_separator, "such_that_separator")
    end
    option_pairs = Pair{Symbol,Any}[pairs((; kwargs...))...]
    such_that === DISPLAY_OPTION_UNSET || push!(option_pairs, :such_that => such_that)
    such_that_separator === DISPLAY_OPTION_UNSET ||
        push!(option_pairs, :such_that_separator => such_that_separator)
    options = _validate_container_option_keys((; option_pairs...), SET_OPTION_KEYS, "set")
    return Group(entries, options)
end

function _set_such_that_entries(value)
    if value isa Tuple || value isa AbstractVector
        isempty(value) && throw(ArgumentError("set such_that entries must not be empty."))
        entries = Tuple(value)
        any(_is_empty_such_that_entry, entries) &&
            throw(ArgumentError("set such_that entries must not be empty."))
        return entries
    end
    _is_empty_such_that_entry(value) &&
        throw(ArgumentError("set such_that entries must not be empty."))
    return (value,)
end

function _is_empty_such_that_entry(value)
    value isa AbstractString && return isempty(strip(String(value)))
    value isa LaTeXString && return isempty(strip(strip_math_delims(value.s)))
    return false
end

function _set_builder_parts(obj_group::Group)
    haskey(obj_group.options, :such_that) || return nothing
    such_that = obj_group.options.such_that
    such_that === nothing && return nothing
    length(obj_group.entries) == 1 || throw(
        ArgumentError(
            "set with such_that requires exactly one leading entry; got $(length(obj_group.entries)).",
        ),
    )
    conditions = _set_such_that_entries(such_that)
    such_that_separator = get(obj_group.options, :such_that_separator, LaTeXString("\\mid"))
    return (
        first_entry = obj_group.entries[1],
        conditions = conditions,
        separator = such_that_separator,
    )
end

"""
    L_show_set(obj_group; kwargs...) -> String

Render a `Group` with delimiters and separators.
"""
function L_show_set(
    obj_group;
    setstyle = DISPLAY_OPTION_UNSET,
    arraystyle = DISPLAY_OPTION_UNSET,
    color = DISPLAY_OPTION_UNSET,
    separator = DISPLAY_OPTION_UNSET,
    number_formatter = DISPLAY_OPTION_UNSET,
    per_element_style = DISPLAY_OPTION_UNSET,
    factor_out = DISPLAY_OPTION_UNSET,
    symopts = DISPLAY_OPTION_UNSET,
)
    if !(obj_group isa Group)
        throw(ArgumentError("L_show_set expected a Group, got: $(typeof(obj_group))"))
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

    builder_parts = _set_builder_parts(obj_group)
    if builder_parts === nothing
        obj_latex = map(obj -> L_show_core(obj, combined_options), obj_group.entries)
        joined_latex = join(obj_latex, " " * clean_separator * " ")
    else
        first_latex = L_show_core(builder_parts.first_entry, combined_options)
        condition_latex =
            map(obj -> L_show_core(obj, combined_options), builder_parts.conditions)
        condition_join = join(condition_latex, " " * clean_separator * " ")
        such_that_separator = normalize_separator(builder_parts.separator)
        joined_latex = first_latex * " " * such_that_separator * " " * condition_join
    end

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
    arraystyle = DISPLAY_OPTION_UNSET,
    color = DISPLAY_OPTION_UNSET,
    number_formatter = DISPLAY_OPTION_UNSET,
    per_element_style = DISPLAY_OPTION_UNSET,
    factor_out = DISPLAY_OPTION_UNSET,
    symopts = DISPLAY_OPTION_UNSET,
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
    arraystyle = DISPLAY_OPTION_UNSET,
    color = DISPLAY_OPTION_UNSET,
    number_formatter = DISPLAY_OPTION_UNSET,
    per_element_style = DISPLAY_OPTION_UNSET,
    factor_out = DISPLAY_OPTION_UNSET,
    symopts = DISPLAY_OPTION_UNSET,
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
