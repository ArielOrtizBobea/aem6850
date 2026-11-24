# AEM 6850, session 25 (Radar & LiDAR). LiDAR data in R
# Script 2 of 6 - read the campus point cloud, its classes, drop the noise, the ground, surface and height
# grids, the Arts Quad lawn
# Reads: data_clean/lidar/campus.laz (the USGS points, clipped to 600 x 600 m around McGraw Tower)
# Writes: nothing (data_clean/lidar/campus_dtm.tif, campus_dsm.tif and campus_height.tif hold the same grids)
# Open 25-lidar-drones.Rproj first, so R starts in the project folder; then
#   source("code/2_lidar.R")
# Every section matches a slide of the same name. Takes about 10 seconds.

# 1). Preliminary ----
# Clean up workspace and load or install necessary packages if necessary
  rm(list = ls())
  want <- c("lidR", "terra", "sf")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only = TRUE))
  rm(want, need)
  options(width = 100, lidR.progress = FALSE); terraOptions(progress = 0)
  misc <- list()
  misc$laz  <- "data_clean/lidar/campus.laz"            # the 2020 Finger Lakes flight, clipped to the campus
  misc$lawn <- c(x = 377964.8, y = 4700674.7)           # a point on the Arts Quad lawn, UTM zone 18N, metres

# 2). Reading the campus points ----
  las <- readLAS(misc$laz)   # about 2 seconds
  las

# 3). Ground and everything else ----
  table(las$Classification)                               # 1 other, 2 ground, 7 and 18 noise
  las <- filter_poi(las, !Classification %in% c(7, 18))   # drop the noise
  npoints(las)

# 4). The ground grid ----
  ground <- rasterize_terrain(las, res = 1, algorithm = tin())   # bare ground, 1 m cells

# 5). The surface grid ----
  surface <- rasterize_canopy(las, res = 1, algorithm = p2r(na.fill = tin()))   # top point

# 6). Height above ground ----
  height <- surface - ground                         # height above ground, metres
  round(range(values(height), na.rm = TRUE), 1)      # lowest and highest

# 7). The Arts Quad lawn reads 0 m ----
  g3 <- c(ground, surface, height); names(g3) <- c("ground", "surface", "height")
  lawn <- vect(cbind(377964.8, 4700674.7), crs = crs(g3))   # a point on the Arts Quad lawn
  round(extract(g3, lawn), 2)

# the end ----
