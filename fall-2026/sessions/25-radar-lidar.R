# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# AEM 6850 -- Empirical Methods for Applied Economists
# Prof. Ariel Ortiz-Bobea
# Session 25 -- Radar & LiDAR
# Tuesday, Nov 24, 2026
#
# Run it one line at a time: put the cursor on a line and press Cmd-Return
# (Mac) or Ctrl-Enter (Windows).
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# Preliminary ----
# Clean up workspace and load or install necessary packages if necessary
  rm(list=ls())
  want <- c("terra")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only=TRUE))
  rm(want, need)


# Load or install the four packages ----
want <- c("lidR", "terra", "sf", "exactextractr")
need <- want[!(want %in% installed.packages()[,"Package"])]
if (length(need)) install.packages(need)
lapply(want, function(i) require(i, character.only = TRUE))
rm(want, need)
options(lidR.progress = FALSE); terraOptions(progress = 0)


# Radar elevation in Tompkins County ----
rad <- rast("data_clean/radar/tompkins_copernicus_utm.tif")   # radar elevation, m, 30 m cells
dem <- rast("data_clean/terrain/tompkins_dem_utm.tif")        # USGS ground elevation, m
compareGeom(rad, dem)                                         # TRUE: the same cells


# Radar minus ground elevation ----
towns <- st_read("data_clean/terrain/tompkins_towns.gpkg", quiet = TRUE)
diff <- mask(rad - dem + 0.49, vect(towns))   # radar minus ground in the county, m
diff[dem < 116.45] <- NA                      # drop Cayuga Lake
v <- values(diff, na.rm = TRUE)
round(c(median_m = median(v), pct_above_5m = 100 * mean(v > 5)), 1)


# Each town's share of land above 5 m ----
tall <- exact_extract(diff > 5, towns, "mean", progress = FALSE)
d <- data.frame(town = towns$NAMELSAD, pct_above_5m = round(100 * tall))
d[order(-d$pct_above_5m), ]


# Reading the radar hail raster in R ----
mesh <- rast("data_clean/hail/mesh_20220612.tif")       # largest hail in each cell, mm
mesh
counties <- vect("data_clean/hail/counties_7states.gpkg")
big <- extract(mesh, counties, fun = max)               # largest hail in each county
sum(big[, 2] >= 25.4)                                   # counties with hail of 1 inch or more


# Plot the two radar rasters ----
plot(mesh > 0, main = "Cells with radar hail, 12 June 2022")
refl <- rast("data_clean/hail/reflectivity_20220612.tif")   # reflectivity at midnight Central, dBZ
plot(refl, main = "Radar reflectivity, dBZ")


# Radar hail on 12 June 2022 ----
hail <- read.csv("data_clean/hail/hail_county_day.csv", colClasses = c(geoid = "character"))
cty  <- st_read("data_clean/hail/counties_7states.gpkg", quiet = TRUE)
day  <- hail[hail$date == "2022-06-12", ]                     # one radar day
cty$km2 <- day$km2_1in[match(cty$GEOID, day$geoid)]           # km2 of radar hail of 1 inch or more
cty$km2[is.na(cty$km2)] <- 0
plot(cty["km2"], breaks = c(0, 0.001, 50, 200, 1000, 3000), main = "Radar hail of 1 inch or more, km2")
c(radar_hail = sum(day$km2_1in > 0), with_report = sum(day$km2_1in > 0 & day$reports > 0))


# Radar hail, hail reports and crop insurance ----
hail <- read.csv("data_clean/hail/hail_county_day.csv", colClasses = c(geoid = "character"))
big  <- hail[hail$km2_1in >= 25, ]      # 25 km2 or more of hail of 1 inch or more
round(100 * mean(big$reports == 0))     # percent of these county-days with no report


# No report, by population density ----
round(100 * tapply(big$reports == 0, big$density_fifth, mean))   # Q1 is the least dense fifth


# Radar hail and crop-insurance losses ----
hm  <- read.csv("data_clean/hail/hail_county_month.csv", colClasses = c(geoid = "character"))
auc <- function(score, y) { r <- rank(score); n1 <- sum(y); n0 <- sum(!y); (sum(r[y]) - n1 * (n1 + 1) / 2) / (n1 * n0) }
loss <- hm$loss_usd > 1e5                                       # more than $100,000 of hail losses
round(c(radar = auc(hm$km2_1in, loss), reports = auc(hm$reports, loss)), 2)


# Reading LiDAR data in R ----
las <- readLAS("data_clean/lidar/campus.laz")   # about 2 seconds
las


