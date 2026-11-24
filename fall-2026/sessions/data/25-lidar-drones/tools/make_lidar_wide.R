# AEM 6850, session 25. Builds 1 m ground, surface and height grids over a wider view of Cornell's campus, for the figures only.
# Run in the 25-lidar-drones folder (open 25-lidar-drones.Rproj first), after tools/fetch_lidar_wide.R:
#   source("tools/make_lidar_wide.R")
# What it does: reads the EPT nodes from USGS's AWS copy (Web Mercator), moves them to UTM 18N (EPSG:6347), clips a
#   1.6 x 1.6 km box (Cascadilla Gorge to Fall Creek gorge, Libe Slope to Beebe Lake), drops the noise classes,
#   builds the ground (DTM), surface (DSM) and height-above-ground grids at 1 m with the same lidR calls as
#   tools/make_lidar.R (plus one step for Beebe Lake, section 4), and measures the numbers a slide could quote:
#   each gorge's depth, the tallest structures.
# The students' data stay on the 600 m square in data_clean/lidar/; nothing here is in the class zip.
# Reads: data/lidar_wide/ept/ept-data/*.laz, data/lidar_wide/fetch_summary.txt.
# Writes: data_clean/lidar_wide/campus_wide_dtm.tif, campus_wide_dsm.tif, campus_wide_height.tif; logs/prep_lidar_wide.txt.

