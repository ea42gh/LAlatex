r"""Small Python bridge for using LAlatex.jl through juliacall.

The module keeps Python notebook helpers in one place:

    from lalatex import L, L_show, l_show, init
    init(project="/path/to/LAlatex.jl")
    l_show("x = ", 3, L(r";\quad "), "x^2 = ", 9)
"""

from __future__ import annotations

import json
import math
import os
from fractions import Fraction
from numbers import Number
from pathlib import Path
from typing import Any


class RawLatex(str):
    """Marker for Python strings that should become Julia LaTeXString values."""


class LAlatexBridge:
    """Stateful juliacall bridge for Python-side LAlatex helpers."""

    def __init__(self, project: str | os.PathLike[str] | None = None, instantiate: bool = True):
        try:
            from juliacall import Main as jl
        except ImportError as err:
            raise ImportError(
                "LAlatex Python helpers require juliacall. Install it with "
                "`python -m pip install juliacall` or use the documented notebook image."
            ) from err

        self.jl = jl
        if project is not None:
            project_text = str(Path(project)) if not str(project).startswith("@") else str(project)
            command = f"import Pkg; Pkg.activate({json.dumps(project_text)})"
            if instantiate:
                command += "; Pkg.instantiate()"
            jl.seval(command)

        jl.seval("using LAlatex, LaTeXStrings, LinearAlgebra")
        jl.seval(
            """
            function _lalatex_python_L_show(args, raw_indices, raw_kwarg_names; kwargs...)
                raw = Set(Int.(raw_indices))
                converted = Any[
                    i in raw ? LaTeXString(String(args[i])) : args[i]
                    for i in eachindex(args)
                ]
                raw_kwargs = Set(Symbol.(raw_kwarg_names))
                converted_kwargs = (; (
                    key => key in raw_kwargs ? LaTeXString(String(value)) : value
                    for (key, value) in pairs(kwargs)
                )...)
                return LAlatex.L_show(converted...; converted_kwargs...)
            end
            """
        )
        self._l_show_string = jl.seval("_lalatex_python_L_show")

    def convert_arg(self, value: Any) -> Any:
        if isinstance(value, (list, tuple)) and not value:
            raise ValueError("Python vectors must have at least one entry.")
        if _is_ragged_numeric_sequence(value):
            raise ValueError("Python matrices must be rectangular.")
        if _is_2d_numeric_sequence(value):
            return self._list_to_julia_matrix(value)
        if _is_1d_numeric_sequence(value):
            return self._list_to_julia_vector(value)
        return value

    def L_show(self, *args: Any, **kwargs: Any) -> str:
        converted = []
        raw_indices = []
        raw_kwarg_names = []
        for index, arg in enumerate(args, start=1):
            if isinstance(arg, RawLatex):
                raw_indices.append(index)
                converted.append(str(arg))
            else:
                converted.append(self.convert_arg(arg))
        converted_kwargs = {}
        for key, value in kwargs.items():
            if isinstance(value, RawLatex):
                converted_kwargs[key] = str(value)
                raw_kwarg_names.append(key)
            else:
                converted_kwargs[key] = value
        return str(
            self._l_show_string(
                converted,
                raw_indices,
                raw_kwarg_names,
                **converted_kwargs,
            )
        )

    def l_show(
        self,
        *args: Any,
        display_result: bool = True,
        strict_display: bool = False,
        **kwargs: Any,
    ) -> str:
        latex = self.L_show(*args, **kwargs)
        if display_result:
            try:
                from IPython.display import Latex, display

                display(Latex(latex))
            except Exception as err:
                if strict_display:
                    raise RuntimeError("IPython LaTeX display failed.") from err
        return latex

    def _list_to_julia_matrix(self, value: Any) -> Any:
        if not value or not value[0]:
            raise ValueError("Python matrices must have at least one row and one column.")
        rows = [" ".join(_format_julia_number(item) for item in row) for row in value]
        return self.jl.seval("[" + "; ".join(rows) + "]")

    def _list_to_julia_vector(self, value: Any) -> Any:
        if not value:
            raise ValueError("Python vectors must have at least one entry.")
        entries = ", ".join(_format_julia_number(item) for item in value)
        return self.jl.seval("[" + entries + "]")


_DEFAULT_BRIDGE: LAlatexBridge | None = None


def init(project: str | os.PathLike[str] | None = None, instantiate: bool = True) -> LAlatexBridge:
    """Initialize and return the module-level LAlatex bridge."""

    global _DEFAULT_BRIDGE
    _DEFAULT_BRIDGE = LAlatexBridge(project=project, instantiate=instantiate)
    return _DEFAULT_BRIDGE


def bridge() -> LAlatexBridge:
    """Return the module-level bridge, initializing it lazily when needed."""

    global _DEFAULT_BRIDGE
    if _DEFAULT_BRIDGE is None:
        project = os.environ.get("LALATEX_PROJECT") or os.environ.get("JULIA_PROJECT")
        _DEFAULT_BRIDGE = LAlatexBridge(project=project or None)
    return _DEFAULT_BRIDGE


def L(value: str) -> RawLatex:
    """Wrap a Python string as raw LaTeX for LAlatex helper calls."""

    if not isinstance(value, str):
        raise TypeError(f"L(...) expects a Python string; got {type(value).__name__}.")
    return RawLatex(value)


def L_show(*args: Any, **kwargs: Any) -> str:
    """Return LAlatex-rendered LaTeX as a Python string."""

    return bridge().L_show(*args, **kwargs)


def l_show(
    *args: Any,
    display_result: bool = True,
    strict_display: bool = False,
    **kwargs: Any,
) -> str:
    """Display LAlatex-rendered LaTeX in IPython and return the LaTeX string."""

    return bridge().l_show(
        *args,
        display_result=display_result,
        strict_display=strict_display,
        **kwargs,
    )


def _is_2d_numeric_sequence(value: Any) -> bool:
    return (
        isinstance(value, (list, tuple))
        and bool(value)
        and all(isinstance(row, (list, tuple)) for row in value)
        and len({len(row) for row in value}) == 1
        and all(isinstance(item, Number) for row in value for item in row)
    )


def _is_1d_numeric_sequence(value: Any) -> bool:
    return (
        isinstance(value, (list, tuple))
        and bool(value)
        and all(isinstance(item, Number) for item in value)
    )


def _is_ragged_numeric_sequence(value: Any) -> bool:
    return (
        isinstance(value, (list, tuple))
        and bool(value)
        and all(isinstance(row, (list, tuple)) for row in value)
        and len({len(row) for row in value}) != 1
        and all(isinstance(item, Number) for row in value for item in row)
    )


def _format_julia_number(value: Number) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, int):
        return str(value)
    if isinstance(value, float):
        if not math.isfinite(value):
            raise ValueError("Python numeric entries must be finite numbers.")
        return repr(value)
    if isinstance(value, Fraction):
        return f"{value.numerator}//{value.denominator}"
    if isinstance(value, complex):
        if not (math.isfinite(value.real) and math.isfinite(value.imag)):
            raise ValueError("Python numeric entries must be finite numbers.")
        real = _format_julia_number(value.real)
        imag = _format_julia_number(abs(value.imag))
        sign = "+" if value.imag >= 0 else "-"
        return f"{real} {sign} {imag}*im"
    raise TypeError(
        "Python numeric entries must be bool, int, float, complex, or Fraction; "
        f"got {type(value).__name__}."
    )


__all__ = ["L", "LAlatexBridge", "L_show", "RawLatex", "bridge", "init", "l_show"]
