import json
import os
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent
REPO_ROOT = ROOT.parent
NOTEBOOK_DIR = ROOT / "src" / "notebooks"
NOTEBOOKS = [
    "LAlatex_basics.ipynb",
    "LAlatex_L_show_Guide.ipynb",
    "LAlatex_cases_Guide.ipynb",
    "LAlatex_aligned_Guide.ipynb",
    "LAlatex_HTML_Utilities.ipynb",
    "LAlatex_from_Python.ipynb",
    "LAlatex_examples.ipynb",
]
NOTEBOOK_PATHS = [NOTEBOOK_DIR / name for name in NOTEBOOKS]
NOTEBOOK_PATHS.append(REPO_ROOT / "notebooks" / "LAlatex_demo.ipynb")


def lalatex_project() -> Path:
    return Path(os.environ.get("LALATEX_PROJECT", REPO_ROOT))


def notebook_language(path: Path) -> str:
    notebook = json.loads(path.read_text(encoding="utf-8"))
    kernelspec = notebook.get("metadata", {}).get("kernelspec", {})
    language = notebook.get("metadata", {}).get("language_info", {}).get("name")
    return str(language or kernelspec.get("language") or kernelspec.get("name") or "").lower()


def execute_julia_notebook(path: Path) -> None:
    helper = ROOT / "execute_notebook_smoke.py"
    subprocess.run(
        [sys.executable, str(helper), str(path)],
        cwd=REPO_ROOT,
        check=True,
    )


def execute_python_notebook(path: Path) -> None:
    try:
        from lalatex import L, L_show, init, l_show
        from juliacall import Main as jl
    except ImportError:
        sys.path.insert(0, str(REPO_ROOT / "python"))
        try:
            from lalatex import L, L_show, init, l_show
            from juliacall import Main as jl
        except ImportError as retry_err:
            raise SystemExit(
                "Python interop notebook execution requires juliacall and the "
                "LAlatex Python shim. Install this checkout with "
                "`python -m pip install --upgrade pip setuptools wheel` and "
                "`python -m pip install -e .`, or run this check in the "
                "documented Jupyter/Binder image."
            ) from retry_err
    except Exception as err:
        raise SystemExit(
            "Python interop notebook execution could not initialize juliacall. "
            "Ensure Python and Julia have compatible architectures, and set "
            "PYTHON_JULIACALL_EXE and LALATEX_PROJECT when using a custom "
            "Julia installation."
        ) from err

    try:
        init(project=lalatex_project())
    except Exception as err:
        raise SystemExit(
            "Python interop notebook execution could not initialize LAlatex "
            "through juliacall. Ensure LALATEX_PROJECT points to a compatible "
            "Julia project and Python can load the selected Julia runtime."
        ) from err

    namespace = {
        "L": L,
        "L_show": L_show,
        "l_show": l_show,
        "display": lambda value: value,
    }

    notebook = json.loads(path.read_text(encoding="utf-8"))
    for index, cell in enumerate(notebook.get("cells", []), start=1):
        if cell.get("cell_type") != "code":
            continue
        source = "".join(cell.get("source", [])).strip()
        if not source:
            continue
        try:
            if source.startswith("%%julia"):
                julia_code = source.split("\n", 1)[1] if "\n" in source else ""
                jl.seval("begin\n" + julia_code + "\nend")
            else:
                exec(compile(source, f"{path.name}:cell-{index}", "exec"), namespace)
        except Exception as err:
            raise RuntimeError(f"{path.name}: code cell {index} failed") from err


def execute_notebook(path: Path) -> None:
    language = notebook_language(path)
    if language == "python" or path.name == "LAlatex_from_Python.ipynb":
        execute_python_notebook(path)
    else:
        execute_julia_notebook(path)


def selected_notebook_paths(args: list[str]) -> list[Path]:
    if not args:
        return NOTEBOOK_PATHS

    paths = []
    for arg in args:
        path = Path(arg)
        if not path.is_absolute():
            path = REPO_ROOT / path
        paths.append(path.resolve())
    return paths


def main() -> None:
    notebook_paths = selected_notebook_paths(sys.argv[1:])
    missing = [str(path.relative_to(REPO_ROOT)) for path in notebook_paths if not path.is_file()]
    if missing:
        raise SystemExit(f"Missing expected notebooks: {', '.join(missing)}")

    for path in notebook_paths:
        print(f"Executing {path.relative_to(REPO_ROOT)}", flush=True)
        execute_notebook(path)

    print("All documentation notebooks executed successfully.")


if __name__ == "__main__":
    main()