# 1). Preliminary ----
  # Clean up workspace and load or install necessary packages if necessary
  rm(list = ls())
  want <- c("lidR", "terra", "sf")
  need <- want[!(want %in% installed.packages()[, "Package"])]
  if (length(need)) install.packages(need)
  invisible(lapply(want, function(i) suppressMessages(require(i, character.only = TRUE))))
  rm(want, need)

  options(lidR.progress = FALSE)
  misc <- list(nodes = list.files("data/lidar_wide/ept/ept-data", pattern = "\\.laz$", full.names = TRUE),
               box   = c(xmin = 377400, ymin = 4699800, xmax = 379000, ymax = 4701400),   # EPSG:6347, metres
               small = c(xmin = 377600, ymin = 4700350, xmax = 378200, ymax = 4700950),   # the students' 600 m square
               out   = "data_clean/lidar_wide",
               log   = "logs/prep_lidar_wide.txt")
  dir.create(misc$out, recursive = TRUE, showWarnings = FALSE)
  dir.create("logs", showWarnings = FALSE)
  t_start <- Sys.time()

  # Landmarks, lon/lat, all from OpenStreetMap through the Overpass API (overpass.kumi.systems), queried 2026-11-24.
  # The OSM object is given for each; areas use the centre Overpass reports (out center). McGraw Tower matches our own log.
  lm <- read.csv(text = "name,lon,lat,osm
McGraw Tower,-76.48504,42.44757,way 310881323 (man_made=tower; height=52)
Arts Quad,-76.48448,42.44947,way 311207406 (landuse=grass)
Ag Quad,-76.47799,42.44879,way 311485841 (landuse=grass)
Warren Hall,-76.47715,42.44921,way 200864764 (building=university)
Libe Slope,-76.48649,42.44842,way 468552432 (landuse=grass)
Beebe Lake,-76.47646,42.45124,relation 1530035 (natural=water)
Cascadilla Gorge,-76.48545,42.44274,way 1253084875 (leisure=nature_reserve)
Suspension Bridge,-76.48606,42.45205,way 116421789 (bridge over Fall Creek)
Triphammer Falls,-76.47968,42.45185,node 1236639322 (waterway=waterfall)
Bradfield Hall,-76.47579,42.44787,way 437501474 (building=university; building:levels=11)
Mann Library,-76.47608,42.44883,way 35067735 (building=university)
Barton Hall,-76.48074,42.44594,way 107457269 (building=university)
Bailey Hall,-76.48012,42.44926,way 107869173 (building=university)
Baker Laboratory,-76.48177,42.45045,relation 14912250 (building=university)
Willard Straight Hall,-76.48565,42.44657,way 310881325 (building=university)
Schoellkopf Field,-76.47858,42.44409,way 139661943
Balch Hall,-76.47968,42.45339,way 403931090 (building=dormitory)
Heating plant chimney,-76.47487,42.44288,node 11384263405 (man_made=chimney; Cornell University Central Heating Plant is way 1227647019)")

  # Every number goes to the log with the line of code that produced it
  log_lines <- c(paste("Session 25 wide LiDAR prep, run", format(Sys.time(), "%Y-%m-%d %H:%M %Z")),
                 paste("lidR", packageVersion("lidR"), "| terra", packageVersion("terra"), "|", R.version.string), "")
  say  <- function(...) { x <- paste0(...); log_lines <<- c(log_lines, x); cat(x, "\n") }
  rec  <- function(label, expr) {
    code <- paste(deparse(substitute(expr), width.cutoff = 500), collapse = " ")
    v <- expr
    say(label, ": ", paste(format(v), collapse = " "), "    <- ", code)
    invisible(v)
  }
  timed <- function(label, expr) {
    code <- paste(deparse(substitute(expr), width.cutoff = 500), collapse = " ")
    tt <- system.time(v <- expr)[["elapsed"]]
    say("TIME ", label, ": ", sprintf("%.2f", tt), " s    <- ", code)
    invisible(v)
  }
  xy <- sf::st_coordinates(sf::st_transform(sf::st_as_sf(lm, coords = c("lon", "lat"), crs = 4326), 6347))
  lm$x <- round(xy[, 1], 1); lm$y <- round(xy[, 2], 1)

# 2). The download and the landmarks ----
  say("== 2. Download and landmarks ==")
  say("Fetch (tools/fetch_lidar_wide.R): ", paste(readLines("data/lidar_wide/fetch_summary.txt"), collapse = " | "))
  rec("EPT nodes on disk", length(misc$nodes))
  rec("Download, MB", round(sum(file.size(misc$nodes)) / 1e6, 1))
  say("Landmarks (OpenStreetMap, Overpass API, queried 2026-11-24), in EPSG:6347:")
  say(paste(sprintf("  %-22s lon %.5f lat %.5f  x %.0f y %.0f  %s", lm$name, lm$lon, lm$lat, lm$x, lm$y, lm$osm), collapse = "\n"))
  inside <- lm$x > misc$box[["xmin"]] & lm$x < misc$box[["xmax"]] & lm$y > misc$box[["ymin"]] & lm$y < misc$box[["ymax"]]
  rec("Landmarks inside the box", sum(inside))
  stopifnot(all(inside))

# 3). Clip the box ----
  say("", "== 3. Clip ==")
  say("Box corners, EPSG:6347 metres: xmin ", misc$box[["xmin"]], ", ymin ", misc$box[["ymin"]], ", xmax ", misc$box[["xmax"]], ", ymax ", misc$box[["ymax"]])
  corners <- sf::st_coordinates(sf::st_transform(sf::st_as_sfc(sf::st_bbox(misc$box, crs = 6347)), 4326))[1:4, 1:2]
  say("Box corners, lon/lat: ", paste(sprintf("(%.5f, %.5f)", corners[, 1], corners[, 2]), collapse = " "))
  area <- (misc$box[["xmax"]] - misc$box[["xmin"]]) * (misc$box[["ymax"]] - misc$box[["ymin"]])
  rec("Box area, km2", area / 1e6)
  las <- timed("readLAS() of the EPT nodes", readLAS(misc$nodes))
  rec("Points in all nodes read", npoints(las))
  las <- timed("st_transform() from EPSG:3857 to EPSG:6347", sf::st_transform(las, sf::st_crs(6347)))
  las <- timed("clip_rectangle() to the box",
               clip_rectangle(las, misc$box[["xmin"]], misc$box[["ymin"]], misc$box[["xmax"]], misc$box[["ymax"]]))
  sf::st_crs(las) <- 6347
  rec("Points in the clip", npoints(las))
  rec("Density in the clip, points per m2", round(npoints(las) / area, 2))
  rec("Ground (class 2) density in the clip, points per m2", round(sum(las$Classification == 2) / area, 2))
  cl <- table(las$Classification)
  say("Classification codes in the clip:")
  say(paste(sprintf("  class %3s: %9d points, %5.2f%%", names(cl), as.integer(cl), 100 * as.integer(cl) / npoints(las)), collapse = "\n"))
  say("    <- table(las$Classification)")
  days <- table(as.Date(as.POSIXct(las$gpstime + 1e9, origin = "1980-01-06", tz = "UTC")))
  say("Flight days in the clip (from GPS time), points: ", paste(names(days), as.integer(days), sep = "=", collapse = ", "),
      "    <- table(as.Date(as.POSIXct(las$gpstime + 1e9, origin = '1980-01-06', tz = 'UTC')))")
  dens <- rasterize_density(las, res = 5)
  rec("Points per m2 on the 5 m grid: min, 1st pct, median, max", round(as.numeric(quantile(values(dens), c(0, 0.01, 0.5, 1), na.rm = TRUE)), 2))
  rec("5 m cells with no point", sum(values(dens) == 0 | is.na(values(dens))))
  # water returns few pulses: where are the empty cells, and how many lie within 150 m of Beebe Lake's OSM centre?
  emp <- as.data.frame(dens, xy = TRUE, na.rm = FALSE); emp <- emp[is.na(emp[[3]]) | emp[[3]] == 0, ]
  bl  <- lm[lm$name == "Beebe Lake", ]
  rec("Empty 5 m cells: median x, median y (EPSG:6347)", round(c(median(emp$x), median(emp$y))))
  rec("Empty 5 m cells within 150 m of Beebe Lake's OSM centre", sum((emp$x - bl$x)^2 + (emp$y - bl$y)^2 < 150^2))
  rec("Size of the clip in memory, MB", round(as.numeric(object.size(las)) / 1e6))

# 4). Grids at 1 m: ground, surface, height ----
  say("", "== 4. Grids (1 m) ==")
  las <- filter_poi(las, !Classification %in% c(7, 18))   # drop low and high noise
  rec("Points left after dropping noise (classes 7, 18)", npoints(las))
  dtm <- timed("rasterize_terrain(las, 1, tin())", rasterize_terrain(las, res = 1, algorithm = tin()))
  dsm <- timed("rasterize_canopy(las, 1, p2r(na.fill = tin()))", rasterize_canopy(las, res = 1, algorithm = p2r(na.fill = tin())))
  # Water returns almost no pulse, so Beebe Lake is a hole in the cloud. tin() then fills the surface over the hole
  #   from the tree tops on its shores, and the lake shows trees up to several metres tall. One step that
  #   tools/make_lidar.R does not need (its square has no water): a 1 m cell with no point within 2 m gets the ground.
  cnt   <- timed("rasterize_density(las, 1) for the holes", rasterize_density(las, res = 1))
  far   <- focal(cnt > 0, 5, max, na.rm = TRUE) == 0
  rec("Surface cells with no point within 2 m, set to the ground", sum(values(far, mat = FALSE), na.rm = TRUE))
  bl <- lm[lm$name == "Beebe Lake", ]
  rec("Of those, cells within 150 m of Beebe Lake's OSM centre",
      sum(extract(far, vect(sf::st_buffer(sf::st_sfc(sf::st_point(c(bl$x, bl$y)), crs = 6347), 150)))[[2]], na.rm = TRUE))
  dsm <- ifel(far, dtm, dsm)
  height <- dsm - dtm
  names(dtm) <- "ground_m"; names(dsm) <- "surface_m"; names(height) <- "height_m"
  # lidR snaps the grid to whole metres, so crop to the box exactly
  e <- ext(misc$box[["xmin"]], misc$box[["xmax"]], misc$box[["ymin"]], misc$box[["ymax"]])
  dtm <- crop(dtm, e); dsm <- crop(dsm, e); height <- crop(height, e)
  writeRaster(dtm,    file.path(misc$out, "campus_wide_dtm.tif"),    overwrite = TRUE, gdal = "COMPRESS=DEFLATE")
  writeRaster(dsm,    file.path(misc$out, "campus_wide_dsm.tif"),    overwrite = TRUE, gdal = "COMPRESS=DEFLATE")
  writeRaster(height, file.path(misc$out, "campus_wide_height.tif"), overwrite = TRUE, gdal = "COMPRESS=DEFLATE")
  for (f in c("campus_wide_dtm.tif", "campus_wide_dsm.tif", "campus_wide_height.tif"))
    say(f, ": ", round(file.size(file.path(misc$out, f)) / 1e6, 2), " MB, ", paste(dim(rast(file.path(misc$out, f)))[1:2], collapse = " x "),
        " cells, CRS ", crs(rast(file.path(misc$out, f)), describe = TRUE)$code)
  rec("Grid extent, EPSG:6347", as.vector(ext(dtm)))
  rec("Empty (NA) cells: ground, surface", c(sum(is.na(values(dtm))), sum(is.na(values(dsm)))))
  rec("Ground elevation range in the box, m (NAVD88)", round(as.numeric(global(dtm, range, na.rm = TRUE)), 1))
  rec("Surface elevation range in the box, m (NAVD88)", round(as.numeric(global(dsm, range, na.rm = TRUE)), 1))
  rec("Height range, m", round(as.numeric(global(height, range, na.rm = TRUE)), 1))

# 5). How deep each gorge is ----
  say("", "== 5. Gorges ==")
  # A 300 m north-south line of ground cells through a named place. The creek is the lowest cell on the line;
  #   each rim is the highest ground within 100 m of the creek on that side; the depth is measured to the lower rim.
  gorge <- function(name, dx = 0, half = 150, reach = 100) {
    p <- lm[lm$name == name, ]; p$x <- p$x + dx
    ys <- seq(p$y - half, p$y + half, by = 1)
    z  <- extract(dtm, cbind(p$x, ys))[[1]]
    i  <- which.min(z)
    s  <- ys < ys[i] & ys >= ys[i] - reach; n <- ys > ys[i] & ys <= ys[i] + reach
    c(x = p$x, creek_y = ys[i], creek_m = round(z[i], 1), south_rim_m = round(max(z[s]), 1), north_rim_m = round(max(z[n]), 1),
      depth_to_lower_rim_m = round(min(max(z[s]), max(z[n])) - z[i], 1))
  }
  rec("Fall Creek gorge at the Suspension Bridge (north-south line through its OSM centre)", gorge("Suspension Bridge"))
  rec("Fall Creek gorge below Triphammer Falls, on a line 40 m west of the falls", gorge("Triphammer Falls", dx = -40))
  rec("Cascadilla Gorge at the centre of OSM's Cascadilla Gorge outline", gorge("Cascadilla Gorge"))
  rec("Fall Creek near the Suspension Bridge: lowest ground within 30 m, m (NAVD88)",
      round(min(extract(dtm, vect(sf::st_buffer(sf::st_sfc(sf::st_point(unlist(lm[lm$name == "Suspension Bridge", c("x", "y")])), crs = 6347), 30)))[[2]], na.rm = TRUE), 1))

# 6). The tallest things in the box ----
  say("", "== 6. Tallest cells ==")
  # the eight tallest cells, each at least 40 m from a taller one, with the nearest OSM landmark and the share of
  #   points above 2 m that are one of several returns (near 1 = tree crown, near 0 = roof or tower)
  hv <- as.data.frame(height, xy = TRUE, na.rm = TRUE); hv <- hv[hv$height_m > 20, ]; hv <- hv[order(-hv$height_m), ]
  pick <- hv[1, ]
  for (i in seq_len(nrow(hv))) {
    if (nrow(pick) == 8) break
    if (all((hv$x[i] - pick$x)^2 + (hv$y[i] - pick$y)^2 > 40^2)) pick <- rbind(pick, hv[i, ])
  }
  pick$height_m <- round(pick$height_m, 1)
  pick$nearest <- sapply(seq_len(nrow(pick)), function(i) { d <- sqrt((lm$x - pick$x[i])^2 + (lm$y - pick$y[i])^2); paste0(lm$name[which.min(d)], " (", round(min(d)), " m)") })
  pick$multi_return_share <- sapply(seq_len(nrow(pick)), function(i) {
    p <- filter_poi(las, abs(X - pick$x[i]) < 3 & abs(Y - pick$y[i]) < 3 & Z > extract(dtm, cbind(pick$x[i], pick$y[i]))[[1]] + 2)
    round(mean(p$NumberOfReturns > 1), 2)
  })
  say(paste(capture.output(print(pick, row.names = FALSE)), collapse = "\n"))
  say("    <- as.data.frame(height, xy = TRUE) sorted by height, greedy pick 40 m apart; nearest landmark; NumberOfReturns > 1 within 3 m")
  near_max <- function(name, r) { p <- lm[lm$name == name, ]; round(max(extract(height, vect(sf::st_buffer(sf::st_sfc(sf::st_point(c(p$x, p$y)), crs = 6347), r)))[[2]], na.rm = TRUE), 1) }
  rec("Tallest height within 20 m of McGraw Tower, m", near_max("McGraw Tower", 20))
  rec("Tallest height within 40 m of Bradfield Hall's OSM centre, m", near_max("Bradfield Hall", 40))
  rec("Tallest height within 40 m of Warren Hall's OSM centre, m", near_max("Warren Hall", 40))
  rec("Tallest height within 40 m of Baker Laboratory's OSM centre, m", near_max("Baker Laboratory", 40))
  rec("Tallest height within 10 m of the heating plant chimney (OSM node), m", near_max("Heating plant chimney", 10))

  say("", "TIME whole script (from the downloaded EPT nodes): ", sprintf("%.1f", as.numeric(difftime(Sys.time(), t_start, units = "secs"))), " s")
  writeLines(log_lines, misc$log)

# the end ----
