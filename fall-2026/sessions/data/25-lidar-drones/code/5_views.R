# AEM 6850, session 25 (Radar & LiDAR). Views
# Script 5 of 6 - what McGraw Tower can see with viewshed(), each town's share of land in view,
# Exercise 2 (the view from the ground), the view as polygons
# Reads: data_clean/terrain/tompkins_dem_utm.tif, data_clean/terrain/tompkins_towns.gpkg
# Writes: nothing
# Open 25-lidar-drones.Rproj first, so R starts in the project folder; then
#   source("code/5_views.R")

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
  misc$dem   <- "data_clean/terrain/tompkins_dem_utm.tif"   # elevation, m, 30 m cells
  misc$towns <- "data_clean/terrain/tompkins_towns.gpkg"
  misc$eye   <- 53                                          # metres, Cornell's 52.7 m for the tower

# 2). The grid, the towns and the tower from script 4 ----
  # dem, the 30 m elevation grid; towns, the ten towns; tw, McGraw Tower in the grid's coordinates
  dem   <- rast(misc$dem)
  towns <- st_read(misc$towns, quiet = TRUE)
  tw    <- project(vect(cbind(-76.48505, 42.44757), crs = "EPSG:4326"), crs(dem))

# 3). What McGraw Tower can see ----
  top  <- viewshed(dem, crds(tw), observer = 53, target = 0)    # TRUE where visible
  round(global(top, "sum", na.rm = TRUE)[[1]] * 900 / 1e6, 1)   # km2 in view
  land <- dem > 116.45                         # 0.5 m above the lake's flat surface
  towns$top <- round(100 * exact_extract(top * land * 900, towns, "sum", progress = FALSE) /
                     towns$ALAND, 1)
  plot(dem, col = grey.colors(50))
  plot(ifel(top, 1, NA), col = adjustcolor("orange", 0.7), add = TRUE, legend = FALSE)
  plot(st_geometry(towns), add = TRUE); points(crds(tw), pch = 17, col = "blue", cex = 1.6)

# 4). Exercise 2, solution: the view from the ground at McGraw Tower ----
  # What you see depends on how high your eye is. dem, tw, land and towns are from sections 2 and 3.
  gnd <- viewshed(dem, crds(tw), observer = 1.7, target = 0)
  round(global(gnd, "sum", na.rm = TRUE)[[1]] * 900 / 1e6, 1)
  towns$gnd <- round(100 * exact_extract(gnd * land * 900, towns, "sum", progress = FALSE) /
                     towns$ALAND, 1)
  towns[, c("NAMELSAD", "top", "gnd"), drop = TRUE]

# 5). The view as polygons ----
  view <- disagg(as.polygons(ifel(top, 1, NA)))   # one polygon per separate piece
  nrow(view)
  round(sum(expanse(view)) / 1e6, 1)              # km2, against the grid's 236.5

# the end ----