# Ground points ----
table(las$Classification)                               # 1 other, 2 ground, 7 and 18 noise
las <- filter_poi(las, !Classification %in% c(7, 18))   # drop the noise
npoints(las)


# A slice through McGraw Tower ----
strip <- filter_poi(las, abs(Y - 4700539.6) < 5, !Classification %in% c(7, 18))   # 10 m wide
plot(strip$X - 377600, strip$Z, pch = ".", asp = 2, xlab = "Metres east", ylab = "Elevation, m",
     col = ifelse(strip$Classification == 2, "tan4", "cyan4"))


# Ground elevation ----
ground <- rasterize_terrain(las, res = 1, algorithm = tin())   # bare ground, 1 m cells


# Surface elevation ----
surface <- rasterize_canopy(las, res = 1, algorithm = p2r(na.fill = tin()))   # top point


# The height of buildings and trees ----
height <- surface - ground                         # height above ground, metres
round(range(values(height), na.rm = TRUE), 1)      # lowest and highest


# Checking the rasters on a lawn ----
g3 <- c(ground, surface, height); names(g3) <- c("ground", "surface", "height")
lawn <- vect(cbind(377964.8, 4700674.7), crs = crs(g3))   # a point on the Arts Quad lawn
round(extract(g3, lawn), 2)


# Measuring McGraw Tower in R ----
tower <- vect(cbind(377876.1, 4700539.6), crs = crs(g3))   # McGraw Tower
zone  <- buffer(tower, 20)                                 # every cell within 20 m
e <- extract(g3, zone)
nrow(e)
e[which.max(e$height), ]                                   # the tallest of them


# The Empire State Building in 30 m cells ----
esb <- rast("data_clean/lidar_nyc/esb_height.tif")                    # height above ground, 1 m
b   <- buffer(vect(cbind(585631.7, 4511326.9), crs = crs(esb)), 60)   # 60 m around the building
max(extract(esb, b)[[2]], na.rm = TRUE)
esb30 <- aggregate(esb, fact = 30, fun = "mean")                      # 30 x 30 cells into one
max(extract(esb30, b)[[2]], na.rm = TRUE)


# The Empire State Building in 5 m and 10 m cells ----
sapply(c(5, 10), function(k) round(max(extract(aggregate(esb, fact = k, fun = "mean"), b)[[2]],
                                       na.rm = TRUE), 1))


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Exercise 1 (4 minutes) ----
# Exercise 1 (4 minutes). McGraw Tower in 5 m and 10 m cells.
# In 10 m cells McGraw Tower loses most of its height.
# In the 25-radar-lidar folder, with height and zone as on the slides before
# (or run code/3_heights.R first).
# 1. h5 <- aggregate(height, fact = 5, fun = "mean")      # 5 m cells
# 2. max(extract(h5, zone)[[2]], na.rm = TRUE)            # the tallest 5 m cell near the tower
# 3. Repeat steps 1 and 2 with fact = 10.
# 4. Divide each result by 50.6 m. Compare with 323.7 / 440.3, the Empire State Building in 30 m.
# Two answers to compare with the class: the tower's height in 10 m cells, and the share of its
# height it keeps. Without lidR: height <- rast("data_clean/lidar/campus_height.tif").
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




# Reading the elevation raster and towns ----
dem   <- rast("data_clean/terrain/tompkins_dem_utm.tif")     # elevation, m, 30 m cells
towns <- st_read("data_clean/terrain/tompkins_towns.gpkg", quiet = TRUE)
dem


# Slope with terrain() ----
slope_pct <- tan(terrain(dem, v = "slope", unit = "radians")) * 100   # percent
steep     <- slope_pct > 15                                         # TRUE where steeper than 15%


# Slope from 4 neighbours ----
s4 <- tan(terrain(dem, v = "slope", unit = "radians", neighbors = 4)) * 100
round(100 * c(eight = sum(exact_extract((slope_pct > 15) * 900, towns, "sum", progress = FALSE)),
              four  = sum(exact_extract((s4 > 15) * 900, towns, "sum", progress = FALSE))) /
        sum(towns$ALAND), 1)


# The slope by hand in R ----
tw <- project(vect(cbind(-76.48505, 42.44757), crs = "EPSG:4326"), crs(dem))   # McGraw Tower
rc <- rowColFromCell(dem, cellFromXY(dem, crds(tw)))                          # row 753, col 651
w  <- matrix(values(dem, row = rc[1] - 1, nrows = 3, col = rc[2] - 1, ncols = 3), 3, byrow = TRUE)
dx <- (sum(w[, 3] * c(1, 2, 1)) - sum(w[, 1] * c(1, 2, 1))) / (8 * 30)
dy <- (sum(w[3, ] * c(1, 2, 1)) - sum(w[1, ] * c(1, 2, 1))) / (8 * 30)
round(c(by_hand = 100 * sqrt(dx^2 + dy^2), terrain = extract(slope_pct, tw)[1, 2]), 3)


