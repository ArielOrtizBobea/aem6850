# AEM 6850, session 26 (Drone & satellite imagery). Measurement error
# Script 6 of 7 - forest loss in Mexico in numbers, the older lights series that stops at 63 (every
# Manhattan cell reads 63), the correlation of lights and population in both series, Practice 5
# Reads: data/lights/ntl_li2020_2013_ny.tif (Li et al.'s older series for 2013, 0 to 63, 0.14 MB),
#        data/lights/ntl_viirs_2023_ny.tif (VIIRS lights at night, mean of 2023),
#        data_clean/census/ny_counties.gpkg (the 62 counties with their population)
# Writes: nothing
# Open 26-satellite-local.Rproj first, so R starts in the project folder; then
#   source("code/6_error.R")
# Every section matches a slide of the same name. Takes about 25 seconds (the VIIRS county sums take 20).

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
  misc$li    <- "data/lights/ntl_li2020_2013_ny.tif"          # older series, 2013, 0 to 63
  misc$viirs <- "data/lights/ntl_viirs_2023_ny.tif"          # VIIRS, mean of 2023
  misc$ny    <- "data_clean/census/ny_counties.gpkg"
  misc$nyc   <- c("Bronx", "Kings", "New York", "Queens", "Richmond")   # New York City's five counties

# 2). Forest loss in Mexico ----
  # Alix-Garcia & Millimet's numbers: the map shows 49 of 100 real losses, and loss in 1.2 of 100
  # parcel-years with none. With a true share of loss near 34%, the map shows loss in about 17%.
  0.49 * 0.34 + 0.012 * 0.66

# 3). Lights stop counting at 63 ----
  li <- rast("data/lights/ntl_li2020_2013_ny.tif")             # older series, 0 to 63
  ny <- vect("data_clean/census/ny_counties.gpkg")
  x  <- extract(li, ny[ny$NAME == "New York", ])               # Manhattan's cells
  c(cells = nrow(x), at_63 = sum(x[[2]] == 63))
  # page: the correlation of log lights and log 2013 population, with and without New York City
  sl  <- extract(li, ny, fun = sum, na.rm = TRUE, exact = TRUE)
  nyc <- ny$NAME %in% misc$nyc
  round(c(all = cor(log(sl[, 2]), log(ny$pop2013)),
          without_nyc = cor(log(sl[!nyc, 2]), log(ny$pop2013[!nyc]))), 3)

# 4). Practice 5: lights without New York City ----
  # Drop Bronx, Kings, New York, Queens and Richmond and recompute both correlations.
  viirs <- rast(misc$viirs)
  s <- extract(viirs, ny, fun = sum, na.rm = TRUE, exact = TRUE)   # as in script 4, about 20 seconds
  round(c(viirs_all   = cor(log(s[, 2]), log(ny$pop2023)),
          viirs_noNYC = cor(log(s[!nyc, 2]), log(ny$pop2023[!nyc])),
          older_all   = cor(log(sl[, 2]), log(ny$pop2013)),
          older_noNYC = cor(log(sl[!nyc, 2]), log(ny$pop2013[!nyc]))), 2)

# the end ----
