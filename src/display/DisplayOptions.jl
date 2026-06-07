const DISPLAY_OPTION_KEYS = (
    :setstyle,
    :arraystyle,
    :color,
    :separator,
    :number_formatter,
    :per_element_style,
    :factor_out,
    :boxes,
    :symopts,
)

struct DisplayOptionUnset end

const DISPLAY_OPTION_UNSET = DisplayOptionUnset()
const DISPLAY_DEFAULTS_TASK_KEY = (:LAlatex, :display_defaults)

struct DisplayOptions
    setstyle::Symbol
    arraystyle::Symbol
    color::Any
    separator::Any
    number_formatter::Any
    per_element_style::Any
    factor_out::Bool
    boxes::Any
    symopts::NamedTuple
end

struct DisplayDefaults{T<:NamedTuple}
    values::T
end

DisplayDefaults() = DisplayDefaults(NamedTuple())

const GLOBAL_DISPLAY_DEFAULTS = Ref{DisplayDefaults}(DisplayDefaults())
const GLOBAL_DISPLAY_DEFAULTS_LOCK = ReentrantLock()

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

function _validate_callback_value(callback, option_name::AbstractString)
    (callback === nothing || callback isa Function) && return callback
    throw(
        ArgumentError(
            "$option_name must be a callable function or nothing; got $(repr(callback)) of type $(typeof(callback)).",
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
    if haskey(defaults, :color) && defaults.color !== nothing
        validate_latex_color_value(defaults.color)
    end
    if haskey(defaults, :factor_out)
        _validate_factor_out_value(defaults.factor_out)
    end
    if haskey(defaults, :number_formatter)
        _validate_callback_value(defaults.number_formatter, "number_formatter")
    end
    if haskey(defaults, :per_element_style)
        _validate_callback_value(defaults.per_element_style, "per_element_style")
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

function _display_default_value(defaults::DisplayDefaults, key::Symbol)
    return get(defaults.values, key, DISPLAY_OPTION_UNSET)
end

function _display_defaults_to_named_tuple(defaults::DisplayDefaults)
    return defaults.values
end

function _canonical_display_defaults(defaults)
    defaults = _validate_display_defaults(defaults)
    pairs = Pair{Symbol,Any}[]
    for key in DISPLAY_OPTION_KEYS
        haskey(defaults, key) && push!(pairs, key => defaults[key])
    end
    return (; pairs...)
end

function _merge_display_defaults(defaults::DisplayDefaults, overrides)
    overrides = _canonical_display_defaults(overrides)
    pairs = Pair{Symbol,Any}[]
    for key in DISPLAY_OPTION_KEYS
        value =
            haskey(overrides, key) ? overrides[key] : _display_default_value(defaults, key)
        value === DISPLAY_OPTION_UNSET || push!(pairs, key => value)
    end
    return DisplayDefaults((; pairs...))
end

function _scoped_display_defaults()
    return get(task_local_storage(), DISPLAY_DEFAULTS_TASK_KEY, DisplayDefaults())
end

function _global_display_defaults()
    lock(GLOBAL_DISPLAY_DEFAULTS_LOCK)
    try
        return GLOBAL_DISPLAY_DEFAULTS[]
    finally
        unlock(GLOBAL_DISPLAY_DEFAULTS_LOCK)
    end
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
        boxes = nothing,
        symopts = NamedTuple(),
    )
end

function _effective_display_defaults()
    hardcoded = _hardcoded_display_defaults()
    global_defaults = _global_display_defaults()
    scoped_defaults = _scoped_display_defaults()
    return (;
        (
            key => begin
                scoped = _display_default_value(scoped_defaults, key)
                if scoped !== DISPLAY_OPTION_UNSET
                    scoped
                else
                    global_value = _display_default_value(global_defaults, key)
                    global_value !== DISPLAY_OPTION_UNSET ? global_value :
                    getproperty(hardcoded, key)
                end
            end for key in DISPLAY_OPTION_KEYS
        )...,
    )
end

function _resolve_display_option(defaults, key, value)
    return value === DISPLAY_OPTION_UNSET ? getproperty(defaults, key) : value
end

"""
    set_display_defaults!(; kwargs...) -> NamedTuple

Set process-wide display defaults used by `L_show`, `l_show`, and nested display
containers. Updates are lock-protected. Explicit call-site keywords still take
precedence.
"""
function set_display_defaults!(; kwargs...)
    lock(GLOBAL_DISPLAY_DEFAULTS_LOCK)
    try
        GLOBAL_DISPLAY_DEFAULTS[] =
            _merge_display_defaults(GLOBAL_DISPLAY_DEFAULTS[], (; kwargs...))
        return _display_defaults_to_named_tuple(GLOBAL_DISPLAY_DEFAULTS[])
    finally
        unlock(GLOBAL_DISPLAY_DEFAULTS_LOCK)
    end
end

"""
    reset_display_defaults!() -> NamedTuple

Clear process-wide display defaults.
"""
function reset_display_defaults!()
    lock(GLOBAL_DISPLAY_DEFAULTS_LOCK)
    try
        GLOBAL_DISPLAY_DEFAULTS[] = DisplayDefaults()
        return _display_defaults_to_named_tuple(GLOBAL_DISPLAY_DEFAULTS[])
    finally
        unlock(GLOBAL_DISPLAY_DEFAULTS_LOCK)
    end
end

"""
    display_defaults() -> NamedTuple

Return the currently configured process-wide display defaults.
"""
display_defaults() = _display_defaults_to_named_tuple(_global_display_defaults())

"""
    with_display_defaults(f; kwargs...)

Run `f` with task-local display defaults. Scoped defaults override process-wide
defaults for the current task, and explicit display keywords override both.
"""
function with_display_defaults(f; kwargs...)
    previous = _scoped_display_defaults()
    task_local_storage(
        DISPLAY_DEFAULTS_TASK_KEY,
        _merge_display_defaults(previous, (; kwargs...)),
    )
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
    boxes = DISPLAY_OPTION_UNSET,
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
    boxes = _resolve_display_option(defaults, :boxes, boxes)
    symopts = _resolve_display_option(defaults, :symopts, symopts)

    return DisplayOptions(
        validate_arraystyle_value(setstyle, "setstyle"),
        validate_arraystyle_value(arraystyle, "arraystyle"),
        color === nothing ? nothing : validate_latex_color_value(color),
        separator,
        _validate_callback_value(number_formatter, "number_formatter"),
        _validate_callback_value(per_element_style, "per_element_style"),
        _validate_factor_out_value(factor_out),
        boxes,
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
        boxes = get(override_dict, :boxes, base.boxes),
        symopts = get(override_dict, :symopts, base.symopts),
    )
end
