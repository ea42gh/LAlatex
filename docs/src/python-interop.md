# Python interop

LAlatex can interoperate with Python via `PythonCall` (Julia -> Python) and
`juliacall` (Python -> Julia).

## Julia -> Python (PythonCall)

```julia
using LAlatex
using PythonCall
pyimport("sys").executable
```

## Python -> Julia (juliacall)

Install the Python-side bridge before running Python examples:

```bash
python -m pip install juliacall
```

```python
from juliacall import Main as jl
from IPython.display import Latex, display

jl.seval("using LAlatex")
latex = jl.LAlatex.L_show("A = ", [[1, 2], [3, 4]])

display(Latex(latex))
```

If you are working in the `elementary-linear-algebra` notebook environment, a
startup helper file named `10-julia-magic.py` may also define Python-side
helpers such as `l_show(...)` and `L(...)`.

`10-julia-magic.py` is not part of `LAlatex`. It is an external notebook
convenience layer. `LAlatex` itself exposes Julia functions such as
`L_show(...)` and `l_show(...)`, but it does not install Python globals named
`l_show` or `L`.

In that environment, the Python-side helper must convert raw-LaTeX marker
strings to Julia `LaTeXString` values before calling `L_show`:

```python
from juliacall import Main as jl
from IPython.display import Latex, display
from numbers import Number

jl.seval("using LAlatex, LaTeXStrings")

class RawLatex(str):
    """Marker for strings that should be passed to Julia as LaTeXString."""

def L(value):
    """Wrap a Python string as raw LaTeX for the l_show helper."""
    return RawLatex(value)

def _convert_arg(value):
    if isinstance(value, RawLatex):
        return jl.LaTeXString(str(value))
    if _is_2d_list(value):
        return _list_to_julia_matrix(value)
    return value

def L_show(*args, **kwargs):
    return str(jl.LAlatex.L_show(*(_convert_arg(arg) for arg in args), **kwargs))

def l_show(*args, **kwargs):
    display(Latex(L_show(*args, **kwargs)))

def _is_2d_list(value):
    return (
        isinstance(value, (list, tuple))
        and bool(value)
        and all(isinstance(row, (list, tuple)) for row in value)
        and len({len(row) for row in value}) == 1
        and all(isinstance(item, Number) for row in value for item in row)
    )

def _list_to_julia_matrix(value):
    rows = [" ".join(_format_julia_number(item) for item in row) for row in value]
    return jl.seval("[" + "; ".join(rows) + "]")

def _format_julia_number(value):
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, int):
        return str(value)
    if isinstance(value, float):
        return repr(value)
    if isinstance(value, complex):
        sign = "+" if value.imag >= 0 else "-"
        return f"{_format_julia_number(value.real)} {sign} {_format_julia_number(abs(value.imag))}*im"
    return str(value)

A = [[1, 2, 4], [3, 4, 1]]
l_show("A = ", A)
l_show("x = ", 3, L(r";\\quad "), "x^2 = ", 9)
```

## No-conda setup

Ensure the following environment variables are set so PythonCall uses the system Python:

- `JULIA_CONDAPKG_BACKEND=Null`
- `JULIA_PYTHONCALL_EXE=/usr/local/bin/python3`
