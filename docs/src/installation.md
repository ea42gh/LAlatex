# Installation

LAlatex is a Julia package. The default Symbolics backend does not require
Python. SymPy support is optional and uses the bundled PythonCall dependency.

## Julia install

```julia
using Pkg
Pkg.add("LAlatex")
```

## SymPy (optional)

If you want the SymPy backend, install SymPy in the Python that PythonCall uses.

Recommended: point PythonCall at a system Python that already has SymPy.

```bash
python3 -m pip install sympy
```

```bash
export JULIA_PYTHONCALL_EXE=/usr/local/bin/python3
export JULIA_CONDAPKG_BACKEND=Null
```

## Quick verification

```julia
using LAlatex
using PythonCall

PythonCall.pyimport("sympy")
set_backend!(:sympy)
LAlatex.@syms x y
```

If SymPy is not needed, skip the Python steps and use the default Symbolics backend.

## Source checkout tests

From the repository root, use the package project for the runtime suite:

```bash
julia --project=. test/runtests.jl
```

The direct test path skips test-only quality tools when they are not installed
in the active project. Run the package-test path to include `Aqua`, targeted
`JET` checks, and `JuliaFormatter`:

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

For a non-SymPy check that avoids Python initialization:

```bash
LALATEX_DISABLE_PYTHONCALL=1 LALATEX_TEST_SUITE=core julia --project=. test/runtests.jl
```
