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

Install the Python bridge before running Python examples from a source checkout:

```bash
python -m pip install -e .
```

```python
from pathlib import Path

from lalatex import L, L_show, init, l_show

init(project=Path.cwd())

latex = L_show("A = ", [[1, 2], [3, 4]])
l_show("x = ", 3, L(r";\quad "), "x^2 = ", 9)
```

The repository ships a small Python shim at `python/lalatex.py`, exposed by the
checkout's `pyproject.toml` as the Python module `lalatex`. It is the canonical
Python helper layer used by the Python interop notebook and release notebook
executor. The examples above assume the current working directory is the
repository root when calling `init(project=Path.cwd())`; pass the checkout path
explicitly when running from another directory.

Python and Julia must have compatible architectures because `juliacall` loads
`libjulia` into the Python process. On Windows, for example, an arm64 Python
cannot load an x64 Julia. Use a Python interpreter that matches the installed
Julia architecture, or run the interop checks in the project Docker/Binder image
or GitHub Actions.

Helper contract:

- `L("...")` marks a Python string as raw LaTeX and converts it to Julia
  `LaTeXString`.
- Plain Python strings render as text.
- `L_show(...)` returns the LaTeX string produced by Julia `LAlatex.L_show`.
- `l_show(...)` displays the rendered LaTeX in IPython when possible and
  returns the LaTeX string. Pass `strict_display=True` to surface IPython
  display failures as exceptions.
- Rectangular two-dimensional Python numeric lists are converted to Julia
  matrices before rendering. They must have at least one row and one column.
  Matrix entries must be finite `bool`, `int`, `float`, `complex`, or
  `fractions.Fraction` values.

```python
A = [[1, 2, 4], [3, 4, 1]]
l_show("A = ", A)
l_show("x = ", 3, L(r";\quad "), "x^2 = ", 9)
```

If you are working in the `elementary-linear-algebra` notebook environment, an
external startup file named `10-julia-magic.py` may also define Python-side
helpers. It should import or mirror this shim rather than defining incompatible
conversion rules.

## No-conda setup

Ensure the following environment variables are set so PythonCall uses the system Python:

- `JULIA_CONDAPKG_BACKEND=Null`
- `JULIA_PYTHONCALL_EXE=/usr/local/bin/python3`

For Python-to-Julia checks, also point JuliaCall at the Julia executable and
project you want to use:

- `PYTHON_JULIACALL_EXE=julia`
- `LALATEX_PROJECT=/path/to/LAlatex.jl`
