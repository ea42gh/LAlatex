"""
    LinearCombination(s, X, options)

Container for linear-combination rendering in `L_show`.
"""
struct LinearCombination
    s::Any
    X::Any
    options::NamedTuple
end

"""
    lc(s, X; kwargs...) -> LinearCombination

Create a linear-combination group that `l_show` can render.
"""
function _pyconvert_vector_or_nothing(x)
    pc = _ensure_pythoncall()
    (pc === nothing || !_is_pythoncall_py(x)) && return nothing
    return try
        Base.invokelatest(pc.pyconvert, Vector{Any}, x)
    catch
        nothing
    end
end

function _pyconvert_matrix_or_nothing(x)
    pc = _ensure_pythoncall()
    (pc === nothing || !_is_pythoncall_py(x)) && return nothing
    return try
        Base.invokelatest(pc.pyconvert, Matrix{Any}, x)
    catch
        nothing
    end
end

function _pyconvert_lc_coefficients(s)
    _is_pythoncall_py(s) || return s
    converted = _pyconvert_vector_or_nothing(s)
    converted !== nothing && return converted

    converted = _pyconvert_matrix_or_nothing(s)
    converted !== nothing && return vec(converted)
    return s
end

function _pyconvert_lc_vectors(X)
    _is_pythoncall_py(X) || return X
    converted = _pyconvert_matrix_or_nothing(X)
    converted !== nothing && return converted

    converted = _pyconvert_vector_or_nothing(X)
    converted !== nothing && return converted
    return X
end

function lc(s, X; kwargs...)
    if _is_pythoncall_py(s) || _is_pythoncall_py(X)
        s = _pyconvert_lc_coefficients(s)
        X = _pyconvert_lc_vectors(X)
    end
    return LinearCombination(s, X, (; kwargs...))
end

function _lc_literal_number(x)
    if x isa Symbolics.Num
        return _lc_literal_number(Symbolics.unwrap(x))
    end
    if x isa Number
        return x
    end
    if Symbolics.SymbolicUtils.is_literal_number(x)
        return Symbolics.SymbolicUtils.unwrap_const(x)
    end
    return nothing
end

function _lc_is_negative_literal(x)
    val = _lc_literal_number(x)
    return val isa Real && val < 0
end

function _lc_is_zero_coeff(x, raw::AbstractString)
    val = _lc_literal_number(x)
    if val isa Number
        return iszero(val)
    end
    if x isa Symbolics.Num ||
       Symbolics.SymbolicUtils.issym(x) ||
       Symbolics.SymbolicUtils.iscall(x)
        return try
            iszero(Symbolics.simplify(x))
        catch
            raw == "0"
        end
    end
    if _is_sympy_py(x)
        pc = _ensure_pythoncall()
        return try
            Base.invokelatest(pc.pyconvert, Bool, x == 0)
        catch
            raw == "0"
        end
    end
    return raw == "0"
end

function _lc_symbolics_extract_negative(x)
    if !(
        x isa Symbolics.Num ||
        Symbolics.SymbolicUtils.issym(x) ||
        Symbolics.SymbolicUtils.iscall(x)
    )
        return nothing
    end
    coeffs = symbolic_term_coefficients(x)
    if !isempty(coeffs) && all(_lc_is_negative_literal, coeffs)
        return -x
    end
    return nothing
end

function _lc_sympy_extract_negative(x)
    _is_sympy_py(x) || return nothing
    pc = _ensure_pythoncall()
    return try
        method = Base.invokelatest(pc.pygetattr, x, "could_extract_minus_sign")
        can_extract =
            Base.invokelatest(pc.pyconvert, Bool, Base.invokelatest(pc.pycall, method))
        can_extract ? -x : nothing
    catch
        nothing
    end
end

function _lc_extract_negative(x)
    val = _lc_literal_number(x)
    if val isa Real && val < 0
        return -x
    end
    neg = _lc_symbolics_extract_negative(x)
    neg !== nothing && return neg
    neg = _lc_sympy_extract_negative(x)
    neg !== nothing && return neg
    return nothing
end

function _lc_split_sign(x, raw0::AbstractString, inner)
    neg_x = _lc_extract_negative(x)
    if neg_x !== nothing
        return (true, String(strip(inner(neg_x))), true)
    end

    r = String(strip(raw0))
    if occursin(r"^-\\s*\\((.*)\\)$", r)
        m = match(r"^-\\s*\\((.*)\\)$", r)
        return (true, String(m.captures[1]), true)
    end
    if startswith(r, "-")
        absraw = String(strip(r[2:end]))
        single = !(occursin(r"\+", absraw) || occursin(r"(?<!^)-", absraw))
        return (true, absraw, single)
    end
    return (false, r, false)
end

function _validate_lc_sign_policy(sign_policy)
    sign_policy in (:signed, :plus) && return sign_policy
    throw(
        ArgumentError(
            "Unsupported lc sign_policy: $(repr(sign_policy)). Expected :signed or :plus.",
        ),
    )
