# AEM 6850, session 24 (Spatial II: rasters). Raster data in R
# Script 1 of 5 - read one day of temperature, a raster as a matrix, one layer per day, crop to New York,
# a point's value on every day, Exercise 1
# Reads: data/prism/prism_tmax_us_25m_20120717.zip, data_clean/tmax_july2012.tif,
#        data/census/cb_2024_us_county_500k.zip
# Writes: data_clean/prism/ and data_clean/counties/ (the two zips, unzipped)
# Open 24-spatial-rasters.Rproj first, so R starts in the project folder; then
#   source("code/1_raster.R")
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
  misc$day    <- "data/prism/prism_tmax_us_25m_20120717.zip"   # one day as PRISM serves it
  misc$july   <- "data_clean/tmax_july2012.tif"                # the 31 days of July 2012 in one file
  misc$county <- "data/census/cb_2024_us_county_500k.zip"      # the Census county outlines
  misc$wh     <- c(lon = -76.4797, lat = 42.4490)              # Warren Hall, Cornell, Ithaca

# 2). Reading one day of temperature ----
  unzip("data/prism/prism_tmax_us_25m_20120717.zip", exdir = "data_clean/prism")   # seven files
  r <- rast("data_clean/prism/prism_tmax_us_25m_20120717.tif")    # the .tif holds the grid
  r

# 3). What is in PRISM's zip ----
  unzip("data/prism/prism_tmax_us_25m_20120717.zip", list = TRUE)$Name

# 4). A raster is a matrix with coordinates ----
  vals <- values(r)                               # every cell's value, row by row from the top left
  c(rows = nrow(r), columns = ncol(r), cells = nrow(vals), with_value = sum(!is.na(vals)))
  i <- cellFromXY(r, cbind(-76.4797, 42.4490))    # Warren Hall's cell (longitude, latitude)
  i                                               # (180 - 1) x 1,405 + 1,165
  rowColFromCell(r, i)                            # its row and column
  vals[i]                                         # its value in the 17 July layer, degrees C

# 5). One layer per day ----
  tmax <- rast("data_clean/tmax_july2012.tif")    # the 31 daily grids of July 2012 in one file
  nlyr(tmax)
  names(tmax)[c(1, 2, 31)]
  range(time(tmax))                               # the dates, stored as dates
  dim(values(tmax))                               # cells by days
  values(tmax)[i, 16:18]                          # Warren Hall's cell on 16, 17 and 18 July

# 6). Cropping and masking to New York ----
  unzip("data/census/cb_2024_us_county_500k.zip", exdir = "data_clean/counties")
  co  <- st_read("data_clean/counties/cb_2024_us_county_500k.shp", quiet = TRUE)   # county outlines
  ny  <- co[co$STUSPS == "NY", ]                  # New York's 62 counties
  st_crs(ny) == st_crs(tmax)                      # do the counties and the grid share one CRS?
  tny <- crop(tmax, ny)                           # the cells inside New York's bounding box
  dim(tny)
  cellFromXY(tny, cbind(-76.4797, 42.4490))       # Warren Hall's cell number in the smaller grid
  tny_in <- mask(tny, ny)                         # NA in every cell whose centre is outside New York

# 7). The crop and the mask on a map ----
  par(mfrow = c(1, 2))
  plot(tny[["2012-07-17"]], main = "crop()", legend = FALSE, axes = FALSE); lines(vect(ny), lwd = 0.5)
  plot(tny_in[["2012-07-17"]], main = "mask()", axes = FALSE); lines(vect(ny), lwd = 0.5)
  c(crop = sum(!is.na(values(tny[["2012-07-17"]]))),
    mask = sum(!is.na(values(tny_in[["2012-07-17"]]))))
  par(mfrow = c(1, 1))

# 8). Daily temperature at Warren Hall ----
  wh <- vect(cbind(lon = -76.4797, lat = 42.4490), crs = "EPSG:4326")   # Warren Hall: longitude first
  wh <- project(wh, crs(tny))                     # the point in the grid's coordinate system
  wh_t <- unlist(extract(tny, wh, ID = FALSE))    # the value of Warren Hall's cell in each layer
  round(wh_t[16:19], 1)
  data.frame(hottest = names(which.max(wh_t)), degrees = round(max(wh_t), 1),
             days_above_30 = sum(wh_t > 30))

# 9). Warren Hall's 31 days on a plot ----
  par(mar = c(3, 4.2, 1, 1), las = 1, bty = "n")
  plot(time(tny), wh_t, type = "b", pch = 19, xlab = "", ylab = "°C, Warren Hall's cell")
  abline(h = 30, lty = 2)
  text(time(tny)[which.max(wh_t)], max(wh_t), "35.8 °C", pos = 4)

# 10). Exercise 1: the hottest July 2012 layer at five places ----
  pl <- data.frame(name = c("Times Square", "Willis Tower, Chicago", "Des Moines",
                            "Furnace Creek, Death Valley", "Toronto"),
                   lon = c(-73.9855, -87.6359, -93.6250, -116.8669, -79.3832),
                   lat = c(40.7580, 41.8789, 41.5868, 36.4572, 43.6532))
  p  <- project(vect(pl, geom = c("lon", "lat"), crs = "EPSG:4326"), crs(tmax))
  X  <- as.matrix(extract(tmax, p, ID = FALSE))                       # places by days
  data.frame(name = pl$name, hottest = names(tmax)[apply(X, 1, function(z) which.max(z)[1])],
             degrees = round(apply(X, 1, max), 1), days_above_30 = rowSums(X > 30))

# the end ----
