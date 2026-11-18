# AEM 6850, session 24 (Spatial II: rasters). An application to the Eaton fire
# Script 5 of 5 - NASA's picture of Los Angeles on 9 January 2025, the wind at the fire, the population cells
# downwind of it, the people who lived there, the downwind cells over the picture
# Reads: data/nasa/worldview_terra_20250109.tif, data_clean/u10_la_20250109.tif,
#        data_clean/v10_la_20250109.tif, data_clean/pop_2010.tif
# Writes: nothing
# Open 24-spatial-rasters.Rproj first, so R starts in the project folder; then
#   source("code/5_eaton.R")
# Every section matches a slide of the same name; the live script 24-spatial-rasters.R runs them all in order.

# 1). Preliminary ----
# Clean up workspace and load or install necessary packages if necessary
  rm(list = ls())
  want <- c("terra")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only = TRUE))
  rm(want, need)
  misc <- list()
  misc$picture <- "data/nasa/worldview_terra_20250109.tif"     # NASA Worldview, MODIS on Terra
  misc$fire    <- c(lon = -118.069155, lat = 34.203483)        # the Eaton fire's origin, from CAL FIRE
  misc$hour    <- "18:00"                                      # the wind's hour in UTC: 10 am in Los Angeles

# 2). The layers from earlier scripts ----
  # none: this part reads its own files

# 3). The Eaton fire on 9 January 2025 ----
  img  <- rast("data/nasa/worldview_terra_20250109.tif")         # NASA's Terra, 9 January 2025
  dim(img)                                                       # rows, columns, layers
  fire <- vect(cbind(lon = -118.069155, lat = 34.203483), crs = "EPSG:4326")   # the fire's origin
  plotRGB(img); points(fire, pch = 21, bg = "red", col = "white", cex = 1.6)

# 4). The wind at the fire at 10 am ----
  u_la <- rast("data_clean/u10_la_20250109.tif")                 # wind toward the east, by hour
  v_la <- rast("data_clean/v10_la_20250109.tif")                 # wind toward the north
  uf <- extract(u_la[["18:00"]], fire, ID = FALSE)[1, 1]         # 18:00 UTC is 10 am in Los Angeles
  vf <- extract(v_la[["18:00"]], fire, ID = FALSE)[1, 1]
  to <- (atan2(uf, vf) * 180 / pi) %% 360                        # the direction the wind blows toward
  round(c(u = uf, v = vf, kmh = sqrt(uf^2 + vf^2) * 3.6,
          from = (atan2(-uf, -vf) * 180 / pi) %% 360, toward = to), 1)

# 5). The cells downwind of the fire ----
  people <- crop(rast("data_clean/pop_2010.tif"), img)           # people per cell, 2010
  km    <- values(distance(people, fire))[, 1] / 1000            # km from the fire to each cell
  xy    <- xyFromCell(people, 1:ncell(people))                   # each cell's centre: lon, lat
  east  <- (xy[, 1] - crds(fire)[1]) * cos(crds(fire)[2] * pi / 180)   # degrees east, shrunk at 34 N
  north <-  xy[, 2] - crds(fire)[2]                              # degrees north of the fire
  bear  <- (atan2(east, north) * 180 / pi) %% 360                # direction from the fire to the cell
  gap   <- abs((bear - to + 180) %% 360 - 180)                   # degrees away from the wind
  down  <- km <= 100 & gap <= 20
  c(cells = ncell(people), downwind = sum(down))

# 6). 3.6 million people lived downwind ----
  n <- values(people)[, 1]
  round(c(downwind = sum(n[down], na.rm = TRUE), in_the_picture = sum(n, na.rm = TRUE)))
  round(100 * sum(n[down], na.rm = TRUE) / sum(n, na.rm = TRUE), 1)

# 7). The downwind cells over the picture ----
  dw <- rast(people); values(dw) <- ifelse(down, 1, NA)          # 1 downwind, NA elsewhere
  plotRGB(img); lines(as.polygons(dw), col = "yellow", lwd = 2)
  points(fire, pch = 21, bg = "red", col = "white", cex = 1.6)

# the end ----
