const DISPLAY_OPTION_KEYS = (:setstyle, :arraystyle, :color, :separator,
                             :number_formatter, :per_element_style, :factor_out, :symopts)

struct DisplayOptions
    setstyle::Symbol
    arraystyle::Symbol
    color
    separator
    number_formatter
    per_element_style
    factor_out::Bool
    symopts::NamedTuple
end

function DisplayOptions(; setstyle=:Barray, arraystyle=:parray, color=nothing, separator=", ",
                        number_formatter=nothing, per_element_style=nothing, factor_out=true,
                        symopts=NamedTuple())
    return DisplayOptions(setstyle, arraystyle, color, separator, number_formatter,
                          per_element_style, factor_out, normalize_symopts(symopts))
end

function merge_display_options(base::DisplayOptions, overrides)
    override_dict = Dict(k => v for (k, v) in pairs(overrides) if k in DISPLAY_OPTION_KEYS)
    isempty(override_dict) && return base
    return DisplayOptions(;
        setstyle=get(override_dict, :setstyle, base.setstyle),
        arraystyle=get(override_dict, :arraystyle, base.arraystyle),
        color=get(override_dict, :color, base.color),
        separator=get(override_dict, :separator, base.separator),
        number_formatter=get(override_dict, :number_formatter, base.number_formatter),
        per_element_style=get(override_dict, :per_element_style, base.per_element_style),
        factor_out=get(override_dict, :factor_out, base.factor_out),
        symopts=get(override_dict, :symopts, base.symopts),
    )
end
