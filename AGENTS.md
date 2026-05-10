# LAlatex Follow-Up Work

Work through these items one step at a time. Keep changes scoped, add focused tests for each step, and run `julia --project=. -e "using Pkg; Pkg.test()"` before committing.

## Industry-Standard Enhancement Plan - 2026-05-07

Goal: improve the codebase quality score from about 3.6/5 to 4.3/5 or better while preserving all current public capabilities and adding tests for every behavior-preserving refactor.

Execution rules:
- Work one step at a time.
- Add or preserve tests before each risky refactor.
- Keep public API compatibility unless an intentional breaking change is explicitly requested.
- Run `julia --project=. test/runtests.jl` after each completed step.
- Run docs and notebook smoke checks before finalizing larger documentation or display-contract changes.
- Keep `AGENTS.md` local and uncommitted unless explicitly requested.

1. DONE - Lock public display behavior with focused contract tests.
   - Add tests proving `L_show(...)` returns a `String` with math delimiters and trailing newline.
   - Add tests proving `l_show(...)` returns a `LaTeXString` whose `text/latex` MIME payload is valid math.
   - Cover `inline=true`, `inline=false`, strings, `LaTeXString`, scalars, vectors, matrices, block arrays, `set`, `lc`, `cases`, and `aligned`.
   - Include regression coverage for the previous `l_show([1 2; 3 4])` delimiter failure.
   - Completed in `test/display_contracts.jl`, included from `test/runtests.jl`.
   - Verification: `julia --project=. test/runtests.jl` passed with `450 / 450`.

2. DONE - Split the monolithic test file into focused files.
   - Keep `test/runtests.jl` as the orchestrator.
   - Create focused files for display contracts, matrix rendering, symbolic rendering, containers, formatters, HTML helpers, and Python/SymPy interop.
   - Preserve all existing assertions during the split.
   - Completed with `test/public_exports.jl`, `test/backends.jl`, `test/html_helpers.jl`, `test/latex_helpers.jl`, `test/symbolic_display.jl`, `test/formatters.jl`, and `test/l_show_helpers.jl`.
   - Verification: `julia --project=. test/runtests.jl` passed with `450 / 450`.

3. DONE - Split `src/L_show.jl` into focused display modules without behavior changes.
   - Suggested files: `src/display/LShowPublic.jl`, `src/display/LShowCore.jl`, `src/display/MatrixDisplay.jl`, `src/display/Containers.jl`, `src/display/LinearCombinationDisplay.jl`, and `src/display/PythonDisplayInterop.jl`.
   - Keep exports and public function names unchanged.
   - Run the full test suite after each extraction or coherent group of extractions.
   - Completed with `src/display/MatrixDisplay.jl`, `src/display/Containers.jl`, `src/display/LinearCombinationDisplay.jl`, `src/display/LShowCore.jl`, and `src/display/LShowPublic.jl`.
   - Python/SymPy matrix interop remains inside `LShowCore.jl` for now and should be extracted during the PythonCall/SymPy hardening step.
   - Verification: `julia --project=. test/runtests.jl` passed with `450 / 450`.

4. DONE - Replace repeated loose option plumbing with an internal display-options type.
   - Introduce an internal immutable options/config representation.
   - Preserve the public keyword API.
   - Add tests for top-level option propagation, nested container option overrides, and invalid `symopts` errors.
   - Progress: added focused `test/display_options.jl` coverage for propagation, overrides, formatter/color propagation, `Dict`/`Pair`/`nothing` `symopts`, invalid `Bool` `symopts`, ignored unknown option keys, and local separator override precedence.
   - Progress: added internal `DisplayOptions` in `src/display/DisplayOptions.jl` and migrated container rendering (`set`, `cases`, `aligned`) to it.
   - Progress: fixed `normalize_symopts(:expand => true)` so the documented `Pair` compatibility works.
   - Progress: migrated top-level `L_show`, `L_show_core`, matrix rendering, container rendering, cases/aligned rendering, and linear-combination rendering to `DisplayOptions` while preserving keyword compatibility.
   - Progress: added regression coverage for top-level/core `arraystyle`, `separator`, `color`, `setstyle`, NamedTuple-local overrides, and direct `L_show_core` separator behavior.
   - Verification: `julia --project=. test/runtests.jl` passed with `482 / 482`.
   - Verification: `julia --project=. -e "using Pkg; Pkg.test()"` passed with `482 / 482` after rerunning with a longer timeout.

5. DONE - Harden PythonCall/SymPy error handling.
   - Replace broad fallback blocks with narrowly named helper probes.
   - Preserve graceful fallback behavior where currently intentional.
   - Add tests for SymPy scalar, SymPy matrix, non-SymPy Python objects, disabled PythonCall, and conversion fallback paths where practical.
   - Progress: extracted SymPy matrix shape/row conversion from `L_show_core` into narrow helper probes with explicit graceful fallbacks.
   - Progress: added tests for SymPy scalar fallback, direct SymPy matrix conversion, direct SymPy matrix `arraystyle` rendering, non-SymPy Python object handling, non-square and empty SymPy matrices, and disabled PythonCall startup.
   - Progress: hardened denominator factoring so denominator extraction and expansion are explicitly SymPy-only, while arbitrary Python objects leave mixed arrays unchanged.
   - Progress: narrowed symbolic transforms and LaTeX conversion to SymPy `Py` objects only; unsupported Python objects now raise clear `ArgumentError`s instead of SymPy/Python exceptions.
   - Progress: extracted PythonCall list/matrix conversion helpers for `lc(...)`, preserving Python-list coefficient/vector interop while keeping SymPy-only sign probes.
   - Verification: `julia --project=. test/runtests.jl` passed with `506 / 506`.
   - Verification: `julia --project=. -e "using Pkg; Pkg.test()"` passed with `430 / 430`; SymPy tests were skipped in that temporary environment after a Pixi/Rayon install panic, while the direct project test run exercised SymPy successfully.

6. DONE - Add golden snapshot tests for stable canonical LaTeX output.
   - Cover representative scalars, rationals, complex numbers, vectors, matrices, block arrays, symbolic expressions, `lc`, `cases`, and `aligned`.
   - Keep exact snapshots focused and use invariant tests where exact formatting is intentionally flexible.
   - Progress: added `test/golden_snapshots.jl` with exact snapshots for rationals, complex numbers, Symbolics monomials, numeric and symbolic vectors, numeric and symbolic matrices, block matrices, `set`, `lc`, `cases`, and `aligned`.
   - Verification: `julia --project=. test/runtests.jl` passed with `518 / 518`.
   - Verification: `julia --project=. -e "using Pkg; Pkg.test()"` passed with `518 / 518`.

