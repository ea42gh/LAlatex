import os
import sys
from decimal import Decimal
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


def check(condition: bool, value: object) -> None:
    if not condition:
        raise AssertionError(value)


def main() -> None:
    project = Path(os.environ.get("LALATEX_PROJECT", ROOT))

    try:
        L(3)
    except TypeError as err:
        check("expects a Python string" in str(err), err)
    else:
        raise AssertionError("L(...) must reject non-string values.")

    init(project=project)

    raw = L_show("x = ", 3, L(r";\quad "), "x^2 = ", 9)
    check(r";\quad " in raw, raw)
    check(r"\text{;\textbackslash{}quad }" not in raw, raw)

    raw_separator = L_show("vector = ", [1, 2, 3], separator=L(r";\quad "))
    check(r";\quad " in raw_separator, raw_separator)
    check(r"\text{;\textbackslash{}quad }" not in raw_separator, raw_separator)

    tuple_vector = L_show("tuple vector = ", (1, 2, 3))
    check(r"\left(\begin{array}" in tuple_vector, tuple_vector)

    try:
        L_show("bad vector = ", [float("inf")])
    except ValueError as err:
        check("finite numbers" in str(err), err)
    else:
        raise AssertionError("Non-finite Python vector entries must be rejected.")

    try:
        L_show("empty vector = ", [])
    except ValueError as err:
        check("at least one entry" in str(err), err)
    else:
        raise AssertionError("Empty Python list vectors must be rejected.")

    try:
        L_show("empty vector = ", ())
    except ValueError as err:
        check("at least one entry" in str(err), err)
    else:
        raise AssertionError("Empty Python tuple vectors must be rejected.")

    try:
        L_show("bad vector = ", [Decimal("1.5")])
    except TypeError as err:
        check("Python numeric entries" in str(err), err)
    else:
        raise AssertionError("Unsupported Python vector entries must be rejected.")

    matrix = L_show("A = ", [[1, 2], [3, 4]])
    check(r"\text{A = }" in matrix, matrix)
    check(r"\begin{array}" in matrix, matrix)

    bool_matrix = L_show("flags = ", [[True, False]])
    check("true" in bool_matrix, bool_matrix)
    check("false" in bool_matrix, bool_matrix)

    complex_matrix = L_show("z = ", [[1 + 2j, 3 - 4j]])
    check(r"1.0+2.0\mathit{i}" in complex_matrix, complex_matrix)
    check(r"3.0-4.0\mathit{i}" in complex_matrix, complex_matrix)

    rational_matrix = L_show(
        "B = ",
        [[Fraction(1, 2), Fraction(2, 3)]],
        factor_out=False,
    )
    check(r"\frac{1}{2}" in rational_matrix, rational_matrix)
    check(r"\frac{2}{3}" in rational_matrix, rational_matrix)

    try:
        L_show("bad = ", [[float("nan")]])
    except ValueError as err:
        check("finite numbers" in str(err), err)
    else:
        raise AssertionError("non-finite Python matrix entries must be rejected")

    try:
        L_show("empty = ", [[], []])
    except ValueError as err:
        check("at least one row and one column" in str(err), err)
    else:
        raise AssertionError("zero-column Python matrices must be rejected")

    try:
        L_show("ragged = ", [[1], [2, 3]])
    except ValueError as err:
        check("rectangular" in str(err), err)
    else:
        raise AssertionError("ragged Python matrices must be rejected")

    display_math = L_show(L(r"A = "), [[1, 2], [3, 4]], inline=False)
    check(display_math.startswith("$$"), display_math)
    check(r"\text{A = }" not in display_math, display_math)

    text_display_math = L_show("A = ", [[1, 2], [3, 4]], inline=False)
    check(text_display_math.startswith("$$"), text_display_math)
    check(r"\text{A = }" in text_display_math, text_display_math)

    tagged_display_math = L_show(
        L(r"x = y"),
        inline=False,
        tag=L(r"\ast"),
        label="eq:python-interop",
    )
    check(tagged_display_math.startswith("$$"), tagged_display_math)
    check(r"\tag{\ast} \label{eq:python-interop}" in tagged_display_math, tagged_display_math)
    check(r"\textbackslash{}ast" not in tagged_display_math, tagged_display_math)

    returned = l_show("A = ", [[1, 2], [3, 4]], display_result=False)
    check(returned == matrix, returned)

    print("Python interop smoke checks passed.")


if __name__ == "__main__":
    main()
