# AEM 6850, session 23 (Spatial I: vectors). Vector data in R
# Script 1 of 6 - read the county file, subset it, join points and a table to it
# Reads: data/census/cb_2024_us_county_500k.zip, co-est2024-alldata.csv
# Writes: data_clean/counties/ (the unzipped shapefile)
# Open 23-spatial-vector.Rproj first, so R starts in the project folder; then
#   source("code/1_vector.R")
# Every section matches a slide of the same name; the live script 23-spatial-vector.R runs them all in order.

# 1). Preliminary ----
# Clean up workspace and load or install necessary packages if necessary
  rm(list = ls())
  want <- c("sf")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only = TRUE))
  rm(want, need)

# 2). Reading the county file ----
  unzip("data/census/cb_2024_us_county_500k.zip", exdir = "data_clean/counties")   # seven files
  co <- st_read("data_clean/counties/cb_2024_us_county_500k.shp", quiet = TRUE)
  print(co, n = 0)                                      # the header alone, no rows

# 3). An sf object is a data frame ----
  class(co)
  co[1:3, c("GEOID", "NAME", "STUSPS", "ALAND")]        # three rows, four columns: the geometry comes too

# 4). The rows outside the 50 states and DC ----
  table(co$STUSPS[!co$STUSPS %in% c(state.abb, "DC")])   # AS American Samoa, GU Guam, MP Northern Mariana
                                                         # Islands, PR Puerto Rico, VI US Virgin Islands

# 5). Subsetting and plotting New York's counties ----
  ny <- co[co$STUSPS == "NY", ]          # rows by a condition
  nrow(ny)
  tk <- ny[ny$NAME == "Tompkins", ]      # Tompkins County, used again below
  par(mar = c(0, 0, 0, 0))
  plot(st_geometry(ny), col = ifelse(ny$NAME == "Tompkins", "#B31B1B", "grey90"), border = "white")

# 6). A polygon is a list of corners ----
  xy <- st_coordinates(tk)          # one row per corner
  nrow(xy)
  head(xy, 2)
  plot(st_geometry(tk))
  points(xy[, "X"], xy[, "Y"], pch = 20, cex = 0.5)

# 7). Points from longitude and latitude ----
  wh <- st_as_sf(data.frame(name = "Warren Hall", lon = -76.4797, lat = 42.4490),
                 coords = c("lon", "lat"), crs = 4326)        # x (longitude) first, then y (latitude)
  wh

# 8). The county that holds Warren Hall ----
  wh <- st_transform(wh, st_crs(co))                          # the point in the counties' CRS
  st_drop_geometry(st_join(wh, co[c("GEOID", "NAME", "STUSPS")]))

# 9). County codes read as numbers ----
  pop <- read.csv("data/census/co-est2024-alldata.csv", fileEncoding = "latin1")
  pop <- pop[pop$SUMLEV == 50, ]                        # 50: county rows; 40: state rows
  head(pop[, c("STATE", "COUNTY", "CTYNAME")], 3)
  pop$GEOID <- paste0(pop$STATE, pop$COUNTY)            # should be 01001, 01003, 01005
  head(pop$GEOID, 3)
  nrow(merge(co, pop[c("GEOID", "POPESTIMATE2024")], by = "GEOID"))

# 10). Merging population by GEOID ----
  pop <- read.csv("data/census/co-est2024-alldata.csv", fileEncoding = "latin1",
                  colClasses = c(STATE = "character", COUNTY = "character"))   # codes stay text: "01"
  pop <- pop[pop$SUMLEV == 50, ]
  pop$GEOID <- paste0(pop$STATE, pop$COUNTY)
  head(pop$GEOID, 3)
  cp <- merge(co, pop[c("GEOID", "POPESTIMATE2024")], by = "GEOID")
  nrow(cp)
  st_drop_geometry(cp[cp$GEOID == "36109", c("NAME", "POPESTIMATE2024")])

# 11). Exercise 1: four places, their counties and populations ----
  pl <- data.frame(name = c("Times Square", "Willis Tower", "Hollywood sign", "Golden Gate Bridge"),
                   lon = c(-73.9855, -87.6359, -118.3217, -122.4783),
                   lat = c(40.7580, 41.8789, 34.1341, 37.8199))
  p <- st_transform(st_as_sf(pl, coords = c("lon", "lat"), crs = 4326), st_crs(co))
  j <- st_join(p, co[c("GEOID", "NAME", "STUSPS")])
  merge(st_drop_geometry(j), pop[c("GEOID", "POPESTIMATE2024")], by = "GEOID", all.x = TRUE)

# the end ----