7. DONE - Add display invariants and property-style checks.
   - Check balanced math delimiters.
   - Check no embedded `\begin{equation}` fragments inside rendered matrix entries.
   - Check no empty matrix cells such as ` &  & `.
   - Check `factor_out=false`, `drop_zero=true`, and formatter propagation invariants.
   - Completed in `test/display_invariants.jl` with representative outputs and focused option invariants.
   - Verification: `julia --project=. test/runtests.jl` passed with `619 / 619`.
   - Verification: `julia --project=. -e "using Pkg; Pkg.test()"` passed with `619 / 619`.

8. DONE - Layer tests and CI by cost.
   - Keep fast core tests independent of Python environment creation where possible.
   - Keep Symbolics and SymPy tests isolated enough to diagnose backend failures.
   - Ensure docs build and notebook smoke checks remain part of the larger verification path.
   - Added `LALATEX_TEST_SUITE=core` to run the full non-SymPy suite without the upfront SymPy probe.
   - Added a CI/macOS CI core test step with `LALATEX_DISABLE_PYTHONCALL=1` before the full test run.
   - Verification: `LALATEX_DISABLE_PYTHONCALL=1 LALATEX_TEST_SUITE=core julia --project=. test/runtests.jl` passed with `543 / 543`.
   - Verification: `julia --project=. test/runtests.jl` passed with `619 / 619`.
   - Verification: `julia --project=. -e "using Pkg; Pkg.test()"` passed with `619 / 619`.

9. DONE - Add lightweight static quality checks.
   - Consider `JuliaFormatter.jl`, `Aqua.jl`, and targeted `JET.jl` checks.
   - Start nonblocking if needed, then tighten once the codebase passes cleanly.
   - Progress: added an Aqua.jl test target with lightweight checks enabled and noisy/slow checks (`ambiguities`, `stale_deps`, `deps_compat`, `persistent_tasks`) disabled for the first pass.
   - Verification: `julia --project=. -e "using Pkg; Pkg.test()"` passed with `623 / 623`, including Aqua checks.
   - Verification: `LALATEX_DISABLE_PYTHONCALL=1 LALATEX_TEST_SUITE=core julia --project=. test/runtests.jl` passed with `543 / 543`; Aqua is skipped in direct project runs because test extras are only active under `Pkg.test()`.
   - Progress: applied a mechanical JuliaFormatter pass across `src` and `test`, then added JuliaFormatter as a test-only quality gate.
   - Decision: defer `JET.jl` until a separate typed-API pass; the current public surface intentionally accepts broad dynamic inputs, so a useful JET gate needs narrower targets.
   - Verification: `julia --project=. test/runtests.jl` passed with `619 / 619`.
   - Verification: `LALATEX_DISABLE_PYTHONCALL=1 LALATEX_TEST_SUITE=core julia --project=. test/runtests.jl` passed with `543 / 543`.
   - Verification: `julia --project=. -e "using Pkg; Pkg.test()"` passed with `624 / 624`, including Aqua and JuliaFormatter checks.
   - Follow-up: enabled the remaining Aqua checks and narrowed `stale_deps` to ignore only the intentional lazy `PythonCall` dependency.
   - Follow-up: added stdlib/test compat bounds required by Aqua `deps_compat`.
   - Follow-up: probed `JET.test_package`; the broad package gate still reports dynamic display callback paths, so JET remains a separate typed-API cleanup rather than a test gate.
   - Verification: `julia --project=. test/runtests.jl` passed with `621 / 621`.
   - Verification: `julia --project=. -e "using Pkg; Pkg.test()"` passed with `633 / 633`, including tightened Aqua and JuliaFormatter checks.

10. DONE - Update documentation for display contracts and option precedence.
    - Document the exact distinction between `L_show` and `l_show`.
    - Document plain string vs `LaTeXString` rendering.
    - Document top-level vs container-local option precedence.
    - Link this policy from README and API docs.
    - Progress: updated `docs/src/display-policy.md`, `docs/src/api.md`, `docs/src/index.md`, and `README.md`.
    - Verification: `julia --project=. -e "using Pkg; Pkg.test()"` passed with `624 / 624`, including Aqua and JuliaFormatter checks.
    - Verification: `julia --project=docs docs/make.jl` completed successfully.

Current status:
- Item 1 is complete in the working tree: `test/runtests.jl` now has a dedicated `Symbolic display policy` testset.
- Item 2 is complete in the working tree: scalar and matrix-entry LaTeX rendering now share private normalization helpers.
- Item 3 is complete in the working tree: `factor_out_denominator` policy is documented in the docstring and docs.
- Item 4 is complete in the working tree: direct SymPy denominator policy tests were added, and SymPy denominator extraction now handles additive scalar fractions via `sympy.together`.
- Item 5 is complete in the working tree: denominator factoring helpers and methods now live in `src/DenominatorFactoring.jl`, included before `src/L_show.jl`.
- Item 6 is complete in the working tree: direct Symbolics storage field access is isolated behind private helpers, denominator factoring reuses those helpers, and `lc` sign extraction now routes through `symbolic_term_coefficients`.
- Item 7 is complete in the working tree: exact-output snapshots now cover `L_show((3//10)^n)`, the `exp(-3t)` vector, `L_show("A10n=", power_matrix)`, and a representative signed `lc(...)` expression.
- Item 8 is complete in the working tree: top-level exports are grouped in `src/LAlatex.jl`, duplicate `factor_out_denominator` export was removed, and redundant formatter exports from `src/Formatters.jl` were removed.
- Item 9 is complete in the working tree: `docs/src/compatibility.md` now has a backend parity checklist, and `test/runtests.jl` has a focused `Backend parity checklist` testset for scalar rendering, matrix rendering, symbolic transforms, denominator factoring, power denominator policy, and `lc` sign handling across Symbolics and SymPy.
- Item 10 is complete in this planning file: the commit plan below separates behavior changes, refactors, tests, docs, and export cleanup so commits can stay reviewable.
- Commits pushed: `0bb9bd8 Refactor symbolic display handling` and `69a465a Add symbolic display parity tests`.
- Last verification: `Pkg.test()` passed with `284 / 284`; backend availability, numeric formatter, text escaping, Base-extension cleanup, and Symbolics public-API refactors are included in the passing suite.
- Latest verification on `main`: `Pkg.test()` passed with `295 / 295`, docs build passed, and GitHub Actions CI/docs are green on commit `cb9d2ab`.
- Latest verification on `main`: `Pkg.test()` passed with `306 / 306`, docs build passed, package version is `1.0.0`, and the `backend_available` API has been renamed to `backend_usable` on commit `8276f51`.
- Latest verification on `main`: `Pkg.test()` passed with `306 / 306`, docs build passed, notebook smoke checks passed, and GitHub Actions CI/docs are green on commit `8bbb2e6`.
- CI instability on 2026-04-23 was traced to brittle Symbolics term-order assertions in `test/runtests.jl`, not package behavior regressions. Tests now accept equivalent operand orderings (`x + y` vs `y + x`, `x - y` vs `-y + x`).
- CI workflow now pins `JULIA_PYTHONCALL_EXE` to the exact `actions/setup-python` interpreter path in both test and docs workflows, `julia-actions/setup-julia` has been updated to `v3`, and duplicate tag-triggered CI runs were removed.
- CI now includes a Windows lane (`windows-latest`, Julia `1.10`) in addition to the Ubuntu matrix.
- The first Windows-lane failure on 2026-04-24 was not a package failure; it died in the `Install Python deps` workflow step because the quoted Python-path invocation was being interpreted by PowerShell. The fix was to run that step under `bash` in `CI.yml`.
- Docs workflow now runs a notebook smoke check via `docs/smoke_notebooks.py` before building and deploying documentation.
- Release process is now documented in `RELEASING.md`, and README/docs include a 1.0 migration note covering `backend_usable(...)`.
- HTML helpers now validate CSS color strings and numeric sizing inputs instead of interpolating arbitrary style fragments.
- Current working-tree files include local review follow-up changes; `AGENTS.md` is excluded locally in `.git/info/exclude`.
- Follow-up completed: searched the broader `LA` workspace for `Backend.backend_available`/`backend_available`; remaining hits are intentional migration notes and the notebook smoke-test forbidden-snippet list.
- Follow-up completed: broad `JET.test_package` probe now reports only dynamic display callback/string-normalization paths after the Symbolics transform cleanup.
- The repository now has a formal `v1.0.0` GitHub Release object and a documented release checklist.
- Latest closeout verification on `main`: `julia --project=. test/runtests.jl` passed with `800 / 800`, `julia --project=. -e "using Pkg; Pkg.test()"` passed with `800 / 800`, no-Python core tests passed with `724 / 724`, notebook smoke checks passed, and the roadmap items below are complete through configurable display defaults and public option validation.
- `AGENTS.md` is a local planning file and should remain uncommitted unless explicitly requested.