# Steep land in each town ----
s <- exact_extract(steep * 900, towns, "sum", progress = FALSE)     # m2 steeper than 15%
d <- data.frame(town = towns$NAMELSAD, pct_of_land = round(100 * s / towns$ALAND, 1))
d[order(-d$pct_of_land), ]


# Steep land in the county ----
round(c(km2_steep = sum(s) / 1e6, km2_land = sum(towns$ALAND) / 1e6,
        pct = 100 * sum(s) / sum(towns$ALAND)), 1)


# Computing the view in R ----
tw   <- project(vect(cbind(-76.48505, 42.44757), crs = "EPSG:4326"), crs(dem))   # McGraw Tower
top  <- viewshed(dem, crds(tw), observer = 53, target = 0)    # TRUE where visible
round(global(top, "sum", na.rm = TRUE)[[1]] * 900 / 1e6, 1)   # km2 in view
land <- dem > 116.45                         # 0.5 m above the lake's flat surface
towns$top <- round(100 * exact_extract(top * land * 900, towns, "sum", progress = FALSE) /
                   towns$ALAND, 1)


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Exercise 2 (4 minutes) ----
# Exercise 2 (4 minutes). The view from the ground at McGraw Tower.
# What you see depends on how high your eye is.
# In the 25-radar-lidar folder, with dem, tw, land and towns as on the slides before
# (or run code/5_views.R up to this exercise).
# 1. gnd <- viewshed(dem, crds(tw), observer = 1.7, target = 0)
# 2. The area in view in km2, as on the slide before.
# 3. Each town's share of land in view, as on the slide before, in a column towns$gnd.
# 4. towns[, c("NAMELSAD", "top", "gnd"), drop = TRUE] sets the two columns side by side.
# Two answers to compare with the class: the area in view from the ground against 236.5 km2,
# and the towns whose share falls to zero.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




# Turning the view into polygons ----
view <- disagg(as.polygons(ifel(top, 1, NA)))   # one polygon per separate piece
nrow(view)


# The area of the pieces ----
round(sum(expanse(view)) / 1e6, 1)


# Flow direction and accumulation in R ----
filled <- rast("data_clean/terrain/fallcreek_dem_filled.tif")   # 30 m, pits filled before class
fd  <- terrain(filled, v = "flowdir")                          # the neighbour each cell drains to
acc <- flowAccumulation(fd)                                    # cells draining through each cell


# Computing the watershed in R ----
gauge <- project(vect(cbind(-76.47278, 42.45333), crs = "EPSG:4269"), crs(fd))
e  <- extract(acc, buffer(gauge, 150), cells = TRUE)
ws <- terra::watershed(fd, xyFromCell(acc, e$cell[which.max(e[[2]])]))   # 1 = drains to the gauge
round(global(ws, "sum", na.rm = TRUE)[[1]] * 900 / 1e6, 1)              # km2


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Practice ----
# Practice. Run in the 25-radar-lidar folder after the slides' code has built
# las, ground, surface, height, g3, dem, towns, slope_pct, steep, tw, land, top, fd and acc.

# Heights
#  1. The tallest objects on campus: the five tallest cells of height, each at least 30 m from a
#     taller one. Which is McGraw Tower?
#  2. Tree or roof from the returns: at each of the five, the share of points within 3 m (and more
#     than 2 m above the ground) from pulses with several returns (NumberOfReturns > 1).
#  3. The surface grid without na.fill: rasterize_canopy(las, res = 1, algorithm = p2r()).
#     How many cells stay empty, and where?
# Slope
#  4. The polygon mean against the share of land: exact_extract(steep, towns, "mean").
#     Which towns move most, and why?
#  5. The 15% threshold in degrees: terrain(dem, v = "slope") is in degrees. Which angle is 15%,
#     and does the county's share change?
#  6. Other thresholds: each town's share of land steeper than 10% and than 25%.
# Views
#  7. A target 1.7 m tall: can someone at the top of the tower see a person standing anywhere?
#     viewshed() with target = 1.7. The area in view and Ithaca city's share.
#  8. The view from a point of your choice, from 1.7 m.
# Watersheds
#  9. The basin on the grid as downloaded: data_clean/terrain/fallcreek_dem_utm.tif, with the
#     same 150 m snap. Why is it so small?
# 10. The basin's towns: the km2 of the basin in each Tompkins town, and the share of the basin
#     inside the county.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =


# The end
