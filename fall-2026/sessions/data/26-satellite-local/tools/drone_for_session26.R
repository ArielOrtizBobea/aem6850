# AEM 6850, session 26. Drone imagery (copied on 2026-11-24 from 25-radar-lidar/tools/drone_for_session26.R, where it was
# script 4 of 7 of the session 25 draft). Read the drone mosaic of a corn trial, average it to 10 m and 30 m cells, the Census
# road line against the road in the image
# Reads: data/drone/willis_corn_trial.tif (the mosaic as OpenAerialMap serves it, 11.4 MB),
#        data_clean/drone/caldwell_roads_near_mosaic.gpkg (Census TIGER roads near the mosaic),
#        data_clean/drone/tiger_offset.csv (the offsets measured before class)
# Writes: nothing
# Open 26-satellite-local.Rproj first, so R starts in the project folder; then
#   source("tools/drone_for_session26.R")
# The lecture's own code/2_drone.R replaces it; it is kept as the worked source for that script.

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
  misc$mosaic <- "data/drone/willis_corn_trial.tif"
  misc$roads  <- "data_clean/drone/caldwell_roads_near_mosaic.gpkg"
  misc$offset <- "data_clean/drone/tiger_offset.csv"

# 2). Reading the mosaic in R ----
  mo <- rast(misc$mosaic)
  mo
  mo <- mask(mo, sum(mo) == 0, maskvalues = TRUE)   # black corners become NA (3.6 s with terra held to 2 GB)

# 3). The same field in 10 m and 30 m cells ----
  m10 <- aggregate(mo, fact = 243, fun = "mean", na.rm = TRUE)   # 10 m cells
  m30 <- aggregate(mo, fact = 730, fun = "mean", na.rm = TRUE)   # 30 m cells
  n10 <- global(!is.na(m10[[1]]), "sum")[[1]]
  n30 <- global(!is.na(m30[[1]]), "sum")[[1]]
  c(cells_10m = n10, cells_30m = n30)
  res(m10); res(m30)
  par(mfrow = c(1, 3))
  plotRGB(aggregate(mo, 8), main = "4 cm (drawn at 33 cm)", mar = c(1, 1, 3, 1))
  plotRGB(m10, main = "10 m", mar = c(1, 1, 3, 1))
  plotRGB(m30, main = "30 m", mar = c(1, 1, 3, 1))
  par(mfrow = c(1, 1))

# 4). The Census road against the road in the image ----
  # Pennell St NE, the TIGER line inside the mosaic
  rd <- st_read(misc$roads, quiet = TRUE)
  ln <- st_cast(st_intersection(st_union(rd[rd$FULLNAME == "Pennell St NE", ]),
                                st_as_sfc(st_bbox(ext(mo) - 10, crs = st_crs(rd)))), "LINESTRING")[1]
  # At 20, 50 and 80% along the line, read the pixels on a 50 m line across it, one every 4 cm.
  # Asphalt here is blue-grey (blue above red). After a 1 m running mean, runs of asphalt less than 1 m
  # apart are joined (the two lanes either side of the stripe). The road is the run over 3 m wide
  # nearest the TIGER line, and the offset is the distance from the line to the middle of that run.
  off <- do.call(rbind, lapply(c(0.2, 0.5, 0.8), function(fr) {
    p0 <- st_coordinates(st_line_sample(ln, sample = fr))[1, 1:2]
    p1 <- st_coordinates(st_line_sample(ln, sample = fr + 0.01))[1, 1:2]
    tv <- (p1 - p0) / sqrt(sum((p1 - p0)^2)); nv <- c(-tv[2], tv[1])   # unit normal, left of the line
    s  <- seq(-25, 25, by = 0.04)
    v  <- extract(mo, cbind(p0[1] + s * nv[1], p0[2] + s * nv[2]))
    asph <- as.vector(stats::filter((v$blue > v$red) * 1, rep(1 / 25, 25)) > 0.5)
    asph[is.na(asph)] <- FALSE
    r <- rle(asph); en <- cumsum(r$lengths); stt <- en - r$lengths + 1
    runs <- data.frame(from = s[stt], to = s[en])[r$values, ]
    k <- 1
    while (k < nrow(runs)) {                       # join the two lanes across the centre stripe
      if (runs$from[k + 1] - runs$to[k] < 1) {
        runs$to[k] <- runs$to[k + 1]; runs <- runs[-(k + 1), ]
      } else k <- k + 1
    }
    runs <- runs[runs$to - runs$from > 3, ]
    runs <- runs[which.min(pmin(abs(runs$from), abs(runs$to),
                                ifelse(runs$from < 0 & runs$to > 0, 0, Inf))), ]
    data.frame(point = fr, width_m = round(runs$to - runs$from, 1),
               offset_to_centre_m = round((runs$from + runs$to) / 2, 1))
  }))
  off
  read.csv(misc$offset)[, c("point", "width_m", "offset_to_centre_m")]   # measured before class

# the end ----