## Code Review Findings - 2026-04-23

Work through these one step at a time. Add focused tests for each fix, then run `julia --project=. -e "using Pkg; Pkg.test()"`.

1. DONE - Make `Backend.backend_available(SymPyBackend)` reflect real availability.
   - Current implementation returns `false` even when `import_sympy()` works.
   - Use a guarded runtime check so documented availability does not produce false negatives.
   - Add tests for Symbolics availability and, when SymPy is importable, SymPy availability.
   - Follow-up completed: renamed the public API to `Backend.backend_usable(...)` to make the runtime-probe semantics clearer.

2. DONE - Correct numeric formatter semantics.
   - `scientific_formatter(100.0; digits=1)` currently returns `100.0e2.0`, which is not normalized scientific notation.
   - `exponential_formatter` has similar exponent formatting issues and should handle zero without `log10(0)`.
   - Update tests to assert normalized mantissa/exponent output.

3. DONE - Escape common LaTeX special characters in plain text.
   - `sanitize_text` currently escapes `_` and `$` only.
   - Escape `%`, `&`, `#`, `{`, `}`, and backslash for strings rendered inside `\text{...}`.
   - Add focused tests for representative special characters.

4. DONE - Reconsider global `Base.transpose` / `Base.adjoint` extensions.
   - `Base.transpose(::String)`, `Base.adjoint(::String)`, and related methods are package-wide side effects.
   - Prefer handling display transposes in `L_show_core` without extending Base methods for external types.
   - Add tests for the notebook ergonomics this was meant to preserve before removing the Base extensions.

5. DONE - Track Symbolics private-storage reliance.
   - Replaced package-side direct field access with public SymbolicUtils argument/coefficient helpers where practical.
   - Keep compat bounds tight and run upgrade tests before broadening Symbolics compat.

## Enhancement Roadmap

The current enhancement list is intentionally limited to cases/piecewise displays.
Keep `set()` as the public API for formatting mathematical sets.

1. DONE - Add `cases(...)` for piecewise displays.
   - Support entries written as `value => condition` or `(value, condition)`.
   - Render each value and condition through the existing `L_show` policy.
   - Support scalar, vector, matrix, symbolic, string, and `LaTeXString` values.
   - Add tests for vector-valued cases, symbolic `symopts`, plain-text conditions, LaTeX conditions, and invalid entries.
   - Add API and examples documentation.

2. DONE - Add `aligned(...)` for derivations and equivalence chains.
   - Support rows written as vectors, tuples, or pairs.
   - Insert LaTeX `&` alignment markers implicitly between row cells; users should not write `&`.
   - Render each cell through the existing `L_show` policy.
   - Add tests for vector rows, tuple rows, pair rows, symbolic `symopts`, and invalid rows.
   - Add API and examples documentation.

3. DONE - Document `cases(...)` and `aligned(...)` output policy.
   - Decide whether conditions should always be rendered as text for strings and math for `LaTeXString`.
   - Decide whether to add options for suppressing the comma before `&`, custom row separators, or aligned variants.
   - Added `docs/src/display-policy.md` covering entry forms, implicit alignment markers, shared options, and invalid rows.

## Packaging/CI Metadata Findings

Work through these one step at a time. Keep generated environment files out of commits, run the relevant tests or docs build after changes, and do not commit `AGENTS.md`.

1. DONE - Add missing direct dependency compatibility bounds.
   - `PythonCall` is a direct dependency and needs a `[compat]` entry.
   - Re-run package resolution or tests after changing package metadata.

2. DONE - Remove unused runtime dependency on `Revise`.
   - `Revise` appears to be a development helper only.
   - Remove it from `[deps]` and `[compat]` unless a real runtime use is added.

3. DONE - Consolidate duplicated docs deployment workflows.
   - `CI.yml` and `docs.yml` both deploy documentation.
   - Keep one docs deployment path and avoid races on `gh-pages`.

4. DONE - Ensure doctests run before docs deployment.
   - If the `CI.yml` docs job remains, move doctests before deployment.
   - If docs deployment is consolidated into `docs.yml`, ensure that path runs `makedocs`/doctests before `deploydocs`.

5. DONE - Stop tracking generated CondaPkg environment files.
   - Remove `.CondaPkg` and `docs/.CondaPkg` from the index while preserving local files.
   - Fix `.gitignore` typo from `.CondPkg/` to `.CondaPkg/`.

6. DONE - Normalize docs CI environment settings.
   - Use one documented Python/SymPy setup for docs builds.
   - Set `JULIA_CONDAPKG_BACKEND=Null` and `JULIA_PYTHONCALL_EXE=python` where docs build needs SymPy.
   - Follow-up completed: docs workflow now pins `JULIA_PYTHONCALL_EXE` to the exact `actions/setup-python` interpreter path, matching CI.

7. DONE - Clarify dependency-update ownership.
   - Dependabot covers GitHub Actions.
   - CompatHelper covers Julia package compat updates.

8. DONE - Align package versioning and release workflow.
   - `Project.toml` version now reads `1.0.0`.
   - Removed duplicate tag-triggered CI runs from `CI.yml`.
   - Repository tags should use `v1.0.0` going forward; older tags can remain as historical artifacts unless explicitly cleaned up.

