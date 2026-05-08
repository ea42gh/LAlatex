const DISPLAY_OPTION_KEYS = (
    :setstyle,
    :arraystyle,
    :color,
    :separator,
    :number_formatter,
    :per_element_style,
    :factor_out,
    :symopts,
)

struct DisplayOptionUnset end

const DISPLAY_OPTION_UNSET = DisplayOptionUnset()
const GLOBAL_DISPLAY_DEFAULTS = Ref{Any}(NamedTuple())
const DISPLAY_DEFAULTS_TASK_KEY = (:LAlatex, :display_defaults)

struct DisplayOptions
    setstyle::Symbol
    arraystyle::Symbol
    color::Any
    separator::Any
    number_formatter::Any
    per_element_style::Any
    factor_out::Bool
    symopts::NamedTuple
end

function _validate_display_default_keys(defaults)
    for key in keys(defaults)
        if !(key in DISPLAY_OPTION_KEYS)
            throw(ArgumentError("Unsupported display default option: $(repr(key))."))
        end
    end
    return defaults
end

function _validate_factor_out_value(factor_out)
    factor_out isa Bool && return factor_out
    throw(
        ArgumentError(
            "factor_out must be a Bool; got $(repr(factor_out)) of type $(typeof(factor_out)).",
        ),
    )
end

function _validate_display_default_values(defaults)
    if haskey(defaults, :setstyle)
        validate_arraystyle_value(defaults.setstyle, "setstyle")
    end
    if haskey(defaults, :arraystyle)
        validate_arraystyle_value(defaults.arraystyle, "arraystyle")
    end
    if haskey(defaults, :factor_out)
        _validate_factor_out_value(defaults.factor_out)
    end
    if haskey(defaults, :symopts)
        normalize_symopts(defaults.symopts)
    end
    return defaults
end

function _validate_display_defaults(defaults)
    _validate_display_default_keys(defaults)
    return _validate_display_default_values(defaults)
end

function _scoped_display_defaults()
    return get(task_local_storage(), DISPLAY_DEFAULTS_TASK_KEY, NamedTuple())
end

function _hardcoded_display_defaults()
    return (
        setstyle = :Barray,
        arraystyle = :parray,
        color = nothing,
        separator = ", ",
        number_formatter = nothing,
        per_element_style = nothing,
        factor_out = true,
        symopts = NamedTuple(),
    )
end

function _effective_display_defaults()
    return merge(
        _hardcoded_display_defaults(),
        GLOBAL_DISPLAY_DEFAULTS[],
        _scoped_display_defaults(),
    )
end

function _resolve_display_option(defaults, key, value)
    return value === DISPLAY_OPTION_UNSET ? getproperty(defaults, key) : value
end

"""
    set_display_defaults!(; kwargs...) -> NamedTuple

Set process-wide display defaults used by `L_show`, `l_show`, and nested display
containers. Explicit call-site keywords still take precedence.
"""
function set_display_defaults!(; kwargs...)
    defaults = _validate_display_defaults((; kwargs...))
    GLOBAL_DISPLAY_DEFAULTS[] = merge(GLOBAL_DISPLAY_DEFAULTS[], defaults)
    return GLOBAL_DISPLAY_DEFAULTS[]
end

"""
    reset_display_defaults!() -> NamedTuple

Clear process-wide display defaults.
"""
function reset_display_defaults!()
    GLOBAL_DISPLAY_DEFAULTS[] = NamedTuple()
    return GLOBAL_DISPLAY_DEFAULTS[]
end

"""
    display_defaults() -> NamedTuple

Return the currently configured process-wide display defaults.
"""
display_defaults() = GLOBAL_DISPLAY_DEFAULTS[]

"""
    with_display_defaults(f; kwargs...)

Run `f` with task-local display defaults. Scoped defaults override process-wide
defaults, and explicit display keywords override both.
"""
function with_display_defaults(f; kwargs...)
    defaults = _validate_display_defaults((; kwargs...))
    previous = _scoped_display_defaults()
    task_local_storage(DISPLAY_DEFAULTS_TASK_KEY, merge(previous, defaults))
    try
        return f()
    finally
        task_local_storage(DISPLAY_DEFAULTS_TASK_KEY, previous)
    end
end

function DisplayOptions(;
    setstyle = DISPLAY_OPTION_UNSET,
    arraystyle = DISPLAY_OPTION_UNSET,
    color = DISPLAY_OPTION_UNSET,
    separator = DISPLAY_OPTION_UNSET,
    number_formatter = DISPLAY_OPTION_UNSET,
    per_element_style = DISPLAY_OPTION_UNSET,
    factor_out = DISPLAY_OPTION_UNSET,
    symopts = DISPLAY_OPTION_UNSET,
)
    defaults = _effective_display_defaults()
    setstyle = _resolve_display_option(defaults, :setstyle, setstyle)
    arraystyle = _resolve_display_option(defaults, :arraystyle, arraystyle)
    color = _resolve_display_option(defaults, :color, color)
    separator = _resolve_display_option(defaults, :separator, separator)
    number_formatter =
        _resolve_display_option(defaults, :number_formatter, number_formatter)
    per_element_style =
        _resolve_display_option(defaults, :per_element_style, per_element_style)
    factor_out = _resolve_display_option(defaults, :factor_out, factor_out)
    symopts = _resolve_display_option(defaults, :symopts, symopts)

    return DisplayOptions(
        validate_arraystyle_value(setstyle, "setstyle"),
        validate_arraystyle_value(arraystyle, "arraystyle"),
        color,
        separator,
        number_formatter,
        per_element_style,
        _validate_factor_out_value(factor_out),
        normalize_symopts(symopts),
    )
end

function merge_display_options(base::DisplayOptions, overrides)
    override_dict = Dict(k => v for (k, v) in pairs(overrides) if k in DISPLAY_OPTION_KEYS)
    isempty(override_dict) && return base
    return DisplayOptions(;
        setstyle = get(override_dict, :setstyle, base.setstyle),
        arraystyle = get(override_dict, :arraystyle, base.arraystyle),
        color = get(override_dict, :color, base.color),
        separator = get(override_dict, :separator, base.separator),
        number_formatter = get(override_dict, :number_formatter, base.number_formatter),
        per_element_style = get(override_dict, :per_element_style, base.per_element_style),
        factor_out = get(override_dict, :factor_out, base.factor_out),
        symopts = get(override_dict, :symopts, base.symopts),
    )
end
