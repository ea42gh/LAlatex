@testset "Public exports" begin
    exported = names(LAlatex)
    expected_exports = [
        Symbol("@syms"),
        Symbol("@syms_sympy"),
        Symbol("@mixed_matrix"),
        :LAlatex,
        :L_interp,
        :L_show,
        :RawHTML,
        :aligned,
        :apply_function,
        :assume!,
        :assumptions,
        :block_formatter,
        :bold_formatter,
        :capture_output,
        :cases,
        :color_formatter,
        :combine_formatters,
        :conditional_color_formatter,
        :diagonal_blocks_formatter,
        :display_defaults,
        :exponential_formatter,
        :factor_out_denominator,
        :get_backend,
        :highlight_large_values,
        :import_sympy,
        :italic_formatter,
        :jordanblock_formatter,
        :l_show,
        :lc,
        :mixed_matrix,
        :overline_formatter,
        :percentage_formatter,
        :pr,
        :print_np_array_def,
        :reset_display_defaults!,
        :round_matrices,
        :round_value,
        :rowechelon_formatter,
        :scientific_formatter,
        :set,
        :set_backend!,
        :set_display_defaults!,
        :show_html,
        :show_side_by_side,
        :show_side_by_side_html,
        :symbolic_term_coefficients,
        :symbolic_transform,
        :syms,
        :syms_sympy,
        :to_html,
        :to_latex,
        :tril_formatter,
        :underline_formatter,
        :with_display_defaults,
    ]
    @test Set(exported) == Set(expected_exports)
    @test :syms_symbolics ∉ exported
    @test :assume_symbolics! ∉ exported
    @test :symbolics_assumptions ∉ exported
end

@testset "API docs mention public exports" begin
    api_docs = read(joinpath(@__DIR__, "..", "docs", "src", "api.md"), String)
    for name in names(LAlatex)
        @test occursin(String(name), api_docs)
    end
end
