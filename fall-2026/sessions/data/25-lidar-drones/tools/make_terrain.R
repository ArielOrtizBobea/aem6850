# AEM 6850, session 25. Builds the terrain and drone files in data_clean/ and tests the numbers the slides show.
# Run in the 25-lidar-drones folder, after tools/fetch_terrain.R:
#   source("tools/make_terrain.R")
# What it does: crops and projects the 30 m elevation grid of Tompkins County; slope and steep land by town;
#   what can be seen from McGraw Tower; the land that drains to the Fall Creek gauge; one drone mosaic at three pixel sizes.
# Reads: data/usgs_dem/, data/census/, data/drone/, data/usgs_gauge/.
# Writes: data_clean/terrain/, data_clean/drone/, logs/prep_terrain.txt and check plots logs/check_*.png.

# 1). Preliminary ----
  # Clean up workspace and load or install necessary packages if necessary
  rm(list = ls())
  want <- c("terra", "sf", "exactextractr")
  need <- want[!(want %in% installed.packages()[, "Package"])]
  if (length(need)) install.packages(need)
  invisible(lapply(want, function(i) suppressMessages(require(i, character.only = TRUE))))
  rm(want, need)

  misc <- list(crs     = "EPSG:26918",                        # UTM zone 18N, NAD83, metres
               margin  = 0.02,                                # degrees added around the towns' box
               tower   = c(lon = -76.48505, lat = 42.44757),  # McGraw Tower
               tower_h = 53,                                  # metres, 173 ft (Cornell Chronicle)
               gauge   = "04234000",
               box_fc  = c(xmin = -76.62, xmax = -76.02, ymin = 42.36, ymax = 42.82),  # wide box for Fall Creek's basin
               snap_m  = 150,
               steep   = 15,                                  # percent rise (Saiz, QJE 2010)
               log     = "logs/prep_terrain.txt")
  for (d in c("data_clean/terrain", "data_clean/drone", "logs")) dir.create(d, recursive = TRUE, showWarnings = FALSE)
  cat("AEM 6850 session 25, terrain and drone prep. Run on", format(Sys.time(), "%Y-%m-%d %H:%M %Z"),
      "with terra", as.character(packageVersion("terra")), "\n", file = misc$log)
  say <- function(...) { s <- paste0(...); cat(s, "\n"); cat(s, "\n", file = misc$log, append = TRUE) }
  tm  <- function(label, expr) {
    t0 <- Sys.time(); x <- force(expr)
    say(sprintf("  [time] %s: %.2f s", label, as.numeric(difftime(Sys.time(), t0, units = "secs")))); x
  }
  tab <- function(df) { o <- capture.output(print(df, row.names = FALSE)); for (l in o) say("  ", l) }

# 2). A. Towns and the elevation grid ----
  say("\n== A. Towns and grid ==")
  towns_ll <- st_read("/vsizip/data/census/tl_2024_36_cousub.zip/tl_2024_36_cousub.shp", quiet = TRUE)
  towns_ll <- towns_ll[towns_ll$COUNTYFP == "109", c("NAME", "NAMELSAD", "ALAND", "AWATER")]
  say("Tompkins subdivisions: ", nrow(towns_ll), "; land ", round(sum(towns_ll$ALAND) / 1e6, 1),
      " km2, water ", round(sum(towns_ll$AWATER) / 1e6, 1), " km2")
  towns <- st_transform(towns_ll, misc$crs)
  st_write(towns, "data_clean/terrain/tompkins_towns.gpkg", delete_dsn = TRUE, quiet = TRUE)

  tile <- rast("data/usgs_dem/USGS_1_n43w077.tif")
  box  <- ext(st_bbox(towns_ll)[c("xmin", "xmax", "ymin", "ymax")]) + misc$margin
  dem_ll <- tm("crop() to the towns' box + 0.02 deg", crop(tile, box))
  writeRaster(dem_ll, "data_clean/terrain/tompkins_dem_lonlat.tif", overwrite = TRUE, gdal = "COMPRESS=DEFLATE")
  dem <- tm("project() to UTM 18N, 30 m, bilinear", project(dem_ll, misc$crs, method = "bilinear", res = 30))
  names(dem) <- "elev"
  writeRaster(dem, "data_clean/terrain/tompkins_dem_utm.tif", overwrite = TRUE, gdal = "COMPRESS=DEFLATE")
  mm <- global(dem, c("min", "max"), na.rm = TRUE)
  say("Lon/lat crop: ", nrow(dem_ll), " x ", ncol(dem_ll), " cells")
  say("UTM grid: ", nrow(dem), " rows x ", ncol(dem), " cols = ", ncell(dem), " cells; res ", paste(res(dem), collapse = " x "),
      " m; extent ", paste(round(as.vector(ext(dem))), collapse = ", "))
  say(sprintf("Elevation min %.2f m, max %.2f m", mm$min, mm$max))
  low <- as.data.frame(dem, xy = TRUE); low <- low[which.min(low$elev), ]
  lowll <- st_coordinates(st_transform(st_as_sf(low, coords = c("x", "y"), crs = misc$crs), 4326))
  say(sprintf("Lowest cell at %.4f N, %.4f W (%.2f m)", lowll[2], -lowll[1], low$elev))
  # Cayuga Lake is hydro-flattened in 3DEP: count the cells within 0.5 m of the minimum
  lake <- dem <= mm$min + 0.5
  say("Cells within 0.5 m of the minimum: ", global(lake, "sum", na.rm = TRUE)[[1]],
      " (", round(global(lake, "sum", na.rm = TRUE)[[1]] * 900 / 1e6, 1), " km2)")