## Capability Review Findings

Work through these one step at a time. Add focused tests for each finding before or with the fix, then run `julia --project=. -e "using Pkg; Pkg.test()"`.

1. DONE - BlockVector rendering is unsupported even though denominator factoring supports block vectors.
   - `L_show_core` routes `BlockVector` to `L_show_matrix`, but `construct_latex_matrix_body` assumes two-dimensional block axes and uses `size(A, 2)`.
   - `to_latex(A::BlockArray)` calls `Matrix(A)`, which fails for block vectors.
   - Preserve block-vector axes and render them as column vectors with horizontal block separators where practical.
   - Add tests for `L_show(BlockArray(...))` and `to_latex(BlockArray(...))` on a block vector.

2. DONE - `symopts` do not apply to complex symbolic values.
   - `symbolic_transform` should recurse into complex real and imaginary parts.
   - Matrix-entry symbolic detection should recognize `Complex{Symbolics.Num}` and complex PythonCall/SymPy parts.
   - Add scalar and matrix-entry tests for complex symbolic expansion.

3. DONE - `to_latex(::Vector)` catches ordinary vectors and returns malformed nested arrays.
   - Narrow the vector-of-matrices method or split it into a deliberately named helper.
   - Add tests for ordinary vectors and vector-of-matrices behavior.

4. DONE - Group/set display does not honor all display options.
   - Forward `factor_out` and symbolic options consistently through grouped display.
   - Handle empty `set()` without indexing `obj_latex[1]`.
   - Add tests for `set(...; factor_out=false)` and empty sets.

5. DONE - `number_formatter` runs before denominator factoring and changes factoring behavior.
   - Decide whether `number_formatter` is a value transform or a display-only formatter.
   - If it is display-only, move it later in the matrix-entry rendering pipeline.
   - Document the chosen policy and add a regression test.

6. DONE - Linear-combination display lacks input-length validation.
   - Raise a clear `ArgumentError` when coefficient count and vector/matrix count differ.
   - Add tests for too few and too many coefficients.

7. DONE - SymPy integer denominator extraction still narrows to `Int`.
   - Replace `Int(den_jl)` with a conversion path that preserves large integer denominators.
   - Add a targeted test for a SymPy rational denominator larger than `typemax(Int)`.

## DenominatorFactoring Review Findings

Work through these one step at a time. Add focused tests for each finding before or with the fix, then run `julia --project=. -e "using Pkg; Pkg.test()"`.

1. DONE - BlockArray factoring likely fails for block vectors.
   - Current `factor_out_denominator(A::BlockArray)` uses `Matrix(A)`, which assumes a two-dimensional block array.
   - Decide whether to support block vectors directly or narrow the method to block matrices.
   - Preserve original block dimensionality and block axes where practical.
   - Add tests for a block matrix and a block vector.

2. DONE - Empty rational vectors/matrices throw instead of returning a stable result.
   - Specialized rational methods use `reduce(lcm, denominator.(A))` without `init=1`.
   - Add tests for empty rational vector and empty rational matrix.
   - Decide whether empty rational arrays should return `(1, A)` unchanged or `(1, Int64.(A))`; prefer consistency with the generic method.

3. DONE - Rational support is narrower than the docstring implies.
   - Current direct array support targets `Rational{Int}`; non-`Int` rational entries fall through as generic numbers.
   - Decide whether the public policy is `Rational{Int}` only or all `Rational`.
   - If `Rational{Int}` only, update docs/docstrings explicitly.
   - If all `Rational`, broaden methods carefully and avoid unconditional `Int64` conversion.

4. DONE - Complex symbolic entries may not be expanded after denominator scaling.
   - The expansion guard checks whole entries for Symbolics values, so `Complex{Symbolics.Num}` may skip expansion.
   - Add a helper such as `_contains_symbolics(x)` that checks complex real/imaginary parts.
   - Add a test for complex symbolic entries whose real or imaginary part has a symbolic denominator.

## Commit Plan

1. Behavior fix: symbolic display and denominator policy.
   - Suggested message: `Fix symbolic LaTeX display policy`
   - Include: `src/L_show.jl`, `src/SymbolicDisplay.jl`, `src/DenominatorFactoring.jl`, and the behavior-focused portions of `test/runtests.jl`.
   - Scope: render Symbolics expressions without `equation` fragments, preserve rational-power parentheses, avoid factoring denominators out of powers/functions, handle SymPy additive scalar fractions with `sympy.together`, and keep `lc` symbolic sign handling consistent.

2. Refactor: denominator factoring file split and Symbolics helper encapsulation.
   - Suggested message: `Refactor symbolic denominator handling`
   - Include: `src/DenominatorFactoring.jl`, `src/LAlatex.jl`, `src/L_show.jl`, and `src/SymbolicDisplay.jl` hunks that only move helpers or isolate Symbolics storage access.
   - Scope: no intended display output changes beyond preserving the behavior fixed above.

3. Test coverage: symbolic policy, snapshots, exports, and backend parity.
   - Suggested message: `Add symbolic display policy tests`
   - Include: `test/runtests.jl`.
   - Scope: dedicated symbolic policy testset, exact snapshots for canonical regressions, export smoke test, and backend parity checklist testset.

4. Docs: denominator and backend parity policy.
   - Suggested message: `Document symbolic backend display policy`
   - Include: `docs/src/api.md`, `docs/src/examples.md`, and `docs/src/compatibility.md` if those files are dirty in the final diff.
   - Scope: document coefficient-level denominator factoring and backend parity expectations.

5. Cleanup: API export grouping.
   - Suggested message: `Clean up LAlatex exports`
   - Include: `src/LAlatex.jl`, `src/Formatters.jl`, and the export smoke test if it is not already committed with tests.
   - Scope: remove duplicate/redundant exports and group the public export list.

Practical note: the current working tree has overlapping hunks, especially in `src/L_show.jl`, `src/LAlatex.jl`, and `test/runtests.jl`. Use `git add -p` or equivalent patch staging to keep the split above. If a clean patch split becomes too noisy, prefer two commits: one behavior/refactor commit plus one tests/docs/export-cleanup commit.

## Symbolic Display Improvements

1. DONE - Add a dedicated symbolic display policy testset.
   - Group the high-risk symbolic rendering tests together instead of spreading them across generic LaTeX and `L_show` testsets.
   - Cover Symbolics scalar, vector, and matrix rendering.
   - Cover `exp`, trig, `log`, powers, rational powers, denominator factoring, `lc` sign policy, and SymPy parity.

2. DONE - Normalize SymPy and Symbolics rendering through clearer shared boundaries.
   - Consider private helpers such as `_to_latex_scalar(x; number_formatter=nothing)` and `_to_latex_matrix_entry(x; number_formatter=nothing)`.
   - Make `to_latex`, `L_show_core`, and matrix-entry rendering use the same scalar normalization path where possible.
   - Preserve the existing SymPy matrix special case so array styles still apply.

