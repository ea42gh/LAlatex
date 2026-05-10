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

`assume!(x; key=value)` attaches LAlatex metadata to Symbolics variables and
returns the same variable for fluent setup. SymPy assumptions should be passed
when creating SymPy symbols with `syms(...; backend=:sympy)` or `syms_sympy`.
`assumptions(x)` returns a copy of stored Symbolics metadata, or an empty
dictionary for values without stored assumptions.

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
| `factor` | `true`/`false` | Factor algebraic expressions. Symbolics uses conservative common-factor extraction for additive expressions; SymPy delegates to `sympy.factor`. |
| `collect` | `Symbolics.Num`/`PythonCall.Py`/`nothing` | Collect terms with respect to a variable. Symbolics groups polynomial-like additive terms; SymPy delegates to `sympy.collect`. |

Use `symopts=(; factor=true)` or `symopts=(factor=true,)` to build a `NamedTuple`.

Examples:

```julia
@syms x y

L_show((x + y)^2; symopts=(expand=true,))
L_show(x^2 + x*y; symopts=(factor=true,))
L_show(x^2 + x*y + x + 1; symopts=(collect=x,))
L_show((x + y)^2; symopts=(expand=true, simplify=true))
```

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
- `set_display_defaults!`, `reset_display_defaults!`, `display_defaults`,
  `with_display_defaults`
- `set`, `lc`, `cases`, `aligned`
- `L_interp`
- `apply_function`, `round_value`, `round_matrices` for elementwise numeric
  transformations; non-numeric values and non-integer `digits` throw
  `ArgumentError`
- `print_np_array_def` for numeric arrays that should be copied as NumPy
  literals; unsupported element types and invalid Python destination names
  throw `ArgumentError`
- `L_show(...; symopts=...)` for optional Symbolics/SymPy transforms
- `L_show(...; number_formatter=f)` applies `f` while rendering scalar entries; matrix-wide denominator factoring runs before entry formatting. Formatter results that are `String` or `LaTeXString` are treated as already-rendered LaTeX fragments, while numeric results are converted normally.
- `factor_out_denominator` (returns `(den, scaled)` and expands symbolic entries elementwise; symbolic factoring is coefficient-level and does not pull denominators out of powers/functions or non-scalar symbolic denominators)

### Display contracts

`L_show(args...)` returns a `String` containing a complete LaTeX math fragment.
With the default `inline=true`, the returned string is wrapped in dollar
delimiters and ends with a newline. With `inline=false`, the returned string is
wrapped in Jupyter-Markdown-compatible `$$...$$` display-math delimiters.

`l_show(args...)` calls `L_show(args...)` and returns a `LaTeXString` for
notebook/rich-display output. With the default `inline=true`, it strips the
outer inline math delimiters before constructing the display value. With
`inline=false`, it preserves the `$$...$$` display block so notebook frontends
receive display math rather than inline math. Use `L_show` when you need the
literal LaTeX string, and use `l_show` when the value should render directly in
a display frontend.

Plain `String` values are rendered as text. `LaTeXString` values are treated
as already-authored LaTeX math fragments. The same distinction applies to
top-level arguments and to cells inside `set`, `cases`, and `aligned`.
`LinearAlgebra.UniformScaling` values such as `I`, `0I`, and `2I` render as
math identity fragments rather than plain text.

Display containers inherit options from the surrounding `L_show` call, then
apply their own keyword arguments as local overrides. Known display options are
`setstyle`, `arraystyle`, `color`, `separator`, `number_formatter`,
`per_element_style`, `factor_out`, and `symopts`. Container-local overrides
apply only to that container's rendered cells. `lc(...)` also accepts these
display options locally for its coefficients and vectors. Unknown container
option names throw `ArgumentError`.

`color` accepts a LaTeX/xcolor color name or expression as a `String` or
`Symbol`, such as `"red"` or `"red!50!black"`. Braces, backslashes, control
characters, and LaTeX special characters are rejected because `color` is placed
inside `\textcolor{...}{...}`.

Notebook-wide style can be configured with `set_display_defaults!(...)` and
cleared with `reset_display_defaults!()`. For temporary styles, use
`with_display_defaults(...) do ... end`. Explicit keywords override scoped
defaults, scoped defaults override process-wide defaults, and process-wide
defaults override the library defaults.

Defaults cover `setstyle`, `arraystyle`, `color`, `separator`,
`number_formatter`, `per_element_style`, `factor_out`, and `symopts`. Configure
`inline` and `lc` construction options such as `sign_policy`, `drop_zero`,
`omit_one`, `parens_coeff`, `plus`, `pos`, and `neg` explicitly at the call
site. Unknown `lc` option names throw `ArgumentError`.

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
