# AEM 6850, session 26. Downloads lights at night over New York State: the VIIRS mean of 2023 and the older,
# DMSP-style series of 2013.
# Run in the 26-satellite-local folder (open 26-satellite-local.Rproj first), after tools/fetch_census.R:
#   source("tools/fetch_lights.R")
# Needs the network, no account. About 30 seconds. A file already on disk is never fetched again.
# Sources:
#   (1) World Bank Light Every Night, VIIRS monthly composites of the Suomi NPP satellite (stray-light corrected,
#       average radiance, nW/cm2/sr, 15 arc-second cells). The public bucket https://globalnightlight.s3.amazonaws.com/
#       holds no annual file, so the twelve months of 2023 are averaged. Each global file is 3.5 to 4.2 GB, but it is
#       tiled with overviews, so only New York's window is read.
#       Registry: https://registry.opendata.aws/wb-light-every-night/ (licence named there "World Bank Open Database
#       License (ODbL)", linked to CC BY 4.0). Credit: "World Bank Light Every Night".
#   (2) Li, Zhou, Zhao and Zhao (Scientific Data, 2020), harmonized global night lights, DMSP-calibrated values
#       0 to 63, 30 arc-second cells, 2013 file, figshare article 9828827, CC BY 4.0:
#       https://ndownloader.figshare.com/files/17626034 (Harmonized_DN_NTL_2013_calDMSP.tif, 38 MB global).
# Reads: data/census/cb_2023_ny_county_500k.gpkg (the state's outline).
# Writes: data/lights/ntl_viirs_2023_ny.tif and data/lights/ntl_li2020_2013_ny.tif, cropped to New York plus
#   0.05 degree and set to NA outside the state.

# 1). Preliminary ----
  # Clean up workspace and load or install necessary packages if necessary
  rm(list = ls())
  want <- c("terra")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only = TRUE))
  rm(want, need)
  terraOptions(progress = 0, memmax = 2)
  options(HTTPUserAgent = "aem6850-course-data-script")
  setGDALconfig("GDAL_HTTP_USERAGENT", "aem6850-course-data-script")
  misc <- list()
  misc$bucket <- "https://globalnightlight.s3.amazonaws.com"
  misc$months <- sprintf("2023%02d", 1:12)
  misc$li     <- "/vsicurl/https://ndownloader.figshare.com/files/17626034"
  misc$cb     <- "data/census/cb_2023_ny_county_500k.gpkg"
  misc$out_viirs <- "data/lights/ntl_viirs_2023_ny.tif"
  misc$out_li    <- "data/lights/ntl_li2020_2013_ny.tif"
  dir.create("data/lights", recursive = TRUE, showWarnings = FALSE)
  ny <- project(vect(misc$cb), "EPSG:4326")
  e  <- ext(ny) + 0.05

# 2). VIIRS, the mean of the twelve months of 2023 ----
  if (!file.exists(misc$out_viirs)) {
    urls <- sapply(misc$months, function(m) {             # the bucket's listing gives each month's file name
      x <- paste(readLines(sprintf("%s/?list-type=2&prefix=composites/npp_%s_ops/", misc$bucket, m), warn = FALSE),
                 collapse = "")
      k <- regmatches(x, gregexpr("<Key>[^<]*slcorr[^<]*avg_rade9.tif", x))[[1]]
      paste0("/vsicurl/", misc$bucket, "/", sub("<Key>", "", k[1]))
    })
    mon   <- lapply(urls, function(u) crop(rast(u), e))
    viirs <- mean(rast(mon), na.rm = TRUE)
    names(viirs) <- "avg_rade9_2023"
    writeRaster(mask(viirs, ny), misc$out_viirs, gdal = "COMPRESS=DEFLATE", overwrite = TRUE)
  }

# 3). The older series, 2013 ----
  if (!file.exists(misc$out_li)) {
    li <- crop(rast(misc$li), e)
    names(li) <- "DN_2013"
    writeRaster(mask(li, ny), misc$out_li, gdal = "COMPRESS=DEFLATE", overwrite = TRUE)
  }
  rast(misc$out_viirs); rast(misc$out_li)

# the end ----