# 3). B. Slope ----
  say("\n== B. Slope ==")
  slope_deg <- tm("terrain(slope, degrees, 8 neighbours)", terrain(dem, v = "slope", unit = "degrees"))
  slope_pct <- tan(slope_deg * pi / 180) * 100
  names(slope_pct) <- "slope_pct"
  writeRaster(slope_pct, "data_clean/terrain/tompkins_slope_pct.tif", overwrite = TRUE, gdal = "COMPRESS=DEFLATE")

  # One cell by hand: the cell holding McGraw Tower. Horn (1981), which terra uses with 8 neighbours:
  #   dz/dx = ((c + 2f + i) - (a + 2d + g)) / (8 * 30),  dz/dy = ((g + 2h + i) - (a + 2b + c)) / (8 * 30)
  #   with a b c / d e f / g h i the 3 x 3 window, north at the top; slope = sqrt(dz/dx^2 + dz/dy^2).
  tw <- vect(st_transform(st_sfc(st_point(misc$tower), crs = 4326), misc$crs))
  cl <- cellFromXY(dem, crds(tw)); rc <- rowColFromCell(dem, cl)
  w  <- matrix(values(dem, row = rc[1] - 1, nrows = 3, col = rc[2] - 1, ncols = 3), 3, 3, byrow = TRUE)
  dzdx <- ((w[1, 3] + 2 * w[2, 3] + w[3, 3]) - (w[1, 1] + 2 * w[2, 1] + w[3, 1])) / (8 * 30)
  dzdy <- ((w[3, 1] + 2 * w[3, 2] + w[3, 3]) - (w[1, 1] + 2 * w[1, 2] + w[1, 3])) / (8 * 30)
  hand <- sqrt(dzdx^2 + dzdy^2) * 100
  say("McGraw Tower cell ", cl, " (row ", rc[1], ", col ", rc[2], "), 3 x 3 elevations in m (north at top):")
  for (i in 1:3) say("  ", paste(sprintf("%8.2f", w[i, ]), collapse = ""))
  say(sprintf("By hand (Horn): dz/dx = %.4f, dz/dy = %.4f, slope = %.3f %% (%.3f deg); terra: %.3f %%",
              dzdx, dzdy, hand, atan(hand / 100) * 180 / pi, slope_pct[cl][[1]]))
  say(sprintf("Simple rise over run, centre to lowest neighbour: %.3f %%",
              max((w[2, 2] - w[c(2, 4, 6, 8)]) / 30, (w[2, 2] - w[c(1, 3, 7, 9)]) / (30 * sqrt(2))) * 100))

  steep <- slope_pct > misc$steep
  steep_area <- tm("exact_extract steep area by town",
                   exact_extract(steep * 900, towns, "sum", progress = FALSE))
  steep_mean <- tm("exact_extract polygon mean by town",
                   exact_extract(steep, towns, "mean", progress = FALSE))
  st <- data.frame(town = towns$NAMELSAD, land_km2 = round(towns$ALAND / 1e6, 1), water_km2 = round(towns$AWATER / 1e6, 1),
                   steep_km2 = round(steep_area / 1e6, 1),
                   share_of_land = round(100 * steep_area / towns$ALAND, 1),
                   polygon_mean = round(100 * steep_mean, 1))
  st <- st[order(-st$share_of_land), ]
  write.csv(st, "data_clean/terrain/steep_by_town.csv", row.names = FALSE)
  say("Land steeper than ", misc$steep, " % rise, by town (shares in percent):"); tab(st)
  say(sprintf("County: steep %.1f km2 of %.1f km2 land = %.1f %%; polygon mean over the county's area = %.1f %%",
              sum(steep_area) / 1e6, sum(towns$ALAND) / 1e6, 100 * sum(steep_area) / sum(towns$ALAND),
              100 * sum(steep_mean * (towns$ALAND + towns$AWATER)) / sum(towns$ALAND + towns$AWATER)))
  say("Grid cells with slope > 15 %: ", global(steep, "sum", na.rm = TRUE)[[1]], " of ", global(!is.na(steep), "sum")[[1]])

