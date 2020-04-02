using CodeCosts
using InteractiveUtils
using Test

@inline func_000(x::T) where T = (x + 1/3, x - oneunit(T), x / 3.0, x * 5.0)

@inline func_001(x::Integer) = x << 3

buf = IOBuffer()

v"1.5.0-DEV.0" <= VERSION < v"1.6" && @testset "Basic v1.5" begin
    @testset "func_000" begin
        res = @code_costs func_000(1.0f0)
        show(res)
        println()
        @test res.costs == [1, 1, 1, 1, 20, 1, 4, 0, 0]

        print(buf, res.summary)
        @test String(take!(buf)) == """
                                    CodeCostsSummary(
                                         zero:  2|
                                        cheap:  5| 11111
                                       middle:  4| 4===
                                    expensive: 20| 20==================
                                        total: 29| 100 (default threshold)
                                    )"""

        res = @code_costs func_000(1.0)
        @test res.costs == [1, 1, 20, 4, 0, 0]
    end
end

v"1.4" <= VERSION < v"1.5.0-DEV.0" && @testset "Basic v1.4" begin
    @testset "func_000" begin
        res = @code_costs func_000(1.0f0)
        show(res)
        println()
        @test res.costs == [1, 1, 1, 1, 20, 1, 4, 0, 0]

        print(buf, res.summary)
        @test String(take!(buf)) == """
                                    CodeCostsSummary(
                                         zero:  2|
                                        cheap:  5| 11111
                                       middle:  4| 4===
                                    expensive: 20| 20==================
                                        total: 29| 100 (default threshold)
                                    )"""

        res = @code_costs func_000(1.0)
        @test res.costs == [1, 1, 20, 4, 0, 0]
    end
end

v"1.0" <= VERSION < v"1.1" && @testset "Basic v1.0" begin
    @testset "func_000" begin
        res = @code_costs func_000(1.0f0)
        show(res)
        println()
        @test res.costs == [1, 1, 1, 1, 20, 1, 4, 0, 0]

        print(buf, res.summary)
        @test String(take!(buf)) == """
                                    CodeCostsSummary(
                                         zero:  2|
                                        cheap:  5| 11111
                                       middle:  4| 4===
                                    expensive: 20| 20==================
                                        total: 29| 100 (default threshold)
                                    )"""
        res = @code_costs func_000(1.0)
        @test res.costs == [1, 1, 20, 4, 0, 0]
    end
end
