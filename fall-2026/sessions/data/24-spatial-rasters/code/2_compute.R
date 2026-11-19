# AEM 6850, session 24 (Spatial II: rasters). Raster calculations
# Script 2 of 5 - arithmetic cell by cell, counting days, two grids with different cells, wind speed and
# direction, and three more uses of a grid (the session page)
# Reads: data_clean/tmax_july2012.tif, data/census/cb_2024_us_county_500k.zip,
#        data_clean/u10_ny_20120717.tif, data_clean/v10_ny_20120717.tif, data_clean/cropland_2011.tif
# Writes: data_clean/counties/ (the county zip, unzipped, if script 1 has not done it)
# Open 24-spatial-rasters.Rproj first, so R starts in the project folder; then
#   source("code/2_compute.R")
# Every section matches a slide of the same name; the live script 24-spatial-rasters.R runs them all in order.

# 1). Preliminary ----
# Clean up workspace and load or install necessary packages if necessary
  rm(list = ls())
  want <- c("terra", "sf")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only = TRUE))
  rm(want, need)
  misc <- list()
  misc$july   <- "data_clean/tmax_july2012.tif"                # the 31 days of July 2012 in one file
  misc$county <- "data/census/cb_2024_us_county_500k.zip"      # the Census county outlines
  misc$shp    <- "data_clean/counties/cb_2024_us_county_500k.shp"
  misc$wh     <- c(lon = -76.4797, lat = 42.4490)              # Warren Hall, Cornell, Ithaca

# 2). The layers from earlier scripts ----
  # tmax, the 31 days; ny, New York's counties; tny, the days cropped to New York; wh, Warren Hall
  tmax <- rast(misc$july)
  if (!file.exists(misc$shp)) unzip(misc$county, exdir = "data_clean/counties")
  co   <- st_read(misc$shp, quiet = TRUE)
  ny   <- co[co$STUSPS == "NY", ]
  tny  <- crop(tmax, ny)
  wh   <- project(vect(cbind(lon = misc$wh[1], lat = misc$wh[2]), crs = "EPSG:4326"), crs(tny))

# 3). 17 July minus July's mean ----
  t17 <- tny[["2012-07-17"]]
  dev <- t17 - mean(tny)                          # mean() of a stack averages its 31 layers
  round(range(values(dev), na.rm = TRUE), 1)
  g <- c(t17, mean(tny), dev); names(g) <- c("day", "month_mean", "difference")   # c() stacks layers
  round(unlist(extract(g, wh, ID = FALSE)), 1)    # Warren Hall
  plot(g, nc = 3, fun = function() lines(vect(ny)))

# 4). Days above 30 °C in New York ----
  hot <- sum(tny > 30)                            # TRUE or FALSE per cell and day; sum() counts TRUE
  range(values(hot), na.rm = TRUE)
  unlist(extract(hot, wh, ID = FALSE))            # Warren Hall
  plot(mask(hot, ny)); lines(vect(ny))

# 5). Two grids with different cells ----
  u <- rast("data_clean/u10_ny_20120717.tif")     # wind toward the east, m/s, one layer per hour
  res(u); res(tny)                                # cell size in degrees
  compareGeom(u, tny, stopOnError = FALSE)        # do the two grids have the same cells?
  u4 <- project(u[["18:00"]], tny)                # weighted mean of nearby wind cells, in tny's CRS
  compareGeom(u4, tny, stopOnError = FALSE)
  round(c(before = extract(u[["18:00"]], project(wh, crs(u)), ID = FALSE)[1, 1],
          after = extract(u4, wh, ID = FALSE)[1, 1]), 2)        # Warren Hall, m/s

# 6). The wind at Warren Hall ----
  v10  <- rast("data_clean/v10_ny_20120717.tif")  # wind toward the north, metres per second
  kmh  <- sqrt(u^2 + v10^2) * 3.6                 # speed: 1 metre per second is 3.6 km/h
  from <- (atan2(-u, -v10) * 180 / pi) %% 360     # where the wind comes from, clockwise from north
  now  <- c(u[["18:00"]], v10[["18:00"]], kmh[["18:00"]], from[["18:00"]])
  names(now) <- c("u", "v", "kmh", "from")
  round(unlist(extract(now, project(wh, crs(u)), ID = FALSE)), 1)    # Warren Hall at 18:00 UTC

# 7). The cell as the unit of observation ----
  dim(as.data.frame(t17, xy = TRUE))              # x, y and the value
  dim(as.data.frame(tny, xy = TRUE))              # x, y and one column per day

# 8). The cells around each cell ----
  fo <- focal(t17, w = 3, fun = "mean")           # mean of each cell and its eight neighbours
  round(c(cell = extract(t17, wh, ID = FALSE)[1, 1], around = extract(fo, wh, ID = FALSE)[1, 1]), 2)

# 9). Categories in cells ----
  cr  <- rast("data_clean/cropland_2011.tif")                  # percent of each cell under crops
  nyw <- project(vect(ny), crs(cr))                            # New York in the grid's CRS
  cl  <- classify(mask(crop(cr, nyw), nyw), c(-Inf, 1, 25, 50, Inf))   # four classes
  f   <- freq(cl)
  data.frame(class = c("1% or less", "1 to 25%", "25 to 50%", "over 50%"),
             percent_of_cells = round(100 * f$count / sum(f$count), 1))

# the end ----