3. DONE - Document `factor_out_denominator` policy.
   - Factor denominators from literal rational entries.
   - Factor denominators from numeric coefficients in symbolic expressions.
   - Factor denominators from explicit scalar divisions such as `x / 2`.
   - Do not factor denominators buried inside powers or functions, such as `(3//10)^n`.
   - Do not factor denominators from non-scalar symbolic denominators, such as `x / (2y)`.

4. DONE - Add direct SymPy denominator policy tests.
   - Test `factor_out_denominator([a / 2 a])`.
   - Test `factor_out_denominator([(a + 1) / 2 a])`.
   - Test the SymPy equivalent of `(3//10)^n`, for example `sympy.Rational(3, 10)^a`, and verify it does not factor out `10`.

5. DONE - Move denominator factoring helpers into a dedicated section or file.
   - Consider `src/DenominatorFactoring.jl` if the helper group continues to grow.
   - Include it before `src/L_show.jl`.
   - Keep the public API unchanged.

6. DONE - Reduce reliance on Symbolics internals where practical.
   - The current code inspects `data`, `dict`, and `coeff` fields.
   - Keep these accesses encapsulated behind narrowly named helpers.
   - Add comments where the code intentionally performs coefficient-level extraction rather than full expression traversal.
   - Investigate whether SymbolicUtils has stable coefficient APIs that can replace direct field access.

7. DONE - Add a small number of exact-output snapshot tests.
   - Use exact tests only for canonical examples where output stability matters.
   - Suggested cases: `L_show((3//10)^n)`, the `exp(-3t)` vector, `L_show("A10n=", power_matrix)`, and a representative `lc(...)` signed expression.
   - Keep broader tests using `occursin` where exact formatting would be too brittle.

8. DONE - Clean up API exports.
   - Remove duplicate exports such as repeated `factor_out_denominator`.
   - Keep export ordering readable and grouped by feature.

9. DONE - Add a backend parity checklist.
   - For each symbolic feature, decide whether it should support Symbolics only, SymPy only, or both.
   - Reflect that decision in tests.
   - Pay special attention to denominator factoring, scalar LaTeX normalization, matrix rendering, and `lc` sign handling.

10. DONE - Keep refactors separate from behavior changes.
    - Commit cleanup-only changes separately from display behavior fixes.
    - Prefer commit messages that state the intent, such as `Refactor symbolic denominator handling` or `Add symbolic display policy tests`.

## Code Review Remediation Plan - 2026-05-08

Current stringent industry score estimate: **4.2 / 5 stars**.

Scorecard:
- Correctness: 4.1 - strong core behavior coverage; remaining edge cases are
  `NamedTuple` local `symopts`, `UniformScaling`, and title validation.
- Test coverage: 4.5 - broad contract, snapshot, invariant, backend, quality,
  and CI coverage; add tests for each review finding.
- Maintainability: 4.2 - display modules are split well; dynamic callback paths
  and broad display surfaces still limit static reasoning.
- API design: 4.0 - practical public API, but option validation and error
  contracts need tightening.
- Error handling: 4.0 - Python/SymPy handling is much better; public helpers
  should avoid leaking low-level errors such as `BoundsError`.
- Documentation: 4.3 - good policy docs; remaining Symbolics transform wording
  needs alignment across compatibility docs and notebooks.
- CI/quality gates: 4.5 - multi-OS CI, docs, notebook smoke, no-Python core,
  Aqua, and JuliaFormatter are active; CompatHelper failure should be
  investigated separately.
- Static analysis/type robustness: 3.6 - broad JET is not yet clean; target
  typed internal paths after review fixes.
- Security/injection safety: 4.1 - HTML escaping and `RawHTML` are explicit;
  keep validating public HTML inputs.
- Performance/precompile: 4.0 - precompile workload exists; benchmark
  regression thresholds would improve confidence later.

Expected score impact:
- Completing items 1-4 should move the codebase toward **4.4 / 5**.
- Completing item 5 with a stable targeted JET layer and stricter public API
  validation should make **4.6 / 5** realistic.

Work through these one at a time. Add focused tests with each behavior change,
run `julia --project=. test/runtests.jl`, then run
`julia --project=. -e "using Pkg; Pkg.test()"` before committing. Run
`julia --project=docs docs/make.jl` for documentation-only or documentation-
affecting steps.

1. DONE - Fix `NamedTuple` entry-local `symopts` handling.
   - Metrics improved: correctness, API design, documentation consistency,
     static-analysis clarity.
   - Problem: `L_show((value=(x+y)^2, symopts=(expand=true,)))` treats
     `symopts` as display content and can render option values such as `true`.
   - Change: include `:symopts` in the `NamedTuple` local option filter in
     `L_show_core`, or deliberately reject option-like keys if per-entry
     `symopts` should not be supported.
   - Preferred behavior: support per-entry `symopts`, matching the documented
     display-option list.
   - Tests: add coverage that a `NamedTuple` entry with local `symopts` expands
     Symbolics expressions and does not render the option tuple/value itself.
   - Tests: preserve existing local `arraystyle` and top-level/container
     precedence behavior.
   - Progress: added `:symopts` to the `NamedTuple` local option filter in
     `L_show_core`.
   - Progress: added display-option regression coverage for local `symopts`
     expansion and for not rendering option values such as `true`.
   - Verification: `julia --project=. test/runtests.jl` passed with
     `624 / 624`.
   - Verification: `julia --project=. -e "using Pkg; Pkg.test()"` passed with
     `636 / 636`, including tightened Aqua and JuliaFormatter checks.
   - Follow-up regression: `L_show(...; inline=false)` returned `\[`/`\]`
     display delimiters, which are not pasteable into Jupyter Markdown cells.
   - Progress: changed `L_show(...; inline=false)` to return a `$$...$$`
     display block and kept `l_show(...; inline=false)` on a notebook-safe
     `LaTeXString` payload without nested display delimiters.
   - Progress: installed `Aqua` and `JuliaFormatter` in the active project
     environment and configured stale-dependency checks to treat them as
     project tooling.
   - Verification: reproduced `L_show("centered: A = ", A; inline=false)` as a
     `$$...$$` block and confirmed the `l_show` MIME payload is `$...$` without
     inner display delimiters.
   - Verification: `julia --project=. test/runtests.jl` passed with
     `712 / 712`.
   - Verification: `julia --project=. -e "using Pkg; Pkg.test()"` passed with
     `712 / 712`, including Aqua and JuliaFormatter checks.

