const HAS_JET = Base.find_package("JET") !== nothing

@testset "Targeted JET checks" begin
    if !HAS_JET
        @info "JET is not available in the active project; run `Pkg.test()` to execute targeted JET checks."
    elseif VERSION.prerelease !== ()
        @info "Skipping targeted JET checks on prerelease Julia builds."
    else
        @eval import JET
        include_string(
            @__MODULE__,
            raw"""
        function assert_no_jet_reports(label, report)
            reports = JET.get_reports(report)
            @test isempty(reports)
            if !isempty(reports)
                @info "JET reports for $label" reports
            end
        end

        scalar_report = JET.@report_call LAlatex.to_latex(3//4)
        assert_no_jet_reports("numeric scalar LaTeX", scalar_report)

        arraystyle_report =
            JET.@report_call LAlatex.validate_arraystyle_value(:bmatrix, "arraystyle")
        assert_no_jet_reports("arraystyle validation", arraystyle_report)

        color_report = JET.@report_call LAlatex.validate_latex_color_value("red!50!black")
        assert_no_jet_reports("LaTeX color validation", color_report)

        options_report = JET.@report_call LAlatex.DisplayOptions(;
            arraystyle = :bmatrix,
            color = "red!50!black",
            factor_out = true,
        )
        assert_no_jet_reports("display option construction", options_report)
        """,
        )
    end
end
