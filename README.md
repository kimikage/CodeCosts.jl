# CodeCosts.jl
[![Build Status](https://travis-ci.com/kimikage/CodeCosts.jl.svg?branch=master)](https://travis-ci.com/kimikage/CodeCosts.jl)
[![PkgEval](https://juliaci.github.io/NanosoldierReports/pkgeval_badges/C/CodeCosts.svg)](https://juliaci.github.io/NanosoldierReports/pkgeval_badges/report.html)
[![Codecov](https://codecov.io/gh/kimikage/CodeCosts.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/kimikage/CodeCosts.jl)

This package provides a variant of `@code_typed` with [estimated costs for the
inlining](https://docs.julialang.org/en/v1/devdocs/inference/#The-inlining-algorithm-(inline_worthy)-1).
This helps find the factors which are preventing the SIMD vectorization.

```julia
julia> using CodeCosts

julia> f(x::T) where T = convert(T, max(x * 10.0, x / 3))
f (generic function with 1 method)

julia> @code_costs f(1.0f0)
CodeCostsInfo(
     CodeInfo(
   1 1 ─ %1  = Base.fpext(Base.Float64, x)::Float64
   4 │   %2  = Base.mul_float(%1, 10.0)::Float64
  20 │   %3  = Base.div_float(x, 3.0f0)::Float32
   1 │   %4  = Base.fpext(Base.Float64, %3)::Float64
   2 │   %5  = Base.lt_float(%2, %4)::Bool
   1 │   %6  = Base.bitcast(Base.Int64, %4)::Int64
   1 │   %7  = Base.slt_int(%6, 0)::Bool
   1 │   %8  = Base.bitcast(Base.Int64, %2)::Int64
   1 │   %9  = Base.slt_int(%8, 0)::Bool
   0 │   %10 = Base.not_int(%7)::Bool
   1 │   %11 = Base.and_int(%9, %10)::Bool
   1 │   %12 = Base.or_int(%5, %11)::Bool
   2 │   %13 = Base.ne_float(%2, %2)::Bool
   1 │   %14 = Base.Math.ifelse(%13, %2, %4)::Float64
   2 │   %15 = Base.ne_float(%4, %4)::Bool
   1 │   %16 = Base.Math.ifelse(%15, %4, %2)::Float64
   1 │   %17 = Base.Math.ifelse(%12, %14, %16)::Float64
   1 │   %18 = Base.fptrunc(Base.Float32, %17)::Float32
   0 └──       return %18
     )
, CodeCostsSummary(
     zero:  2|
    cheap: 12| 111111111111
   middle: 10| 4===2=2=2=
expensive: 20| 20==================
    total: 42| 100 (default threshold)
))
```
