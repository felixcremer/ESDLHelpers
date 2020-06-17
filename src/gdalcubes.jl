using Dates
using ArchGDAL
const AG=ArchGDAL
using Glob

using ESDL

"""
   getdate(x,reg = r"[0-9]{8}T[0-9]{6}", df = dateformat"yyyymmddTHHMMSS")
Return a DateTime object from a string where the time stamp is found by `reg`
and it is parsed according to the `df` dateformat.
"""
function getdate(x,reg = r"[0-9]{8}T[0-9]{6}", df = dateformat"yyyymmddTHHMMSS")
   m = match(reg,x).match
   date =DateTime(m,df)
end

"""
grouptimes(times, timediff=200000)
Group a sorted vector of time stamps into subgroups
where the difference between neighbouring elements are less than `timediff` milliseconds.
This returns the indices of the subgroups as a vector of vectors.
"""
function grouptimes(times, timediff=200000)
   @assert sort(times) == times
   group = [1]
   groups = [group]

   for i in 2:length(times)
      t = times[i]
      period = t - times[group[end]]
      if period.value < timediff
         push!(group, i)
      else
         push!(groups, [i])
         group = groups[end]
      end
   end
   return groups
end



#indir = "/home/crem_fe/Daten/bonds/jurua/tifs"
#pol="VV"
"""
   gdalcube(indir, pol)

Load the datasets in `indir` with a polarisation `pol` as a ESDLArray.
We assume, that `indir` is a folder with geotiffs in the same CRS which are mosaicked into timesteps and then stacked as a threedimensional array.

"""
function gdalcube(indir, pol)

filenames = glob("*$(pol)*.tif", indir)
dates = getdate.(filenames)
# Sort the dates and files by DateTime
p = sortperm(dates)
sdates = dates[p]
sfiles = filenames[p]
@show sfiles
# Put the dates which are 200 seconds apart into groups
groupinds = grouptimes(sdates, 200000)

datasets = AG.read.(sfiles)
datasetgroups = [datasets[group] for group in groupinds]
#We have to save the vrts because the usage of nested vrts is not working as a rasterdataset

temp = tempdir()
outpaths = [joinpath(temp, splitext(basename(sfiles[group][1]))[1] * ".vrt") for group in groupinds]
@show outpaths
@show length(outpaths), length(datasetgroups)
vrt_grouped = AG.unsafe_gdalbuildvrt.(datasetgroups)
AG.write.(vrt_grouped, outpaths)
vrt_grouped = AG.read.(outpaths)
vrt_vv = AG.unsafe_gdalbuildvrt(vrt_grouped, ["-separate"])
rvrt_vv = AG.RasterDataset(vrt_vv)
cube=ESDLArray(rvrt_vv)
#bandnames = AG.GDAL.gdalgetfilelist(vrt_vv.ptr)



# Set the timestaps from the bandnames as time axis
dates_grouped = [sdates[group[begin]] for group in groupinds]

taxis = RangeAxis(:Time, dates_grouped)
ESDL.Cubes.renameaxis!(cube, "Band"=>taxis)
return cube
end
#Tryout chunking the data
