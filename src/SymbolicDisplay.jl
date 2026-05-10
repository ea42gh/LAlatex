"""
    symbolic_transform(x; simplify=:auto, expand=false, factor=false, collect=nothing)

Apply optional symbolic transformations for display. Works with Symbolics and SymPy.
Non-symbolic inputs are returned unchanged.
"""
function _symbolics_factor_transform(y::Symbolics.Num)
    terms = _symbolics_add_terms(Symbolics.unwrap(y))
    length(terms) > 1 || return y

    term_factors = [_symbolics_factor_counts(term) for term in terms]
    common_factors = _symbolics_common_factors(term_factors)
    isempty(common_factors) && return y

    common = _symbolics_factor_product(common_factors)
    remainders = [Symbolics.Num(term) / common for term in terms]
    return common * _symbolics_sum(remainders)
end

function _symbolics_collect_transform(y::Symbolics.Num, collect_var)
    var = _symbolics_unwrap_num(collect_var)
    terms = _symbolics_add_terms(Symbolics.unwrap(y))
    length(terms) > 1 || return y

    grouped = Dict{Int,Vector{Any}}()
    for term in terms
        power, coeff = _symbolics_split_var_power(term, var)
        push!(get!(grouped, power, Any[]), coeff)
    end

    collected_terms = Any[]
    for power in sort(collect(keys(grouped)); rev = true)
        coeff = _symbolics_sum(grouped[power])
        if power == 0
            push!(collected_terms, coeff)
        else
            var_term = _symbolics_power(var, power)
            if isequal(Symbolics.unwrap(coeff), 1)
                push!(collected_terms, var_term)
            else
                push!(collected_terms, var_term * coeff)
            end
        end
    end
    return _symbolics_sum(collected_terms)
end

function _symbolics_is_call(expr, op)
    return _symbolics_iscall(expr) && _symbolics_operation(expr) == op
end

function _symbolics_add_terms(expr)
    if _symbolics_isadd(expr) || _symbolics_is_call(expr, +)
        return collect(_symbolics_arguments(expr))
    elseif _symbolics_is_call(expr, -) && length(_symbolics_arguments(expr)) == 2
        args = _symbolics_arguments(expr)
        return Any[args[1], -Symbolics.Num(args[2])]
    end
    return Any[expr]
end

function _symbolics_mul_factors(expr)
    if _symbolics_ismul(expr) || _symbolics_is_call(expr, *)
        return collect(_symbolics_arguments(expr))
    end
    return Any[expr]
end

function _symbolics_integer_power(expr)
    if _symbolics_is_call(expr, ^)
        args = _symbolics_arguments(expr)
        if length(args) == 2
            exponent = _symbolics_literal_number(args[2])
            exponent isa Integer && exponent > 0 && return args[1], exponent
        end
    end
    return expr, 1
end

function _symbolics_literal_number(expr)
    if expr isa Symbolics.Num
        expr = Symbolics.unwrap(expr)
    end
    if _symbolics_is_literal_number(expr)
        return _symbolics_unwrap_const(expr)
    end
    return expr isa Number ? expr : nothing
end

function _symbolics_factor_counts(term)
    counts = Dict{Any,Int}()
    for factor in _symbolics_mul_factors(term)
        _symbolics_literal_number(factor) !== nothing && continue
        base, power = _symbolics_integer_power(factor)
        counts[base] = get(counts, base, 0) + power
    end
    return counts
end

function _symbolics_common_factors(term_factors)
    isempty(term_factors) && return Dict{Any,Int}()
    common = copy(first(term_factors))
    for factors in Iterators.drop(term_factors, 1)
        for key in collect(keys(common))
            if haskey(factors, key)
                common[key] = min(common[key], factors[key])
            else
                delete!(common, key)
            end
        end
    end
    return common
end

function _symbolics_power(base, power::Integer)
    base_num = Symbolics.Num(base)
    power == 1 && return base_num
    return base_num^power
end

function _symbolics_factor_product(factors::Dict)
    result = 1
    for (base, power) in factors
        result *= _symbolics_power(base, power)
    end
    return result
end

function _symbolics_product(factors)
    result = 1
    for factor in factors
        result *= Symbolics.Num(factor)
    end
    return result
end

function _symbolics_sum(terms)
    result = 0
    for term in terms
        result += Symbolics.Num(term)
    end
    return result
end

function _symbolics_split_var_power(term, var)
    power = 0
    remainder_factors = Any[]
    for factor in _symbolics_mul_factors(term)
        base, exponent = _symbolics_integer_power(factor)
        if isequal(base, var)
            power += exponent
        else
            push!(remainder_factors, factor)
        end
    end
    return power, _symbolics_product(remainder_factors)
end

