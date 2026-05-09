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

## Toolchain troubleshooting

`Pkg.test()` creates an isolated package-test environment and may initialize
PythonCall when SymPy integration tests are available. If that environment
cannot provision Python packages, or if an unrelated default Julia environment
has a broken `PyCall`/`SymPy` precompile, use the direct project test path to
separate package behavior from local toolchain setup:

```bash
julia --project=. test/runtests.jl
```

For non-SymPy checks, disable PythonCall explicitly:

```bash
LALATEX_DISABLE_PYTHONCALL=1 LALATEX_TEST_SUITE=core julia --project=. test/runtests.jl
```

For SymPy checks, prefer a system Python with SymPy installed and point
PythonCall at that interpreter:

```bash
export JULIA_CONDAPKG_BACKEND=Null
export JULIA_PYTHONCALL_EXE=/path/to/python
```

When installing development tools such as `JuliaFormatter` into another Julia
environment, a failure from that environment's `PyCall` or `SymPy` precompile is
not evidence that LAlatex's package tests failed. Re-run the LAlatex commands
above from the package project to verify the repository itself.
