# Figures for the session 25 page and slides, part 5 (radar and LiDAR).
# Base R, terra, sf and exactextractr. Run from fall-2026/sessions:
#   Rscript _figures-25c.R                       # every block
#   Rscript _figures-25c.R f27_campus_radar_lidar  # setup, then one block (and its DEPS)
# Writes figures/25-radar-lidar/<block>.png. Inputs: data/25-radar-lidar/data_clean/ (the session project, after
# its tools/make_terrain.R, tools/make_lidar.R and tools/make_radar.R have run), and for f29 the dated events in
# _planning/session25_radar_lidar_facts.md.
# Drawn at res 200. A figure W inches wide shown at about 100 * W px on the 1050 x 700 slide
# keeps its point sizes; every label is 10.5 pt or more at that width.
# The radar grid is the Copernicus DEM GLO-30 (TanDEM-X). Its heights are on EGM2008; USGS and LiDAR are on NAVD88.
# The radar grids are moved onto NAVD88 by the constant offset logged in logs/prep_radar.txt (flat-land mode, -0.49 m).

# ---- Run named blocks only: Rscript _figures-25c.R <block> [<block> ...] ----
local({
  want <- commandArgs(trailingOnly = TRUE)
  self <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE))
  if (!length(self)) return(invisible())
  src <- readLines(self)
  s <- grep("^# ==== BLOCK: ", src); e <- grep("^# ==== END BLOCK ====", src)
  nm <- sub("^# ==== BLOCK: ([^ ]+).*", "\\1", src[s])
  if (!length(want)) want <- nm
  dp <- lapply(src[s], function(l) if (grepl("DEPS:", l))
    strsplit(sub(".*DEPS: *([^ ]+).*", "\\1", l), ",")[[1]] else character())
  done <- character()
  run <- function(b) {
    if (b %in% done) return()
    k <- match(b, nm); if (is.na(k)) stop("no block named ", b)
    for (d in c("setup", dp[[k]])) if (d != b) run(d)
    cat("block", b, "\n")
    eval(parse(text = src[(s[k] + 1):(e[e > s[k]][1] - 1)]), envir = globalenv())
    done <<- c(done, b)
  }
  for (b in want) run(b)
  quit(save = "no")
})

# ==== BLOCK: setup ====
suppressPackageStartupMessages({library(terra); library(sf); library(exactextractr)})
out <- "figures/25-radar-lidar"; dat <- "data/25-radar-lidar"
dir.create(out, showWarnings = FALSE, recursive = TRUE)
ink <- "#222222"; acc <- "#B31B1B"; grey <- "#666666"; light <- "#E4E2DC"; rule <- "#BBBBBB"
blue <- "#3A6C9C"; amber <- "#E6A700"; red <- "#C0392B"; teal <- "#2A9D8F"
land <- "#F1EFEA"; sea <- "#CFE0EC"; nodata <- "#E3E3E3"
brown <- "#8B5A2B"; sky <- "#EAF2F8"; leaf <- "#5E8C4A"
lakeblue <- "#7FA9CF"; orange <- "#E8892B"
fig <- function(name, w, h, mar = c(0, 0, 0, 0), ps = 12) {
  png(file.path(out, name), width = w, height = h, units = "in", res = 200, pointsize = ps)
  par(mar = mar, family = "sans", xpd = NA)
}
dpath <- function(...) file.path(dat, ...)
# a one-layer raster drawn as an image, classed by breaks
rimg <- function(r, pal, br, na = "transparent") {
  v <- values(r, mat = FALSE); k <- findInterval(v, br, all.inside = TRUE)
  col <- ifelse(is.na(v), na, pal[k]); e <- as.vector(ext(r))
  rasterImage(as.raster(matrix(col, nrow(r), ncol(r), byrow = TRUE)), e[1], e[3], e[2], e[4], interpolate = FALSE)
}
# a TRUE/FALSE raster drawn in one colour where TRUE
rmask <- function(r, col) {
  v <- values(r, mat = FALSE); e <- as.vector(ext(r))
  m <- matrix(ifelse(!is.na(v) & v > 0, col, "transparent"), nrow(r), ncol(r), byrow = TRUE)
  rasterImage(as.raster(m), e[1], e[3], e[2], e[4], interpolate = FALSE)
}
# text with a halo, so it reads over a map or a photo
halo <- function(x, y, s, col = ink, bg = "white", r = 0.014, ...) {
  for (a in seq(0, 2 * pi, length.out = 17)[-17]) text(x + xinch(r * cos(a)), y + yinch(r * sin(a)), s, col = bg, ...)
  text(x, y, s, col = col, ...)
}
# a boxed horizontal colour key: equal boxes, labels under the box edges ("" skips one)
hkey <- function(x0, x1, y0, h, pal, lab, title, cex = 1, padx = 0.03, cexl = cex) {
  n <- length(pal); xs <- seq(x0, x1, length.out = n + 1)
  ch <- strheight("M", cex = cex); cw <- strwidth(lab[c(1, n + 1)], cex = cexl) / 2
  tw <- strwidth(title, cex = cex, font = 2)
  rect(min(x0 - cw[1], x0) - padx, y0 - 2.1 * ch, max(x1 + cw[2], x0 + tw) + padx, y0 + h + 2.0 * ch,
       col = "white", border = rule)
  rect(xs[-(n + 1)], y0, xs[-1], y0 + h, col = pal, border = NA)
  segments(xs[lab != ""], y0, xs[lab != ""], y0 - 0.3 * ch, col = ink)
  text(xs[lab != ""], y0 - 1.1 * ch, lab[lab != ""], cex = cexl)
  text(x0, y0 + h + 1.0 * ch, title, adj = c(0, 0.5), cex = cex, font = 2)
}
# a boxed legend of filled squares and point symbols, top-left corner at (x, y)
boxleg <- function(x, y, lab, fill = NA, pch = NA, pcol = ink, pbg = NA, cex = 1, title = NULL) {
  legend(x, y, lab, fill = fill, border = ifelse(is.na(fill), NA, ink), pch = pch, col = pcol, pt.bg = pbg,
         pt.cex = 1.5, bg = "white", box.col = rule, cex = cex, title = title, title.font = 2, title.adj = 0,
         x.intersp = 0.8, y.intersp = 1.15, inset = 0)
}
fmt <- function(x, d = 0) formatC(x, format = "f", digits = d, big.mark = ",")

