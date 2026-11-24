# AEM 6850, session 25 (Radar & LiDAR). Watersheds
# Script 6 of 6 - which way water flows, flow accumulation, the land that drains to the USGS gauge on
# Fall Creek
# Reads: data_clean/terrain/fallcreek_dem_filled.tif (30 m elevation around Fall Creek, pits filled before class)
# Writes: nothing
# Open 25-lidar-drones.Rproj first, so R starts in the project folder; then
#   source("code/6_watershed.R")
# It loads terra, not lidR: lidR has a watershed() of its own, so the call below names terra's.

# 1). Preliminary ----
# Clean up workspace and load or install necessary packages if necessary
  rm(list = ls())
  want <- c("terra", "sf", "exactextractr")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only = TRUE))
  rm(want, need)
  options(width = 100); terraOptions(progress = 0)
  misc <- list()
  misc$filled <- "data_clean/terrain/fallcreek_dem_filled.tif"   # 30 m, pits filled before class
  misc$gauge  <- c(lon = -76.47278, lat = 42.45333)              # USGS gauge 04234000, NAD83
  misc$snap   <- 150                                             # metres searched for the stream

# 2). Which way water flows ----
  filled <- rast(misc$filled)                                    # 30 m, pits filled before class
  fd  <- terrain(filled, v = "flowdir")                          # the neighbour each cell drains to
  acc <- flowAccumulation(fd)                                    # cells draining through each cell
  plot(log(acc), legend = FALSE)

# 3). The Fall Creek basin is 324.6 km2 ----
  gauge <- project(vect(cbind(-76.47278, 42.45333), crs = "EPSG:4269"), crs(fd))
  e  <- extract(acc, buffer(gauge, 150), cells = TRUE)
  ws <- terra::watershed(fd, xyFromCell(acc, e$cell[which.max(e[[2]])]))   # 1 = drains to the gauge
  round(global(ws, "sum", na.rm = TRUE)[[1]] * 900 / 1e6, 1)              # km2
  max(e[[2]])                                                              # upstream cells at the outlet
  plot(filled, col = grey.colors(50))
  plot(ifel(ws == 1, 1, NA), col = adjustcolor("steelblue", 0.5), add = TRUE, legend = FALSE)
  points(crds(gauge), pch = 21, bg = "red", cex = 1.6)

# the end ----
