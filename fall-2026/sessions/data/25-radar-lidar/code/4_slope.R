# AEM 6850, session 25 (Radar & LiDAR). Slope
# Script 4 of 6 - the 30 m elevation grid of Tompkins County, slope with terrain(), one cell's slope by
# hand, each town's share of land steeper than 15%
# Reads: data_clean/terrain/tompkins_dem_utm.tif (USGS's 1 arc-second grid, projected to UTM zone 18N),
#        data_clean/terrain/tompkins_towns.gpkg (the county's nine towns and the city of Ithaca)
# Writes: nothing
# Open 25-radar-lidar.Rproj first, so R starts in the project folder; then
#   source("code/4_slope.R")

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
  misc$steep <- 15                                          # percent rise (Saiz, QJE 2010)

# 2). The 30 m elevation grid of Tompkins County ----
  dem   <- rast(misc$dem)                                    # elevation, m, 30 m cells
  towns <- st_read(misc$towns, quiet = TRUE)
  dem

# 3). Slope with terrain() ----
  slope_pct <- tan(terrain(dem, v = "slope", unit = "radians")) * 100   # percent
  steep     <- slope_pct > 15                                         # TRUE where steeper than 15%
  plot(steep, col = c("grey90", "firebrick"), legend = FALSE)
  plot(st_geometry(towns), add = TRUE)

# 4). One cell's slope by hand ----
  tw <- project(vect(cbind(-76.48505, 42.44757), crs = "EPSG:4326"), crs(dem))   # McGraw Tower
  rc <- rowColFromCell(dem, cellFromXY(dem, crds(tw)))                          # row 753, col 651
  w  <- matrix(values(dem, row = rc[1] - 1, nrows = 3, col = rc[2] - 1, ncols = 3), 3, byrow = TRUE)
  dx <- (sum(w[, 3] * c(1, 2, 1)) - sum(w[, 1] * c(1, 2, 1))) / (8 * 30)
  dy <- (sum(w[3, ] * c(1, 2, 1)) - sum(w[1, ] * c(1, 2, 1))) / (8 * 30)
  round(c(by_hand = 100 * sqrt(dx^2 + dy^2), terrain = extract(slope_pct, tw)[1, 2]), 3)
  round(w, 2)                                         # the 3 x 3 window, north at the top
  c(dx = dx, dy = dy)

# 5). Steep land in each town ----
  s <- exact_extract(steep * 900, towns, "sum", progress = FALSE)     # m2 steeper than 15%
  d <- data.frame(town = towns$NAMELSAD, pct_of_land = round(100 * s / towns$ALAND, 1))
  d[order(-d$pct_of_land), ]
  round(100 * sum(s) / sum(towns$ALAND), 1)           # the county, percent of land

# the end ----
