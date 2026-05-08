# API

## Backends

- `set_backend!` / `get_backend`
- `syms`, `@syms`
- `syms_sympy`, `@syms_sympy` (SymPy-only)
- `Backend.backend_usable` probes backend usability in the current runtime and
  may initialize Python/import `sympy`
- `import_sympy` for explicit SymPy import and diagnostics
- `mixed_matrix`, `@mixed_matrix`

Note: `mixed_matrix` and `@mixed_matrix` are construction helpers for
heterogeneous symbolic/numeric matrices. Use them when an ordinary Julia matrix
literal fails or coerces entries while mixing Symbolics/SymPy objects with exact
rationals, complex rationals, or objects from different symbolic backends. For
homogeneous numeric or symbolic matrices, ordinary Julia matrix literals are
preferred.

`Backend.backend_usable(...)` answers whether a backend is usable now in the
current runtime session. For the SymPy backend this is not a static package
installation check; it may initialize Python and attempt to import `sympy`.
Use `import_sympy()` when you want explicit initialization and a direct error
message for import failures.

## Assumptions (Symbolics metadata)

- `assume!`
- `assumptions`

## HTML helpers

- `to_html`, `show_html`, `pr`
- `capture_output`
- `show_side_by_side_html`, `show_side_by_side`
- `RawHTML`

HTML helpers escape text content by default and are intended for ordinary text
display. Use `RawHTML(...)` when a side-by-side slot should render trusted HTML
instead of escaped text.

## LaTeX helpers

- `to_latex`
- `symbolic_transform` (Symbolics/SymPy display transforms)
- `symbolic_term_coefficients` for coefficient-level symbolic inspection used by display helpers

### symbolic_transform options

`symbolic_transform(x; kwargs...)` and `L_show(...; symopts=kwargs)` accept:

| Option | Values | Notes |
| --- | --- | --- |
| `simplify` | `true`/`false` | Apply backend simplification. |
| `expand` | `true`/`false` | Expand algebraic products. |
| `factor` | `true`/`false` | Factor algebraic expressions when the active backend exposes a stable factor API. Currently active for SymPy and a no-op for Symbolics. |
| `collect` | `Symbolics.Num`/`PythonCall.Py`/`nothing` | Collect terms with respect to a variable when the active backend exposes a stable collect API. Currently active for SymPy and a no-op for Symbolics. |

Use `symopts=(; factor=true)` or `symopts=(factor=true,)` to build a `NamedTuple`.

## Formatter helpers

- `bold_formatter`, `italic_formatter`, `color_formatter`
- `conditional_color_formatter`, `highlight_large_values`
- `underline_formatter`, `overline_formatter`
- `combine_formatters`
- `scientific_formatter`, `percentage_formatter`, `exponential_formatter`
- `tril_formatter`, `block_formatter`, `diagonal_blocks_formatter`, `jordanblock_formatter`
- `rowechelon_formatter`

## LaTeX display helpers

- `L_show`
- `l_show`
- `set`, `lc`, `cases`, `aligned`
- `L_interp`
- `apply_function`, `round_value`, `round_matrices`
- `print_np_array_def`
- `L_show(...; symopts=...)` for optional Symbolics/SymPy transforms
- `L_show(...; number_formatter=f)` applies `f` while rendering scalar entries; matrix-wide denominator factoring runs before entry formatting. Formatter results that are `String` or `LaTeXString` are treated as already-rendered LaTeX fragments, while numeric results are converted normally.
- `factor_out_denominator` (returns `(den, scaled)` and expands symbolic entries elementwise; symbolic factoring is coefficient-level and does not pull denominators out of powers/functions or non-scalar symbolic denominators)

### Display contracts

`L_show(args...)` returns a `String` containing a complete LaTeX math fragment.
With the default `inline=true`, the returned string is wrapped in dollar
delimiters and ends with a newline. With `inline=false`, the returned string is
wrapped in Jupyter-Markdown-compatible `$$...$$` display-math delimiters.

`l_show(args...)` calls `L_show(args...)`, strips the outer math delimiters,
and returns a `LaTeXString` for notebook/rich-display output. Use `L_show`
when you need the literal LaTeX string, and use `l_show` when the value should
render directly in a display frontend.

Plain `String` values are rendered as text. `LaTeXString` values are treated
as already-authored LaTeX math fragments. The same distinction applies to
top-level arguments and to cells inside `set`, `cases`, and `aligned`.

Display containers inherit options from the surrounding `L_show` call, then
apply their own keyword arguments as local overrides. Known display options are
`setstyle`, `arraystyle`, `color`, `separator`, `number_formatter`,
`per_element_style`, `factor_out`, and `symopts`. Container-local overrides
apply only to that container's rendered cells.

See the Display policy page for examples and the exact row policies for
`cases` and `aligned`.


## Internal API coverage

```@docs
LAlatex.Backend
LAlatex.Backend.get_backend
LAlatex.Backend.set_backend!
LAlatex.Backend.backend_usable
LAlatex.SymbolicsBackendImpl.syms_symbolics
LAlatex.SymbolicsBackendImpl.assume_symbolics!
LAlatex.SymbolicsBackendImpl.symbolics_assumptions
```

## Generated Public Docstrings

```@autodocs
Modules = [LAlatex]
Private = false
```