# 4). C. What can be seen from McGraw Tower ----
  say("\n== C. Viewshed from McGraw Tower ==")
  say("?viewshed (terra 1.9.50): observer = height above the elevation data of the observer; target = height above the",
      " elevation data of the targets; curvcoef = 6/7 by default, elevations corrected by curvcoef * distance^2 / earth_diameter",
      " (Earth curvature and refraction handled); output 'yes/no'. Algorithm: Wang et al. (2000).")
  say(sprintf("Check of the help's sentence '1 m for each 385 m': 6/7 * 385^2 / 12,742,000 = %.4f m; 1 m is reached at %.0f m",
              6 / 7 * 385^2 / 12742000, sqrt(12742000 / (6 / 7))))
  say(sprintf("Tower cell elevation %.2f m; observer eye at %.2f m", dem[cl][[1]], dem[cl][[1]] + misc$tower_h))
  county <- st_union(towns)
  county_area <- as.numeric(st_area(county))
  landmask <- !lake                         # land = not the flat lake surface
  run_vs <- function(grid, obs, tgt, label) {
    v <- tm(paste0("viewshed() ", label), viewshed(grid, crds(tw), observer = obs, target = tgt))
    v
  }
  vs_report <- function(v, label) {
    vis_km2 <- global(v, "sum", na.rm = TRUE)[[1]] * 900 / 1e6
    in_cty  <- exact_extract(v * 900, st_sf(geometry = county), "sum", progress = FALSE) / 1e6
    land_by <- exact_extract(v * landmask * 900, towns, "sum", progress = FALSE)
    say(sprintf("%s: visible %.1f km2 in the grid; %.1f km2 inside the county = %.1f %% of the county's area (land + water)",
                label, vis_km2, in_cty, 100 * in_cty * 1e6 / county_area))
    say(sprintf("  visible land inside the county: %.1f km2 = %.1f %% of the county's land (ALAND)",
                sum(land_by) / 1e6, 100 * sum(land_by) / sum(towns$ALAND)))
    data.frame(town = towns$NAMELSAD, pct = round(100 * land_by / towns$ALAND, 1))
  }
  vs53_0  <- run_vs(dem, misc$tower_h, 0,   "observer 53 m, target 0")
  vs53_17 <- run_vs(dem, misc$tower_h, 1.7, "observer 53 m, target 1.7 m")
  vs_gr   <- run_vs(dem, 1.7, 0,            "observer 1.7 m (ground), target 0")
  t1 <- vs_report(vs53_0, "Tower 53 m, target 0"); t2 <- vs_report(vs53_17, "Tower 53 m, target 1.7 m")
  t3 <- vs_report(vs_gr, "Ground 1.7 m, target 0")
  vt <- data.frame(town = t1$town, tower_t0 = t1$pct, tower_t1.7 = t2$pct, ground = t3$pct)
  say("Share of each town's land in view (percent of ALAND; lake cells excluded):"); tab(vt[order(-vt$tower_t0), ])
  write.csv(vt, "data_clean/terrain/viewshed_by_town.csv", row.names = FALSE)
  writeRaster(vs53_0,  "data_clean/terrain/viewshed_tower_target0.tif",   overwrite = TRUE, datatype = "INT1U")
  writeRaster(vs53_17, "data_clean/terrain/viewshed_tower_target1.7.tif", overwrite = TRUE, datatype = "INT1U")
  writeRaster(vs_gr,   "data_clean/terrain/viewshed_ground.tif",          overwrite = TRUE, datatype = "INT1U")

  lake_reach <- function(v, lk, label) {
    xy <- as.data.frame(ifel(v & lk, 1, NA), xy = TRUE, na.rm = TRUE)
    if (!nrow(xy)) { say(label, ": no lake cell in view"); return(invisible(NULL)) }
    n <- xy[which.max(xy$y), ]
    p <- st_coordinates(st_transform(st_as_sf(n, coords = c("x", "y"), crs = misc$crs), 4326))
    d <- sqrt(sum((c(n$x, n$y) - crds(tw))^2)) / 1000
    say(sprintf("%s: northernmost visible lake cell %.4f N, %.4f W; %.1f km from the tower (%.1f km north); grid top edge at y = %.0f, cell y = %.0f",
                label, p[2], -p[1], d, (n$y - crds(tw)[2]) / 1000, ymax(v), n$y))
  }
  lake_reach(vs53_0, lake, "Tower 53 m, target 0, county grid")
  lake_reach(vs53_17, lake, "Tower 53 m, target 1.7 m, county grid")
  lake_reach(vs_gr, lake, "Ground 1.7 m, county grid")
  # The county grid stops near 42.65 N; Cayuga Lake runs on to about 42.95 N. Run again on a grid that holds the whole lake (west to the tile edge at 77 W).
  dem_n <- project(crop(tile, ext(-77.00, -76.40, 42.38, 43.00)), misc$crs, method = "bilinear", res = 30)
  lake_n <- dem_n <= mm$min + 0.5
  vsn <- run_vs(dem_n, misc$tower_h, 0, "observer 53 m, target 0, grid to 43.0 N")
  lake_reach(vsn, lake_n, "Tower 53 m, target 0, grid to 43.0 N")
  vsn17 <- run_vs(dem_n, misc$tower_h, 1.7, "observer 53 m, target 1.7 m, grid to 43.0 N")
  lake_reach(vsn17, lake_n, "Tower 53 m, target 1.7 m, grid to 43.0 N")
  vsn0 <- viewshed(dem_n, crds(tw), observer = misc$tower_h, target = 0, curvcoef = 0)
  lake_reach(vsn0, lake_n, "Tower 53 m, target 0, curvcoef = 0 (flat Earth), grid to 43.0 N")

  vis_na <- ifel(vs53_0, 1, NA)
  pol <- tm("as.polygons() of the visible cells (tower, target 0)", as.polygons(vis_na))
  pol_sf <- tm("sf::st_as_sf()", st_as_sf(pol))
  parts <- tm("disagg() into separate pieces", disagg(pol))
  say("Visible area as polygons: ", nrow(pol), " feature (dissolved), ", nrow(parts), " separate pieces; ",
      sprintf("%.1f km2", sum(expanse(parts)) / 1e6))
  st_write(st_as_sf(parts), "data_clean/terrain/viewshed_tower_polygons.gpkg", delete_dsn = TRUE, quiet = TRUE)

