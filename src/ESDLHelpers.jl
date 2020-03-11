module ESDLHelpers

using ESDL
using Statistics
using RecurrenceAnalysis
using DataStructures
using StatsBase:skewness, kurtosis, mad
#using EmpiricalModeDecomposition; const EMD=EmpiricalModeDecomposition
using LombScargle

"""
timestats(cube, )

Compute the multi temporal statistics of a cube with temporal axis and return a cube with an `Stats` axis.
"""
function timestats(cube;kwargs...)

    indims = InDims("Time")
    funcs = OrderedDict("Mean"=>mean, #"5th Quantile"=>x->quantile(x,.05),
            #"25th Quantile" => x->quantile(x, 0.25), "Median" => median,
            #"75th Quantile" => x->quantile(x,0.75), "95th Quantile" =>x->quantile(x,0.95),
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

function decompose(cube, algorithm, num_imfs=6)
    indims = InDims("Time")
    imfax = CategoricalAxis("IntrinsicModeFunctions", [("IMF " .* string(1:num_imfs))..., "Residual"])
    od = OutDims(imfax, )
    timeax = ESDL.getAxis("Time", cube)
    mapCube(cubeemd!, (cube, timeax), indims=(indims, indims), outdims=od)

end

function cubeemd!(xout, xin, times, num_imfs)
    ts = collect(skipmissing(xin))
    ind = .!ismissing.(xin)
    @show xin[ind], times[ind]

end

function lombscargle(cube, kwargs...)
    indims = InDims("Time")
    lombax = CategoricalAxis("LombScargle", ["Number of Frequencies", "Period with maximal power", "Maximal Power"])
    @show cube
    timeax = ESDL.getAxis("Time", cube)
    od = OutDims(lombax)
    mapCube(clombscargle, (cube, timeax), indims=(indims, indims), outdims=od)
end

function clombscargle(xout, xin, times)
    ind = .!ismissing.(xin)
    ts = collect(nonmissingtype(eltype(xin)), xin[ind])
    x = times[ind]
    if length(ts) < 10
        @show length(ts)
        xout .= missing
        return
    end
    datediff = Date.(x) .- Date(x[1])
    dateint = getproperty.(datediff, :value)
    pl = LombScargle.plan(dateint, ts)
    #@show pl
    pgram = LombScargle.lombscargle(pl)
    lsperiod= findmaxperiod(pgram)
    lspower = findmaxpower(pgram)
    lsnum = LombScargle.M(pgram)
    #@show lsperiod, lspower
    #@show findmaxfreq(pgram), findmaxpower(pgram)
    xout .= [lsnum, lsperiod[1], lspower]
end

function ctslength(xin)
    ind = .!ismissing.(xin)
    return count(ind)
end

tslength(cube) = mapslices(ctslength, cube, dims="Time")

end # module