# The Tompkins grid, its towns, the lake, the hillshade and McGraw Tower
dem   <- rast(dpath("data_clean/terrain/tompkins_dem_utm.tif"))          # elevation, m, 30 m cells
towns <- st_read(dpath("data_clean/terrain/tompkins_towns.gpkg"), quiet = TRUE)
lake  <- dem <= global(dem, "min", na.rm = TRUE)[[1]] + 0.5              # Cayuga Lake's flat surface
landm <- !lake                                                            # 0.5 m above it: land (slide 37's `land`)
hs    <- shade(terrain(dem, "slope", unit = "radians"), terrain(dem, "aspect", unit = "radians"), 40, 315)
palHS <- grey.colors(40, start = 0.45, end = 0.97)
brHS  <- quantile(values(hs, mat = FALSE), seq(0, 1, length.out = 41), na.rm = TRUE)
tw    <- project(vect(cbind(-76.48505, 42.44757), crs = "EPSG:4326"), crs(dem))   # McGraw Tower
twc   <- crds(tw)[1, ]
ext0  <- as.vector(ext(dem))
county <- st_union(towns)
# where each town's name goes (UTM metres), and its name on the map
tl <- data.frame(NAMELSAD = c("Lansing town", "Groton town", "Ulysses town", "Dryden town", "Enfield town",
                              "Ithaca town", "Ithaca city", "Newfield town", "Danby town", "Caroline town"),
                 lab = c("Lansing", "Groton", "Ulysses", "Dryden", "Enfield", "Ithaca town", "Ithaca\ncity",
                         "Newfield", "Danby", "Caroline"),
                 x = c(375600, 389000, 365600, 389500, 365500, 376600, 375900, 366000, 377300, 389500),
                 y = c(4715000, 4716000, 4708300, 4704500, 4699300, 4695900, 4701300, 4688300, 4688300, 4691000))
# the county map frame, with room below for a key
mapwin <- function(extra_bottom = 0) {
  plot.new(); plot.window(ext0[1:2], c(ext0[3] - extra_bottom, ext0[4]), asp = 1, xaxs = "i", yaxs = "i")
}
towns_lines <- function(col = ink, lwd = 1) plot(st_geometry(towns), add = TRUE, border = col, lwd = lwd)
town_labels <- function(extra = NULL, cex = 1, at = NULL) {
  lab <- tl$lab; x <- tl$x; y <- tl$y
  if (!is.null(extra)) {                                   # the city's name on one line, its share under it, west of the tower
    lab[tl$lab == "Ithaca\ncity"] <- "Ithaca city"
    lab <- paste0(lab, ifelse(lab == "Ithaca city", "\n", " "), extra[match(tl$NAMELSAD, names(extra))])
    x[tl$lab == "Ithaca\ncity"] <- 373600; y[tl$lab == "Ithaca\ncity"] <- 4700500
  }
  for (k in names(at)) { i <- tl$NAMELSAD == k; x[i] <- at[[k]][1]; y[i] <- at[[k]][2] }   # labels moved for one map
  for (i in seq_len(nrow(tl))) halo(x[i], y[i], lab[i], font = 2, cex = cex)
}
tower_mark <- function(cex = 1.7) points(twc[1], twc[2], pch = 24, bg = "white", col = ink, cex = cex, lwd = 2)
scalebar <- function(x, y, km = 10, cex = 1) {
  rect(x, y, x + km * 1000, y + 250, col = ink, border = NA)
  text(x + km * 500, y + 500, paste(km, "km"), adj = c(0.5, 0), font = 2, cex = cex)
}
# the cells of a raster as rectangles (for small grids, with grid lines)
cellrect <- function(r, col, border = "white", lwd = 0.6) {
  xy <- xyFromCell(r, 1:ncell(r)); h <- res(r) / 2
  rect(xy[, 1] - h[1], xy[, 2] - h[2], xy[, 1] + h[1], xy[, 2] + h[2], col = col, border = border, lwd = lwd)
}
# radar on EGM2008 minus USGS on NAVD88 on flat land: -0.49 m (logs/prep_radar.txt); subtract it to put radar on NAVD88
off <- -0.49
# ==== END BLOCK ====

