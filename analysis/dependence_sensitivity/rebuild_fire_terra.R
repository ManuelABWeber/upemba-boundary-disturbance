# Recover the original fire processing definition in a separate audit folder.
source("analysis/dependence_sensitivity/paths.R")
library(terra)
base <- Sys.getenv("UPEMBA_DEPENDENCE_RASTER_ROOT")
stopifnot(nzchar(base))
template <- rast(file.path(base,'run_2026_04_07/SESU_covariates_500m.tif'))[[1]]
dir.create(file.path(base,'terra_fire'),showWarnings=FALSE)
for (year in 2021:2022) {
  files <- list.files(file.path(base,'data/fire'),pattern='-JD.tif$',recursive=TRUE,full.names=TRUE)
  files <- sort(files[grepl(paste0('/',year),gsub('\\\\','/',files))])
  stopifnot(length(files)==7)
  r <- rast(files)
  te <- ext(project(template,crs(r)))
  r <- crop(r,ext(xmin(te)-.25,xmax(te)+.25,ymin(te)-.25,ymax(te)+.25),snap='out')
  seasonal <- ifel(r>=100 & r<=300,r,NA)
  doy <- app(seasonal,fun=function(...) {
    x <- c(...);x <- x[is.finite(x)&x>=100&x<=300]
    if (!length(x)) return(NA_real_)
    min(x)
  })
  burned <- ifel(is.na(doy),0,1)
  fraction <- project(burned,template,method='average')
  for (tau in c(.10,.25,.50)) {
    binary <- as.int(fraction>=tau);binary[is.na(binary)]<-0
    target <- file.path(base,'terra_fire',sprintf('fire_%d_tau%03d.tif',year,round(tau*100)))
    if(file.exists(target)) stop('Refusing to overwrite ',target)
    writeRaster(binary,target,datatype='INT1U',wopt=list(gdal='COMPRESS=DEFLATE'))
  }
  cat('Completed original terra processing for',year,'\n')
}
capture.output(sessionInfo(),file=file.path(base,'terra_fire/sessionInfo.txt'))
