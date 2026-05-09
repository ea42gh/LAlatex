# Display Policy

This page documents the display policy for structured LaTeX helpers. These
helpers do not parse raw LaTeX equations. They render Julia values through the
same `L_show` machinery used for scalars, vectors, matrices, symbolic
expressions, strings, and `LaTeXString`s.

## `L_show` and `l_show`

`L_show(args...)` is the string-producing API. It renders each argument,
joins the rendered fragments with spaces, and returns a complete LaTeX math
string. By default the result is inline math with dollar delimiters and a
trailing newline:

```julia
L_show([1 2; 3 4])
```

Set `inline=false` when a Jupyter-Markdown-compatible display-math string is
needed:

```julia
L_show([1 2; 3 4]; inline=false)
```

This returns a `$$...$$` block, not `\[...\]`, because the string-producing API
is intended to be pasteable into Markdown cells.

`l_show(args...)` is the notebook-display API. It calls `L_show`, removes the
outer math delimiters, and returns a `LaTeXString`. This lets notebook and rich
display frontends choose the correct math rendering path for the value. Use
`L_show` when you need text to paste into Markdown, generated docs, logs, or
files. Use `l_show` when the result should display directly in a notebook cell.

The two functions intentionally share the same rendering options and object
support. A rendering difference between them is usually a delimiter/display
frontend issue, not a matrix or symbolic conversion issue.

## Text and math cells

Plain Julia strings are rendered as text:

```julia
L_show("otherwise")
```

Use `LaTeXString`s for math fragments:

```julia
L_show(L"x \in \mathcal{N}(A)")
```

This distinction also applies inside `cases` and `aligned`.

Plain strings are escaped and wrapped as text. `LaTeXString` values are treated
as already-authored LaTeX and are inserted as math fragments. If a condition,
label, or aligned cell should render in math mode, pass `L"..."` instead of a
plain string.

`LinearAlgebra.UniformScaling` values are rendered as math identity fragments,
not text. For example, `L_show(I)`, `L_show(0I)`, and `L_show(2I)` render as
`$I$`, `$0$`, and `$2 I$` rather than `\text{I}` or `\text{2 I}`.

## Cases

Use `cases` for piecewise definitions. Each entry may be written as a pair:

```julia
cases(value => condition)
```

or as a two-tuple:

```julia
cases((value, condition))
```

Each value and condition is rendered through the normal `L_show` policy.
Vectors render as column vectors, matrices render as matrices, symbolic
expressions honor `symopts`, and plain strings render as `\text{...}`.

Example:

```julia
@syms x y

L_show(
    "T(v) = ",
    cases(
        [x, 0] => L"v \in \operatorname{span}\{e_1\}",
        ([0, y], "otherwise"),
    ),
)
```

The current `cases` row policy is:

```latex
value, & condition \\
```

That means `cases` inserts the comma before the condition and the alignment
marker before the condition column. Users should not add `&` manually.

## Aligned

Use `aligned` for derivations, equation chains, and equivalence chains. Each
row may be a vector, tuple, or pair.

Vector row:

```julia
aligned([L"Ax", L"=", b])
```

Tuple row:

```julia
aligned((L"x", L"\in", L"\mathcal{N}(A)"))
```

Pair row:

```julia
aligned(L"Ax" => b)
```

For vector and tuple rows, every row cell is rendered with `L_show` and joined
with implicit LaTeX alignment markers:

```latex
cell_1 & cell_2 & cell_3 \\
```

For pair rows, `aligned(left => right)` is equivalent to:

```julia
aligned((left, L"=", right))
```

so it renders as:

```latex
left & = & right \\
```

Users should provide row cells and should not include `&` manually. If raw
LaTeX alignment is needed, pass a complete `LaTeXString` directly to `L_show`
instead of using `aligned`.

Example:

```julia
@syms x y

L_show(
    aligned(
        [L"Ax", L"=", [x, y]],
        (L"x", L"\in", L"\mathcal{N}(A)"),
        L"\dim\mathcal{N}(A)" => L"n - \operatorname{rank}(A)",
    ),
)
```

## Shared options

`cases` and `aligned` propagate display options into their cells:

- `arraystyle`
- `number_formatter`
- `per_element_style`
- `factor_out`
- `symopts`
- `color`

`set` also propagates these options and additionally uses `setstyle` and
`separator` for its delimiters and item separator.

Display option precedence is:

1. explicit keywords on the current call or container
2. scoped defaults from `with_display_defaults(...) do ... end`
3. process-wide defaults from `set_display_defaults!(...)`
4. library defaults

Top-level options passed to `L_show` provide defaults for every nested display
container. Options passed directly to a container override those defaults only
inside that container:

```julia
L_show(
    "S = ",
    set([1, 2], [3, 4]; arraystyle=:bmatrix, separator=L",\; ");
    arraystyle=:parray,
)
```

In this example the surrounding call defaults arrays to `:parray`, but arrays
inside the `set` render with `:bmatrix`, and the set uses its local separator.

Use process-wide defaults when a notebook should keep the same display style
across many cells:

```julia
set_display_defaults!(arraystyle=:bmatrix, separator=L";", symopts=(expand=true,))
L_show([1 2; 3 4])
reset_display_defaults!()
```

Use scoped defaults for a temporary style:

```julia
with_display_defaults(arraystyle=:vmatrix) do
    l_show("A = ", [1 2; 3 4])
end
```

Display defaults cover the shared rendering options that naturally propagate
through `L_show`, `l_show`, `set`, `cases`, `aligned`, `lc`, and matrix entries:
`setstyle`, `arraystyle`, `color`, `separator`, `number_formatter`,
`per_element_style`, `factor_out`, and `symopts`.

Display defaults intentionally do not include `inline`, because `L_show`
string output and `l_show` notebook-display output have different delimiter
contracts. Pass `inline=false` at the call site when a pasteable display-math
string is needed. Defaults also do not include `lc`-specific construction
options such as `sign_policy`, `drop_zero`, `omit_one`, `parens_coeff`, `plus`,
`pos`, or `neg`; set those on the `lc(...)` call so the linear-combination
policy remains visible where the expression is constructed. `lc(...)` rejects
unknown option names with `ArgumentError`.

Unknown container keyword arguments are ignored by the display-option merger.
Known container-local options are:

- `setstyle`
- `arraystyle`
- `color`
- `separator`
- `number_formatter`
- `per_element_style`
- `factor_out`
- `symopts`

`NamedTuple` display entries use those same names as local formatting
metadata. Matching key/value pairs are consumed as display options and are not
rendered as content. Put payload values under non-option keys such as `value`,
`label`, or `data`:

```julia
L_show((value=1//3, color="green"))
L_show((label="color", value="red"))
```

The first call renders the scalar with a local color option. The second call
renders the words `color` and `red` as content because neither `label` nor
`value` is a display-option key.

`color` accepts a LaTeX/xcolor color name or expression as a `String` or
`Symbol`, such as `"red"` or `"red!50!black"`. It rejects braces,
backslashes, control characters, and LaTeX special characters so the value
cannot break out of `\textcolor{...}{...}`.

For example:

```julia
L_show(
    aligned([(x + y)^2, L"=", x]);
    symopts=(expand=true,),
)
```

The symbolic expression is expanded before the aligned row is rendered.

`number_formatter` may return either a value for normal conversion or a raw
LaTeX fragment:

```julia
L_show("42 bold -> ", 42; number_formatter=x -> "\\textbf{$x}")
```

Because the formatter returns a string, `\\textbf{42}` is inserted as LaTeX
instead of being parsed as a Julia expression.

## Invalid rows

`cases` entries must be pairs or two-tuples. `aligned` rows must be pairs,
tuples, or vectors, and empty rows are rejected.
