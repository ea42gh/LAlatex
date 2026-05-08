@testset "HTML helpers" begin
    LAlatex.set_backend!(:symbolics)
    html = LAlatex.to_html(
        "hello";
        sz = 18,
        color = "blue",
        justify = "center",
        height = 20,
        width = 80,
        env = "em",
    )
    @test occursin("hello", html)
    @test occursin("font-size: 18px", html)
    @test occursin("color: blue", html)
    escaped_html = LAlatex.to_html("<script>"; env = "script onclick=1")
    @test occursin("&lt;script&gt;", escaped_html)
    @test !occursin("<script>", escaped_html)
    @test occursin("<strong>", escaped_html)
    sanitized_html = LAlatex.to_html(
        "x";
        sz = -2,
        color = "red; background:url(j)",
        justify = "bogus",
        height = -5,
        width = 250,
    )
    @test occursin("font-size: 0px", sanitized_html)
    @test occursin("color: darkred", sanitized_html)
    @test occursin("text-align: left", sanitized_html)
    @test occursin("height: 0px", sanitized_html)
    @test occursin("width: 100%", sanitized_html)
    @test !occursin("background:url", sanitized_html)

    html2 = LAlatex.to_html("a", "b"; sz1 = 10, sz2 = 12, color = "black", justify = "left")
    @test occursin(">a<", html2)
    @test occursin(">b<", html2)
    sanitized_html2 = LAlatex.to_html(
        "a",
        "b";
        sz1 = "oops",
        sz2 = -3,
        color = "#abc",
        height = "oops",
        width = -10,
    )
    @test occursin("font-size: 20px", sanitized_html2)
    @test occursin("font-size: 0px", sanitized_html2)
    @test occursin("color: #abc", sanitized_html2)
    @test occursin("min-height: 15px", sanitized_html2)
    @test occursin("width: 0%", sanitized_html2)

    out = LAlatex.show_html("hi")
    @test out isa LAlatex.HTMLOut
    @test occursin("hi", out.html)

    out2 = LAlatex.pr("para")
    @test out2 isa LAlatex.HTMLOut
    @test occursin("para", out2.html)

    captured = LAlatex.capture_output(() -> println("line1"))
    @test occursin("line1", captured)

    side = LAlatex.show_side_by_side_html(["one", "two"], ["A", "B"])
    @test occursin("one", side)
    @test occursin("two", side)
    @test occursin("A", side)
    @test occursin("B", side)
    escaped_side = LAlatex.show_side_by_side_html(["<b>x</b>"], ["<i>t</i>"])
    @test occursin("&lt;b&gt;x&lt;/b&gt;", escaped_side)
    @test occursin("&lt;i&gt;t&lt;/i&gt;", escaped_side)

    side_obj = LAlatex.show_side_by_side(["x", "y"])
    @test side_obj isa LAlatex.SideBySideHTML
    mixed_obj = LAlatex.show_side_by_side(
        ["x", LAlatex.RawHTML("<div class=\"arrow\">→</div>")],
        ["A", ""],
    )
    @test mixed_obj isa LAlatex.SideBySideHTML
    @test occursin("<pre>x</pre>", mixed_obj.html)
    @test occursin("<div class=\"arrow\">→</div>", mixed_obj.html)
    @test !occursin("&lt;div class=&quot;arrow&quot;&gt;→&lt;/div&gt;", mixed_obj.html)
    @test occursin("x", side_obj.html)
    @test occursin("y", side_obj.html)

    io = IOBuffer()
    show(io, MIME("text/html"), out)
    @test occursin("hi", String(take!(io)))

    io = IOBuffer()
    show(io, MIME("text/html"), side_obj)
    @test occursin("x", String(take!(io)))
end
