using CodeCosts
using InteractiveUtils
using Test

@inline func_000(x::T) where T = (x + 1/3, x - oneunit(T), x / 3.0, x * 5.0)

v"1.3" <= VERSION < v"1.4" && @testset "Basic v1.3" begin
    res = @code_costs func_000(1.0f0)
    show(res)
end