# 5). D. The land that drains to the Fall Creek gauge ----
  say("\n== D. Fall Creek basin above gauge ", misc$gauge, " ==")
  site <- read.delim("data/usgs_gauge/site_04234000.rdb", comment.char = "#", colClasses = "character")[-1, ]
  g_ll <- c(as.numeric(site$dec_long_va), as.numeric(site$dec_lat_va)); usgs_mi2 <- as.numeric(site$drain_area_va)
  say(sprintf("USGS site record: %s, %.5f N, %.5f W (%s); drainage area %.0f mi2 = %.1f km2; contributing %s mi2",
              site$station_nm, g_ll[2], -g_ll[1], site$dec_coord_datum_cd, usgs_mi2, usgs_mi2 * 2.589988, site$contrib_drain_area_va))
  dem_fc <- tm("crop() + project() the wide box", project(crop(tile, ext(misc$box_fc)), misc$crs, method = "bilinear", res = 30))
  names(dem_fc) <- "elev"
  writeRaster(dem_fc, "data_clean/terrain/fallcreek_dem_utm.tif", overwrite = TRUE, gdal = "COMPRESS=DEFLATE")
  say("Wide grid: ", nrow(dem_fc), " x ", ncol(dem_fc), " cells, box ", paste(misc$box_fc, collapse = ", "))
  fdir <- tm("terrain(v = 'flowdir')", terrain(dem_fc, v = "flowdir"))
  pits <- tm("pitfinder()", pitfinder(fdir))
  say("Pits found by pitfinder(): ", global(pits > 0, "sum", na.rm = TRUE)[[1]], " cells; flowdir == 0: ",
      global(fdir == 0, "sum", na.rm = TRUE)[[1]])
  acc <- tm("flowAccumulation()", flowAccumulation(fdir))
  gp <- vect(st_transform(st_sfc(st_point(g_ll), crs = 4269), misc$crs))
  basin_at <- function(fd, ac, snap, label) {
    e <- extract(ac, buffer(gp, snap), cells = TRUE)
    best <- e[which.max(e[[2]]), ]
    pp <- xyFromCell(ac, best$cell)
    say(sprintf("%s: snap %d m, pour point accumulation %s cells (%.1f km2), %.0f m from the gauge",
                label, snap, format(best[[2]], big.mark = ","), best[[2]] * 900 / 1e6, sqrt(sum((pp - crds(gp))^2))))
    ws <- tm(paste("watershed()", label), watershed(fd, pp))
    km2 <- global(ws, "sum", na.rm = TRUE)[[1]] * 900 / 1e6
    say(sprintf("  basin %.1f km2 = %.1f mi2; USGS %.0f mi2; difference %+.1f %%",
                km2, km2 / 2.589988, usgs_mi2, 100 * (km2 / 2.589988 / usgs_mi2 - 1)))
    list(ws = ws, km2 = km2, pp = pp)
  }
  for (s in c(60, misc$snap_m, 300)) basin_at(fdir, acc, s, "flowdir from terrain() on the raw grid")
  # The raw grid has thousands of pits, so water stops a few cells downhill. Fill them first.
  # terra 1.9.50 has no plain sink fill (pitfiller() is an experimental erosion model), so this is the
  # Planchon and Darboux (2002) fill written with matrices: every cell is raised to the lowest level from
  # which water can still run, step by step, to the edge of the grid or to Cayuga Lake (set to NA as the outlet).
  fill_sinks <- function(r, eps = 0.001) {
    Z <- as.matrix(r, wide = TRUE); nr <- nrow(Z); nc <- ncol(Z)
    sh <- function(M, dr, dc) {                    # M moved by (dr, dc), Inf where nothing moved in
      O <- matrix(Inf, nr, nc)
      rs <- max(1, 1 + dr):min(nr, nr + dr); cs <- max(1, 1 + dc):min(nc, nc + dc)
      O[rs, cs] <- M[rs - dr, cs - dc]; O
    }
    nbs <- list(c(-1, 0), c(1, 0), c(0, -1), c(0, 1), c(-1, -1), c(-1, 1), c(1, -1), c(1, 1))
    out <- is.na(Z); edge <- out                   # outlets: grid edge and cells next to NA
    for (d in nbs) { S <- sh(out * 1, d[1], d[2]); edge <- edge | is.infinite(S) | S == 1 }
    keep <- edge & !is.na(Z)
    W <- matrix(Inf, nr, nc); W[keep] <- Z[keep]; Zf <- Z; Zf[is.na(Z)] <- Inf; it <- 0
    repeat {
      it <- it + 1; m <- matrix(Inf, nr, nc)
      for (k in seq_along(nbs)) m <- pmin(m, sh(W, nbs[[k]][1], nbs[[k]][2]) + eps * ifelse(k > 4, sqrt(2), 1))
      Wn <- pmin(W, pmax(Zf, m)); Wn[keep] <- Z[keep]; Wn[is.na(Z)] <- Inf
      changed <- sum(Wn != W); W <- Wn
      if (changed == 0) break
    }
    W[is.na(Z)] <- NA; say("  fill converged after ", it, " passes")
    rast(W, extent = ext(r), crs = crs(r))
  }
  dem_out <- ifel(dem_fc <= mm$min + 0.5, NA, dem_fc)          # Cayuga Lake's flat surface becomes the outlet
  f_fill <- "data_clean/terrain/fallcreek_dem_filled.tif"         # about 4 minutes; reuse the saved fill
  filled <- if (file.exists(f_fill)) rast(f_fill) else tm("fill_sinks() (Planchon-Darboux, base R)", fill_sinks(dem_out))
  if (file.exists(f_fill)) say("  filled grid read from ", f_fill, " (the fill took 222.6 s on 2026-11-23; delete the file to redo it)")
  say(sprintf("Cells raised by the fill: %d; largest raise %.2f m",
              global(filled > dem_out + 1e-6, "sum", na.rm = TRUE)[[1]], global(filled - dem_out, "max", na.rm = TRUE)[[1]]))
  if (!file.exists(f_fill)) writeRaster(filled, f_fill, gdal = "COMPRESS=DEFLATE")
  fdir <- tm("terrain(v = 'flowdir') on the filled grid", terrain(filled, v = "flowdir"))
  say("Pits left after the fill: ", global(pitfinder(fdir) > 0, "sum", na.rm = TRUE)[[1]], " cells")
  acc <- tm("flowAccumulation() on the filled grid", flowAccumulation(fdir))
  for (s in c(60, 300)) basin_at(fdir, acc, s, "filled grid")
  b150 <- basin_at(fdir, acc, misc$snap_m, "filled grid")
  basin <- b150$ws
  edge <- global(basin * (boundaries(!is.na(dem_fc), inner = TRUE)), "sum", na.rm = TRUE)[[1]]
  rr <- trim(ifel(basin == 1, 1, NA))
  say("Basin cells on the box edge: ", edge, "; basin extent ", paste(round(as.vector(ext(rr))), collapse = ", "),
      " vs box ", paste(round(as.vector(ext(dem_fc))), collapse = ", "))
  writeRaster(basin, "data_clean/terrain/fallcreek_basin.tif", overwrite = TRUE, datatype = "INT1U")
  writeRaster(acc, "data_clean/terrain/fallcreek_flowacc.tif", overwrite = TRUE, gdal = "COMPRESS=DEFLATE")
  bp <- st_as_sf(as.polygons(ifel(basin == 1, 1, NA)))
  bp <- st_sf(geometry = st_union(bp))
  st_write(bp, "data_clean/terrain/fallcreek_basin.gpkg", delete_dsn = TRUE, quiet = TRUE)
  ov <- suppressWarnings(st_intersection(towns, bp))
  ov$km2 <- round(as.numeric(st_area(ov)) / 1e6, 1)
  ov <- st_drop_geometry(ov)[order(-ov$km2), c("NAMELSAD", "km2")]
  say(sprintf("Basin polygon %.1f km2; inside Tompkins County %.1f km2 = %.1f %%", as.numeric(st_area(bp)) / 1e6,
              sum(ov$km2), 100 * sum(ov$km2) / (as.numeric(st_area(bp)) / 1e6)))
  say("Towns the basin overlaps (km2 of basin in each; slivers under 0.5 km2 are border noise):"); tab(ov)