2. DONE - Render `UniformScaling` values as math, not text.
   - Metrics improved: correctness, display API consistency, test coverage.
   - Problem: `L_show(I)` currently renders `\text{I}` through
     `L_show_string`, which is inconsistent with linear-algebra math display.
   - Change: render `I`, `0`, and scaled identities as raw math fragments while
     preserving `color` wrapping.
   - Tests: add display-contract coverage for `I`, `0I`, and `2I`, asserting
     math output and no `\text{I}` wrapper.
   - Compatibility note: if text rendering is deemed intentional, document that
     explicitly instead of changing behavior.
   - Progress: routed `UniformScaling` display through raw math fragments with
     existing color wrapping, avoiding `\text{...}` for `I`, `0`, and scaled
     identities.
   - Verification: `julia --project=. test/runtests.jl` passed with
     `754 / 754`.
   - Verification: `julia --project=. -e "using Pkg; Pkg.test()"` passed with
     `754 / 754`, including Aqua and JuliaFormatter checks.

3. DONE - Validate `show_side_by_side_html` title lengths.
   - Metrics improved: error handling, API design, security/input hygiene.
   - Problem: fewer titles than outputs raises a raw `BoundsError`; extra
     titles are silently ignored.
   - Change: validate `titles` length against `captured_outputs` length and
     throw a clear `ArgumentError` on mismatch.
   - Tests: add HTML helper tests for matching titles, too few titles, and too
     many titles.
   - Preserve current escaping behavior for text outputs and titles, and
     preserve `RawHTML` behavior for explicitly trusted content.
   - Progress: `show_side_by_side_html` now validates provided title count
     before rendering and throws a clear `ArgumentError` for too few or too
     many titles.
   - Verification: `julia --project=. test/runtests.jl` passed with
     `756 / 756`.
   - Verification: `julia --project=. -e "using Pkg; Pkg.test()"` passed with
     `756 / 756`, including Aqua and JuliaFormatter checks.

4. DONE - Align Symbolics transform documentation.
   - Metrics improved: documentation, API design, user trust.
   - Problem: `docs/src/api.md` says Symbolics `factor` and `collect` are
     no-ops, but `docs/src/compatibility.md` and some notebooks/examples still
     describe them generically as supported where available.
   - Change: implement Symbolics `factor` and `collect` support, then update
     compatibility docs and notebook/example prose to describe the implemented
     policy.
   - Tests/checks: run docs build and notebook smoke checks if notebooks are
     edited.
   - Progress: added conservative Symbolics common-factor extraction for
     additive expressions and collect-by-variable grouping for polynomial-like
     additive terms.
   - Progress: updated API, compatibility, examples, and notebook prose so
     Symbolics `factor`/`collect` are documented as supported rather than
     no-ops.
   - Verification: `julia --project=. test/runtests.jl` passed with
     `759 / 759`.
   - Verification: `python docs/smoke_notebooks.py` passed.
   - Verification: `julia --project=docs docs/make.jl` passed.
   - Verification: `julia --project=. -e "using Pkg; Pkg.test()"` passed with
     `759 / 759`, including Aqua and JuliaFormatter checks.

5. DONE - Reassess JET after the targeted fixes.
   - Metrics improved: static analysis/type robustness, maintainability.
   - Problem: broad `JET.test_package` still reports dynamic display callback
     paths, mostly around string-like callback outputs and regex captures.
   - Change: after items 1-3, rerun a temporary JET probe and decide whether
     any remaining reports are actionable defects or acceptable dynamic API
     boundaries.
   - Do not add JET as a required quality gate until the probe is clean or
     narrowly targeted enough to be stable.
   - Progress: ran JET in a temporary Julia environment so no package
     dependency or test-gate change was added.
   - Result: broad `JET.test_package(LAlatex)` with definition analysis enabled
     failed inside JET on Julia 1.12 with `Expected MethodTableView`, before
     producing package diagnostics.
   - Result: `JET.test_package(LAlatex; analyze_from_definitions=false)`
     completed successfully but is too shallow to justify a CI gate.
   - Result: targeted `JET.@report_call` probes on stable paths produced no
     diagnostics for `L_show([1 2; 3 4])`, `L_show(x^2 + x*y;
     symopts=(factor=true,))`, `symbolic_transform(...; collect=x)`, or
     `to_latex(3//4)`.
   - Decision: broad `JET.test_package` remains unsuitable as a required gate
     until the upstream/toolchain failure is resolved, but the project now has
     a narrowly targeted stable JET test file for LAlatex-owned scalar
     conversion and option-validation paths.
   - Progress: added `test/jet_checks.jl`, included it from `test/runtests.jl`,
     and added JET as project tooling with Aqua stale-dependency handling.
   - Verification: `julia --project=. test/runtests.jl` passed with
     `823 / 823`.
   - Verification: `julia --project=. -e "using Pkg; Pkg.test()"` passed; the
     isolated package-test environment skipped SymPy integration tests after the
     known Pixi/Rayon setup panic, while the direct suite covered all 823 tests.

6. DONE - Investigate CompatHelper automation failure.
   - Metrics improved: CI/quality gates, repository operations.
   - Problem: package CI and docs were green on the last checked pushed commit,
     but CompatHelper was failing independently.
   - Change: inspect the failed CompatHelper run logs, determine whether this
     is permissions, workflow drift, registry access, or dependency metadata,
     and fix the workflow if needed.
   - Tests/checks: rerun or wait for the next CompatHelper workflow after the
     fix; do not conflate this with package test failures.
   - Progress: queried public GitHub Actions metadata for the latest failed
     CompatHelper run. Failure occurred in the `Run CompatHelper` step after
     `Install CompatHelper` succeeded.
   - Finding: raw log download requires repository admin auth, but the workflow
     was missing the `permissions: contents: write` and `pull-requests: write`
     block from CompatHelper's bundled GitHub Actions workflow. That matches a
     run-step failure when CompatHelper attempts to create/update PR branches.
   - Change: updated `.github/workflows/CompatHelper.yml` to include explicit
     write permissions, Julia setup, General registry initialization, and a
     pinned CompatHelper v3 install.
   - Verification: local temp-environment `Pkg.add("CompatHelper"); using
     CompatHelper` succeeds, and `julia --project=. -e "using Pkg;
     Pkg.status()"` succeeds.
   - Follow-up: rerun the workflow manually after commit/push or wait for the
     next scheduled run; unauthenticated public API access cannot dispatch or
     download logs.

