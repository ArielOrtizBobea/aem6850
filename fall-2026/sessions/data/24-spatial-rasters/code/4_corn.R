# AEM 6850, session 24 (Spatial II: rasters). An application to heat and corn yields
# Script 4 of 5 - each county's 2012 corn yield against its 2002-2011 mean, degree days above 29 °C in each
# cell, cropland moved onto the temperature grid, county heat over cropland, heat against the yield change
# Reads: data_clean/tmax_july2012.tif, data/census/cb_2024_us_county_500k.zip, cb_2024_us_state_500k.zip,
#        data_clean/corn_yield_2002_2012.csv, data_clean/cropland_2011.tif
# Writes: data_clean/counties/ and data_clean/states/ (the two zips, unzipped)
# Open 24-spatial-rasters.Rproj first, so R starts in the project folder; then
#   source("code/4_corn.R")
# Every section matches a slide of the same name; the live script 24-spatial-rasters.R runs them all in order.

# 1). Preliminary ----
# Clean up workspace and load or install necessary packages if necessary
  rm(list = ls())
  want <- c("terra", "sf", "exactextractr", "Matrix")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only = TRUE))
  rm(want, need)
  misc <- list()
  misc$july   <- "data_clean/tmax_july2012.tif"                # the 31 days of July 2012 in one file
  misc$county <- "data/census/cb_2024_us_county_500k.zip"      # the Census county outlines
  misc$shp    <- "data_clean/counties/cb_2024_us_county_500k.shp"
  misc$wh     <- c(lon = -76.4797, lat = 42.4490)              # Warren Hall, Cornell, Ithaca
  misc$off    <- c("AK", "HI", "PR", "GU", "VI", "AS", "MP")   # Alaska, Hawaii and the five territories

# 2). The layers from earlier scripts ----
  # tmax and its matrix M; wh, Warren Hall; low, the 3,109 counties of the lower 48 and DC;
  # tabN, their table of cells and fractions; P, the area weights (about 3 seconds)
  tmax <- rast(misc$july)
  M    <- values(tmax)
  wh   <- project(vect(cbind(lon = misc$wh[1], lat = misc$wh[2]), crs = "EPSG:4326"), crs(tmax))
  if (!file.exists(misc$shp)) unzip(misc$county, exdir = "data_clean/counties")
  co   <- st_read(misc$shp, quiet = TRUE)
  low  <- co[!(co$STUSPS %in% misc$off), ]
  info <- exact_extract(tmax[[1]], low, include_cell = TRUE, progress = FALSE)
  tabN <- data.frame(county = rep(1:nrow(low), sapply(info, nrow)), do.call(rbind, info))
  tabN <- tabN[!is.na(tabN$value), ]
  tabN$w <- tabN$coverage_fraction / ave(tabN$coverage_fraction, tabN$county, FUN = sum)
  P    <- sparseMatrix(i = tabN$county, j = tabN$cell, x = tabN$w, dims = c(nrow(low), ncell(tmax)))

# 3). The 2012 yield against each county's 2002 to 2011 mean ----
  y    <- read.csv("data_clean/corn_yield_2002_2012.csv", colClasses = c(GEOID = "character"))
  yw   <- tapply(y$yield, list(y$GEOID, y$year), mean)                 # counties by years
  base <- rowMeans(yw[, as.character(2002:2011)], na.rm = TRUE)        # each county's 2002-2011 mean
  nb   <- rowSums(!is.na(yw[, as.character(2002:2011)]))               # years reported out of ten
  chg  <- 100 * (yw[, "2012"] / base - 1)                              # 2012 against that mean, %
  chg[nb < 8] <- NA
  low$chg <- chg[match(low$GEOID, names(chg))]
  c(report_2012 = sum(!is.na(yw[, "2012"])), with_8_years = sum(!is.na(low$chg)))

# 4). Heat above 29 °C in each cell ----
  heat <- sum((tmax - 29) * (tmax > 29))          # each day's degrees above 29, summed over 31 days
  round(range(values(heat), na.rm = TRUE))
  round(unlist(extract(heat, wh, ID = FALSE)), 1) # Warren Hall

# 5). The heat as a matrix ----
  nlyr(max(tmax - 29, 0))                         # one layer: a different quantity
  system.time(hm <- rowSums(pmax(M - 29, 0)))     # the same heat, from the matrix of cells by days
  max(abs(hm - values(heat)[, 1]), na.rm = TRUE)

# 6). Cropland on the temperature grid ----
  crops <- rast("data_clean/cropland_2011.tif")   # percent of each cell under crops, 0 to 100
  res(crops)
  cropg <- project(crops, tmax, method = "average")   # the average share over each temperature cell
  round(unlist(extract(cropg, wh, ID = FALSE)), 1)    # Warren Hall's cell, percent under crops

# 7). Cropland on a map, and the two grids compared ----
  compareGeom(crops, tmax, stopOnError = FALSE)
  compareGeom(cropg, tmax, stopOnError = FALSE)
  unzip("data/census/cb_2024_us_state_500k.zip", exdir = "data_clean/states")
  st <- st_read("data_clean/states/cb_2024_us_state_500k.shp", quiet = TRUE)
  plot(cropg, axes = FALSE, col = hcl.colors(50, "YlGn", rev = TRUE))
  lines(vect(st[st$STUSPS %in% low$STUSPS, ]), lwd = 0.4)

# 8). County heat over cropland ----
  tabN$wc <- tabN$coverage_fraction * values(cropg)[tabN$cell]   # fraction times cropland share
  tabN$wc <- tabN$wc / ave(tabN$wc, tabN$county, FUN = sum)      # 0/0 in a county with no cropland
  Pc <- sparseMatrix(i = tabN$county, j = tabN$cell, x = tabN$wc, dims = dim(P))
  low$heat      <- as.vector(Pc %*% values(heat))                # heat over each county's cropland
  low$heat_area <- as.vector(P %*% values(heat))                 # heat over the whole county
  sum(is.na(low$heat))                                           # counties with no cropland
  k <- match(c("17019", "47153"), low$GEOID)                     # Champaign, IL and Sequatchie, TN
  data.frame(county = low$NAME[k], over_cropland = round(low$heat[k], 1),
             whole_county = round(low$heat_area[k], 1))

# 9). County heat over cropland, on a map ----
  east <- low[st_coordinates(st_centroid(st_geometry(low)))[, 1] > -100, ]   # east of 100 W
  plot(east["heat"], main = "", border = NA)
  paste(low$NAME, low$STUSPS)[is.na(low$heat)]

# 10). Heat against the yield change ----
  lon <- st_coordinates(st_centroid(st_geometry(low)))[, 1]      # each county's centre, longitude
  d   <- st_drop_geometry(low[!is.na(low$chg) & !is.na(low$heat) & lon > -100, ])
  fit <- lm(chg ~ heat, d)
  c(counties = nrow(d), correlation = round(cor(d$heat, d$chg), 2), slope = round(coef(fit)[[2]], 2))
  round(tapply(d$chg, d$STUSPS, median)[c("MO", "KY", "IL", "IN", "IA", "MN")])

# the end ----
