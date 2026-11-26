# AEM 6850, session 26 (Drone & satellite imagery). Drone images
# Script 2 of 7 - the drone image of a corn trial read in R, its black corners set to NA with mask(),
# the field averaged to 10 m and 30 m cells, the Census road line against the road in the image
# Reads: data/drone/willis_corn_trial.tif (the drone image as OpenAerialMap serves it, 11.4 MB),
#        data_clean/drone/caldwell_roads_near_mosaic.gpkg (Census TIGER roads near the field),
#        data_clean/drone/tiger_offset.csv (the road offsets measured before class)
# Writes: nothing
# Open 26-satellite-local.Rproj first, so R starts in the project folder; then
#   source("code/2_drone.R")
# Every section matches a slide of the same name. Takes about 20 seconds; mask() on 47 million pixels
# needs about 1.5 GB of memory with terra held to 2 GB.

# 1). Preliminary ----
# Clean up workspace and load or install necessary packages if necessary
  rm(list = ls())
  want <- c("terra", "sf")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only=TRUE))
  rm(want, need)
  options(width = 100); terraOptions(progress = 0, memmax = 2)
  misc <- list()
  misc$mosaic <- "data/drone/willis_corn_trial.tif"                  # 4.1 cm pixels, UTM zone 17N
  misc$roads  <- "data_clean/drone/caldwell_roads_near_mosaic.gpkg"
  misc$offset <- "data_clean/drone/tiger_offset.csv"

# 2). Reading the drone image in R ----
  mo <- rast("data/drone/willis_corn_trial.tif")
  mo
  mo <- mask(mo, sum(mo) == 0, maskvalues = TRUE)   # black corners become NA

# 3). The same field in 10 m and 30 m cells ----
  m10 <- aggregate(mo, fact = 243, fun = "mean", na.rm = TRUE)   # 243 pixels x 4.1 cm = 10 m cells
  m30 <- aggregate(mo, fact = 730, fun = "mean", na.rm = TRUE)   # 730 pixels x 4.1 cm = 30 m cells
  # page: counting the cells with some image
  n10 <- global(!is.na(m10[[1]]), "sum")[[1]]
  n30 <- global(!is.na(m30[[1]]), "sum")[[1]]
  c(cells_10m = n10, cells_30m = n30)

# 4). A Census road on the drone image ----
  # page: at three points along the TIGER line, read the pixels on a line of 50 m across the road,
  # one every 4 cm. Asphalt here is blue-grey, so its blue layer is higher than its red layer.
  # The road is the nearest stretch of asphalt wider than 3 m.
  rd <- st_read("data_clean/drone/caldwell_roads_near_mosaic.gpkg", quiet = TRUE)
  ln <- st_cast(st_intersection(st_union(rd[rd$FULLNAME == "Pennell St NE", ]),
                                st_as_sfc(st_bbox(ext(mo) - 10, crs = st_crs(rd)))), "LINESTRING")[1]
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
