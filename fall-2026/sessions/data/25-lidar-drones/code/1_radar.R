# AEM 6850, session 25 (Radar & LiDAR). Radar data in R
# Script 1 of 6 - the radar elevation raster of Tompkins County, radar minus USGS's ground elevation, each
# town's share of land more than 5 m above the ground; radar hail on 12 June 2022, radar hail against hail
# reports and crop-insurance hail losses (my own preliminary work)
# Reads: data_clean/radar/tompkins_copernicus_utm.tif (Copernicus 30 m elevation from the TanDEM-X radar
#          satellites, put on the cells of USGS's raster before class),
#        data_clean/terrain/tompkins_dem_utm.tif (USGS's ground elevation, made from LiDAR),
#        data_clean/terrain/tompkins_towns.gpkg (the county's nine towns and the city of Ithaca),
#        data_clean/hail/ (radar hail, hail reports and crop-insurance hail losses by county, seven Plains
#          states, April to September 2021 to 2025, from my hail pilot)
# Writes: nothing
# Open 25-lidar-drones.Rproj first, so R starts in the project folder; then
#   source("code/1_radar.R")
# Every section matches a slide of the same name. Takes about 5 seconds.

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
  misc$radar  <- "data_clean/radar/tompkins_copernicus_utm.tif"   # radar elevation, m, 30 m cells
  misc$dem    <- "data_clean/terrain/tompkins_dem_utm.tif"         # USGS ground elevation, m, 30 m cells
  misc$towns  <- "data_clean/terrain/tompkins_towns.gpkg"
  misc$offset <- 0.49    # radar sits 0.49 m below USGS on flat fields (logs/prep_radar.txt)
  misc$lake   <- 116.45  # Cayuga Lake is flat at 115.95 m in USGS's raster; cells below 116.45 m are lake

# 2). Radar elevation in Tompkins County ----
  rad <- rast(misc$radar)     # radar elevation, m, 30 m cells
  dem <- rast(misc$dem)       # USGS ground elevation from LiDAR, m
  rad
  compareGeom(rad, dem)       # TRUE: the same cells

# 3). Radar minus LiDAR ----
  towns <- st_read(misc$towns, quiet = TRUE)
  diff  <- rad - dem + misc$offset           # radar minus ground, m
  diff  <- mask(diff, vect(towns))           # the county only
  diff[dem < misc$lake] <- NA                # drop Cayuga Lake
  v <- values(diff, na.rm = TRUE)
  round(c(median_m = median(v), pct_above_5m = 100 * mean(v > 5)), 1)
  # each town's share of land more than 5 m above the ground
  tall <- exact_extract(diff > 5, towns, "mean", progress = FALSE)
  d <- data.frame(town = towns$NAMELSAD, pct_above_5m = round(100 * tall))
  d[order(-d$pct_above_5m), ]

# 4). The radar hail raster of 12 June 2022 ----
  mesh <- rast("data_clean/hail/mesh_20220612.tif")   # largest hail in each cell, mm
  mesh
  plot(mesh > 0, main = "Cells with radar hail, 12 June 2022")
  counties <- vect("data_clean/hail/counties_7states.gpkg")
  big <- extract(mesh, counties, fun = max)            # largest hail in each county
  sum(big[, 2] >= 25.4)                                # counties with hail of 1 inch or more
  refl <- rast("data_clean/hail/reflectivity_20220612.tif")   # reflectivity at midnight Central, dBZ
  plot(refl, main = "Radar reflectivity, dBZ")

# 5). Radar hail by county, 12 June 2022 ----
  hail <- read.csv("data_clean/hail/hail_county_day.csv", colClasses = c(geoid = "character"))
  cty  <- st_read("data_clean/hail/counties_7states.gpkg", quiet = TRUE)
  day  <- hail[hail$date == "2022-06-12", ]                     # one radar day
  cty$km2 <- day$km2_1in[match(cty$GEOID, day$geoid)]           # km2 of radar hail of 1 inch or more
  cty$km2[is.na(cty$km2)] <- 0
  plot(cty["km2"], breaks = c(0, 0.001, 50, 200, 1000, 3000), main = "Radar hail of 1 inch or more, km2")
  c(radar_hail = sum(day$km2_1in > 0), with_report = sum(day$km2_1in > 0 & day$reports > 0))

# 6). Radar hail, hail reports and crop insurance ----
  big <- hail[hail$km2_1in >= 25, ]       # county-days with 25 km2 or more of radar hail of 1 inch or more
  round(100 * mean(big$reports == 0))     # percent with no hail report
  round(100 * tapply(big$reports == 0, big$density_fifth, mean))   # by population density, Q1 least dense
  # Which ranks county-months with large hail losses higher: radar hail or the count of reports?
  # The AUC is the chance that a county-month with more than $100,000 of losses scores higher than one without.
  hm  <- read.csv("data_clean/hail/hail_county_month.csv", colClasses = c(geoid = "character"))
  auc <- function(score, y) { r <- rank(score); n1 <- sum(y); n0 <- sum(!y); (sum(r[y]) - n1 * (n1 + 1) / 2) / (n1 * n0) }
  loss <- hm$loss_usd > 1e5
  round(c(radar = auc(hm$km2_1in, loss), reports = auc(hm$reports, loss)), 2)

# the end ----
