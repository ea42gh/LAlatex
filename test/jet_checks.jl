@testset "Targeted JET checks" begin
    if !optional_test_dependency("JET", "targeted JET checks")
        nothing
    elseif VERSION < v"1.12"
        @info "Skipping targeted JET checks on Julia versions older than 1.12."
    elseif VERSION.prerelease !== ()
        @info "Skipping targeted JET checks on prerelease Julia builds."
    else
        @eval import JET
        # Parse JET macros only after JET is available, so direct test runs from
        # the project environment can skip these test-only extras cleanly.
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

        lc_option_keys_report =
            JET.@report_call LAlatex._validate_lc_option_keys((
                sign_policy = :signed,
                arraystyle = :bmatrix,
                symopts = NamedTuple(),
            ))
        assert_no_jet_reports("lc option-key validation", lc_option_keys_report)

        container_option_keys_report =
            JET.@report_call LAlatex._validate_container_option_keys(
                (arraystyle = :bmatrix, symopts = NamedTuple()),
                LAlatex.CELL_CONTAINER_OPTION_KEYS,
                "cases",
            )
        assert_no_jet_reports("container option-key validation", container_option_keys_report)

        symbolics_adapter_literal_report =
            JET.@report_call LAlatex._symbolics_literal_number(Symbolics.unwrap(Num(3//4)))
        assert_no_jet_reports("Symbolics adapter literal handling", symbolics_adapter_literal_report)

        symopts_report = JET.@report_call LAlatex.normalize_symopts((expand = true,))
        assert_no_jet_reports("symbolic option normalization", symopts_report)

        annotated_lshow_report = JET.@report_call LAlatex.L_show(
            LaTeXString("x = y");
            inline = false,
            tag = "1",
            label = "eq:jet",
        )
        assert_no_jet_reports("annotated display L_show", annotated_lshow_report)

        tag_validation_report = JET.@report_call LAlatex._validate_equation_tag("A_1")
        assert_no_jet_reports("equation tag validation", tag_validation_report)

        label_validation_report =
            JET.@report_call LAlatex._validate_equation_label("eq:jet")
        assert_no_jet_reports("equation label validation", label_validation_report)

        set_builder_report = JET.@report_call LAlatex.set(
            LaTeXString("x");
            such_that = LaTeXString("x > 0"),
        )
        assert_no_jet_reports("set-builder construction", set_builder_report)

        set_separator_report =
            JET.@report_call LAlatex._validate_set_separator_value(LaTeXString(":"), "such_that_separator")
        assert_no_jet_reports("set-builder separator validation", set_separator_report)

        inline_validation_report = JET.@report_call LAlatex._validate_inline_value(false)
        assert_no_jet_reports("inline option validation", inline_validation_report)

        annotation_context_report =
            JET.@report_call LAlatex._validate_equation_annotation_context(false, "S", "eq:set")
        assert_no_jet_reports("equation annotation context validation", annotation_context_report)

        display_defaults_report = JET.@report_call LAlatex._validate_display_defaults((
            color = "red!50!black",
            factor_out = false,
            symopts = (expand = true,),
        ))
        assert_no_jet_reports("display-default validation", display_defaults_report)

        option_merge_report = JET.@report_call LAlatex.merge_display_options(
            LAlatex.DisplayOptions(),
            (color = "blue", separator = LaTeXString(";")),
        )
        assert_no_jet_reports("display-option merging", option_merge_report)

        such_that_entries_report = JET.@report_call LAlatex._set_such_that_entries((
            LaTeXString("x > 0"),
            LaTeXString("x < 1"),
        ))
        assert_no_jet_reports("set-builder condition normalization", such_that_entries_report)
        """,
        )
    end
end
