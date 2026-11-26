# AEM 6850, session 26. New York's 62 counties with their population, and the lights summed in each county.
# Run in the 26-satellite-local folder (open 26-satellite-local.Rproj first), after tools/fetch_census.R and
#   tools/fetch_lights.R:
#   source("tools/make_counties.R")
# No network. About 30 seconds (the two county sums).
# Reads: data/census/cb_2023_ny_county_500k.gpkg, data/census/co-est2023-alldata.csv, data/census/co-est2019-alldata_ny.csv,
#        data/lights/ntl_viirs_2023_ny.tif, data/lights/ntl_li2020_2013_ny.tif
# Writes: data_clean/census/ny_counties.gpkg (GEOID, NAME, NAMELSAD, ALAND, pop2023, pop2013; longitude and latitude, WGS 84),
#         data_clean/lights/ny_county_lights.csv (geoid, name, pop2023, pop2013, lights_viirs2023, lights_li2013),
#         logs/make_counties.txt

# 1). Preliminary ----
  # Clean up workspace and load or install necessary packages if necessary
  rm(list = ls())
  want <- c("terra", "sf")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only = TRUE))
  rm(want, need)
  options(width = 100); terraOptions(progress = 0, memmax = 2)
  misc <- list()
  misc$cb     <- "data/census/cb_2023_ny_county_500k.gpkg"
  misc$pop23  <- "data/census/co-est2023-alldata.csv"
  misc$pop13  <- "data/census/co-est2019-alldata_ny.csv"
  misc$viirs  <- "data/lights/ntl_viirs_2023_ny.tif"
  misc$li     <- "data/lights/ntl_li2020_2013_ny.tif"
  misc$out_gpkg <- "data_clean/census/ny_counties.gpkg"
  misc$out_csv  <- "data_clean/lights/ny_county_lights.csv"
  dir.create("data_clean/census", recursive = TRUE, showWarnings = FALSE)
  dir.create("data_clean/lights", recursive = TRUE, showWarnings = FALSE)
  dir.create("logs", showWarnings = FALSE)
  sink("logs/make_counties.txt", split = TRUE)

# 2). Counties with population ----
  ny <- st_transform(st_read(misc$cb, quiet = TRUE), 4326)
  pop <- function(file, col) {
    p <- read.csv(file, fileEncoding = "latin1")
    p <- p[p$STATE == 36 & p$COUNTY > 0, ]
    setNames(p[[col]], sprintf("36%03d", p$COUNTY))
  }
  ny$pop2023 <- unname(pop(misc$pop23, "POPESTIMATE2023")[ny$GEOID])
  ny$pop2013 <- unname(pop(misc$pop13, "POPESTIMATE2013")[ny$GEOID])
  ny <- ny[order(ny$GEOID), c("GEOID", "NAME", "NAMELSAD", "ALAND", "pop2023", "pop2013")]
  cat("counties:", nrow(ny), " with 2023 population:", sum(!is.na(ny$pop2023)),
      " with 2013 population:", sum(!is.na(ny$pop2013)), "\n")
  if (file.exists(misc$out_gpkg)) file.remove(misc$out_gpkg)
  st_write(ny, misc$out_gpkg, quiet = TRUE)

# 3). Lights summed in each county ----
  nyv <- vect(misc$out_gpkg)
  t0 <- Sys.time()
  s1 <- extract(rast(misc$viirs), nyv, fun = sum, na.rm = TRUE, exact = TRUE)
  cat("VIIRS county sums, seconds:", round(as.numeric(Sys.time() - t0, units = "secs"), 1), "\n")
  s2 <- extract(rast(misc$li), nyv, fun = sum, na.rm = TRUE, exact = TRUE)
  d <- data.frame(geoid = nyv$GEOID, name = nyv$NAME, pop2023 = nyv$pop2023, pop2013 = nyv$pop2013,
                  lights_viirs2023 = s1[, 2], lights_li2013 = s2[, 2])
  write.csv(d, misc$out_csv, row.names = FALSE)

# 4). The correlations on the slides ----
  nyc <- d$name %in% c("Bronx", "Kings", "New York", "Queens", "Richmond")
  r <- function(l, p, k = TRUE) cor(log(l[k]), log(p[k]))
  print(c(viirs2023_pop2023 = r(d$lights_viirs2023, d$pop2023),
          li2013_pop2013    = r(d$lights_li2013, d$pop2013),
          li2013_pop2023    = r(d$lights_li2013, d$pop2023),
          viirs_no_nyc      = r(d$lights_viirs2023, d$pop2023, !nyc),
          li2013_pop2013_no_nyc = r(d$lights_li2013, d$pop2013, !nyc),
          li2013_pop2023_no_nyc = r(d$lights_li2013, d$pop2023, !nyc)), digits = 7)
  sink()

# the end ----
