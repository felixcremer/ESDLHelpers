using Random
using StatsBase: sample

dB(x) = 10 * log10(x)
dB(x::AbstractArray) = dB.(x)
lin(x) = exp10(x/10)
Base.exp10(Missing) = missing

getinds(x, i) = findall(isequal.(x.data,i))

function neg2miss!(pix)
    zero_ind = pix .<= 1e-4
    zero_ind[ismissing.(zero_ind)] .=false
    pix[collect(skipmissing(zero_ind))] .=missing
    pix
end

function randinds(cube, shppath, polygon,seed=123)
    Random.seed!(seed)
    shpestcube=ESDL.cubefromshape(shppath, cube)
    shpinds=getinds(shpestcube, polygon)
    @info length(shpinds)
    shpsmall = sample(shpinds, 25, replace=false)
end

function getsample(cube, shppath, polygon, axnum, seed=123)
    inds = randinds(cube, shppath, polygon, seed)
    axvals = [cube[ind.I...,:,axnum] for ind in inds]
    nonmissinds = [.!ismissing.(ts) for ts in axvals]
    axnonmiss = [ax[nonmissinds[i]] for (i,ax) in enumerate(axvals)]
    return axnonmiss, nonmissinds
end

function getall(shpcube, metric, ax)
    T =eltype(metric)
    shpmetric = T[]
    for polygon in 1:maximum(skipmissing(shpcube.data))
        shpinds = getinds(shpcube, polygon)
        @show
        append!(shpmetric, collect(skipmissing([metric[i.I...,ax] for i in shpinds])))
    end
    shpmetric
end
