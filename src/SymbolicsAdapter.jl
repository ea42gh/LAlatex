const _SYMBOLICS_UTILS = Symbolics.SymbolicUtils

_symbolics_issym(expr) = _SYMBOLICS_UTILS.issym(expr)
_symbolics_iscall(expr) = _SYMBOLICS_UTILS.iscall(expr)
_symbolics_isadd(expr) = _SYMBOLICS_UTILS.isadd(expr)
_symbolics_ismul(expr) = _SYMBOLICS_UTILS.ismul(expr)
_symbolics_operation(expr) = _SYMBOLICS_UTILS.operation(expr)
_symbolics_arguments(expr) = _SYMBOLICS_UTILS.arguments(expr)
_symbolics_is_literal_number(expr) = _SYMBOLICS_UTILS.is_literal_number(expr)
_symbolics_unwrap_const(expr) = _SYMBOLICS_UTILS.unwrap_const(expr)
_symbolics_expand_expr(expr) = _SYMBOLICS_UTILS.expand(expr)

function _symbolics_mul_coefficient(expr)
    return try
        _SYMBOLICS_UTILS.get_mul_coefficient(expr)
    catch
        nothing
    end
end

function _symbolics_rat_coefficient(expr)
    return try
        _SYMBOLICS_UTILS.ratcoeff(expr)
    catch
        false, nothing
    end
end