function symbolic_transform(
    x;
    simplify = :auto,
    expand = false,
    factor = false,
    collect = nothing,
)
    if x isa Complex
        return symbolic_transform(
            real(x);
            simplify = simplify,
            expand = expand,
            factor = factor,
            collect = collect,
        ) +
               im * symbolic_transform(
            imag(x);
            simplify = simplify,
            expand = expand,
            factor = factor,
            collect = collect,
        )
    end

    if x isa Symbolics.Num
        y = x
        if expand
            y = try
                Symbolics.Num(_symbolics_expand_expr(Symbolics.unwrap(y)))
            catch
                y
            end
        end
        if factor
            y = _symbolics_factor_transform(y)
        end
        if simplify === true
            y = try
                Symbolics.simplify(y)
            catch
                y
            end
        end
        if collect !== nothing
            y = _symbolics_collect_transform(y, collect)
        end
        return y
    end

    if _symbolics_issym(x) || _symbolics_iscall(x)
        return symbolic_transform(
            Symbolics.Num(x);
            simplify = simplify,
            expand = expand,
            factor = factor,
            collect = collect,
        )
    end

    if _is_sympy_py(x)
        sympy = import_sympy()
        y = x
        if simplify !== false
            y = sympy.simplify(y)
        end
        if expand
            y = sympy.expand(y)
        end
        if factor
            y = sympy.factor(y)
        end
        if collect !== nothing
            y = sympy.collect(y, collect)
        end
        return y
    end

    return x
end

function _contains_symbolic_value(x)
    if x isa Complex
        return _contains_symbolic_value(real(x)) || _contains_symbolic_value(imag(x))
    end
    return x isa Symbolics.Num ||
           _is_sympy_py(x) ||
           _symbolics_issym(x) ||
           _symbolics_iscall(x)
end

"""
    normalize_symopts(symopts) -> NamedTuple

Normalize symbolic display options to a `NamedTuple` for safe keyword splatting.
"""
function normalize_symopts(symopts)
    if symopts === nothing
        return NamedTuple()
    end
    if symopts isa NamedTuple
        return symopts
    end
    if symopts isa Dict
        return (; symopts...)
    end
    if symopts isa Pair
        return NamedTuple{(first(symopts),)}((last(symopts),))
    end
    if symopts isa Bool
        throw(ArgumentError("symopts must be a NamedTuple; use symopts=(; factor=true)"))
    end
    throw(ArgumentError("symopts must be a NamedTuple, Dict, or Pair"))
end

"""
    symbolic_term_coefficients(expr) -> Vector{Any}

Return the numeric multipliers for each additive term in a Symbolics expression.

Examples:
- `symbolic_term_coefficients((1//2) * x + 2x * y)` returns `[1//2, 2]`
- `symbolic_term_coefficients(1 + 3x)` returns `[1, 3]`
"""
function _symbolics_unwrap_num(expr)
    return expr isa Symbolics.Num ? Symbolics.unwrap(expr) : expr
end

function symbolic_term_coefficients(expr)
    expr = _symbolics_unwrap_num(expr)

    if _symbolics_is_literal_number(expr)
        return Any[_symbolics_unwrap_const(expr)]
    end

    if expr isa Number
        return Any[expr]
    end

    if _symbolics_ismul(expr)
        coeff = _symbolics_mul_coefficient(expr)
        coeff !== nothing && return Any[coeff]
    end

    # Prefer the public TermInterface argument view over direct storage access.
    if _symbolics_isadd(expr)
        coeffs = Any[]
        for arg in _symbolics_arguments(expr)
            append!(coeffs, symbolic_term_coefficients(arg))
        end
        return coeffs
    end

    if _symbolics_iscall(expr) && _symbolics_operation(expr) == (+)
        coeffs = Any[]
        for arg in _symbolics_arguments(expr)
            append!(coeffs, symbolic_term_coefficients(arg))
        end
        return coeffs
    end

    if _symbolics_ismul(expr)
        coeff = _symbolics_mul_coefficient(expr)
        coeff !== nothing && return Any[coeff]
    end

    if _symbolics_iscall(expr) && _symbolics_operation(expr) == (*)
        coeff = _symbolics_mul_coefficient(expr)
        coeff !== nothing && return Any[coeff]
    end

    if _symbolics_iscall(expr) &&
       _symbolics_operation(expr) == (-) &&
       length(_symbolics_arguments(expr)) == 1
        coeffs = symbolic_term_coefficients(_symbolics_arguments(expr)[1])
        return map(-, coeffs)
    end

    if _symbolics_iscall(expr) &&
       _symbolics_operation(expr) == (-) &&
       length(_symbolics_arguments(expr)) == 2
        args = _symbolics_arguments(expr)
        coeffs = symbolic_term_coefficients(args[1])
        append!(coeffs, map(-, symbolic_term_coefficients(args[2])))
        return coeffs
    end

    if _symbolics_iscall(expr) &&
       _symbolics_operation(expr) == (/) &&
       length(_symbolics_arguments(expr)) >= 1
        return symbolic_term_coefficients(_symbolics_arguments(expr)[1])
    end

    return Any[1]
end
