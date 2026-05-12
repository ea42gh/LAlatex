#!/usr/bin/env julia

const ROOT = normpath(joinpath(@__DIR__, ".."))

function python_executable()
    configured = get(ENV, "PYTHON", "")
    if !isempty(configured)
        return configured
    end

    for candidate in ("python", "python3")
        found = Sys.which(candidate)
        if found !== nothing
            return found
        end
    end

    error(
        "No Python executable found. Set PYTHON to the interpreter used for documentation checks.",
    )
end

function command_text(cmd::Cmd)
    return join(cmd.exec, " ")
end

function lalatex_project()
    return get(ENV, "LALATEX_PROJECT", ROOT)
end

function python_interop_cmd(cmd::Cmd)
    project = lalatex_project()
    return addenv(
        cmd,
        "LALATEX_PROJECT" => project,
        "PYTHON_JULIACALL_PROJECT" => get(ENV, "PYTHON_JULIACALL_PROJECT", project),
        "PYTHON_JULIACALL_EXE" => get(ENV, "PYTHON_JULIACALL_EXE", "julia"),
    )
end

function python_interop_probe(python)
    code = """
from juliacall import Main as jl
jl.seval("1 + 1")
"""
    cmd = python_interop_cmd(`$python -c $code`)
    try
        run(pipeline(Cmd(cmd; dir = ROOT), stdout = devnull, stderr = devnull))
        return true
    catch
        return false
    end
end

function release_steps()
    julia = Base.julia_cmd()
    python = python_executable()
    docs_project = joinpath(ROOT, "docs")

    return [
        (
            "package tests",
            `$julia --project=$ROOT -e "using Pkg; Pkg.test()"`,
            false,
        ),
        (
            "docs build",
            `$julia --project=$docs_project $(joinpath(docs_project, "make.jl"))`,
            false,
        ),
        (
            "notebook smoke checks",
            `$python $(joinpath(ROOT, "docs", "smoke_notebooks.py"))`,
            false,
        ),
        (
            "Python bridge editable install",
            `$python -m pip install --no-build-isolation --no-deps -e $ROOT`,
            true,
        ),
        (
            "full notebook execution",
            `$python $(joinpath(ROOT, "docs", "execute_all_notebooks.py"))`,
            true,
        ),
        (
            "Python interop smoke check",
            `$python $(joinpath(ROOT, "scripts", "python_interop_smoke.py")) --require-installed`,
            true,
        ),
        (
            "benchmark smoke check",
            `$julia --project=$ROOT $(joinpath(ROOT, "perf", "benchmark.jl"))`,
            false,
        ),
    ]
end

function print_usage()
    println(
        "Usage: julia --project=. scripts/release_check.jl [--list|--dry-run|--require-python-interop]",
    )
    println()
    println(
        "Runs the local release-preparation checks in the same order documented in RELEASING.md.",
    )
    println(
        "Use --list to print step names, or --dry-run to print commands without running them.",
    )
    println(
        "Set LALATEX_PROJECT to a compatible Julia project for Python interop checks.",
    )
end

function main(args = ARGS)
    if any(arg -> arg in ("-h", "--help"), args)
        print_usage()
        return nothing
    end

    valid_args = Set(["--list", "--dry-run", "--require-python-interop"])
    invalid = filter(arg -> !(arg in valid_args), args)
    if !isempty(invalid)
        error("Unknown argument(s): $(join(invalid, ", "))")
    end

    python = python_executable()
    steps = release_steps()

    if "--list" in args
        for (index, (name, _, _)) in enumerate(steps)
            println("$(index). $name")
        end
        return nothing
    end

    dry_run = "--dry-run" in args
    require_python_interop = "--require-python-interop" in args
    python_interop_available = dry_run ? true : python_interop_probe(python)

    println("LAlatex release checks")
    println("Repository: $ROOT")
    println("Julia: $(VERSION)")
    println("Python: $python")
    println("LALATEX_PROJECT: $(lalatex_project())")
    println("Dry run: $dry_run")

    if !dry_run && !python_interop_available
        message = string(
            "Python interop checks cannot run with the current Python/Julia ",
            "toolchain. This often means Python and Julia architectures do not ",
            "match, such as Windows arm64 Python with x64 Julia. Set PYTHON to a ",
            "matching interpreter or set LALATEX_PROJECT to a compatible Julia ",
            "project. CI remains strict because it uses matching Python/Julia ",
            "toolchains.",
        )
        if require_python_interop
            println(stderr, "ERROR: $message")
            exit(1)
        end
        @warn message
    end

    for (name, cmd, requires_python_interop) in steps
        println()
        println("==> $name")
        if requires_python_interop && !dry_run
            cmd = python_interop_cmd(cmd)
        end
        println(command_text(cmd))
        if !dry_run
            if requires_python_interop && !python_interop_available
                println("Skipping $name: Python interop preflight failed.")
                continue
            end
            run(Cmd(cmd; dir = ROOT))
        end
    end

    println()
    println("Release checks completed.")
    return nothing
end

main()