7. DONE - Add stricter public option validation after behavior fixes.
   - Metrics improved: API design, error handling, static-analysis clarity.
   - Candidate options: `arraystyle`, `setstyle`, `sign_policy`, formatter
     return values, and display callback return values.
   - Change: prefer clear `ArgumentError`s for unsupported values instead of
     accidental `MethodError`, `BoundsError`, or malformed LaTeX output.
   - Tests: add focused invalid-option tests for each validator before or with
     the implementation.
   - Progress: completed the first validation slice for `arraystyle` and
     `setstyle`. Invalid or non-symbol styles now throw `ArgumentError` from
     public option construction instead of silently falling back to `:array` or
     leaking `MethodError`.
   - Verification: `julia --project=. test/runtests.jl` passed with
     `763 / 763`.
   - Verification: `julia --project=. -e "using Pkg; Pkg.test()"` passed with
     `763 / 763`, including Aqua and JuliaFormatter checks.
   - Progress: completed the second validation slice for `lc(...;
     sign_policy=...)`. Unsupported symbol or string values now throw clear
     `ArgumentError`s instead of silently using signed rendering.
   - Verification: `julia --project=. test/runtests.jl` passed with
     `765 / 765`.
   - Verification: `julia --project=. -e "using Pkg; Pkg.test()"` passed with
     `765 / 765`, including Aqua and JuliaFormatter checks.
   - Progress: completed the third validation slice for callback return
     contracts. `number_formatter` now accepts only `Number`, `String`, or
     `LaTeXString` results, and `per_element_style` accepts only `String` or
     `LaTeXString` fragments; unsupported returns raise clear
     `ArgumentError`s.
   - Verification: `julia --project=. test/runtests.jl` passed with
     `772 / 772`.
   - Verification: `julia --project=. -e "using Pkg; Pkg.test()"` passed with
     `772 / 772`, including Aqua and JuliaFormatter checks.
   - Progress: completed the fourth validation slice for `factor_out`.
     Top-level calls, container-local overrides, `lc(...)` overrides, and
     display defaults now reject non-boolean `factor_out` values with clear
     `ArgumentError`s.
   - Verification: `julia --project=. test/runtests.jl` passed with
     `800 / 800`.
   - Verification: `julia --project=. -e "using Pkg; Pkg.test()"` passed with
     `800 / 800`, including Aqua and JuliaFormatter checks.

8. DONE - Add performance regression guardrails after correctness work.
   - Metrics improved: performance/precompile, release confidence.
   - Change: review `perf/benchmark.jl` and decide whether to add documented
     baseline commands, CI-optional benchmarks, or lightweight allocation
     assertions for representative display paths.
   - Keep benchmarks advisory unless they are stable enough across CI
     platforms.
   - Progress: added a focused `test/performance_guardrails.jl` suite with
     warmed allocation ceilings for numeric matrix, rational matrix,
     `lc(...)`, and Symbolics expansion render paths.
   - Progress: updated `perf/benchmark.jl` so the advisory benchmark reports
     both elapsed time and allocated bytes.
   - Progress: updated README and quickstart benchmarking text for the new
     allocation reporting.
   - Verification: `julia --project=. test/runtests.jl` passed with
     `776 / 776`.
   - Verification: `julia --project=. -e "using Pkg; Pkg.test()"` passed with
     `776 / 776`, including Aqua and JuliaFormatter checks.
   - Verification: `julia --project=. perf/benchmark.jl` completed and printed
     elapsed-time/allocation rows for matrix, `l_show`, `lc`, Symbolics, and
     SymPy paths.
   - Verification: `julia --project=docs docs/make.jl` passed.

9. DONE - Add configurable display defaults for notebook workflows.
   - Metrics improved: API ergonomics, documentation, consistency across
     notebooks.
   - Problem: users repeat the same display options across `L_show`, `l_show`,
     `lc`, `aligned`, `cases`, and `set` calls when they want a consistent
     notebook style.
   - Change: design a central default-options mechanism, preferably with both
     a global setter such as `set_display_defaults!(...)` and a scoped helper
     such as `with_display_defaults(...) do ... end`.
   - Precedence policy: explicit function/container kwargs override scoped
     defaults; scoped defaults override global defaults; global defaults
     override hardcoded library defaults.
   - Initial candidates: `arraystyle`, `setstyle`, `separator`, `factor_out`,
     `symopts`, `number_formatter`, and possibly `color`.
   - Caution: avoid making `inline` a global default unless the `L_show`
     string-output contract and `l_show` notebook-display contract are both
     explicitly documented; be careful with global `per_element_style` because
     it can obscure debugging.
   - Tests: add focused precedence tests for explicit kwargs, scoped defaults,
     global defaults, nested containers, and reset behavior. Ensure existing
     behavior is unchanged when no defaults are configured.
   - Docs: document the mechanism in the display policy and include notebook-
     oriented examples.
   - Progress: added `set_display_defaults!`, `reset_display_defaults!`,
     `display_defaults`, and `with_display_defaults`.
   - Progress: display defaults now flow through `DisplayOptions` with explicit
     keyword precedence preserved by an internal unset sentinel.
   - Progress: global defaults, task-local scoped defaults, explicit keyword
     overrides, nested container overrides, `symopts`, `l_show`, explicit
     `nothing`, invalid options, and reset behavior are covered in
     `test/display_defaults.jl`.
   - Progress: display policy and API docs now document default precedence and
     notebook-oriented examples.
   - Progress: examples and the L_show notebook guide now include concrete
     process-wide defaults, scoped defaults, explicit override, and reset
     examples. The L_show notebook output was refreshed so `inline=false`
     examples show Jupyter-Markdown-compatible `$$...$$` blocks rather than
     `\[...\]`.
   - Verification: `julia --project=. test/runtests.jl` passed with
     `794 / 794`.
   - Verification: `julia --project=. -e "using Pkg; Pkg.test()"` passed with
     `794 / 794`, including Aqua and JuliaFormatter checks.
   - Verification: `julia --project=docs docs/make.jl` passed.
   - Latest verification: `python docs/smoke_notebooks.py` passed.
   - Latest verification: `julia --project=docs docs/make.jl` passed.
   - Latest verification: `julia --project=. test/runtests.jl` passed with
     `823 / 823`.

## Next Review Round

The 2026-05-08 remediation plan is complete. The next useful step is a fresh
stringent review against the current `main` branch, then a new short plan if
the review finds worthwhile issues. Suggested review focus:

1. Public API consistency after display defaults and option validation.
2. Static-analysis boundaries that still prevent broader JET coverage.
3. Documentation/example drift across Markdown pages and notebooks.
4. CI and dependency-health status, especially CompatHelper and the
   upstream/toolchain SymPy package-test environment issue.
5. Performance guardrail stability after the added display-defaults plumbing.

## Fresh Stringent Review - 2026-05-10

Current score estimate: **4.45 / 5 stars**.

Scorecard:
- Correctness: 4.5 - public display contracts, symbolic parity checks,
  golden snapshots, invariants, and backend tests are strong.
- Test coverage: 4.7 - broad direct tests, package tests, docs smoke checks,
  notebook execution checks, Aqua, JuliaFormatter, targeted JET, and
  performance guardrails are active.
- Maintainability: 4.3 - display modules and option handling are well split;
  symbolic transforms remain the densest and most upstream-sensitive area.
- API consistency: 4.5 - exact export tests, API-doc export coverage, option
  validation, and explicit display contracts are now in place.
- Error handling: 4.4 - most public helpers now throw clear `ArgumentError`s;
  remaining dynamic backend fallbacks are intentionally defensive.
- Documentation: 4.6 - policy docs, API docs, notebooks, README, migration,
  installation, and toolchain notes are aligned and smoke-checked.
- CI/automation: 4.6 - multi-OS package CI, docs checks/deploy separation,
  workflow concurrency, CompatHelper permissions, and dependency tooling are
  covered.
