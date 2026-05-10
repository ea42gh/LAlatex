import json
from pathlib import Path


ROOT = Path(__file__).resolve().parent
REPO_ROOT = ROOT.parent
NOTEBOOK_DIR = ROOT / "src" / "notebooks"
EXPECTED_NOTEBOOKS = [
    "LAlatex_basics.ipynb",
    "LAlatex_L_show_Guide.ipynb",
    "LAlatex_cases_Guide.ipynb",
    "LAlatex_aligned_Guide.ipynb",
    "LAlatex_HTML_Utilities.ipynb",
    "LAlatex_from_Python.ipynb",
    "LAlatex_examples.ipynb",
]
TEXT_SOURCES = [REPO_ROOT / "README.md", *(ROOT / "src").glob("*.md")]
SOURCE_FORBIDDEN_SNIPPETS = [
    "1.0.0-DEV",
    "inline=false` for `\\\\[...\\\\]`",
    "Expected `\\\\[",
    "Unknown container keyword arguments are ignored",
    "ignored unknown option keys",
    "They do not cover `inline` or `lc` construction options",
    "\\mathrm{;\\quad }",
    "SymPy.jl",
    "arrytype",
]
NOTEBOOK_FORBIDDEN_SNIPPETS = ["backend_available", *SOURCE_FORBIDDEN_SNIPPETS]


def normalized(text: str) -> str:
    return " ".join(text.split())


def check_forbidden_snippets(name: str, text: str, forbidden_snippets: list[str]) -> None:
    normalized_text = normalized(text)
    for snippet in forbidden_snippets:
        if normalized(snippet) in normalized_text:
            raise SystemExit(f"{name}: forbidden snippet found: {snippet}")


def main() -> None:
    missing = [name for name in EXPECTED_NOTEBOOKS if not (NOTEBOOK_DIR / name).is_file()]
    if missing:
        raise SystemExit(f"Missing documentation notebooks: {', '.join(missing)}")

    for path in TEXT_SOURCES:
        check_forbidden_snippets(
            str(path.relative_to(REPO_ROOT)),
            path.read_text(encoding="utf-8"),
            SOURCE_FORBIDDEN_SNIPPETS,
        )

    for name in EXPECTED_NOTEBOOKS:
        path = NOTEBOOK_DIR / name
        notebook = json.loads(path.read_text(encoding="utf-8"))
        nbformat = notebook.get("nbformat", 0)
        if nbformat < 4:
            raise SystemExit(f"{name}: expected nbformat >= 4, found {nbformat}")

        cells = notebook.get("cells", [])
        code_cells = [cell for cell in cells if cell.get("cell_type") == "code"]
        if not code_cells:
            raise SystemExit(f"{name}: expected at least one code cell")

        text = json.dumps(notebook, ensure_ascii=False)
        check_forbidden_snippets(name, text, NOTEBOOK_FORBIDDEN_SNIPPETS)

    print("Documentation smoke checks passed.")


if __name__ == "__main__":
    main()
