# AEM 6850, session 25. Clips the USGS LiDAR point cloud around the Empire State Building and builds three 1 m grids.
# Run in the 25-lidar-drones folder (open 25-lidar-drones.Rproj first), after tools/fetch_nyc.R:
#   source("tools/make_nyc.R")
# What it does: reads the EPT nodes from USGS's AWS copy of NY_NewYorkCity (Web Mercator), moves them to
#   NAD83(2011) / UTM zone 18N (EPSG:6347), clips a 400 x 400 m box centred on the building, builds the ground,
#   surface and height grids at 1 m, measures the numbers the slides quote, draws check figures.
# Reads: data/lidar_nyc/esb/ept-data/*.laz.
# Writes: data_clean/lidar_nyc/esb.laz, esb_dtm.tif, esb_dsm.tif, esb_height.tif;
#         logs/prep_nyc.txt, logs/check_nyc_side.png, logs/check_nyc_height.png.

# 1). Preliminary ----
  # Clean up workspace and load or install necessary packages if necessary
  rm(list = ls())
  want <- c("lidR", "terra", "sf")
  need <- want[!(want %in% installed.packages()[, "Package"])]
  if (length(need)) install.packages(need)
  invisible(lapply(want, function(i) suppressMessages(require(i, character.only = TRUE))))
  rm(want, need)

  options(lidR.progress = FALSE)
  misc <- list(nodes  = list.files("data/lidar_nyc/esb/ept-data", pattern = "\\.laz$", full.names = TRUE),
               esb    = c(lon = -73.98566, lat = 40.74844),   # Empire State Building
               side   = 400,                                  # metres; the box is side x side
               near   = 60,                                   # metres from the centre that count as "the building"
               street = 150,                                  # metres from the centre for the street (ground) level
               noise  = c(7, 18),
               out    = "data_clean/lidar_nyc",
               log    = "logs/prep_nyc.txt")
  dir.create(misc$out, recursive = TRUE, showWarnings = FALSE)
  t_start <- Sys.time()

  # Every number goes to the log with the line of code that produced it
  log_lines <- c(paste("Session 25 NYC LiDAR prep (Empire State Building), run", format(Sys.time(), "%Y-%m-%d %H:%M %Z")),
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
  ft <- function(m) m / 0.3048

# 2). The source ----
  say("== 2. Source ==")
  info <- jsonlite::fromJSON("data/lidar_nyc/ept.json")
  rec("ept.json points", info$points)
  rec("ept.json reprojection (source CRS -> EPT CRS)", unlist(info$reprojection))
  rec("ept.json boundsConforming (EPSG:3857 x, y; z)", info$boundsConforming)
  rec("ept.json schema", info$schema$name)
  say("Fetch: ", paste(readLines("data/lidar_nyc/esb/fetch.txt"), collapse = " | "))

# 3). Clip the box ----
  say("", "== 3. Clip ==")
  ctr <- sf::st_coordinates(sf::st_transform(sf::st_sfc(sf::st_point(misc$esb), crs = 4326), 6347))[1, ]
  box <- c(xmin = ctr[[1]] - misc$side / 2, ymin = ctr[[2]] - misc$side / 2, xmax = ctr[[1]] + misc$side / 2, ymax = ctr[[2]] + misc$side / 2)
  rec("Empire State Building in EPSG:6347 (NAD83(2011) / UTM 18N), m", round(ctr, 1))
  las <- timed("readLAS() of the EPT nodes", readLAS(misc$nodes))
  rec("Points in all nodes read", npoints(las))
  las <- timed("st_transform() from EPSG:3857 to EPSG:6347", sf::st_transform(las, sf::st_crs(6347)))
  las <- timed("clip_rectangle() to the box", clip_rectangle(las, box[["xmin"]], box[["ymin"]], box[["xmax"]], box[["ymax"]]))
  sf::st_crs(las) <- 6347
  timed("writeLAS() esb.laz", writeLAS(las, file.path(misc$out, "esb.laz")))
  rec("esb.laz size, MB", round(file.size(file.path(misc$out, "esb.laz")) / 1e6, 1))
  rec("Points in the clip", npoints(las))
  rec("Density in the clip, points per m2", round(npoints(las) / misc$side^2, 2))
  rec("Ground (class 2) density, points per m2", round(sum(las$Classification == 2) / misc$side^2, 2))
  say("Classification codes in the clip (ASPRS: 1 unclassified, 2 ground, 6 building, 7 low noise, 9 water, 10 rail, 17 bridge deck, 18 high noise):")
  cl <- table(las$Classification)
  say(paste(sprintf("  class %3s: %9d points, %5.2f%%", names(cl), as.integer(cl), 100 * as.integer(cl) / npoints(las)), collapse = "\n"))
  say("    <- table(las$Classification)")
  rec("Any building class (6)?", any(las$Classification == 6))
  # adjusted standard GPS time: seconds since 1980-01-06 minus 1e9
  days <- table(as.Date(as.POSIXct(las$gpstime + 1e9, origin = "1980-01-06", tz = "UTC")))
  say("Flight days in the clip (from GPS time), points: ", paste(names(days), as.integer(days), sep = "=", collapse = ", "),
      "    <- table(as.Date(as.POSIXct(las$gpstime + 1e9, origin = '1980-01-06', tz = 'UTC')))")
  rec("z range, all classes", round(range(las$Z), 2))
  rec("z range without noise (7, 18)", round(range(las$Z[!las$Classification %in% misc$noise]), 2))

# 4). Grids at 1 m ----
  say("", "== 4. Grids (1 m) ==")
  las_clean <- filter_poi(las, !Classification %in% misc$noise)
  rec("Points dropped as noise (classes 7, 18)", npoints(las) - npoints(las_clean))
  dtm <- timed("rasterize_terrain(las_clean, 1, tin())", rasterize_terrain(las_clean, res = 1, algorithm = tin()))
  dsm <- tryCatch(timed("rasterize_canopy(las_clean, 1, p2r(subcircle = 0.2, na.fill = tin()))",
                        rasterize_canopy(las_clean, res = 1, algorithm = p2r(subcircle = 0.2, na.fill = tin()))),
                  error = function(e) { say("p2r(subcircle = 0.2, na.fill = tin()) failed: ", conditionMessage(e))
                                        timed("rasterize_canopy(las_clean, 1, p2r())", rasterize_canopy(las_clean, res = 1, algorithm = p2r())) })
  height <- timed("height = dsm - dtm", dsm - dtm)
  names(dtm) <- "ground_m"; names(dsm) <- "surface_m"; names(height) <- "height_m"
  writeRaster(dtm,    file.path(misc$out, "esb_dtm.tif"),    overwrite = TRUE, gdal = "COMPRESS=DEFLATE")
  writeRaster(dsm,    file.path(misc$out, "esb_dsm.tif"),    overwrite = TRUE, gdal = "COMPRESS=DEFLATE")
  writeRaster(height, file.path(misc$out, "esb_height.tif"), overwrite = TRUE, gdal = "COMPRESS=DEFLATE")
  for (f in c("esb_dtm.tif", "esb_dsm.tif", "esb_height.tif"))
    say(f, ": ", round(file.size(file.path(misc$out, f)) / 1e6, 2), " MB, ", paste(dim(rast(file.path(misc$out, f)))[1:2], collapse = " x "), " cells")
  rec("Empty (NA) cells in the surface grid", sum(is.na(values(dsm))))
  rec("Ground elevation range, m", round(global(dtm, range, na.rm = TRUE), 1))
  rec("Height range, m", round(global(height, range, na.rm = TRUE), 1))

# 5). Tested numbers ----
  say("", "== 5. Tested numbers ==")
  d2 <- (las$X - ctr[[1]])^2 + (las$Y - ctr[[2]])^2
  bld <- las@data[d2 < misc$near^2, ]
  street <- rec("Street level: median ground (class 2) z within 150 m of the centre, m", round(median(las$Z[las$Classification == 2 & d2 < misc$street^2]), 2))
  rec("Ground points used for it", sum(las$Classification == 2 & d2 < misc$street^2))
  top_all <- bld[which.max(bld$Z), ]
  rec("Highest point within 60 m, any class: z (m)", round(top_all$Z, 2))
  rec("  its class", top_all$Classification)
  rec("  its offset from the centre, x and y (m)", round(c(top_all$X - ctr[[1]], top_all$Y - ctr[[2]]), 1))
  rec("  above the street, m", round(top_all$Z - street, 2))
  rec("  above the street, ft", round(ft(top_all$Z - street), 0))
  b_clean <- bld[!bld$Classification %in% misc$noise, ]
  top_cl <- b_clean[which.max(b_clean$Z), ]
  rec("Highest point within 60 m, noise (7, 18) excluded: z (m)", round(top_cl$Z, 2))
  rec("  its class", top_cl$Classification)
  rec("  its offset from the centre, x and y (m)", round(c(top_cl$X - ctr[[1]], top_cl$Y - ctr[[2]]), 1))
  rec("  above the street, m", round(top_cl$Z - street, 2))
  rec("  above the street, ft", round(ft(top_cl$Z - street), 0))
  rec("  minus the published roof (381 m) and tip (443.2 m), m", round(top_cl$Z - street - c(roof = 381, tip = 443.2), 1))
  top20 <- head(bld[order(-bld$Z), c("X", "Y", "Z", "Classification")], 20)
  top20$above_street <- round(top20$Z - street, 1); top20$X <- round(top20$X - ctr[[1]], 1); top20$Y <- round(top20$Y - ctr[[2]], 1)
  say("Twenty highest points within 60 m (X, Y as offsets from the centre, m):")
  say(paste(capture.output(print(top20, row.names = FALSE)), collapse = "\n"))
  say("    <- head(bld[order(-bld$Z), ], 20)")
  rec("Points within 60 m above 381 m over the street, all classes / noise excluded",
      c(all = sum(bld$Z - street > 381), clean = sum(b_clean$Z - street > 381)))
  rec("Points within 60 m above 430 m over the street, all classes / noise excluded",
      c(all = sum(bld$Z - street > 430), clean = sum(b_clean$Z - street > 430)))
  rec("Classes of the points above 381 m over the street", table(bld$Classification[bld$Z - street > 381]))
  # horizontal extent per 2 m slab: the wider of the x and y spans of the non-noise returns within 60 m
  b_clean$h <- b_clean$Z - street
  slab <- floor(b_clean$h / 2) * 2
  ext <- do.call(rbind, lapply(split(b_clean, slab), function(s) data.frame(from = floor(min(s$h) / 2) * 2, points = nrow(s),
                         across = round(max(diff(range(s$X)), diff(range(s$Y))), 1))))
  ext <- ext[ext$from >= 300, ]
  say("Width across (the wider of the x and y spans, m) of non-noise returns within 60 m, 2 m slabs from 300 m over the street:")
  say(paste(capture.output(print(ext, row.names = FALSE)), collapse = "\n"))
  wide <- ext$from[ext$across >= 5]
  rec("Lowest slab above which every slab is under 5 m across (m over the street)",
      if (length(wide)) min(ext$from[ext$from > max(wide)]) else min(ext$from))
  # the grid
  buf <- vect(sf::st_buffer(sf::st_sfc(sf::st_point(ctr), crs = 6347), misc$near))
  rec("Tallest height in the grid within 60 m, 1 m cells", round(max(terra::extract(height, buf)[[2]], na.rm = TRUE), 2))
  for (k in c(5, 10, 30)) {
    a <- aggregate(height, fact = k, fun = "mean", na.rm = TRUE)
    rec(paste0("Tallest height within 60 m, ", k, " m cells (mean)"), round(max(terra::extract(a, buf, touches = TRUE)[[2]], na.rm = TRUE), 2))
  }
  hv <- as.data.frame(height, xy = TRUE, na.rm = TRUE); hv <- hv[order(-hv$height_m), ]
  pick <- hv[1, ]
  for (i in seq_len(nrow(hv))) {
    if (nrow(pick) == 5) break
    if (all((hv$x[i] - pick$x)^2 + (hv$y[i] - pick$y)^2 > 60^2)) pick <- rbind(pick, hv[i, ])
  }
  ll <- sf::st_coordinates(sf::st_transform(sf::st_as_sf(pick, coords = c("x", "y"), crs = 6347), 4326))
  pick$lon <- round(ll[, 1], 5); pick$lat <- round(ll[, 2], 5)
  pick$from_esb_m <- round(sqrt((pick$x - ctr[[1]])^2 + (pick$y - ctr[[2]])^2))
  say("Five tallest objects in the box (1 m cells, at least 60 m apart):")
  say(paste(capture.output(print(pick, row.names = FALSE)), collapse = "\n"))
  say("    <- as.data.frame(height, xy = TRUE) sorted by height, greedy pick 60 m apart")

# 6). Check figures (for checking only, not slides) ----
  strip <- filter_poi(las, abs(Y - ctr[[2]]) < 15)   # a 30 m wide west-east strip through the building
  g <- strip$Classification == 2; nz <- strip$Classification %in% misc$noise
  png("logs/check_nyc_side.png", width = 2000, height = 1600, res = 170)
  par(mar = c(4.5, 4.5, 3, 1))
  plot(strip$X[!g & !nz] - ctr[[1]], strip$Z[!g & !nz] - street, pch = 16, cex = 0.15, col = "grey30",
       xlim = c(-200, 200), ylim = c(-10, 460), xlab = "metres east of the Empire State Building's centre",
       ylab = "metres above the street", main = "LiDAR points in a 30 m wide west-east strip through the Empire State Building")
  points(strip$X[g] - ctr[[1]], strip$Z[g] - street, pch = 16, cex = 0.25, col = "sienna")
  points(strip$X[nz] - ctr[[1]], strip$Z[nz] - street, pch = 4, cex = 0.6, col = "red")
  abline(h = c(381, 443.2), lty = 3, col = "blue")
  text(-205, c(381, 443.2), c("381 m (1,250 ft, top floor)", "443.2 m (1,454 ft, antenna tip)"), adj = c(0, -0.4), col = "blue", cex = 0.85)
  legend("topright", legend = c("ground (class 2)", "other classes", "noise (7, 18)"), col = c("sienna", "grey30", "red"),
         pch = c(16, 16, 4), bg = "white")
  dev.off()

  png("logs/check_nyc_height.png", width = 1700, height = 1500, res = 170)
  plot(height, main = "Height above ground (m), 1 m cells, 400 x 400 m around the Empire State Building",
       col = hcl.colors(50, "viridis"), plg = list(title = "m"), cex.main = 0.9)
  plot(buf, add = TRUE, border = "red", lwd = 1.5)
  dev.off()

# 7). One World Trade Center, a size and height check only (after Rscript tools/fetch_nyc.R owtc) ----
  ow_nodes <- list.files("data/lidar_nyc/owtc/ept-data", pattern = "\\.laz$", full.names = TRUE)
  if (length(ow_nodes)) {
    say("", "== 7. One World Trade Center (40.71274 N, 74.01338 W), no grids ==")
    say("Fetch: ", paste(readLines("data/lidar_nyc/owtc/fetch.txt"), collapse = " | "))
    oc <- sf::st_coordinates(sf::st_transform(sf::st_sfc(sf::st_point(c(-74.01338, 40.71274)), crs = 4326), 6347))[1, ]
    ow <- sf::st_transform(readLAS(ow_nodes), sf::st_crs(6347))
    ow <- clip_rectangle(ow, oc[[1]] - 200, oc[[2]] - 200, oc[[1]] + 200, oc[[2]] + 200)
    rec("OWTC: points in the 400 x 400 m box", npoints(ow))
    od <- (ow$X - oc[[1]])^2 + (ow$Y - oc[[2]])^2
    days <- table(as.Date(as.POSIXct(ow$gpstime + 1e9, origin = "1980-01-06", tz = "UTC")))
    say("OWTC: flight days in the box, points: ", paste(names(days), as.integer(days), sep = "=", collapse = ", "))
    o_street <- rec("OWTC: street level, median ground z within 150 m, m", round(median(ow$Z[ow$Classification == 2 & od < 150^2]), 2))
    ob <- ow@data[od < 60^2, ]
    rec("OWTC: highest point within 60 m, any class: above the street (m), class", c(round(max(ob$Z) - o_street, 1), ob$Classification[which.max(ob$Z)]))
    obc <- ob[!ob$Classification %in% misc$noise, ]
    rec("OWTC: highest point within 60 m, noise excluded: above the street (m)", round(max(obc$Z) - o_street, 1))
    rec("OWTC: the same in feet (published tip 1,776 ft = 541.3 m)", round(ft(max(obc$Z) - o_street)))
    rec("OWTC: non-noise points within 60 m above 300 m over the street", sum(obc$Z - o_street > 300))
    rec("OWTC: 95th percentile of non-noise z within 60 m, above the street (m)", round(quantile(obc$Z, 0.95) - o_street, 1))
  }

  say("", "TIME whole script (from the downloaded EPT nodes): ", sprintf("%.1f", as.numeric(difftime(Sys.time(), t_start, units = "secs"))), " s")
  writeLines(log_lines, misc$log)

# the end ----
