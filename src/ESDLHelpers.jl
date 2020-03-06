module ESDLHelpers

using ESDL
using Statistics
using RecurrenceAnalysis
using DataStructures
using StatsBase:skewness, kurtosis, mad
#using EmpiricalModeDecomposition; const EMD=EmpiricalModeDecomposition

"""
timestats(cube, )

Compute the multi temporal statistics of a cube with temporal axis and return a cube with an `Stats` axis.
"""
function timestats(cube;kwargs...)

    indims = InDims("Time")
    funcs = OrderedDict("Mean"=>mean, "5th Quantile"=>x->quantile(x,.05),
            "25th Quantile" => x->quantile(x, 0.25), "Median" => median,
            "75th Quantile" => x->quantile(x,0.75), "95th Quantile" =>x->quantile(x,0.95),
            "Standard Deviation" => std, "Minimum" => minimum, "Maximum" => maximum,
            "Skewness" => skewness, "Kurtosis" => kurtosis, "Median Absolute Deviation" =>mad)

    stataxis = CategoricalAxis("Stats", collect(keys(funcs)))
    od = OutDims(stataxis)
    stats = mapCube(ctimestats!, cube, funcs, indims=indims, outdims=od, kwargs...)
end

function ctimestats!(xout, xin, funcs)
    ts = collect(skipmissing(xin))
    stats = []
    for func in values(funcs)
        push!(stats, func(ts))
    end
    xout .=stats
end




end # module
