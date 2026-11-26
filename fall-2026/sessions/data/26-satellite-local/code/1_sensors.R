# AEM 6850, session 26 (Drone & satellite imagery). Passive and active sensors
# Script 1 of 7 - the pictures of part 1: Cayuga Lake on a cloudy day by camera (Sentinel-2, 30 August 2024)
# and by radar (Sentinel-1, 1 September 2024), and the five Sentinel-2 bands in our image
# Reads: data/sentinel2/s2_tci_20240830_cayuga.tif (the camera's true colour, 10 m, 2.5 MB),
#        data/sentinel1/s1_vv_db_20240901_cayuga_20m.tif (radar backscatter, decibels times 10, 20 m, 5.2 MB),
#        data/sentinel2/s2_20240815_cayuga_20m.tif (our image of 15 August 2024, only its layer names here)
# Writes: nothing
# Open 26-satellite-local.Rproj first, so R starts in the project folder; then
#   source("code/1_sensors.R")
# Part 1 has no code on its slides. This script draws the two images of the cloudy day and lists the bands.
# The code that downloaded the two images is in tools/fetch_sentinel2.R and tools/fetch_sentinel1.R
# (it needs the network, so nothing here runs it). Takes about 5 seconds.

# 1). Preliminary ----
# Clean up workspace and load or install necessary packages if necessary
  rm(list = ls())
  want <- c("terra")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only=TRUE))
  rm(want, need)
  options(width = 100); terraOptions(progress = 0, memmax = 2)
  misc <- list()
  misc$camera <- "data/sentinel2/s2_tci_20240830_cayuga.tif"         # true colour, 30 August 2024
  misc$radar  <- "data/sentinel1/s1_vv_db_20240901_cayuga_20m.tif"   # VV backscatter, dB x 10
  misc$s2     <- "data/sentinel2/s2_20240815_cayuga_20m.tif"         # our image, 15 August 2024

# 2). Cayuga Lake on a cloudy day ----
  # The camera saw almost only cloud on 30 August 2024. Two days later, radar showed the lake's outline.
  cam <- rast(misc$camera)                 # red, green and blue, 0 to 255
  rad <- rast(misc$radar) / 10             # decibels
  par(mfrow = c(1, 2))
  plotRGB(cam, r = 1, g = 2, b = 3)                                  # the camera, 30 August
  plot(rad, col = grey.colors(50), range = c(-20, -2), legend = FALSE)   # the radar, 1 September
  par(mfrow = c(1, 1))
  # Calm water reflects the radar signal away from the satellite, so the lakes look dark.
  round(global(rad, quantile, probs = c(0.02, 0.5, 0.98), na.rm = TRUE), 1)

# 3). What a band records ----
  # A camera records light in separate bands. The image stores one layer per band.
  names(rast(misc$s2))
  data.frame(layer = c("B02", "B03", "B04", "B8A", "B11"),
             band  = c("blue", "green", "red", "near-infrared", "shortwave infrared"),
             nm    = c(490, 560, 665, 865, 1610))         # centre of each band, nanometres (ESA)

# the end ----
