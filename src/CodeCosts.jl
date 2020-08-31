module CodeCosts

import InteractiveUtils: gen_call_with_extracted_types_and_kwargs

export @code_costs

struct CostsSummary
    cost_threshold::Int
    zero::Int              # cost == 0
    cheap::Int             # cost == 1
    middle::Vector{Int}    # 2 <= cost <= 5
    expensive::Vector{Int} # 6 <= cost
end

function CostsSummary(cost_threshold::Int, costs::Vector{Int})
    zero = 0
    cheap = 0
    middle = []
    expensive = []
    for c in costs
        if c == 0
            zero += 1
        elseif c == 1
            cheap += 1
        elseif c <= 5
            push!(middle, c)
        else
            push!(expensive, c)
        end
    end
    CostsSummary(cost_threshold, zero, cheap,
                 sort!(middle, rev=true), sort!(expensive, rev=true))
end

struct Hint{ID} end

struct CodeCostsInfo
    ci::Core.CodeInfo
    costs::Vector{Int}
    summary::CostsSummary
    hints::Vector{Tuple{Int,Hint}}
end


macro code_costs(ex0...)
    thecall = gen_call_with_extracted_types_and_kwargs(__module__, :code_costs, ex0)
    quote
        results = $thecall
        results isa CodeCostsInfo ? results : results[1]
    end
end

if isdefined(Core.Compiler, :OptimizationParams)
    function code_costs(f, types; debuginfo::Symbol=:default,
                        params::Core.Compiler.OptimizationParams=Core.Compiler.OptimizationParams(),
                        hints::Symbol=:default)

        mi = Base.method_instances(f, types)[1]
        ci = code_typed(f, types; debuginfo=debuginfo)[1][1]

        interp = Core.Compiler.NativeInterpreter()
        opt = Core.Compiler.OptimizationState(mi, params, interp)

        cost(statement) = 0
        function cost(statement::Expr)
            Core.Compiler.statement_cost(statement, -1, ci, opt.sptypes, opt.slottypes, opt.params)
        end
        raw_costs = map(cost, ci.code)
        cost_threshold = opt.params.inline_cost_threshold
        summary = CostsSummary(cost_threshold, costs(raw_costs, ci))
        hint_messages = Vector{Tuple{Int,Hint}}()
        CodeCostsInfo(ci, raw_costs, summary, hint_messages)
    end
else
    function code_costs(f, types; debuginfo::Symbol=:default,
                        params::Core.Compiler.Params=Core.Compiler.Params(typemax(UInt)),
                        hints::Symbol=:default)

        mi = Base.method_instances(f, types)[1]
        if VERSION >= v"1.1"
            ci = code_typed(f, types; debuginfo=debuginfo)[1][1]
        else
            ci = code_typed(f, types)[1][1]
        end

        opt = Core.Compiler.OptimizationState(mi, params)
        opt.src.inlineable = true
        sptypes = :sptypes in fieldnames(typeof(opt)) ? opt.sptypes : opt.sp

        cost(statement) = 0
        function cost(statement::Expr)
            Core.Compiler.statement_cost(statement, -1, ci, sptypes, opt.slottypes, opt.params)
        end
        raw_costs = map(cost, ci.code)
        cost_threshold = opt.params.inline_cost_threshold
        summary = CostsSummary(cost_threshold, costs(raw_costs, ci))
        hint_messages = Vector{Tuple{Int,Hint}}()
        CodeCostsInfo(ci, raw_costs, summary, hint_messages)
    end
end

function _code_hash(s::String)
    h = UInt(0)
    for c in codeunits(replace(s, r"\e\[[^m]*m" => ""))
        h = (0x20 < c) & (c < 0x80) ? hash(c, h) : h
    end
    h
end

function Base.show(io::IO, costsinfo::CodeCostsInfo; debuginfo::Symbol=:source)
    buf_s = IOBuffer()
    buf_n = IOBuffer()
    if VERSION >= v"1.1"
        show(IOContext(buf_s, io), costsinfo.ci, debuginfo=debuginfo)
        debuginfo !== :none && show(buf_n, costsinfo.ci, debuginfo=:none)
    else
        show(IOContext(buf_s, io), costsinfo.ci)
    end
    println(io, "CodeCostsInfo(")

    seekstart(buf_s)
    seekstart(buf_n)
    idx = 0
    nhash = _code_hash(readline(buf_n))
    for line in readlines(buf_s)
        l = VERSION >= v"1.1" ? line : replace(line, "\e[1G" => "\e[6G")

        if VERSION >= v"1.1" && debuginfo !== :none
            shash = _code_hash(l)
            if shash !== nhash
                println(io, " "^5, l)
                continue
            end
            n = readline(buf_n)
            nhash = _code_hash(n)
        end

        if 0 < idx <= length(costsinfo.costs)
            # multi-line statement
            if !occursin(r"(?:^|\e\[6G)(?:\e\[[^m]*m|\s)*(?:\d+ |│|└)", l)
                println(io, " "^5, l)
                continue
            end
            # skip code_coverage_effect
            if Meta.isexpr(costsinfo.ci.code[idx], :code_coverage_effect)
                idx += 1
                continue
            end

            c = costsinfo.costs[idx]
            cs = lpad(string(c), 4)
            if c == 1
                println(io, cs, " ", l)
            else
                color = c == 0 ? Base.info_color() :
                        c <= 5 ? Base.warn_color() : Base.error_color()
                printstyled(io, cs, color=color)
                println(io, " ", l)
            end
        else
            println(io, " "^5, l)
        end
        idx += 1
    end
    print(io, ", ")
    print(io, costsinfo.summary)
    print(io, ")")
end

function Base.show(io::IO, s::CostsSummary)
    println(io, "CodeCostsSummary(")
    mids, exps = sum(s.middle), sum(s.expensive)
    total = s.cheap + mids + exps
    pad(n) = lpad(string(n), max(ndigits(total), ndigits(s.zero)))
    printstyled(io, "     zero: ", pad(s.zero),  "|", color=Base.info_color())
    println(io)
    print(      io, "    cheap: ", pad(s.cheap), "| ", costs_string(fill(1, s.cheap)))
    println(io)
    printstyled(io, "   middle: ", pad(mids),    "| ", costs_string(s.middle), color=Base.warn_color())
    println(io)
    printstyled(io, "expensive: ", pad(exps),    "| ", costs_string(s.expensive), color=Base.error_color())
    println(io)
    print(      io, "    total: ", pad(total),   "| ", s.cost_threshold, " (default threshold)")
    println(io)
    print(io, ")")
end

function costs_string(costs::Vector{Int})
    buf = IOBuffer()
    len = 0
    for c in costs
        cs = string(c)
        n = min(50, c - length(cs))
        print(buf, cs, "="^n)
        len += c
        if len >= 75
            print(buf, "...")
            break
        end
    end
    String(take!(buf))
end

function costs(raw_costs::Vector{Int}, ci::Core.CodeInfo)
    cs = Int[]
    for (i, c) in enumerate(raw_costs)
        Meta.isexpr(ci.code[i], :code_coverage_effect) || push!(cs, c)
    end
    cs
end
costs(costsinfo::CodeCosts.CodeCostsInfo) = costs(costsinfo.costs, costsinfo.ci)

end # module
