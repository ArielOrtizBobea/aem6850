# AEM 6850, session 25. Clips the USGS LiDAR point cloud to Cornell's central campus and builds three 1 m grids.
# Run in the 25-radar-lidar folder (open 25-radar-lidar.Rproj first), after tools/fetch_lidar.R:
#   source("tools/make_lidar.R")
# What it does: reads the EPT nodes from USGS's AWS copy (Web Mercator), moves them to UTM 18N (EPSG:6347),
#   clips a 600 x 600 m box (McGraw Tower, Libe Slope to its west, the Arts Quad to its north-east), builds the
#   ground (DTM), surface (DSM) and height-above-ground grids at 1 m, measures the numbers the slides quote,
#   draws check maps.
# Reads: data/lidar/ept/ept-data/*.laz, data/lidar/*.xml; the original tiles data/lidar/*.laz if complete (a cross-check).
# Writes: data_clean/lidar/campus.laz, campus_dtm.tif, campus_dsm.tif, campus_height.tif;
#         logs/prep_lidar.txt, logs/check_density_5m.png, logs/check_height_map.png, logs/check_tower_transect.png.

# 1). Preliminary ----
  # Clean up workspace and load or install necessary packages if necessary
  rm(list = ls())
  want <- c("lidR", "terra", "sf")
  need <- want[!(want %in% installed.packages()[, "Package"])]
  if (length(need)) install.packages(need)
  invisible(lapply(want, function(i) suppressMessages(require(i, character.only = TRUE))))
  rm(want, need)

  options(lidR.progress = FALSE)
  misc <- list(nodes  = list.files("data/lidar/ept/ept-data", pattern = "\\.laz$", full.names = TRUE),
               tiles  = file.path("data/lidar", paste0("USGS_LPC_NY_FingerLakes_2020_A20_", c("u_3765069950", "u_3780069950"), ".laz")),
               sizes  = c(86046801, 81058728),   # bytes of the complete original tiles
               box    = c(xmin = 377600, ymin = 4700350, xmax = 378200, ymax = 4700950),   # EPSG:6347, metres
               tower  = c(lon = -76.48505, lat = 42.44757),    # McGraw Tower (Wikipedia's infobox)
               lawn   = c(lon = -76.48400, lat = 42.44880),    # open lawn on the Arts Quad, chosen on the check map
               out    = "data_clean/lidar",
               log    = "logs/prep_lidar.txt")
  dir.create(misc$out, recursive = TRUE, showWarnings = FALSE)
  dir.create("logs", showWarnings = FALSE)
  t_start <- Sys.time()

  # Every number goes to the log with the line of code that produced it
  log_lines <- c(paste("Session 25 LiDAR prep, run", format(Sys.time(), "%Y-%m-%d %H:%M %Z")),
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
  to_utm <- function(p) sf::st_coordinates(sf::st_transform(sf::st_sfc(sf::st_point(p), crs = 4326), 6347))[1, ]

# 2). The sources: what the original tile header and metadata say, what the AWS copy holds ----
  say("== 2. Sources ==")
  # the original tile's header sits at the start of the file, so it reads even while the download is incomplete
  if (file.exists(misc$tiles[1])) {
    h <- readLASheader(misc$tiles[1]); w <- sf::st_crs(h)$wkt
    say("Original tile ", basename(misc$tiles[1]), " header: CRS ", sf::st_crs(h)$Name)
    say("  Vertical: ", regmatches(w, regexpr('VERTCRS\\["[^"]+"', w)), " | ", regmatches(w, regexpr('GEOIDMODEL\\["[^"]+"', w)),
        " | unit ", tail(regmatches(w, gregexpr('LENGTHUNIT\\["[^"]+"', w))[[1]], 1))
    say("  LAS ", h@PHB[["Version Major"]], ".", h@PHB[["Version Minor"]], ", point format ", h@PHB[["Point Data Format ID"]],
        ", system ", h@PHB[["System Identifier"]], ", points ", h@PHB[["Number of point records"]],
        ", extent x ", h@PHB[["Min X"]], "-", h@PHB[["Max X"]], " y ", h@PHB[["Min Y"]], "-", h@PHB[["Max Y"]])
    rec("  Density implied by the tile header, points per m2",
        round(h@PHB[["Number of point records"]] / ((h@PHB[["Max X"]] - h@PHB[["Min X"]]) * (h@PHB[["Max Y"]] - h@PHB[["Min Y"]])), 2))
  }
  for (f in list.files("data/lidar", pattern = "\\.xml$", full.names = TRUE)) {
    x <- readLines(f, warn = FALSE)
    say("Metadata ", basename(f), ": ", paste(trimws(gsub("<[^>]+>", " ", grep("begdate|enddate|altdatum|altunits", x, value = TRUE))), collapse = " | "))
  }
  say("AWS copy: ", length(misc$nodes), " EPT nodes, ", round(sum(file.size(misc$nodes)) / 1e6, 1), " MB, deepest depth ",
      max(as.integer(sub("-.*", "", basename(misc$nodes)))))
  h <- readLASheader(misc$nodes[1])
  say("  Node header: LAS ", h@PHB[["Version Major"]], ".", h@PHB[["Version Minor"]], ", point format ", h@PHB[["Point Data Format ID"]],
      ", CRS ", sf::st_crs(h)$Name, " (x, y only; z kept as in the source, NAVD88 metres)")

# 3). Clip the box over central campus ----
  say("", "== 3. Clip ==")
  say("Box corners, EPSG:6347 metres: xmin ", misc$box[["xmin"]], ", ymin ", misc$box[["ymin"]], ", xmax ", misc$box[["xmax"]], ", ymax ", misc$box[["ymax"]])
  corners <- sf::st_coordinates(sf::st_transform(sf::st_as_sfc(sf::st_bbox(misc$box, crs = 6347)), 4326))[1:4, 1:2]
  say("Box corners, lon/lat: ", paste(sprintf("(%.5f, %.5f)", corners[, 1], corners[, 2]), collapse = " "))
  las <- timed("readLAS() of the EPT nodes", readLAS(misc$nodes))
  rec("Points in all nodes read", npoints(las))
  las <- timed("st_transform() from EPSG:3857 to EPSG:6347", sf::st_transform(las, sf::st_crs(6347)))
  las <- timed("clip_rectangle() to the box",
               clip_rectangle(las, misc$box[["xmin"]], misc$box[["ymin"]], misc$box[["xmax"]], misc$box[["ymax"]]))
  # LAS 1.2 (what Entwine writes) stores the CRS as one EPSG code, so the file carries EPSG:6347; z is NAVD88 metres
  sf::st_crs(las) <- 6347
  timed("writeLAS() campus.laz", writeLAS(las, file.path(misc$out, "campus.laz")))
  rec("campus.laz CRS as read back", sf::st_crs(readLASheader(file.path(misc$out, "campus.laz")))$Name)
  rec("campus.laz size, MB", round(file.size(file.path(misc$out, "campus.laz")) / 1e6, 1))
  rec("Points in the clip", npoints(las))
  rec("Density in the clip, points per m2", round(npoints(las) / 600^2, 2))
  rec("Ground (class 2) density in the clip, points per m2", round(sum(las$Classification == 2) / 600^2, 2))
  rec("First-return density in the clip, points per m2", round(sum(las$ReturnNumber == 1) / 600^2, 2))
  # what a 500 m box would weigh: same centre, clipped and written to a temporary file
  las500 <- clip_rectangle(las, misc$box[["xmin"]] + 50, misc$box[["ymin"]] + 50, misc$box[["xmax"]] - 50, misc$box[["ymax"]] - 50)
  tmp <- tempfile(fileext = ".laz"); writeLAS(las500, tmp)
  rec("A 500 x 500 m box (same centre) would weigh, MB", round(file.size(tmp) / 1e6, 1)); unlink(tmp); rm(las500)

  say("", "Classification codes in the clip (ASPRS: 1 unclassified, 2 ground, 7 low noise, 9 water, 17 bridge deck, 18 high noise):")
  cl <- table(las$Classification)
  say(paste(sprintf("  class %3s: %9d points, %5.2f%%", names(cl), as.integer(cl), 100 * as.integer(cl) / npoints(las)), collapse = "\n"))
  say("    <- table(las$Classification)")
  nr <- table(las$NumberOfReturns)
  say("Number of returns per pulse (NumberOfReturns), points: ", paste(names(nr), as.integer(nr), sep = "=", collapse = ", "), "    <- table(las$NumberOfReturns)")
  # the values are adjusted standard GPS time: seconds since 1980-01-06 minus 1e9
  days <- table(as.Date(as.POSIXct(las$gpstime + 1e9, origin = "1980-01-06", tz = "UTC")))
  say("Flight days in the clip (from GPS time), points: ", paste(names(days), as.integer(days), sep = "=", collapse = ", "),
      "    <- table(as.Date(as.POSIXct(las$gpstime + 1e9, origin = '1980-01-06', tz = 'UTC')))")

  rec("z range in the clip, all classes, m (NAVD88)", round(range(las$Z), 2))
  rec("z range in the clip without noise (7, 18), m", round(range(las$Z[!las$Classification %in% c(7, 18)]), 2))
  # gaps or stripes at the EPT node edges would show on a 5 m density grid
  dens <- rasterize_density(las, res = 5)
  rec("Points per m2 on the 5 m grid: min, 1st pct, median, max", round(as.numeric(quantile(values(dens), c(0, 0.01, 0.5, 1), na.rm = TRUE)), 2))
  rec("5 m cells with no point", sum(values(dens) == 0 | is.na(values(dens))))
  # the density map shows one straight west-east step; flight lines (PointSourceID) explain it, node edges would not
  rec("Points per flight line (PointSourceID)", table(las$PointSourceID))
  rec("Southern edge of flight line 50 (0.1th percentile of its y), m", round(quantile(las$Y[las$PointSourceID == 50], 0.001)))
  rec("EPT node edges (depth 10) in y inside the box, m",
      round(sf::st_coordinates(sf::st_transform(sf::st_sfc(lapply(5195931 + (0:1023) * 151392 / 1024, function(y) sf::st_point(c(-8514200, y))), crs = 3857), 6347))[, 2]) |>
        (\(y) y[y > misc$box[["ymin"]] & y < misc$box[["ymax"]]])())
  png("logs/check_density_5m.png", width = 1400, height = 1300, res = 150)
  plot(dens, main = "Points per m2, 5 m cells (campus clip from the AWS EPT nodes)", col = hcl.colors(50, "inferno"))
  dev.off()

# 4). Grids at 1 m: ground, surface, height ----
  say("", "== 4. Grids (1 m) ==")
  say("Units: the cloud is in metres (horizontal and vertical), so no conversion from feet.")
  las_clean <- filter_poi(las, !Classification %in% c(7, 18))   # drop low and high noise
  rec("Points dropped as noise (classes 7, 18)", npoints(las) - npoints(las_clean))
  dtm <- timed("rasterize_terrain(las, 1, tin())", rasterize_terrain(las_clean, res = 1, algorithm = tin()))
  # p2r() keeps the highest point in each cell; a cell with no point stays empty, so na.fill = tin() fills it from its neighbours
  dsm <- timed("rasterize_canopy(las, 1, p2r(na.fill = tin()))", rasterize_canopy(las_clean, res = 1, algorithm = p2r(na.fill = tin())))
  dsm_raw <- timed("rasterize_canopy(las, 1, p2r()) for comparison", rasterize_canopy(las_clean, res = 1, algorithm = p2r()))
  dsm_sub <- timed("rasterize_canopy(las, 1, p2r(0.2, na.fill = tin())) for comparison", rasterize_canopy(las_clean, res = 1, algorithm = p2r(subcircle = 0.2, na.fill = tin())))
  height <- timed("height = dsm - dtm", dsm - dtm)
  names(dtm) <- "ground_m"; names(dsm) <- "surface_m"; names(height) <- "height_m"
  writeRaster(dtm,    file.path(misc$out, "campus_dtm.tif"),    overwrite = TRUE, gdal = "COMPRESS=DEFLATE")
  writeRaster(dsm,    file.path(misc$out, "campus_dsm.tif"),    overwrite = TRUE, gdal = "COMPRESS=DEFLATE")
  writeRaster(height, file.path(misc$out, "campus_height.tif"), overwrite = TRUE, gdal = "COMPRESS=DEFLATE")
  for (f in c("campus_dtm.tif", "campus_dsm.tif", "campus_height.tif"))
    say(f, ": ", round(file.size(file.path(misc$out, f)) / 1e6, 2), " MB, ", paste(dim(rast(file.path(misc$out, f)))[1:2], collapse = " x "), " cells")
  rec("Empty (NA) cells in the surface grid, p2r(na.fill = tin()) (the one saved)", sum(is.na(values(dsm))))
  rec("Empty (NA) cells in the surface grid, p2r() without na.fill", sum(is.na(values(dsm_raw))))
  rec("Empty (NA) cells in the surface grid, p2r(0.2, na.fill = tin())", sum(is.na(values(dsm_sub))))
  # a pit: a cell more than 3 m below the median of its 3 x 3 neighbours
  pits <- function(r) sum(values(focal(r, 3, median, na.rm = TRUE) - r > 3), na.rm = TRUE)
  rec("Pit cells (>3 m below the 3x3 median), p2r(na.fill = tin())", pits(dsm))
  rec("Pit cells (>3 m below the 3x3 median), p2r() without na.fill", pits(dsm_raw))
  rec("Pit cells (>3 m below the 3x3 median), p2r(0.2, na.fill = tin())", pits(dsm_sub))
  rec("Ground elevation range in the clip, m (NAVD88)", round(global(dtm, range, na.rm = TRUE), 1))
  rec("Height range, m", round(global(height, range, na.rm = TRUE), 1))

# 5). Tested numbers ----
  say("", "== 5. Tested numbers ==")
  tw <- to_utm(misc$tower); say("McGraw Tower in EPSG:6347: x ", round(tw[1], 1), ", y ", round(tw[2], 1))
  tower_buf <- vect(sf::st_buffer(sf::st_sfc(sf::st_point(tw), crs = 6347), 20))
  in_buf <- function(r) { e <- terra::extract(r, tower_buf, xy = TRUE); e[which.max(e[[2]]), ] }
  top <- in_buf(height)
  rec("Tallest height within 20 m of McGraw Tower, m", round(top$height_m, 2))
  rec("That cell's centre, EPSG:6347", c(x = top$x, y = top$y))
  rec("Its distance from the tower's coordinates, m", round(sqrt((top$x - tw[1])^2 + (top$y - tw[2])^2), 1))
  rec("That cell's centre, lon/lat", round(sf::st_coordinates(sf::st_transform(sf::st_sfc(sf::st_point(c(top$x, top$y)), crs = 6347), 4326))[1, ], 5))
  rec("Surface and ground there, m (NAVD88)", round(c(dsm = extract(dsm, cbind(top$x, top$y))[[1]], dtm = extract(dtm, cbind(top$x, top$y))[[1]]), 2))
  # the raw points near the top, noise included: is the top classed as noise?
  near <- filter_poi(las, (X - top$x)^2 + (Y - top$y)^2 < 5^2)
  rec("Highest point within 5 m of that cell, any class, m", round(max(near$Z), 2))
  rec("Its class", near$Classification[which.max(near$Z)])
  rec("Highest non-noise point within 5 m, m", round(max(near$Z[!near$Classification %in% c(7, 18)]), 2))

  lw <- to_utm(misc$lawn)
  rec("Arts Quad lawn point, EPSG:6347", round(lw, 1))
  rec("Height at the lawn point, m", round(extract(height, rbind(lw))[[1]], 2))
  rec("Max height within 5 m of the lawn point, m", round(max(extract(height, vect(sf::st_buffer(sf::st_sfc(sf::st_point(lw), crs = 6347), 5)))[[2]], na.rm = TRUE), 2))

  # tallest object per class: only possible if the cloud classifies vegetation (3-5) and buildings (6)
  has <- c(veg = any(las_clean$Classification %in% 3:5), bldg = any(las_clean$Classification == 6))
  rec("Vegetation and building classes present", has)
  # otherwise: the five tallest cells, each at least 30 m from a taller one
  hv <- as.data.frame(height, xy = TRUE, na.rm = TRUE); hv <- hv[order(-hv$height_m), ]
  pick <- hv[1, ]
  for (i in seq_len(nrow(hv))) {
    if (nrow(pick) == 5) break
    if (all((hv$x[i] - pick$x)^2 + (hv$y[i] - pick$y)^2 > 30^2)) pick <- rbind(pick, hv[i, ])
  }
  ll <- sf::st_coordinates(sf::st_transform(sf::st_as_sf(pick, coords = c("x", "y"), crs = 6347), 4326))
  pick$lon <- round(ll[, 1], 5); pick$lat <- round(ll[, 2], 5)
  # share of first returns that are also not last returns in a 3 m cell: many layers = tree crown, one = roof
  pick$multi_return_share <- sapply(seq_len(nrow(pick)), function(i) {
    p <- filter_poi(las_clean, abs(X - pick$x[i]) < 3 & abs(Y - pick$y[i]) < 3 & Z > extract(dtm, cbind(pick$x[i], pick$y[i]))[[1]] + 2)
    round(mean(p$NumberOfReturns > 1), 2)
  })
  say("Five tallest cells, at least 30 m apart (multi_return_share near 1 = tree crown, near 0 = roof):")
  say(paste(capture.output(print(pick, row.names = FALSE)), collapse = "\n"))
  say("    <- as.data.frame(height, xy = TRUE) sorted by height, greedy pick 30 m apart; NumberOfReturns > 1 within 3 m")

  # what coarse cells do to a thin tower
  for (k in c(5, 10)) {
    a <- aggregate(height, fact = k, fun = "mean", na.rm = TRUE)
    e <- terra::extract(a, tower_buf, xy = TRUE)
    rec(paste0("Tallest height within 20 m of the tower, ", k, " m cells (mean)"), round(max(e[[2]], na.rm = TRUE), 2))
  }

# 6). Check figures (for checking only, not slides) ----
  png("logs/check_height_map.png", width = 1400, height = 1300, res = 150)
  plot(height, main = "Height above ground (m), 1 m cells", col = hcl.colors(50, "viridis"))
  points(tw[1], tw[2], pch = 1, cex = 2, col = "red"); points(lw[1], lw[2], pch = 3, cex = 2, col = "white")
  dev.off()

  strip <- filter_poi(las, abs(Y - tw[2]) < 5)   # a 10 m wide west-east strip through the tower
  cols <- c("1" = "grey60", "2" = "sienna", "7" = "red", "9" = "blue", "17" = "orange", "18" = "magenta")
  png("logs/check_tower_transect.png", width = 2000, height = 900, res = 150)
  plot(strip$X, strip$Z, pch = ".", col = cols[as.character(strip$Classification)], xlab = "x, EPSG:6347 (m)", ylab = "z, NAVD88 (m)",
       main = "Points in a 10 m west-east strip through McGraw Tower, coloured by class")
  abline(v = tw[1], lty = 3)
  legend("topleft", legend = names(cols), col = cols, pch = 15, title = "class", bty = "n", ncol = 6)
  dev.off()

# 7). Cross-check against the original tiles, when both downloads are complete ----
  if (all(file.exists(misc$tiles)) && all(file.size(misc$tiles) == misc$sizes)) {
    say("", "== 7. Original tiles cross-check ==")
    orig <- clip_rectangle(readLAScatalog(misc$tiles), misc$box[["xmin"]], misc$box[["ymin"]], misc$box[["xmax"]], misc$box[["ymax"]])
    rec("Points in the same box from the original tiles", npoints(orig))
    rec("Points in the box from the AWS copy", npoints(las))
    o_h <- rasterize_canopy(filter_poi(orig, !Classification %in% c(7, 18)), 1, p2r(na.fill = tin())) -
           rasterize_terrain(filter_poi(orig, !Classification %in% c(7, 18)), 1, tin())
    rec("Tallest height within 20 m of the tower, original tiles, m", round(max(terra::extract(o_h, tower_buf)[[2]], na.rm = TRUE), 2))
  } else say("", "Original tiles incomplete: ", paste(basename(misc$tiles), file.size(misc$tiles), collapse = ", "), " bytes; no cross-check.")

  say("", "TIME whole script (from the downloaded EPT nodes): ", sprintf("%.1f", as.numeric(difftime(Sys.time(), t_start, units = "secs"))), " s")
  writeLines(log_lines, misc$log)

# the end ----
