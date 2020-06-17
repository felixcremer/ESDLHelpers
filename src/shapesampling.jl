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

function randinds(cube, shpcube::ESDL.Cubes.AbstractCubeData, polygon; seed=123, nsamples=25)
shpinds=getinds(shpcube, polygon)
@info length(shpinds)
Random.seed!(seed)
shpsmall = sample(shpinds, nsamples, replace=false)
end

function randinds(cube, shppath::AbstractString, polygon;seed=123,nsamples=25, wrap=nothing, inner=true)
    if inner
        shpestcube =  ESDL.cubefromshape(shppath, cube, wrap=wrap,samplefactor=10)
    else
        shpestcube=ESDL.cubefromshape(shppath, cube,wrap=wrap)
    end
    @show shpestcube
    @info findall(skipmissing(.!iszero.(shpestcube.data)))
    randinds(cube, shpestcube, polygon, seed=seed, nsamples=nsamples)
end

function getsample(cube, shppath::AbstractString, polygon; seed=123,nsamples=25, wrap=nothing, inner=true)
    inds = randinds(cube, shppath, polygon, seed=seed, nsamples=nsamples, wrap=wrap, inner=inner)
    axvals = [cube[ind.I...,:] for ind in inds]
    nonmissinds = [.!ismissing.(ts) for ts in axvals]
    axnonmiss = [ax[nonmissinds[i]] for (i,ax) in enumerate(axvals)]
    return axnonmiss, nonmissinds
end

function getsample(cube, shppath::AbstractString, polygon, axnum; seed=123,nsamples=25, wrap=nothing, inner=true)
    inds = randinds(cube, shppath, polygon, seed=seed, nsamples=nsamples, wrap=wrap, inner=inner)
    axvals = [cube[ind.I...,:,axnum] for ind in inds]
    nonmissinds = [.!ismissing.(ts) for ts in axvals]
    axnonmiss = [ax[nonmissinds[i]] for (i,ax) in enumerate(axvals)]
    return axnonmiss, nonmissinds
end

function getsample(cube, shpcube, polygon, axnum; seed=123,nsamples=25)
    inds = randinds(cube,shpcube, polygon, seed=seed, nsamples=nsamples)
    axvals = [cube[ind.I...,:,axnum] for ind in inds]
    nonmissinds = [.!ismissing.(ts) for ts in axvals]
    axnonmiss = [ax[nonmissinds[i]] for (i,ax) in enumerate(axvals)]
    return axnonmiss, nonmissinds
end

function getall(shpcube, metric, ax)
    T =eltype(metric)
    shpmetric = []
    for polygon in 1:maximum(skipmissing(shpcube.data))
        shpinds = getinds(shpcube, polygon)
        a = [collect(metric[i.I..., ax...]) for i in shpinds]
        @show typeof(a), size(a)
        append!(shpmetric, a)
    end
    shpmetric
end