# ==== BLOCK: f26_radar_lidar_how ====
# How radar and LiDAR measure elevation, drawn the same way: a sender, a signal down, an echo back.
# Radar: a satellite, radio waves through a cloud. LiDAR: a plane under the cloud, laser pulses (as in f01_pulse).
cloud <- function(x, y, s = 1) {
  xs <- x + s * c(-0.55, -0.2, 0.2, 0.55, 0); ys <- y + s * c(0, 0.12, 0.1, 0, -0.08); rs <- s * c(0.3, 0.38, 0.36, 0.3, 0.3)
  symbols(xs, ys, circles = rs, inches = FALSE, add = TRUE, bg = "#C9D1D9", fg = NA)
}
# a wavy line from (x0, y0) to (x1, y1), with an arrowhead at the end
wave <- function(x0, y0, x1, y1, col, amp = 0.07, n = 7, lwd = 2.6) {
  t <- seq(0, 1, length.out = 300); L <- sqrt((x1 - x0)^2 + (y1 - y0)^2)
  ux <- (x1 - x0) / L; uy <- (y1 - y0) / L
  s <- amp * sin(2 * pi * n * t) * pmin(1, (1 - t) * 8)
  lines(x0 + t * (x1 - x0) - s * uy, y0 + t * (y1 - y0) + s * ux, col = col, lwd = lwd)
  arrows(x1 - 0.12 * ux, y1 - 0.12 * uy, x1, y1, length = 0.13, col = col, lwd = lwd)
}
ground <- function() {
  rect(0.25, 0.75, 5.25, 1.1, col = "#D9C6A5", border = NA)
  segments(0.25, 1.1, 5.25, 1.1, col = brown, lwd = 2)
}
tree <- function(x) {
  rect(x - 0.07, 1.1, x + 0.07, 1.75, col = brown, border = NA)
  symbols(x, 2.15, circles = 0.48, inches = FALSE, add = TRUE, bg = leaf, fg = NA)
}
plane <- function(px, py, col = "#55606B") {
  polygon(px + c(-0.75, 0.65, 0.85, 0.65, -0.75, -0.9), py + c(-0.1, -0.1, 0, 0.1, 0.1, 0.3), col = col, border = NA)
  polygon(px + c(-0.15, 0.25, 0.05, -0.35), py + c(0.02, 0.02, -0.38, -0.38), col = "#3E4750", border = NA)
}
satellite <- function(x, y) {
  rect(x - 0.5, y - 0.1, x - 0.2, y + 0.1, col = blue, border = ink); rect(x + 0.2, y - 0.1, x + 0.5, y + 0.1, col = blue, border = ink)
  segments(x - 0.2, y, x + 0.2, y, lwd = 2)
  rect(x - 0.16, y - 0.2, x + 0.16, y + 0.2, col = "#8A939C", border = ink)
}
lab <- function(x, y, s, col = ink, font = 2, cex = 1) text(x, y, s, adj = c(0, 0.5), col = col, font = font, cex = cex)
fig("f26_radar_lidar_how.png", 11, 5.2, ps = 16)
layout(matrix(1:2, 1)); par(cex = 1)
for (k in 1:2) {
  par(mar = c(0.2, 0.3, 0.2, 0.3))
  plot.new(); plot.window(c(0, 5.5), c(0, 5.2), xaxs = "i", yaxs = "i")
  rect(0.05, 0.05, 5.45, 5.15, border = rule)
  ground(); tree(1.55)
  if (k == 1) {                                            # radar
    text(2.75, 4.85, "Radar", font = 2, cex = 1.35)
    satellite(0.95, 4.25); lab(1.55, 4.25, "Satellite")
    cloud(1.25, 3.35, 0.8)
    wave(0.9, 4.0, 1.5, 2.68, red); wave(1.78, 2.68, 1.18, 4.0, blue)
    lab(2.4, 3.45, "Radio waves,\na few cm long", col = red)
    lab(2.4, 2.55, "Passes through cloud", font = 1)
    lab(2.4, 1.85, "30 m cells from orbit", font = 1)
  } else {                                                 # LiDAR
    text(2.75, 4.85, "LiDAR", font = 2, cex = 1.35)
    cloud(1.3, 4.25, 0.8)
    segments(0.62, 4.85, 0.62, 4.42, lwd = 2.6, col = red, lty = 2)   # a pulse from above stops at the cloud
    text(0.62, 4.32, "\u00d7", col = red, font = 2, cex = 1.6)
    plane(1.35, 3.4); lab(2.4, 3.45, "Plane, under the cloud")
    arrows(1.55, 3.05, 1.55, 2.68, length = 0.12, lwd = 2.6, col = red)
    segments(1.55, 2.6, 1.55, 1.15, lwd = 2.6, col = red, lty = 2)
    arrows(1.33, 2.65, 1.33, 3.05, length = 0.12, lwd = 2.6, col = blue)
    arrows(1.8, 1.15, 1.8, 3.05, length = 0.12, lwd = 2.6, col = teal)
    points(c(1.55, 1.55), c(2.62, 1.12), pch = 21, bg = "white", col = ink, cex = 1.3, lwd = 1.6)
    lab(2.4, 4.25, "Blocked by cloud", font = 1)
    lab(2.4, 2.75, "Laser light", col = red)
    lab(2.4, 2.25, "Returns from the treetop", col = blue)
    lab(2.4, 1.85, "and from the ground", col = teal)
    lab(2.4, 1.4, "Several points per m\u00b2", font = 1)
  }
  text(2.75, 0.42, "Sends a signal and times the echo", font = 2, cex = 1)
}
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f27_campus_radar_lidar ====
# The campus box three times on one elevation scale: radar in 30 m cells, LiDAR surface and ground in 1 m cells.
# Radar comes from data_clean/radar/campus_30m.tif (the box cut in 30 m cells, EPSG:6347), moved onto NAVD88 by `off`.
box   <- c(xmin = 377600, ymin = 4700350, xmax = 378200, ymax = 4700950)
tower <- c(377876.1, 4700539.6)
camp  <- rast(dpath("data_clean/radar/campus_30m.tif"))
rad30 <- camp$radar - off
dsm1  <- rast(dpath("data_clean/lidar/campus_dsm.tif")); dtm1 <- rast(dpath("data_clean/lidar/campus_dtm.tif"))
brC  <- seq(205, 305, 10); palC <- hcl.colors(10, "Lajolla", rev = TRUE)
labC <- c("205", "", "225", "", "245", "", "265", "", "285", "", "305")
nm <- c("Radar from orbit, 30 m cells", "LiDAR surface, 1 m cells", "LiDAR ground, 1 m cells")
fig("f27_campus_radar_lidar.png", 13, 5.6, ps = 14)
layout(matrix(1:3, 1)); par(cex = 1)            # layout() with 3 columns would shrink text to 0.66
for (k in 1:3) {
  par(mar = c(0.2, 0.35, 0.3, 0.35))
  plot.new(); plot.window(c(box[["xmin"]] - 30, box[["xmax"]] + 30), c(box[["ymin"]] - 150, box[["ymax"]] + 75), asp = 1,
                          xaxs = "i", yaxs = "i")
  if (k == 1) cellrect(rad30, palC[findInterval(values(rad30, mat = FALSE), brC, all.inside = TRUE)], border = "white", lwd = 0.8)
  if (k == 2) rimg(dsm1, palC, brC)
  if (k == 3) rimg(dtm1, palC, brC)
  rect(box[["xmin"]], box[["ymin"]], box[["xmax"]], box[["ymax"]], border = rule)
  text(mean(box[c(1, 3)]), box[["ymax"]] + 38, nm[k], font = 2, cex = 1.2)
  text(box[["xmin"]], box[["ymax"]] + 38, letters[k], font = 2, cex = 1.6, adj = c(0, 0.5))
  symbols(tower[1], tower[2], circles = 14, inches = FALSE, add = TRUE, fg = "white", lwd = 4)
  symbols(tower[1], tower[2], circles = 14, inches = FALSE, add = TRUE, fg = acc, lwd = 2)
  halo(tower[1] + 24, tower[2] - 16, "McGraw Tower", adj = c(0, 1), font = 2, cex = 1)
  if (k == 2) hkey(box[["xmin"]] + 25, box[["xmax"]] - 25, box[["ymin"]] - 95, 24, palC, labC,
                   "Elevation, m above sea level", cex = 1, padx = 18)
}
dev.off()
cat("  f27: radar range", round(unlist(global(rad30, range, na.rm = TRUE)), 1), "; surface", round(unlist(global(dsm1, range)), 1),
    "; ground", round(unlist(global(dtm1, range)), 1), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f28_county_radar_minus_lidar ====
# Radar minus USGS's LiDAR-based 30 m elevation over Tompkins County, after the constant offset between
# EGM2008 and NAVD88 is removed. Positive: radar sits above the ground (trees, roofs).
rad <- rast(dpath("data_clean/radar/tompkins_copernicus_utm.tif"))
dd  <- mask(rad - dem - off, vect(county)); dd[lake] <- NA
brD  <- c(-1000, -20, -10, -5, -2, 2, 5, 10, 20, 1000)   # symmetric, so the middle class (-2 to 2) is the pale one
palD <- hcl.colors(9, "PRGn")
fig("f28_county_radar_minus_lidar.png", 6.5, 7.6, ps = 16)
par(mar = c(0.2, 0.2, 0.2, 0.2))
mapwin(7600)
rimg(dd, palD, brD)
rmask(lake, lakeblue)
towns_lines()
town_labels()
halo(368600, 4712600, "Cayuga\nLake", col = "#1F4E79", font = 4, srt = -62)
scalebar(390000, ext0[3] - 6000)
hkey(ext0[1] + 1500, ext0[1] + 27000, ext0[3] - 5300, 1400, palD,
     c("", "−20", "−10", "−5", "−2", "2", "5", "10", "20", ""), "Radar minus USGS ground, m",
     cex = 1, padx = 700)
dev.off()
v <- values(dd, mat = FALSE); v <- v[!is.na(v)]
cat("  f28: cells", length(v), "; median", round(median(v), 2), "; share > 5 m", round(100 * mean(v > 5), 1), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f29_timeline ====
# When sonar, radar and LiDAR appeared: one time axis across the slide, one lane and one colour per sensor.
# Labels alternate above and below each lane so neighbours do not touch. Every event and its source is listed on the
# session page and in _planning/session25_radar_lidar_facts.md and _planning/session25_sonar_facts.md.
col3 <- c(Sonar = "#0072B2", Radar = "#D55E00", LiDAR = "#009E73")   # Okabe-Ito blue, vermillion, bluish green
ev <- data.frame(
  side = c(rep("Sonar", 3), rep("Radar", 4), rep("LiDAR", 4)),
  year = c(1914, 1922, 1963, 1935, 1950, 1978, 2000, 1960, 1971, 2005, 2016),
  pos  = c(1, -1, 1, 1, -1, 1, -1, 1, -1, 1, -1),
  l1 = c("Echo off an iceberg", "Echo sounder on ships", "Multibeam sonar",
         "Radar detects a plane", "Radar at airports", "Imaging radar in orbit", "Shuttle maps the world",
         "First laser", "Laser measures the Moon", "Self-driving car wins race", "USGS maps the US"))
fig("f29_timeline.png", 11, 5.2, ps = 16)
par(mar = c(0.2, 0.2, 0.2, 0.2))
plot.new(); plot.window(c(1889, 2036), c(-0.1, 8.0), xaxs = "i", yaxs = "i")
lane_y <- c(Sonar = 6.75, Radar = 4.3, LiDAR = 1.85)
segments(seq(1910, 2020, 10), 0.55, seq(1910, 2020, 10), 7.9, col = "#EEEEEE", lwd = 1)
segments(1905, 0.55, 2025, 0.55, col = grey, lwd = 1.5)
text(seq(1910, 2020, 10), 0.22, seq(1910, 2020, 10), col = grey, cex = 0.95)
for (k in names(lane_y)) {
  y <- lane_y[[k]]; e <- ev[ev$side == k, ]; cl <- col3[[k]]
  segments(min(e$year), y, 2025, y, col = cl, lwd = 4)
  text(1890, y, k, col = cl, font = 2, cex = 1.25, adj = c(0, 0.5))
  points(e$year, rep(y, nrow(e)), pch = 21, bg = cl, col = "white", cex = 2.2, lwd = 1.5)
  for (i in seq_len(nrow(e))) {                            # the year next to the dot, the event beyond it
    s <- e$pos[i]
    text(e$year[i], y + s * 0.45, e$year[i], col = cl, font = 2, cex = 1)
    text(e$year[i], y + s * 0.85, e$l1[i], cex = 0.95)
  }
}
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f33_radar_elevation ====
# The radar elevation raster of Tompkins County (Copernicus GLO-30, TanDEM-X), on the same 30 m cells as USGS's
# raster, drawn like f16 so the two maps compare. Heights as in the file (EGM2008); the 0.49 m offset is too small to see.
rad <- rast(dpath("data_clean/radar/tompkins_copernicus_utm.tif"))
mmR <- unlist(global(rad, c("min", "max"), na.rm = TRUE))
brR <- c(mmR[1], seq(150, 600, 50), mmR[2]); palR <- hcl.colors(length(brR) - 1, "Terrain 2")
hsR <- shade(terrain(rad, "slope", unit = "radians"), terrain(rad, "aspect", unit = "radians"), 40, 315)
brHSR <- quantile(values(hsR, mat = FALSE), seq(0, 1, length.out = 41), na.rm = TRUE)
fig("f33_radar_elevation.png", 6.5, 7.4, ps = 16)
par(mar = c(0.2, 0.2, 0.2, 0.2))
mapwin(6800)
rimg(hsR, palHS, brHSR)
rimg(rad, adjustcolor(palR, 0.72), brR)
rmask(lake, lakeblue)
towns_lines()
town_labels()
tower_mark()
halo(twc[1] + 900, twc[2] - 300, "McGraw\nTower", adj = c(0, 1), font = 2)
halo(368600, 4712600, "Cayuga\nLake", col = "#1F4E79", font = 4, srt = -62)
scalebar(388000, ext0[3] - 5200)
hkey(ext0[1] + 1500, ext0[1] + 26000, ext0[3] - 4600, 1400, palR,
     c(fmt(mmR[1], 0), "", "200", "", "300", "", "400", "", "500", "", "", fmt(mmR[2], 0)), "Radar elevation, m",
     cex = 1, padx = 700)
dev.off()
cat("  f30: range", round(mmR, 2), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f31_hail_day ====
# Radar hail on 12 June 2022 in the seven Plains states of the instructor's hail pilot (October 2026):
# each county coloured by its area of radar hail of 1 inch or more (NOAA MRMS, the largest hail estimated in each
# 1 km cell over the radar day, 12:00 to 12:00 UTC), a white dot where someone filed a hail report (NCEI Storm Events).
# Reads data_clean/hail/ (made by tools/make_hail.R from _planning/hail_pilot/). Albers equal area (EPSG:5070).
cty7 <- st_transform(st_read(dpath("data_clean/hail/counties_7states.gpkg"), quiet = TRUE), 5070)
hd   <- read.csv(dpath("data_clean/hail/hail_county_day.csv"), colClasses = c(geoid = "character"))
day  <- hd[hd$date == "2022-06-12", ]
cty7$km2  <- day$km2_1in[match(cty7$GEOID, day$geoid)];  cty7$km2[is.na(cty7$km2)] <- 0
cty7$reps <- day$reports[match(cty7$GEOID, day$geoid)];  cty7$reps[is.na(cty7$reps)] <- 0
st7  <- aggregate(cty7["ALAND"], by = list(st = cty7$STUSPS), FUN = sum)
brH  <- c(0, 0.001, 50, 200, 1000, Inf)
palH <- c(land, "#fed976", "#fd8d3c", "#e31a1c", "#800026")
bb   <- st_bbox(cty7)
fig("f31_hail_day.png", 5.6, 5.6, ps = 12)
par(mar = c(0.1, 0.1, 0.1, 0.1))
plot.new(); plot.window(c(bb[["xmin"]], bb[["xmax"]]), c(bb[["ymin"]] - 330000, bb[["ymax"]]), asp = 1, xaxs = "i", yaxs = "i")
plot(st_geometry(cty7), col = palH[findInterval(cty7$km2, brH)], border = "#C9C5BC", lwd = 0.3, add = TRUE)
plot(st_geometry(st7), border = ink, lwd = 1.3, add = TRUE, col = NA)
cen <- st_coordinates(st_point_on_surface(st_geometry(cty7[cty7$reps > 0, ])))
points(cen, pch = 21, bg = "white", col = ink, cex = 1.2, lwd = 1.3)
lab <- st_coordinates(st_point_on_surface(st_geometry(st7)))
for (i in seq_len(nrow(st7))) halo(lab[i, 1], lab[i, 2], st7$st[i], font = 2, cex = 1.15)
legend(bb[["xmin"]], bb[["ymin"]] - 30000, c("none", "under 50", "50 to 200", "200 to 1,000", "1,000 or more"),
       fill = palH, border = ink, bg = "white", box.col = rule, ncol = 3, title = "Radar hail of 1 inch or more, km²",
       title.font = 2, title.adj = 0, x.intersp = 0.6, cex = 1, text.width = 300000)
legend(bb[["xmax"]], bb[["ymin"]] - 30000, "hail report", pch = 21, pt.bg = "white", col = ink, pt.cex = 1.2,
       bg = "white", box.col = rule, xjust = 1, cex = 1)
dev.off()
cat("  f31: counties with radar hail >= 1 in:", sum(cty7$km2 > 0), "; with a report:", sum(cty7$reps > 0),
    "; both:", sum(cty7$km2 > 0 & cty7$reps > 0), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f32_hail_losses ====
# Panel B of the instructor's hail pilot (_planning/hail_pilot/fig_hail.R), redrawn: the share of county-months with
# more than $100,000 of crop-insurance hail losses, by the radar area of hail of 1 inch or more in the county-month,
# for county-months with and without a hail report. Bins with 20 or more county-months, as in the pilot.
hm  <- read.csv(dpath("data_clean/hail/hail_county_month.csv"), colClasses = c(geoid = "character"))
lab <- c("0", "0–10", "10–50", "50–200", "200–1,000", "over 1,000")
hm$bin <- cut(hm$km2_1in, c(-1, 0, 10, 50, 200, 1000, Inf), labels = lab)
b <- aggregate(cbind(p = loss_usd > 1e5, n = 1) ~ bin + rep, transform(hm, rep = reports > 0), sum)
b$p <- b$p / b$n
fig("f32_hail_losses.png", 7.2, 3.3, mar = c(3.6, 5.6, 0.6, 0.6), ps = 13)
plot(NA, xlim = c(0.8, 6.2), ylim = c(0, 0.8), xaxt = "n", yaxt = "n", bty = "l", xlab = "", ylab = "")
axis(1, 1:6, lab, cex.axis = 0.95, col = rule); axis(2, seq(0, 0.8, 0.2), paste0(seq(0, 80, 20), "%"), las = 1, col = rule)
mtext("Radar area of hail of 1 inch or more in the county-month, km²", 1, 2.4)
mtext("Share with losses\nover $100,000", 2, 3.3)
for (k in c(TRUE, FALSE)) {
  q <- b[b$rep == k & b$n >= 20, ]; x <- as.integer(q$bin); cl <- if (k) blue else orange
  lines(x, q$p, lwd = 2.5, col = cl); points(x, q$p, pch = 19, col = cl, cex = 1.1)
}
legend("topleft", c("at least one hail report", "no hail report"), col = c(blue, orange), lwd = 2.5, pch = 19,
       bty = "n", cex = 1, inset = c(0.02, 0))
dev.off()
print(b[b$n >= 20, ])
# ==== END BLOCK ====

# ==== BLOCK: f30_active_passive DEPS: f26_radar_lidar_how ====
# Passive and active sensors, drawn like f26 (same ground, tree, satellite and waves; helpers from that block).
# Passive: the sun lights the ground, a camera on a satellite records the light that bounces back.
# Active: the sensor sends its own signal down and records the echo.
sun <- function(x, y, r = 0.32) {
  a <- seq(0, 2 * pi, length.out = 13)[-13]
  segments(x + 1.35 * r * cos(a), y + 1.35 * r * sin(a), x + 1.8 * r * cos(a), y + 1.8 * r * sin(a), col = amber, lwd = 3)
  symbols(x, y, circles = r, inches = FALSE, add = TRUE, bg = amber, fg = NA)
}
fig("f30_active_passive.png", 6.4, 5.6, ps = 18)
# two wide panels, one above the other, so each is drawn large beside the slide's text
layout(matrix(1:2, 2)); par(cex = 1)
for (k in 1:2) {
  par(mar = c(0.15, 0.15, 0.15, 0.15))
  plot.new(); plot.window(c(0, 8), c(0.55, 4.15), xaxs = "i", yaxs = "i")
  rect(0.05, 0.6, 7.95, 4.1, border = rule)
  rect(0.2, 0.75, 7.8, 1.1, col = "#D9C6A5", border = NA); segments(0.2, 1.1, 7.8, 1.1, col = brown, lwd = 2)
  tree(2.4)
  if (k == 1) {                                            # passive
    text(0.25, 3.8, "Passive", font = 2, cex = 1.3, adj = c(0, 0.5))
    sun(0.85, 3.05, r = 0.26)
    satellite(4.2, 3.45)
    wave(1.15, 2.85, 2.1, 2.55, amber, amp = 0.05, n = 5)
    wave(2.75, 2.6, 3.95, 3.25, amber, amp = 0.05, n = 5)
    lab(4.9, 3.45, "Camera on a satellite", font = 1)
    lab(4.9, 2.55, "Records sunlight", font = 2)
    lab(4.9, 2.0, "that bounces off", font = 2)
    lab(4.9, 1.5, "the ground", font = 2)
  } else {                                                 # active
    text(0.25, 3.8, "Active", font = 2, cex = 1.3, adj = c(0, 0.5))
    satellite(2.4, 3.45)
    wave(2.2, 3.2, 2.2, 2.72, red, amp = 0.05, n = 3)
    wave(2.62, 2.72, 2.62, 3.2, blue, amp = 0.05, n = 3)
    lab(4.9, 3.45, "Radar or LiDAR", font = 1)
    lab(4.9, 2.75, "Signal down", col = red)
    lab(4.9, 2.25, "Echo back", col = blue)
    lab(4.9, 1.6, "Sends its own signal", font = 2)
  }
}
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f34_sonar DEPS: f26_radar_lidar_how ====
# How a multibeam sonar maps the floor, drawn like f30: a ship sends a fan of sound beams down through the water
# and times the echoes. Each pass maps one strip of the floor. Speed of sound from NOAA (about 1,500 m per second).
fig("f34_sonar.png", 6.4, 5.6, ps = 18)
par(mar = c(0.15, 0.15, 0.15, 0.15), cex = 1)
plot.new(); plot.window(c(0, 10), c(0, 6), xaxs = "i", yaxs = "i")
fl <- function(x) 1.45 + 0.22 * sin(0.9 * x) + 0.08 * sin(2.3 * x)        # the floor
xs <- seq(0.1, 9.9, length.out = 400)
rect(0.1, 4.4, 9.9, 5.9, col = sky, border = NA)                          # air
polygon(c(0.1, xs, 9.9), c(4.4, fl(xs), 4.4), col = sea, border = NA)      # water
polygon(c(0.1, xs, 9.9), c(0.1, fl(xs), 0.1), col = "#D9C6A5", border = NA) # floor
lines(xs, fl(xs), col = brown, lwd = 2); segments(0.1, 4.4, 9.9, 4.4, col = blue, lwd = 1.5)
rect(0.05, 0.05, 9.95, 5.95, border = rule)
sx <- 2.8; sy <- 4.3                                                       # the sonar, under the hull
polygon(sx + c(-1.1, 1.1, 0.8, -0.8), c(4.75, 4.75, 4.3, 4.3), col = "#55606B", border = NA)
rect(sx - 0.45, 4.75, sx + 0.25, 5.15, col = "#3E4750", border = NA)
th <- seq(-35, 35, length.out = 9) * pi / 180
hit <- t(sapply(th, function(a) {
  t <- uniroot(function(t) sy - t * cos(a) - fl(sx + t * sin(a)), c(0.1, 6))$root
  c(sx + t * sin(a), sy - t * cos(a))
}))
polygon(c(sx, hit[, 1]), c(sy, hit[, 2]), col = adjustcolor(red, 0.12), border = NA)
arrows(sx, sy, hit[, 1], hit[, 2], length = 0.08, col = red, lwd = 1.6)
xx <- seq(min(hit[, 1]), max(hit[, 1]), length.out = 100)
lines(xx, fl(xx), col = red, lwd = 7)                                     # the strip mapped on this pass
arrows(sx + 0.3, fl(sx + 0.3) + 0.1, sx + 0.3, sy - 0.1, length = 0.12, col = blue, lwd = 2.6)
text(0.3, 5.55, "Sonar", font = 2, cex = 1.3, adj = c(0, 0.5))
lab(5.7, 4.95, "Ship with a sonar", font = 1)
lab(5.7, 3.85, "Sound down", col = red)
lab(5.7, 3.3, "Echo back", col = blue)
lab(5.7, 2.5, "1,500 m per second", font = 1)
text(5, 0.6, "Each pass maps a strip of the floor", font = 2)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f35_footprint DEPS: f26_radar_lidar_how ====
# Why detail falls with distance: a beam spreads at a fixed angle, so the spot it covers grows with distance.
# Left, weather radar seen from above: one beam, its width at two distances. Right, one sonar beam under a ship,
# its spot at two depths. Angles are drawn much wider than they are; the labels carry the true widths, which are
# 2 * d * tan(angle / 2) for the beam widths in _planning/session25_resolution_facts.md.
rad_deg <- 0.925; rad_d <- c(100, 200)                     # radar: NEXRAD beam (NOAA ROC), km
son_deg <- 1;   son_d <- c(100, 4000)                      # sonar: EM 304 across-track beam (NOAA), m
wid <- function(d, deg) 2 * d * tan(deg / 2 * pi / 180)
fig("f35_footprint.png", 11, 4.6, ps = 16)
layout(matrix(1:2, 1)); par(cex = 1)
for (k in 1:2) {
  par(mar = c(0.2, 0.3, 0.2, 0.3))
  plot.new(); plot.window(c(0, 5.5), c(0, 4.6), xaxs = "i", yaxs = "i")
  rect(0.05, 0.05, 5.45, 4.55, border = rule)
  if (k == 1) {                                            # radar, map view: the beam runs left to right
    text(0.25, 4.25, "Weather radar, seen from above", font = 2, cex = 1.15, adj = c(0, 0.5))
    x0 <- 0.45; y0 <- 2.1; a <- 0.17                       # drawn half-angle, in plot units per unit of x
    polygon(c(x0, 5.2, 5.2), c(y0, y0 + a * (5.2 - x0), y0 - a * (5.2 - x0)), col = adjustcolor(red, 0.12), border = red)
    symbols(x0, y0, circles = 0.1, inches = FALSE, add = TRUE, bg = ink, fg = NA)
    xs <- c(2.4, 4.35)                                     # drawn at true proportion, 100 and 200 km
    for (j in 1:2) {
      h <- a * (xs[j] - x0); segments(xs[j], y0 - h, xs[j], y0 + h, col = ink, lwd = 4)
      text(xs[j], y0 - h - 0.3, sprintf("%s km away", format(rad_d[j], big.mark = ",")), cex = 0.95)
      text(xs[j], y0 + h + 0.28, sprintf("%.1f km wide", wid(rad_d[j], rad_deg)), font = 2, cex = 0.95)
    }
    text(x0, y0 - 0.32, "Radar", cex = 0.95)
  } else {                                                 # sonar, side view: the beam runs down from the ship
    text(0.25, 4.25, "Sonar, seen from the side", font = 2, cex = 1.15, adj = c(0, 0.5))
    rect(0.1, 0.1, 5.4, 3.55, col = sea, border = NA); segments(0.1, 3.55, 5.4, 3.55, col = blue, lwd = 1.5)
    sx <- 1.6
    polygon(sx + c(-0.6, 0.6, 0.45, -0.45), c(3.8, 3.8, 3.5, 3.5), col = "#55606B", border = NA)
    a <- 0.2; ys <- c(2.55, 0.55)
    polygon(c(sx, sx + a * (3.5 - 0.3), sx - a * (3.5 - 0.3)), c(3.5, 0.3, 0.3), col = adjustcolor(red, 0.12), border = red)
    for (j in 1:2) {
      h <- a * (3.5 - ys[j]); segments(sx - h, ys[j], sx + h, ys[j], col = brown, lwd = 4)
      lab(2.6, ys[j] + 0.17, sprintf("%s m deep", format(son_d[j], big.mark = ",")), font = 1, cex = 0.95)
      lab(2.6, ys[j] - 0.2, sprintf("spot %s m wide", format(signif(wid(son_d[j], son_deg), 2), big.mark = ",")), cex = 0.95)
    }
  }
}
dev.off()
# ==== END BLOCK ====