# 6). E. Drone mosaic ----
  say("\n== E. Drone mosaic: Willis Corn Trial ==")
  mo <- rast("data/drone/willis_corn_trial.tif")
  say(sprintf("rows %d, cols %d, bands %d; pixel %.3f x %.3f cm; CRS %s; extent x %.1f to %.1f, y %.1f to %.1f m (%.1f x %.1f m); area %.2f ha",
              nrow(mo), ncol(mo), nlyr(mo), res(mo)[1] * 100, res(mo)[2] * 100, crs(mo, describe = TRUE)$code,
              xmin(mo), xmax(mo), ymin(mo), ymax(mo), xmax(mo) - xmin(mo), ymax(mo) - ymin(mo),
              (xmax(mo) - xmin(mo)) * (ymax(mo) - ymin(mo)) / 1e4))
  say("The file declares no NA value: the corners outside the flight are black pixels (0, 0, 0). They are set to NA here.")
  mo <- tm("mask() black pixels to NA", mask(mo, sum(mo) == 0, maskvalues = TRUE))
  nna <- global(is.na(mo[[1]]), "sum")[[1]]
  say("Black (no data) pixels: ", format(nna, big.mark = ","), " of ", format(ncell(mo), big.mark = ","),
      sprintf(" (%.1f %%); area with data %.2f ha", 100 * nna / ncell(mo), (ncell(mo) - nna) * prod(res(mo)) / 1e4))
  for (m in c(10, 30)) {
    f <- round(m / res(mo)[1])
    a <- tm(sprintf("aggregate() to %d m (fact %d, mean)", m, f), aggregate(mo, fact = f, fun = "mean", na.rm = TRUE))
    full <- aggregate(mo[[1]], fact = f, fun = "mean", na.rm = FALSE)
    say(sprintf("%d m: fact %d gives %.3f m cells; grid %d x %d = %d cells; %d hold some data, %d are complete",
                m, f, res(a)[1], nrow(a), ncol(a), ncell(a), global(!is.na(a[[1]]), "sum")[[1]], global(!is.na(full), "sum")[[1]]))
    writeRaster(a, sprintf("data_clean/drone/corn_trial_%dm.tif", m), overwrite = TRUE)
    assign(paste0("mo", m), a)
  }
  roads <- st_read("/vsizip/data/census/tl_2024_37027_roads.zip/tl_2024_37027_roads.shp", quiet = TRUE)
  roads <- st_transform(roads, crs(mo))
  rbox <- st_as_sfc(st_bbox(ext(mo) + 200, crs = st_crs(roads)))
  rd <- suppressWarnings(st_intersection(roads, rbox))
  st_write(rd, "data_clean/drone/caldwell_roads_near_mosaic.gpkg", delete_dsn = TRUE, quiet = TRUE)
  say("TIGER roads within 200 m of the mosaic: ", nrow(rd), " pieces; names: ",
      paste(sort(unique(rd$FULLNAME)), collapse = "; "))
  rin <- suppressWarnings(st_intersection(roads, st_as_sfc(st_bbox(ext(mo), crs = st_crs(roads)))))
  say("Inside the mosaic's box: ", paste(unique(rin$FULLNAME), collapse = "; "), sprintf(" (%.0f m of line)", sum(st_length(rin))))

  # Offset between the TIGER line and the road in the picture. At three points along the TIGER line, read the pixels
  # on a 50 m line across it (one every 4 cm). Asphalt here is blue-grey (blue above red, by 8 to 24 levels); grass, stubble and the
  # yellow centre stripe are not. After a 1 m running mean, runs of asphalt less than 1 m apart are joined (the
  # two lanes either side of the stripe); the road is the run over 3 m wide nearest the TIGER line.
  # Offset = distance from the TIGER line to the middle of that run.
  ln <- st_cast(st_intersection(st_union(rin[rin$FULLNAME == "Pennell St NE", ]),
                                st_as_sfc(st_bbox(ext(mo) - 10, crs = st_crs(rin)))), "LINESTRING")[1]
  off <- do.call(rbind, lapply(c(0.2, 0.5, 0.8), function(fr) {
    p0 <- st_coordinates(st_line_sample(ln, sample = fr))[1, 1:2]
    p1 <- st_coordinates(st_line_sample(ln, sample = fr + 0.01))[1, 1:2]
    tv <- (p1 - p0) / sqrt(sum((p1 - p0)^2)); nv <- c(-tv[2], tv[1])     # unit normal, to the left of the line
    s  <- seq(-25, 25, by = 0.04)
    v  <- extract(mo, cbind(p0[1] + s * nv[1], p0[2] + s * nv[2]))
    asph <- as.vector(stats::filter((v$blue > v$red) * 1, rep(1 / 25, 25)) > 0.5); asph[is.na(asph)] <- FALSE
    r <- rle(asph); en <- cumsum(r$lengths); stt <- en - r$lengths + 1
    runs <- data.frame(from = s[stt], to = s[en])[r$values, ]
    k <- 1; while (k < nrow(runs)) {                        # join the two lanes across the centre stripe (gap under 1 m)
      if (runs$from[k + 1] - runs$to[k] < 1) { runs$to[k] <- runs$to[k + 1]; runs <- runs[-(k + 1), ] } else k <- k + 1 }
    runs <- runs[runs$to - runs$from > 3, ]
    runs <- runs[which.min(pmin(abs(runs$from), abs(runs$to), ifelse(runs$from < 0 & runs$to > 0, 0, Inf))), ]
    data.frame(point = fr, x = round(p0[1], 1), y = round(p0[2], 1), edge_near_m = round(runs$from, 1),
               edge_far_m = round(runs$to, 1), width_m = round(runs$to - runs$from, 1),
               offset_to_centre_m = round((runs$from + runs$to) / 2, 1),
               side = ifelse(nv[2] > 0, "road centre lies NW of the TIGER line", "SE"))
  }))
  write.csv(off, "data_clean/drone/tiger_offset.csv", row.names = FALSE)
  say("TIGER line to the road surface in the mosaic, at 20, 50 and 80 % along the line inside the mosaic:"); tab(off)

