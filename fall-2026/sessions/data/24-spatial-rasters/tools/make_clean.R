# AEM 6850, session 24. Cuts the raw downloads in data/ down to the files the slides read, in data_clean/.
# Run once, in the 24-spatial-rasters folder (open 24-spatial-rasters.Rproj first), after tools/fetch_data.R:
#   source("tools/make_clean.R")
# Reads:  data/prism/*.zip, data/glad/, data/nass/, data/era5/, data/sedac/.
# Writes: data_clean/tmax_july2012.tif, cropland_2011.tif, corn_yield_2002_2012.csv, pop_2010.tif,
#         u10_ny_20120717.tif, v10_ny_20120717.tif, u10_la_20250109.tif, v10_la_20250109.tif.

# 1). Preliminary ----
  want <- c("terra")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only = TRUE))
  rm(want, need)
  dir.create("data_clean", showWarnings = FALSE)
  misc <- list(us = ext(-125.0208, -66.47917, 24.0625, 49.9375),      # PRISM's grid: the lower 48 states
               ny = ext(360 - 80, 360 - 71.5, 40.25, 45.25),           # ERA5 counts longitude from 0 to 360
               la = ext(360 - 119.6, 360 - 117.2, 33.2, 34.8),
               zip = c("COMPRESS=DEFLATE", "PREDICTOR=2", "ZLEVEL=9"))

# 2). PRISM: 31 daily files into one file with 31 layers ----
  tmp <- file.path(tempdir(), "prism"); dir.create(tmp, showWarnings = FALSE)
  for (z in list.files("data/prism", "zip$", full.names = TRUE)) unzip(z, files = sub("zip$", "tif", basename(z)), exdir = tmp)
  tmax <- rast(sort(list.files(tmp, "tif$", full.names = TRUE)))
  stopifnot(nlyr(tmax) == 31)
  time(tmax)  <- seq(as.Date("2012-07-01"), by = "day", length.out = 31)
  names(tmax) <- as.character(time(tmax))
  # hundredths of a degree as whole numbers: a quarter of the size, and the file still reads back in degrees
  # the writer cuts the decimals off, so each value is rounded first and nudged a thousandth away from zero
  r <- round(tmax, 2)
  r <- r + 0.001 * ((r > 0) - (r < 0))
  writeRaster(r, "data_clean/tmax_july2012.tif", datatype = "INT2S", scale = 0.01, gdal = misc$zip, overwrite = TRUE)
  back <- rast("data_clean/tmax_july2012.tif")
  stopifnot(max(abs(values(back[[17]]) - values(tmax[[17]])), na.rm = TRUE) < 0.0051)

# 3). GLAD cropland: the lower 48 states cut from the global file ----
  cl <- crop(rast("data/glad/Global_cropland_3km_2011.tif"), misc$us + 0.5)
  names(cl) <- "cropland"
  writeRaster(cl, "data_clean/cropland_2011.tif", datatype = "INT1U", gdal = misc$zip, overwrite = TRUE)

# 4). Population: the lower 48 states cut from the global file ----
  pop <- crop(rast("data/sedac/gpw_v4_population_count_rev11_2010_2pt5_min.tif"), misc$us + 0.5)
  names(pop) <- "pop"
  writeRaster(pop, "data_clean/pop_2010.tif", gdal = c("COMPRESS=DEFLATE", "PREDICTOR=3", "ZLEVEL=9"), overwrite = TRUE)

# 5). Corn yields: one row per county and year ----
  ya <- read.csv("data/nass/corn_yield_county_2002_2012.csv")
  ya <- ya[!is.na(ya$county_ansi) & ya$year <= 2012, ]               # drops "other (combined) counties" and later years
  y  <- data.frame(GEOID = sprintf("%02d%03d", ya$state_ansi, ya$county_ansi), state = ya$state_alpha,
                   county = ya$county_name, year = ya$year, yield = as.numeric(gsub(",", "", ya$Value)))
  stopifnot(!anyDuplicated(y[, c("GEOID", "year")]), !anyNA(y$yield))
  y <- y[order(y$GEOID, y$year), ]
  write.csv(y, "data_clean/corn_yield_2002_2012.csv", row.names = FALSE)

# 6). ERA5 wind: the two boxes cut from the global files, longitudes moved to -180..180 ----
  cut <- function(file, box, out) {
    r <- shift(crop(rast(file), box, snap = "out"), dx = -360)
    names(r) <- format(time(r), "%H:00")                              # the hour, in UTC
    writeRaster(r, out, gdal = c("COMPRESS=DEFLATE"), overwrite = TRUE)
  }
  cut("data/era5/u10_20120717.nc", misc$ny, "data_clean/u10_ny_20120717.tif")
  cut("data/era5/v10_20120717.nc", misc$ny, "data_clean/v10_ny_20120717.tif")
  cut("data/era5/u10_20250109.nc", misc$la, "data_clean/u10_la_20250109.tif")
  cut("data/era5/v10_20250109.nc", misc$la, "data_clean/v10_la_20250109.tif")
