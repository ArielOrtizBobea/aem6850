# AEM 6850, session 26 (Drone & satellite imagery). Uses in economics
# Script 4 of 7 - lights at night summed in New York's 62 counties against their population, the NDVI of
# cropland and forest in August on ESA's land-cover map, Practice 7 (the bands of ESA's land-cover types)
# and Practice 8 (urban sprawl around Ithaca and Auburn)
# Reads: data/lights/ntl_viirs_2023_ny.tif (VIIRS lights at night, mean of 2023, 2.3 MB),
#        data_clean/census/ny_counties.gpkg (the 62 counties with their 2023 population),
#        data/sentinel2/s2_20240815_cayuga_20m.tif (our image of 15 August 2024),
#        data/worldcover/worldcover2021_cayuga.tif (ESA WorldCover 2021, 10 m, 2 MB)
# Writes: nothing
# Open 26-satellite-local.Rproj first, so R starts in the project folder; then
#   source("code/4_uses.R")
# Every section matches a slide of the same name. Takes about 45 seconds (the county sums take 20).

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
  misc$viirs <- "data/lights/ntl_viirs_2023_ny.tif"        # mean light at night, 2023, nW/cm2/sr
  misc$ny    <- "data_clean/census/ny_counties.gpkg"       # 62 counties, pop2023 and pop2013
  misc$s2    <- "data/sentinel2/s2_20240815_cayuga_20m.tif"
  misc$wc    <- "data/worldcover/worldcover2021_cayuga.tif"
  # s2, refl and ndvi as in script 3 (Reading the image in R; NDVI, a vegetation index)
  s2   <- rast(misc$s2)
  refl <- s2[[1:5]] / 10000
  ndvi <- (refl$B8A - refl$B04) / (refl$B8A + refl$B04)
  names(ndvi) <- "NDVI"

# 2). Lights and population in New York's counties ----
  viirs <- rast("data/lights/ntl_viirs_2023_ny.tif")             # mean light at night, 2023
  ny    <- vect("data_clean/census/ny_counties.gpkg")            # 62 counties, 2023 population
  s     <- extract(viirs, ny, fun = sum, na.rm = TRUE, exact = TRUE)  # exact: share of each cell inside
  cor(log(s[, 2]), log(ny$pop2023))                              # column 2 holds the sums

# 3). Urban sprawl from land-cover maps ----
  # The page's sprawl index for Ithaca and Auburn is Practice 8, at the end of this script.

# 4). NDVI of cropland and forest in August ----
  wc <- rast("data/worldcover/worldcover2021_cayuga.tif")
  names(wc) <- "esa"
  wc20 <- project(wc, s2, method = "mode")           # each 20 m cell takes its most common class
  z <- zonal(ndvi, wc20, fun = "median", na.rm = TRUE)
  z$type <- c("trees", "grass", "crops", "built", "bare", "water", "wetland")
  z$NDVI <- round(z$NDVI, 2)
  z[z$esa %in% c(10, 40, 80), c("type", "NDVI")]
  z                                                  # page: all seven types

# 5). Practice 7: the bands of ESA's land-cover types ----
  # Take the median of each band within ESA's types. Which band puts built cells (50) furthest from
  # crops (40)?
  zb <- zonal(refl, wc20, fun = "median", na.rm = TRUE)          # about 11 seconds
  round(zb, 3)
  round(zb[zb$esa == 50, -1] - zb[zb$esa == 40, -1], 3)          # built minus crops, by band

# 6). Practice 8: urban sprawl around Ithaca and Auburn ----
  # Compute Burchfield et al.'s sprawl index from ESA's map: put it on 30 m cells, call a cell developed
  # when at least half of it is built-up, then average the share of undeveloped land in the square
  # kilometre around each developed cell (a window of 33 x 33 cells of 30 m).
  sprawl <- function(xmin, xmax, ymin, ymax, wcc) {
    x <- crop(wcc, ext(xmin - 0.02, xmax + 0.02, ymin - 0.015, ymax + 0.015))
    tmpl <- rast(project(ext(x), "EPSG:4326", "EPSG:32618"), res = 30, crs = "EPSG:32618")
    dev <- project(x == 50, tmpl, method = "average") >= 0.5            # developed 30 m cells
    und <- focal(1 - dev, w = 33, fun = "mean", na.rm = TRUE)           # undeveloped share around
    inner <- project(vect(ext(xmin, xmax, ymin, ymax), crs = "EPSG:4326"), "EPSG:32618")
    d <- values(crop(dev, inner))[, 1] == 1
    round(100 * mean(values(crop(und, inner))[d, 1], na.rm = TRUE), 1)
  }
  c(Ithaca = sprawl(-76.56, -76.44, 42.41, 42.50, wc),
    Auburn = sprawl(-76.62, -76.50, 42.89, 42.97, wc))

# the end ----