- Static analysis/type robustness: 3.9 - targeted JET checks are useful, but
  broad package JET remains unsuitable because of dynamic display and tooling
  boundaries.
- Security/input hygiene: 4.4 - HTML escaping/sanitization, color validation,
  formatter validation, and NumPy destination-name validation are covered.
- Performance/precompile confidence: 4.2 - precompile workload, advisory
  benchmarks, and allocation guardrails exist; trend tracking is still absent.

Findings:

1. Symbolics integration remains the main fragility point.
   - `src/SymbolicDisplay.jl` still spreads `Symbolics.SymbolicUtils`
     assumptions and defensive fallback paths across many helpers.
   - Tests are strong, but upstream Symbolics representation changes remain
     the highest regression risk.

2. Global display defaults are mutable process state.
   - `GLOBAL_DISPLAY_DEFAULTS` is process-wide mutable state, while scoped
     defaults are task-local.
   - This is acceptable for notebooks, but thread semantics are not yet
     explicitly documented or protected by a lock.

3. Static analysis is targeted rather than broad.
   - `test/jet_checks.jl` covers selected stable internal paths.
   - Broad `JET.test_package` is still not a required quality gate because it
     is not stable enough for this dynamic display API and current toolchain.

4. Docs CI only builds on Julia 1.10.
   - Package CI covers newer Julia versions, but docs generation itself is not
     exercised on latest stable Julia.

Improvement plan to push ratings higher:

1. Add a thin internal Symbolics adapter layer.
   - Centralize calls to `Symbolics.SymbolicUtils` behind narrow helpers.
   - Add focused tests for each adapter behavior used by symbolic display,
     denominator factoring, collection, factoring, and coefficient extraction.
   - Pre-release progress: added `src/SymbolicsAdapter.jl` and routed package
     `Symbolics.SymbolicUtils` access through it, leaving direct access
     centralized in one file. Added adapter-focused symbolic display tests.

2. Expand targeted JET coverage.
   - Add typed probes for matrix rendering, `lc`, denominator factoring, and
     the new Symbolics adapter helpers.
   - Keep broad `JET.test_package` out of CI until it is clean and stable.
   - Pre-release progress: added targeted JET probes for stable Symbolics
     adapter literal handling and symbolic-option normalization. Expression
     tree traversal remains covered by runtime tests because JET reports
     upstream SymbolicUtils inference noise on those paths.

3. Define display-default concurrency semantics.
   - Either document `set_display_defaults!` as process-wide notebook state
     not intended for concurrent mutation, or protect mutation/reset with a
     lock.
   - Add tests for scoped defaults restoring correctly after nested tasks where
     practical.
   - Pre-release progress: protected global display-default reads, mutation,
     and reset with a `ReentrantLock`; documented process-wide versus
     task-local semantics; added nested-task restoration coverage.

4. Add a latest-stable docs CI lane.
   - Keep Julia 1.10 as the minimum-supported docs build.
   - Add latest stable as a non-deploy docs check so generated docs are tested
     against the modern toolchain.
   - Pre-release progress: docs-check now runs a Julia matrix over `1.10` and
     latest stable (`1`); deploy-docs remains pinned to the stable deploy path.

5. Add more property-style display invariants.
   - Generate small numeric/rational matrices, containers, and `lc` inputs.
   - Assert balanced delimiters, no empty cells, no nested display math, and
     stable option propagation without relying on brittle exact output.
   - Pre-release progress: expanded invariant coverage across array styles and
     symbolic transform options, including explicit checks that string output
     remains `$...$`/`$$...$$` pasteable rather than `\[...\]`.

6. Improve performance trend visibility.
   - Keep CI guardrails broad and stable.
   - Add optional local baseline output or comparison tooling for allocations
     and latency so regressions are easier to spot before release.
   - Pre-release progress: benchmark output now includes timestamp, Julia
     version, thread count, and active project for release-prep comparison.

Expected score impact:
- Completing items 1-4 should move the codebase toward **4.6 / 5**.
- Completing items 5-6 should make **4.65-4.75 / 5** realistic.
- The remaining gap is mostly inherent dynamic display and symbolic-backend
  complexity.

## Future Capability Enhancements

These are candidate user-facing capabilities for `l_show`, `L_show`, `lc`,
`set`, and related display helpers. Treat them as future enhancement ideas, not
current bug fixes. Preserve existing display contracts and add focused tests,
docs, and notebook examples for any item that is implemented.

Priority candidates:

1. Add augmented matrix support.
   - Candidate API: `augmented(A, b)` or an explicit display container.
   - Render `[A | b]` cleanly for systems and row-reduction examples.
   - Support vectors, matrices, symbolic entries, block arrays where practical,
     denominator factoring, `arraystyle`, and per-element formatting.

2. Add set-builder notation.
   - Candidate API: `setbuilder(expr, condition)` or
     `set_builder(expr, condition)`.
   - Render examples such as `{x \in R^n : Ax = 0}` without hand-written
     LaTeX.
   - Reuse existing string-vs-`LaTeXString` policy and display-option
     propagation.

3. Add simultaneous-equation/system display.
   - Candidate API: `system(rows...)`.
   - Render aligned systems of equations or constraints using a clear row
     policy distinct from `cases`.
   - Reuse `aligned` cell rendering where possible.

4. Add `lc` layout modes.
   - Candidate API: `lc(...; layout=:inline | :aligned | :column)`.
   - Keep current behavior as the default.
   - Use aligned/column layouts for long linear combinations so each term can
     appear on its own row.

Additional candidates:

5. Add equation tagging/labeling.
   - Candidate API: `L_show(...; tag="1.2")` or a display container wrapper.
   - Needs a careful `L_show` vs `l_show` delimiter policy for Jupyter,
     Markdown, and Documenter.

6. Add row and column labels for matrices.
   - Candidate API: matrix display options such as `row_labels=` and
     `col_labels=`.
   - Useful for basis coordinates, transformations, Markov chains, and
     augmented systems.
   - Must define behavior with block arrays, transposes, and denominator
     factoring.

7. Add basis/span helpers.
   - Candidate APIs: `span(v1, v2, ...)`, `basis(v1, v2; name="B")`.
   - Prefer display-only helpers that compose existing `set`, matrix, and
     text/math rendering policy.

8. Add inner-product and norm display helpers.
   - Candidate APIs: `inner(u, v)`, `norm_expr(v; p=2)`.
   - Keep them as notation/display helpers, not algebra engines.

Implementation rules for future capabilities:
- Start with one capability at a time.
- Define the exact public display contract before implementation.
- Add tests for `L_show`, `l_show`, plain strings, `LaTeXString`, symbolic
  values, option propagation, invalid inputs, and docs examples.
- Add notebook smoke/drift guards for any user-facing prose or examples.
- Keep new helpers composable with `set_display_defaults!` and
  `with_display_defaults` only when the options are true display options.
