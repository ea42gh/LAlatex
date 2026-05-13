import os
import sys
from fractions import Fraction
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
REQUIRE_INSTALLED = "--require-installed" in sys.argv

try:
    from lalatex import L, L_show, init, l_show
except ImportError:
    if REQUIRE_INSTALLED or os.environ.get("LALATEX_REQUIRE_INSTALLED_PYTHON_SHIM") == "1":
        raise
    sys.path.insert(0, str(ROOT / "python"))
    from lalatex import L, L_show, init, l_show


def main() -> None:
    project = Path(os.environ.get("LALATEX_PROJECT", ROOT))
    init(project=project)

    raw = L_show("x = ", 3, L(r";\quad "), "x^2 = ", 9)
    assert r";\quad " in raw, raw
    assert r"\text{;\textbackslash{}quad }" not in raw, raw

    matrix = L_show("A = ", [[1, 2], [3, 4]])
    assert r"\text{A = }" in matrix, matrix
    assert r"\begin{array}" in matrix, matrix

    bool_matrix = L_show("flags = ", [[True, False]])
    assert "true" in bool_matrix, bool_matrix
    assert "false" in bool_matrix, bool_matrix

    complex_matrix = L_show("z = ", [[1 + 2j, 3 - 4j]])
    assert r"1.0+2.0\mathit{i}" in complex_matrix, complex_matrix
    assert r"3.0-4.0\mathit{i}" in complex_matrix, complex_matrix

    rational_matrix = L_show(
        "B = ",
        [[Fraction(1, 2), Fraction(2, 3)]],
        factor_out=False,
    )
    assert r"\frac{1}{2}" in rational_matrix, rational_matrix
    assert r"\frac{2}{3}" in rational_matrix, rational_matrix

    try:
        L_show("bad = ", [[float("nan")]])
    except ValueError as err:
        assert "finite numbers" in str(err), err
    else:
        raise AssertionError("non-finite Python matrix entries must be rejected")

    try:
        L_show("empty = ", [[], []])
    except ValueError as err:
        assert "at least one row and one column" in str(err), err
    else:
        raise AssertionError("zero-column Python matrices must be rejected")

    try:
        L_show("ragged = ", [[1], [2, 3]])
    except ValueError as err:
        assert "rectangular" in str(err), err
    else:
        raise AssertionError("ragged Python matrices must be rejected")

    display_math = L_show(L(r"A = "), [[1, 2], [3, 4]], inline=False)
    assert display_math.startswith("$$"), display_math
    assert r"\text{A = }" not in display_math, display_math

    text_display_math = L_show("A = ", [[1, 2], [3, 4]], inline=False)
    assert text_display_math.startswith("$$"), text_display_math
    assert r"\text{A = }" in text_display_math, text_display_math

    returned = l_show("A = ", [[1, 2], [3, 4]], display_result=False)
    assert returned == matrix, returned

    print("Python interop smoke checks passed.")


if __name__ == "__main__":
    main()