end

"""
    L_show_lc(lcobj; kwargs...) -> String

Render a LinearCombination group.
"""
function L_show_lc(
    lcobj::LinearCombination;
    setstyle = :parray,
    arraystyle = :parray,
    color = nothing,
    number_formatter = nothing,
    per_element_style = nothing,
    factor_out = true,
    symopts = NamedTuple(),
)
    return L_show_lc(
        lcobj,
        DisplayOptions(;
            setstyle = setstyle,
            arraystyle = arraystyle,
            color = color,
            number_formatter = number_formatter,
            per_element_style = per_element_style,
            factor_out = factor_out,
            symopts = symopts,
        ),
    )
end

function L_show_lc(lcobj::LinearCombination, options::DisplayOptions)
    local s = lcobj.s
    local X = lcobj.X

    opts = merge(
        Dict(
            :sign_policy=>:signed,
            :plus=>L" + ",
            :pos=>L" + ",
            :neg=>L" - ",
            :parens_coeff=>true,
            :omit_one=>true,
            :drop_zero=>true,
        ),
        Dict(pairs(lcobj.options)),
    )
    sign_policy = _validate_lc_sign_policy(opts[:sign_policy])
    effective_factor_out = get(opts, :factor_out, options.factor_out)

    inner_options = DisplayOptions(;
        setstyle = options.setstyle,
        arraystyle = options.arraystyle,
        color = options.color,
        separator = options.separator,
        number_formatter = options.number_formatter,
        per_element_style = options.per_element_style,
        factor_out = effective_factor_out,
        symopts = options.symopts,
    )

    inner = x -> L_show_core(x, inner_options)

    needs_parens = x -> begin
        t = replace(inner(x), r"\s" => "")
        if isempty(t)
            return false
        end
        i = nextind(t, firstindex(t))
        while i <= lastindex(t)
            c = t[i]
            if c == '+' || c == '-'
                return true
            end
            i = nextind(t, i)
        end
        return false
    end

    n = X isa AbstractMatrix ? size(X, 2) : length(X)
    coeff_count = try
        length(s)
    catch
        throw(
            ArgumentError("lc coefficients must be an indexable collection with length $n"),
        )
    end
    if coeff_count != n
        throw(
            ArgumentError(
                "lc coefficient count ($coeff_count) must match vector count ($n)",
            ),
        )
    end
    getvec(i) = X isa AbstractMatrix ? X[:, i] : X[i]

    if sign_policy === :plus
        terms =
            map(1:n) do i
                c = strip(inner(s[i]))
                if opts[:drop_zero] && _lc_is_zero_coeff(s[i], c)
                    return nothing
                end
                c =
                    (opts[:omit_one] && c == "1") ? "" :
                    (opts[:parens_coeff] && needs_parens(s[i])) ?
                    "\\left(" * c * "\\right)" : c
                v = inner(getvec(i))
                (a = LaTeXString(c), b = LaTeXString(v), separator = "")
            end |> x -> filter(!isnothing, x)

        if isempty(terms)
            return L_show_number(
                0;
                color = options.color,
                number_formatter = options.number_formatter,
            )
        end

        g = Group((terms...,), (; setstyle = :array))
        return L_show_set(
            g;
            setstyle = :array,
            arraystyle = options.arraystyle,
            color = options.color,
            number_formatter = options.number_formatter,
            per_element_style = options.per_element_style,
            separator = opts[:plus],
        )
    end

    pieces = Any[]
    for i = 1:n
        raw = String(strip(inner(s[i])))
        if opts[:drop_zero] && _lc_is_zero_coeff(s[i], raw)
            continue
        end
        isneg, absraw, factorizable = _lc_split_sign(s[i], raw, inner)
        base = factorizable ? absraw : raw

        showtxt =
            (opts[:omit_one] && base == "1") ? "" :
            (opts[:parens_coeff] && needs_parens(factorizable ? absraw : raw)) ?
            "\\left(" * base * "\\right)" : base

        term = (a = LaTeXString(showtxt), b = LaTeXString(inner(getvec(i))), separator = "")

        if isempty(pieces)
            if isneg && factorizable
                push!(pieces, opts[:neg])
            end
            push!(pieces, term)
        else
            push!(pieces, (isneg && factorizable) ? opts[:neg] : opts[:pos])
            push!(pieces, term)
        end
    end

    if isempty(pieces)
        return L_show_number(
            0;
            color = options.color,
            number_formatter = options.number_formatter,
        )
    end

    g = Group((pieces...,), (; setstyle = :array))
    return L_show_set(
        g;
        setstyle = :array,
        arraystyle = options.arraystyle,
        color = options.color,
        number_formatter = options.number_formatter,
        per_element_style = options.per_element_style,
        separator = L"",
    )
end