# 7). F. Check plots ----
  say("\n== F. Check plots (logs/check_*.png) ==")
  pal <- terrain.colors(50)
  png("logs/check_A_elevation_towns.png", 1100, 1150, res = 110)
  plot(dem, col = pal, main = "Elevation (m), UTM 18N, 30 m, with Tompkins towns")
  plot(st_geometry(towns), add = TRUE, border = "black"); text(st_coordinates(st_centroid(st_geometry(towns))), towns$NAMELSAD, cex = 0.7)
  dev.off()
  png("logs/check_B_steep.png", 1100, 1150, res = 110)
  plot(steep, col = c("grey90", "firebrick"), main = "Slope above 15 % rise", legend = FALSE)
  plot(st_geometry(towns), add = TRUE, border = "black"); dev.off()
  png("logs/check_C_viewshed.png", 1100, 1150, res = 110)
  plot(dem, col = grey.colors(50), main = "Seen from McGraw Tower (53 m, target 0): orange")
  plot(ifel(vs53_0, 1, NA), col = adjustcolor("orange", 0.7), add = TRUE, legend = FALSE)
  plot(st_geometry(towns), add = TRUE, border = "black"); points(crds(tw), pch = 17, col = "blue", cex = 1.6); dev.off()
  png("logs/check_C_viewshed_north.png", 900, 1200, res = 110)
  plot(dem_n, col = grey.colors(50), main = "Seen from McGraw Tower, grid to 43.0 N")
  plot(ifel(vsn, 1, NA), col = adjustcolor("orange", 0.7), add = TRUE, legend = FALSE)
  points(crds(tw), pch = 17, col = "blue", cex = 1.6); dev.off()
  png("logs/check_D_basin.png", 1100, 1150, res = 110)
  plot(dem_fc, col = grey.colors(50), main = "Fall Creek basin above gauge 04234000; lines: > 1 km2 upstream")
  plot(ifel(basin == 1, 1, NA), col = adjustcolor("steelblue", 0.4), add = TRUE, legend = FALSE)
  plot(ifel(acc * 900 / 1e6 > 1, 1, NA), col = "blue", add = TRUE, legend = FALSE)
  plot(st_geometry(towns), add = TRUE, border = "black"); points(crds(gp), pch = 21, bg = "red", cex = 1.6); dev.off()
  png("logs/check_E_mosaic_three_sizes.png", 2100, 760, res = 110)
  par(mfrow = c(1, 3))
  for (k in list(list(aggregate(mo, 8), "4 cm (drawn at 33 cm)"), list(mo10, "10 m"), list(mo30, "30 m"))) {
    plotRGB(k[[1]], main = k[[2]], axes = FALSE, mar = c(1, 1, 3, 1)); plot(st_geometry(rd), add = TRUE, col = "red", lwd = 2)
    points(off$x, off$y, pch = 3, col = "cyan", cex = 2)
  }
  dev.off()
  say("Wrote 6 check plots.")

