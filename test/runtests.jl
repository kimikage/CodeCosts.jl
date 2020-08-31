using CodeCosts
using CodeCosts: costs
using InteractiveUtils
using Test

if get(ENV, "TRAVIS", "false") == "true"
    # force :color => true
    Base.get(::Base.PipeEndpoint, key::Symbol, default) = key === :color ? true : default
    # avoid the `light` colors
    ENV["JULIA_ERROR_COLOR"] = :red
end

@inline func_000(x::T) where T = (x + 1/3, x - oneunit(T), x / 3.0, x * 5.0)

func_001(x) = :(if $x > 0; true; else false; end)

buf = IOBuffer()

v"1.6.0-DEV.0" <= VERSION < v"1.7.0-DEV.0" && @testset "Basic v1.6" begin
    @testset "func_000" begin
        res = @code_costs func_000(1.0f0)
        show(res)
        println()
        @test costs(res) == [1, 1, 1, 1, 20, 1, 4, 0, 0]

        print(buf, res.summary)
        @test String(take!(buf)) == """
                                    CodeCostsSummary(
                                         zero:  2|
                                        cheap:  5| 11111
                                       middle:  4| 4===
                                    expensive: 20| 20==================
                                        total: 29| 100 (default threshold)
                                    )"""

        res = @code_costs debuginfo=:source func_000(1.0)
        show(res)
        println()
        @test costs(res) == [1, 1, 20, 4, 0, 0]
    end

    @testset "func_001" begin
        res = @code_costs func_001(1)
        show(res)
        println()

        print(buf, res)
        @test occursin(r"\n   0 └──      return %\d\n", String(take!(buf)))
        @test costs(res) == [100, 100, 100, 100, 0]
    end
end

v"1.5.0-DEV.0" <= VERSION < v"1.6.0-DEV.0" && @testset "Basic v1.5" begin
    @testset "func_000" begin
        res = @code_costs func_000(1.0f0)
        show(res)
        println()
        @test costs(res) == [1, 1, 1, 1, 20, 1, 4, 0, 0]

        print(buf, res.summary)
        @test String(take!(buf)) == """
                                    CodeCostsSummary(
                                         zero:  2|
                                        cheap:  5| 11111
                                       middle:  4| 4===
                                    expensive: 20| 20==================
                                        total: 29| 100 (default threshold)
                                    )"""

        res = @code_costs debuginfo=:source func_000(1.0)
        show(res)
        println()
        @test costs(res) == [1, 1, 20, 4, 0, 0]
    end

    @testset "func_001" begin
        res = @code_costs func_001(1)
        show(res)
        println()

        print(buf, res)
        @test occursin(r"\n   0 └──      return %\d\n", String(take!(buf)))
        @test costs(res) == [100, 100, 100, 100, 0]
    end
end

v"1.4" <= VERSION < v"1.5.0-DEV.0" && @testset "Basic v1.4" begin
    @testset "func_000" begin
        res = @code_costs func_000(1.0f0)
        show(res)
        println()
        @test costs(res) == [1, 1, 1, 1, 20, 1, 4, 0, 0]

        print(buf, res.summary)
        @test String(take!(buf)) == """
                                    CodeCostsSummary(
                                         zero:  2|
                                        cheap:  5| 11111
                                       middle:  4| 4===
                                    expensive: 20| 20==================
                                        total: 29| 100 (default threshold)
                                    )"""

        res = @code_costs debuginfo=:source func_000(1.0)
        show(res)
        println()
        @test costs(res) == [1, 1, 20, 4, 0, 0]
    end

    @testset "func_001" begin
        res = @code_costs func_001(1)
        show(res)
        println()

        print(buf, res)
        @test occursin(r"\n   0 └──      return %\d\n", String(take!(buf)))
        @test costs(res) == [100, 100, 100, 100, 0]
    end
end

v"1.0" <= VERSION < v"1.1" && @testset "Basic v1.0" begin
    @testset "func_000" begin
        res = @code_costs func_000(1.0f0)
        show(res)
        println()
        @test costs(res) == [1, 1, 1, 1, 20, 1, 4, 0, 0]

        print(buf, res.summary)
        @test String(take!(buf)) == """
                                    CodeCostsSummary(
                                         zero:  2|
                                        cheap:  5| 11111
                                       middle:  4| 4===
                                    expensive: 20| 20==================
                                        total: 29| 100 (default threshold)
                                    )"""
        res = @code_costs debuginfo=:source func_000(1.0)
        show(res)
        println()
        @test costs(res) == [1, 1, 20, 4, 0, 0]
    end

    @testset "func_001" begin
        res = @code_costs func_001(1)
        show(res)
        println()

        print(buf, res)
        @test occursin(r"\n   0    └──      return %\d\n", String(take!(buf)))
        @test costs(res) == [100, 100, 100, 100, 0]
    end
end
