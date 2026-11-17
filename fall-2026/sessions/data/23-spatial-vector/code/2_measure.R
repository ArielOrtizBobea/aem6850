# AEM 6850, session 23 (Spatial I: vectors). Measuring areas, distances and angles
# Script 2 of 6 - areas, distances to a point and a border, a buffer, a highway cut by a state, a direction
# Reads: data/census/ county and state zips, data_clean/interstates_ny_box.gpkg
# Writes: data_clean/states/ (the unzipped shapefile)
# Open 23-spatial-vector.Rproj first, so R starts in the project folder; then
#   source("code/2_measure.R")
# Every section matches a slide of the same name; the live script 23-spatial-vector.R runs them all in order.

# 1). Preliminary ----
# Clean up workspace and load or install necessary packages if necessary
  rm(list = ls())
  want <- c("sf")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only = TRUE))
  rm(want, need)

# 2). The layers from script 1 ----
  # the Census county file (unzipped once into data_clean/)
  if (!file.exists("data_clean/counties/cb_2024_us_county_500k.shp"))
    unzip("data/census/cb_2024_us_county_500k.zip", exdir = "data_clean/counties")
  co <- st_read("data_clean/counties/cb_2024_us_county_500k.shp", quiet = TRUE)
  ny <- co[co$STUSPS == "NY", ]                             # New York's 62 counties
  tk <- co[co$GEOID == "36109", ]                           # Tompkins County
  wh <- st_as_sf(data.frame(name = "Warren Hall", lon = -76.4797, lat = 42.4490),
                 coords = c("lon", "lat"), crs = 4326)        # Warren Hall, Cornell

# 3). Area and perimeter of Tompkins County ----
  tk_m <- st_transform(tk, 5070)                                  # Conus Albers: equal area, metres
  round(c(albers       = as.numeric(st_area(tk_m)) / 1e6,         # km2
          web_mercator = as.numeric(st_area(st_transform(tk, 3857))) / 1e6,
          round_earth  = as.numeric(st_area(tk)) / 1e6,           # degrees: sf measures on a sphere
          census       = (tk$ALAND + tk$AWATER) / 1e6), 1)
  round(as.numeric(st_length(st_boundary(tk_m))) / 1e3, 1)       # perimeter, km

# 4). Each county's distance to Times Square ----
  ts    <- st_as_sf(data.frame(name = "Times Square", lon = -73.9855, lat = 40.7580),
                    coords = c("lon", "lat"), crs = 4326)
  ny_co <- st_transform(ny, 5070)                                   # New York's counties, in metres
  pt_ny <- st_point_on_surface(st_geometry(ny_co))                  # a point inside each county
  ny_co$km_ts <- as.numeric(st_distance(pt_ny, st_transform(ts, 5070))) / 1e3
  km <- setNames(round(ny_co$km_ts), ny_co$NAME); km[c("Tompkins", names(which.max(km)))]

# 5). Distance to a state and its border ----
  if (!file.exists("data_clean/states/cb_2024_us_state_500k.shp"))
    unzip("data/census/cb_2024_us_state_500k.zip", exdir = "data_clean/states")
  states   <- st_read("data_clean/states/cb_2024_us_state_500k.shp", quiet = TRUE)
  states_m <- st_transform(states, 5070); wh_m <- st_transform(wh, 5070)      # Conus Albers, metres
  ny_m <- states_m[states_m$STUSPS == "NY", ]
  km <- function(a, b) round(as.numeric(st_distance(a, b)) / 1e3, 1)
  c(to_PA = km(wh_m, states_m[states_m$STUSPS == "PA", ]), to_NY = km(wh_m, ny_m),
    to_NY_border = km(wh_m, st_boundary(ny_m)))

# 6). A 50 km buffer around Warren Hall ----
  b    <- st_buffer(wh_m, 50000)    # within 50,000 m
  co_m <- st_transform(co, 5070)
  near <- co_m[b, ]                 # the counties b reaches
  table(near$STUSPS)

# 7). The buffer on a map ----
  par(mar = c(0, 0, 0, 0))
  plot(st_geometry(st_buffer(wh_m, 85000)), border = NA)                      # sets the map's extent
  plot(st_geometry(co_m[co_m$STUSPS %in% c("NY", "PA"), ]), col = "grey95", border = "white", add = TRUE)
  plot(st_geometry(near), col = "#C9DAEA", border = "white", add = TRUE)
  plot(st_boundary(st_geometry(ny_m)), lwd = 3, add = TRUE)                   # New York's boundary
  plot(b, col = NA, border = "#B31B1B", lwd = 2, add = TRUE)
  plot(st_geometry(wh_m), pch = 19, col = "#B31B1B", add = TRUE)
  text(st_coordinates(st_point_on_surface(st_geometry(near))), near$NAME, cex = 0.7)

# 8). Interstate miles in New York ----
  it    <- st_read("data_clean/interstates_ny_box.gpkg", quiet = TRUE)   # Census Interstate lines near New York
  it_ny <- st_intersection(st_transform(it, 5070), ny_m["STUSPS"])      # the parts inside New York
  # st_intersection() warns that attributes are assumed constant: expected here
  it_ny$miles <- as.numeric(st_length(it_ny)) / 1609.344
  round(sum(it_ny$miles), 1)
  round(sort(tapply(it_ny$miles, it_ny$FULLNAME, sum), decreasing = TRUE)[1:3], 1)

# 9). Direction from Warren Hall to Times Square ----
  bearing <- function(a, b, crs) {   # degrees from map north
    d <- st_coordinates(st_transform(b, crs)) -
         st_coordinates(st_transform(a, crs))  # east, north (m)
    (atan2(d[1], d[2]) * 180 / pi) %% 360   # 0 to 360
  }
  round(c(utm_18N = bearing(wh, ts, 32618),
          albers  = bearing(wh, ts, 5070)), 1)

# 10). The direction on the round Earth ----
  r  <- pi / 180                                   # degrees to radians
  p1 <- 42.4490 * r; p2 <- 40.7580 * r             # latitudes of Warren Hall and Times Square
  dl <- (-73.9855 - -76.4797) * r                  # difference in longitude
  round((atan2(sin(dl) * cos(p2), cos(p1) * sin(p2) - sin(p1) * cos(p2) * cos(dl)) / r) %% 360, 1)

# the end ----