# 8). Downloads and G. parcel scouting, for the record ----
  say("\n== Raw files in data/ (bytes) ==")
  for (f in list.files(c("data/usgs_dem", "data/census", "data/drone", "data/usgs_gauge"), full.names = TRUE))
    say("  ", f, ": ", format(file.size(f), big.mark = ","))
  say("\n== G. Tompkins parcels with values: checked by hand with curl on 2026-11-23, nothing saved in data/ ==")
  say("  NYS Tax Parcels Public (NYS GIS Program Office, 2025 roll), ArcGIS feature service, no account:")
  say("  https://services6.arcgis.com/EbVsqZ18sv1kVJ3k/arcgis/rest/services/NYS_Tax_Parcels_Public/FeatureServer/1 (polygons)")
  say("  https://nysgeohub.ny.gov/arcgis/rest/services/Parcels/NYS_Tax_Parcel_Centroid_Points/FeatureServer/0 (centroids, 2,000 rows a page)")
  say("  COUNTY_NAME = 'Tompkins': 35,369 parcels (returnCountOnly, both services). Fields include PROP_CLASS, LAND_AV, TOTAL_AV,")
  say("  FULL_MARKET_VAL, ACRES, YR_BLT, SQFT_LIVING, ROLL_YR (2025), and owner names and mailing addresses (PRIMARY_OWNER, MAIL_ADDR).")
  say("  2,000 centroids as GeoJSON with 6 fields: 476,298 bytes, so all 35,369 about 8.4 MB in 18 pages.")
  say("  The old gisservices.its.ny.gov MapServer answered 'Service ... not started'.")

# the end ----
