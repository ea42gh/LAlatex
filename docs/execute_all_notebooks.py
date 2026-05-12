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
    os.environ.setdefault("JULIA_PROJECT", str(REPO_ROOT))
    try:
        from juliacall import Main as jl
    except ImportError as err:
        raise SystemExit(
            "Python interop notebook execution requires juliacall. "
            "Install it or run this check in the documented Jupyter image."
        ) from err

    project_path = json.dumps(str(REPO_ROOT))
    jl.seval(f"import Pkg; Pkg.activate({project_path}); Pkg.instantiate()")
    jl.seval("using LAlatex, LaTeXStrings, LinearAlgebra")
    latex_string = jl.seval("LaTeXString")
    l_show_jl = jl.seval("LAlatex.l_show")
    l_show_string_jl = jl.seval("LAlatex.L_show")

    class RawLatex(str):
        pass

    def convert_arg(value):
        if isinstance(value, RawLatex):
            return latex_string(str(value))
        return value

    def L(value):
        return RawLatex(value)

    def L_show(*args, **kwargs):
        converted = [convert_arg(arg) for arg in args]
        return str(l_show_string_jl(*converted, **kwargs))

    def l_show(*args, **kwargs):
        converted = [convert_arg(arg) for arg in args]
        return l_show_jl(*converted, **kwargs)

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


def main() -> None:
    missing = [str(path.relative_to(REPO_ROOT)) for path in NOTEBOOK_PATHS if not path.is_file()]
    if missing:
        raise SystemExit(f"Missing expected notebooks: {', '.join(missing)}")

    for path in NOTEBOOK_PATHS:
        print(f"Executing {path.relative_to(REPO_ROOT)}", flush=True)
        execute_notebook(path)

    print("All documentation notebooks executed successfully.")


if __name__ == "__main__":
    main()
