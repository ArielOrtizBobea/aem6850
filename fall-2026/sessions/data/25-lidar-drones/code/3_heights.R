# AEM 6850, session 25 (Radar & LiDAR). Heights of buildings and trees
# Script 3 of 6 - McGraw Tower in the height grid, the Empire State Building in 1 m and 30 m cells,
# Exercise 1 (the tower in 5 m and 10 m cells)
# Reads: data_clean/lidar/campus_dtm.tif, campus_dsm.tif, campus_height.tif (the grids script 2 builds),
#        data_clean/lidar_nyc/esb_height.tif (height above ground around the Empire State Building, 1 m)
# Writes: nothing
# Open 25-lidar-drones.Rproj first, so R starts in the project folder; then
#   source("code/3_heights.R")
# It reads the saved grids, so it runs without lidR and without script 2.

# 1). Preliminary ----
# Clean up workspace and load or install necessary packages if necessary
  rm(list = ls())
  want <- c("terra")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only = TRUE))
  rm(want, need)
  options(width = 100); terraOptions(progress = 0)
  misc <- list()
  misc$ground  <- "data_clean/lidar/campus_dtm.tif"      # bare ground, 1 m (script 2, section 4)
  misc$surface <- "data_clean/lidar/campus_dsm.tif"      # highest point per cell, 1 m (script 2, section 5)
  misc$height  <- "data_clean/lidar/campus_height.tif"   # surface minus ground (script 2, section 6)
  misc$esb     <- "data_clean/lidar_nyc/esb_height.tif"

# 2). The grids from script 2 ----
  # ground, surface and height: the three 1 m grids of the campus; g3 holds all three
  ground  <- rast(misc$ground)
  surface <- rast(misc$surface)
  height  <- rast(misc$height)
  g3 <- c(ground, surface, height); names(g3) <- c("ground", "surface", "height")

# 3). McGraw Tower is 50.6 m in the grid ----
  tower <- vect(cbind(377876.1, 4700539.6), crs = crs(g3))   # McGraw Tower
  zone  <- buffer(tower, 20)                                 # every cell within 20 m
  e <- extract(g3, zone)
  nrow(e)
  e[which.max(e$height), ]                                   # the tallest of them

# 4). The Empire State Building is 440 m in the grid ----
  esb <- rast(misc$esb)                                                 # height above ground, 1 m
  b   <- buffer(vect(cbind(585631.7, 4511326.9), crs = crs(esb)), 60)   # 60 m around the building
  max(extract(esb, b)[[2]], na.rm = TRUE)
  esb30 <- aggregate(esb, fact = 30, fun = "mean")                      # 30 x 30 cells into one
  max(extract(esb30, b)[[2]], na.rm = TRUE)

# 5). Exercise 1, solution: McGraw Tower in 5 m and 10 m cells ----
  # In 10 m cells McGraw Tower loses most of its height. height and zone are from sections 2 and 3.
  h5 <- aggregate(height, fact = 5, fun = "mean")
  max(extract(h5, zone)[[2]], na.rm = TRUE)
  h10 <- aggregate(height, fact = 10, fun = "mean")
  max(extract(h10, zone)[[2]], na.rm = TRUE)
  # step 4: the share of its 1 m height each keeps, against the Empire State Building in 30 m cells
  round(c(tower_5m  = max(extract(h5, zone)[[2]], na.rm = TRUE) / 50.6,
          tower_10m = max(extract(h10, zone)[[2]], na.rm = TRUE) / 50.6,
          esb_30m   = 323.7 / 440.3), 2)
  sum(e$height > 40, na.rm = TRUE)                           # cells near the tower above 40 m

# the end ----
