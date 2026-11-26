# AEM 6850, session 26 (Drone & satellite imagery). Satellite images in R
# Script 3 of 7 - the saved catalog search, our Sentinel-2 image of 15 August 2024 read in R, reflectance,
# the median of each band in ESA's classes with zonal(), true and false colour, NDVI, Exercise 1 (the median
# NDVI of plants, bare ground and water), dropping cloudy cells, Practice 1 and 2
# Reads: data_clean/catalog/s2_search_20240810_20240820.csv (the catalog search, saved before class),
#        data/sentinel2/s2_20240815_cayuga_20m.tif (five bands and ESA's class for each cell, 20 m, 37 MB)
# Writes: nothing
# Open 26-satellite-local.Rproj first, so R starts in the project folder; then
#   source("code/3_sentinel2.R")
# Every section matches a slide of the same name. The search itself needs the network, so it is in
# tools/fetch_sentinel2.R and does not run here. Takes about 20 seconds.

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
  misc$search <- "data_clean/catalog/s2_search_20240810_20240820.csv"   # id, tile, date, cloud
  misc$s2     <- "data/sentinel2/s2_20240815_cayuga_20m.tif"           # B02, B03, B04, B8A, B11, SCL
  misc$scale  <- 10000      # the file stores reflectance times 10,000; the offset is already applied

# 2). The image of 15 August 2024 ----
  s2_search <- read.csv("data_clean/catalog/s2_search_20240810_20240820.csv")
  print(s2_search[s2_search$tile == "18TUN", c("id", "date", "cloud")], row.names = FALSE)

# 3). Reading the image in R ----
  s2 <- rast("data/sentinel2/s2_20240815_cayuga_20m.tif")
  s2
  refl <- s2[[1:5]] / 10000                        # reflectance, from 0 to 1

# 4). Reflectance of plants, bare ground and water ----
  m <- zonal(refl, s2$SCL, fun = "median", na.rm = TRUE)   # about 6 seconds
  m[m$SCL >= 4 & m$SCL <= 6, ]
  # page: a cell in mid-lake reads 0.009 in shortwave infrared
  lake <- project(vect(cbind(-76.715, 42.700), crs = "EPSG:4326"), crs(s2))
  round(extract(refl, lake, ID = FALSE), 4)

# 5). True and false colour ----
  box   <- project(vect(ext(-76.56, -76.44, 42.43, 42.50), crs = "EPSG:4326"), crs(refl))
  south <- crop(refl, box)                                     # the south end of the lake
  par(mfrow = c(1, 2))                                         # two pictures side by side
  plotRGB(south, r = 3, g = 2, b = 1, stretch = "lin", mar = c(0, 0, 2, 0), main = "True colour")
  plotRGB(south, r = 4, g = 3, b = 2, stretch = "lin", mar = c(0, 0, 2, 0), main = "False colour")
  par(mfrow = c(1, 1))                                         # back to one plot per page

# 6). NDVI, a vegetation index ----
  ndvi <- (refl$B8A - refl$B04) / (refl$B8A + refl$B04)
  names(ndvi) <- "NDVI"                              # otherwise the layer keeps the name B8A
  plot(ndvi, col = hcl.colors(50, "Greens", rev = TRUE), plg = list(title = "NDVI"))
  # page: the range of NDVI, and the Arts Quad lawn (the 20 m cell that holds the point)
  minmax(ndvi)
  aq <- project(vect(cbind(-76.4855, 42.4489), crs = "EPSG:4326"), crs(s2))   # the Arts Quad
  round(extract(ndvi, aq, ID = FALSE), 3)

# 7). Exercise 1, solution: the median NDVI of plants, bare ground and water ----
  # NDVI puts plants far above bare ground and water. Water still sits above 0.
  # s2 and ndvi are from sections 3 and 6.
  z <- zonal(ndvi, s2$SCL, fun = "median", na.rm = TRUE)
  round(z[z$SCL >= 4 & z$SCL <= 6, ], 2)
  # from lowest to highest: water 0.19, bare ground 0.30, plants 0.84
  # On this date the lake reflects a little more near-infrared (0.047) than red (0.032),
  # so its NDVI is above 0.

# 8). Dropping cloudy cells (page only) ----
  # A cloud mask marks cells hidden by cloud or its shadow: ESA's classes 3 (shadow), 8 and 9 (cloud)
  # and 10 (thin, high cirrus). global() adds up a raster over all its cells.
  cloud <- (s2$SCL == 3) | (s2$SCL >= 8 & s2$SCL <= 10)
  global(cloud, "sum", na.rm = TRUE)                 # 44
  refl_masked <- mask(refl, cloud, maskvalues = TRUE)

# 9). Practice 1: NDVI at four places ----
  # Rank mid-lake, Sapsucker Woods, the Shops at Ithaca Mall parking lot and a field near Aurora by NDVI.
  pl <- data.frame(place = c("mid-lake", "Sapsucker Woods", "mall parking lot", "field near Aurora"),
                   lon = c(-76.654, -76.444, -76.4917, -76.6817),
                   lat = c(42.600, 42.485, 42.4840, 42.7601))
  p <- project(vect(pl, geom = c("lon", "lat"), crs = "EPSG:4326"), crs(s2))
  pl$NDVI <- round(extract(ndvi, p, ID = FALSE)$NDVI, 2)
  pl[order(pl$NDVI), c("place", "NDVI")]

# 10). Practice 2: the five bands at those points ----
  # Which band separates the parking lot from the lake?
  cbind(pl["place"], round(extract(refl, p, ID = FALSE), 3))

# the end ----
