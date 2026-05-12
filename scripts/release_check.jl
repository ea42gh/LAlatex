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

    error("No Python executable found. Set PYTHON to the interpreter used for documentation checks.")
end

function command_text(cmd::Cmd)
    return join(cmd.exec, " ")
end

function release_steps()
    julia = Base.julia_cmd()
    python = python_executable()
    docs_project = joinpath(ROOT, "docs")

    return [
        (
            "package tests",
            `$julia --project=$ROOT -e "using Pkg; Pkg.test()"`,
        ),
        (
            "docs build",
            `$julia --project=$docs_project $(joinpath(docs_project, "make.jl"))`,
        ),
        (
            "notebook smoke checks",
            `$python $(joinpath(ROOT, "docs", "smoke_notebooks.py"))`,
        ),
        (
            "full notebook execution",
            `$python $(joinpath(ROOT, "docs", "execute_all_notebooks.py"))`,
        ),
        (
            "benchmark smoke check",
            `$julia --project=$ROOT $(joinpath(ROOT, "perf", "benchmark.jl"))`,
        ),
    ]
end

function print_usage()
    println("Usage: julia --project=. scripts/release_check.jl [--list|--dry-run]")
    println()
    println("Runs the local release-preparation checks in the same order documented in RELEASING.md.")
    println("Use --list to print step names, or --dry-run to print commands without running them.")
end

function main(args = ARGS)
    if any(arg -> arg in ("-h", "--help"), args)
        print_usage()
        return nothing
    end

    valid_args = Set(["--list", "--dry-run"])
    invalid = filter(arg -> !(arg in valid_args), args)
    if !isempty(invalid)
        error("Unknown argument(s): $(join(invalid, ", "))")
    end

    steps = release_steps()

    if "--list" in args
        for (index, (name, _)) in enumerate(steps)
            println("$(index). $name")
        end
        return nothing
    end

    dry_run = "--dry-run" in args
    println("LAlatex release checks")
    println("Repository: $ROOT")
    println("Julia: $(VERSION)")
    println("Dry run: $dry_run")

    for (name, cmd) in steps
        println()
        println("==> $name")
        println(command_text(cmd))
        if !dry_run
            run(Cmd(cmd; dir = ROOT))
        end
    end

    println()
    println("Release checks completed.")
    return nothing
end

main()
