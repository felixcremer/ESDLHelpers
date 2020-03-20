module ESDLHelpers

using ESDL
using Statistics
using RecurrenceAnalysis
using DataStructures
using StatsBase:skewness, kurtosis, mad
#using EmpiricalModeDecomposition; const EMD=EmpiricalModeDecomposition
using LombScargle


export timestats, lombscargle, tslength

include("tsanalysis.jl")




end # module
