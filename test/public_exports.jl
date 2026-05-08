@testset "Public exports" begin
    exported = names(LAlatex)
    expected_exports = [
        Symbol("@syms"),
        Symbol("@syms_sympy"),
        Symbol("@mixed_matrix"),
        :syms,
        :syms_sympy,
        :import_sympy,
        :get_backend,
        :set_backend!,
        :symbolic_transform,
        :symbolic_term_coefficients,
        :to_latex,
        :L_show,
        :l_show,
        :L_interp,
        :set_display_defaults!,
        :reset_display_defaults!,
        :display_defaults,
        :with_display_defaults,
        :to_html,
        :mixed_matrix,
        :set,
        :lc,
        :cases,
        :aligned,
        :factor_out_denominator,
        :bold_formatter,
        :scientific_formatter,
        :tril_formatter,
    ]
    @test all(name -> name in exported, expected_exports)
    @test :syms_symbolics ∉ exported
    @test :assume_symbolics! ∉ exported
    @test :symbolics_assumptions ∉ exported
end
