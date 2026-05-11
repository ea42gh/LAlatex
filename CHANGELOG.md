# Changelog

## Unreleased

- Added display-math equation annotations with `L_show`/`l_show`
  `tag` and `label` keywords.
- Added set-builder notation through `set(...; such_that=...,
  such_that_separator=...)`.

## 1.1.1 - 2026-05-10

- Broadened IOCapture compatibility to allow IOCapture 1.x, avoiding
  unnecessary downgrades in environments that already use IOCapture 1.0.

## 1.1.0 - 2026-05-10

- Added configurable display defaults with `set_display_defaults!`,
  `reset_display_defaults!`, `display_defaults`, and `with_display_defaults`.
- Added strict public option validation for display containers, `lc`,
  callbacks, `factor_out`, colors, array styles, and helper inputs.
- Added Jupyter-Markdown-compatible `$$...$$` block output for
  `L_show(...; inline=false)` while preserving notebook-safe `l_show` display.
- Added Symbolics `factor` and `collect` support for display-time `symopts`.
- Added exact public export contract tests and API documentation coverage for
  all exported names.
- Added targeted JET checks, Aqua checks, JuliaFormatter checks, and warmed
  allocation guardrails.
- Added a thin internal Symbolics adapter layer so direct `Symbolics.SymbolicUtils`
  access is centralized behind LAlatex-owned helpers.
- Added lock-protected process-wide display defaults, documented task-local
  default semantics, and expanded defaults restoration coverage.
- Added docs drift smoke checks across Markdown and notebooks, including
  stale delimiter, option, backend, and wording guards.
- Added CI/docs workflow concurrency controls and split docs checks from
  deployment permissions.
- Added latest-stable Julia docs checks alongside the minimum-supported Julia
  docs check.
- Added Python/SymPy toolchain troubleshooting documentation for package-test
  and local precompile failures.
- Hardened `print_np_array_def` by validating NumPy destination names.
- Clarified helper behavior for `round_value`, `round_matrices`, and
  `L_interp`; `L_interp` now accepts `AbstractDict`.
- Added Windows and macOS CI coverage alongside the Ubuntu matrix.
- Added structural and executed notebook smoke checks to the docs workflow.
- Documented 1.0 migration, release policy, and release checklist expectations.
- Added a lightweight benchmark script at `perf/benchmark.jl` for first-call render timing and release-prep environment metadata.
- Fixed Symbolics expression rendering in `L_show` so symbolic functions such as `exp(-3t)` no longer produce embedded `equation` environments inside matrices.
- Preserved rational-power base parentheses, including outputs such as `L_show((3//10)^n)`.
- Clarified and hardened symbolic denominator factoring: denominators are factored from literal rationals, numeric symbolic coefficients, and explicit scalar divisions, but not from powers, functions, or non-scalar symbolic denominators.
- Added support for denominator factoring in block vectors while preserving `BlockArray` dimensionality and block axes.
- Stabilized empty rational vector and matrix denominator factoring by returning `(1, A)` unchanged.
- Broadened rational denominator factoring beyond `Rational{Int}`, including `Rational{BigInt}` and complex rational arrays.
- Normalized complex symbolic rendering after denominator scaling so complex entries with symbolic real or imaginary parts avoid embedded `equation` environments.
- Added focused Symbolics/SymPy parity, exact snapshot, export, block array, empty rational array, broad rational, and complex symbolic denominator tests.
