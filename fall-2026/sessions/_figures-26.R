# Figures for the session 26 page and slides (Drone & satellite imagery).
# Base R, terra, sf and rpart. Run from fall-2026/sessions:
#   Rscript _figures-26.R              # every block
#   Rscript _figures-26.R f04_box      # setup, then one block (and its DEPS)
# Writes figures/26-satellite-local/<name>.png. Inputs: data/26-satellite-local/ (the session project), and for f01
# the 2019 aerial photo of the Arts Quad saved by the prep test (_planning/session26_tests/fig/naip_usgs_artsquad.png).
# Drawn at res 200. A figure W inches wide shown at about 100 * W px on the 1050 x 700 slide
# keeps its point sizes; every label is 10.5 pt or more at that width.
# f13_mosaic, f14_mosaic_sizes, f15_road and f30_active_passive are session 25's blocks, moved here with their
# paths pointing at the 26 project folder. The outline's F13, F14 and F15 are f13_forest_loss, f14_lights_two_series
# and f15_lake_patch.

# ---- Run named blocks only: Rscript _figures-26.R <block> [<block> ...] ----
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
suppressPackageStartupMessages({library(terra); library(sf)})
terraOptions(progress = 0, memmax = 2)
out <- "figures/26-satellite-local"; dat <- "data/26-satellite-local"
dir.create(out, showWarnings = FALSE, recursive = TRUE)
ink <- "#222222"; acc <- "#B31B1B"; grey <- "#666666"; light <- "#E4E2DC"; rule <- "#BBBBBB"
blue <- "#3A6C9C"; amber <- "#E6A700"; red <- "#C0392B"; teal <- "#2A9D8F"
land <- "#F1EFEA"; sea <- "#CFE0EC"; nodata <- "#E3E3E3"
brown <- "#8B5A2B"; sky <- "#EAF2F8"; leaf <- "#5E8C4A"
# one colour per thing, the same in every figure
col_water  <- "#2F6DB5"                         # water, the lake
col_forest <- "#1F6B3A"                         # forest (ESA: tree cover)
col_crops  <- "#B7BF2E"                         # grass or crops
col_built  <- "#C0392B"                         # built
col_plants <- "#3E9B44"                         # plants (ESA's class 4)
col_bare   <- "#A0703C"                         # bare ground, roofs and roads (ESA's class 5)
col_other  <- "#E8892B"                         # the other water bodies, against the lake
col_land   <- "#ECEAE4"                         # land on a water map
classes    <- c("water", "forest", "grass or crops", "built")
col_class  <- setNames(c(col_water, col_forest, col_crops, col_built), classes)
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
# the cells of a raster as rectangles (for small grids, with grid lines)
cellrect <- function(r, col, border = "white", lwd = 0.6) {
  xy <- xyFromCell(r, 1:ncell(r)); h <- res(r) / 2
  rect(xy[, 1] - h[1], xy[, 2] - h[2], xy[, 1] + h[1], xy[, 2] + h[2], col = col, border = border, lwd = lwd)
}
# text with a halo, so it reads over a map or a photo
halo <- function(x, y, s, col = ink, bg = "white", r = 0.014, ...) {
  for (a in seq(0, 2 * pi, length.out = 17)[-17]) text(x + xinch(r * cos(a)), y + yinch(r * sin(a)), s, col = bg, ...)
  text(x, y, s, col = col, ...)
}
fmt <- function(x, d = 0) formatC(x, format = "f", digits = d, big.mark = ",")
# a scale bar in map units (metres): a black bar with a white edge, its label above
sbar <- function(x, y, len, label, h = NULL, cex = 1) {
  if (is.null(h)) h <- yinch(0.05)
  rect(x, y, x + len, y + h, col = ink, border = "white", lwd = 1.2)
  halo(x + len / 2, y + h + yinch(0.04), label, adj = c(0.5, 0), font = 2, cex = cex)
}
# a boxed legend of filled squares, round dots or lines, one row each; (x, y) is the corner named by `corner`
boxleg <- function(x, y, lab, fill = NA, border = ink, pch = NA, pcol = ink, pbg = NA, pcex = 1.3, lty = NA, lcol = ink,
                   lwd = 2, title = NULL, cex = 1, gap = 1.45, pad = 0.45, corner = "tl") {
  ch <- strheight("M", cex = cex); cw <- strwidth("M", cex = cex)
  n <- length(lab); rows <- n + !is.null(title)
  w <- max(strwidth(lab, cex = cex) + 2.3 * cw, if (!is.null(title)) strwidth(title, cex = cex, font = 2) else 0) + 2 * pad * cw
  h <- (rows * gap + 2 * pad) * ch
  if (substr(corner, 1, 1) == "b") y <- y + h
  if (substr(corner, 2, 2) == "r") x <- x - w
  rect(x, y - h, x + w, y, col = "white", border = rule)
  yy <- y - pad * ch - (seq_len(rows) - 0.5) * gap * ch
  if (!is.null(title)) { text(x + pad * cw, yy[1], title, adj = c(0, 0.5), font = 2, cex = cex); yy <- yy[-1] }
  xs <- x + pad * cw + 0.6 * cw
  rep_ <- function(v) rep(v, length.out = n)
  fill <- rep_(fill); border <- rep_(border); pch <- rep_(pch); pcol <- rep_(pcol); pbg <- rep_(pbg); lty <- rep_(lty)
  lcol <- rep_(lcol); lwd <- rep_(lwd); pcex <- rep_(pcex)
  for (i in seq_len(n)) {
    if (!is.na(fill[i])) rect(xs - 0.5 * cw, yy[i] - 0.4 * ch, xs + 0.5 * cw, yy[i] + 0.5 * ch, col = fill[i], border = border[i])
    if (!is.na(lty[i])) segments(xs - 0.6 * cw, yy[i], xs + 0.6 * cw, yy[i], lty = lty[i], col = lcol[i], lwd = lwd[i])
    if (!is.na(pch[i])) points(xs, yy[i], pch = pch[i], col = pcol[i], bg = pbg[i], cex = pcex[i])
    text(xs + 1.15 * cw, yy[i], lab[i], adj = c(0, 0.5), cex = cex)
  }
  invisible(c(x, y - h, x + w, y))
}
# panel letter at the left and a centred bold title, above the plot region
ptitle <- function(letter, title, line = 0.4, cex = 1.1) {
  if (!is.null(letter)) mtext(letter, side = 3, line = line, adj = 0, font = 2, cex = 1.35)
  mtext(title, side = 3, line = line, font = 2, cex = cex)
}
# a three-layer raster drawn as an image from fixed lower and upper limits per layer (a linear stretch)
rgbstretch <- function(r, lo, hi, e = as.vector(ext(r)), white = 0) {
  v <- values(r); ok <- stats::complete.cases(v)
  for (j in 1:3) v[, j] <- pmin(pmax((v[, j] - lo[j]) / (hi[j] - lo[j]), 0), 1)
  if (white > 0) v <- white + (1 - white) * v                  # fade toward white, for a background
  col <- rep("transparent", nrow(v)); col[ok] <- rgb(v[ok, 1], v[ok, 2], v[ok, 3])
  rasterImage(as.raster(matrix(col, nrow(r), ncol(r), byrow = TRUE)), e[1], e[3], e[2], e[4], interpolate = FALSE)
}
# longitude and latitude to the image's metres (UTM 18N)
utm <- function(lon, lat) crds(project(vect(cbind(lon, lat), crs = "EPSG:4326"), "EPSG:32618"))
# places named on the maps of the box (longitude, latitude)
places <- data.frame(name = c("Ithaca", "Auburn", "Aurora", "Cayuga Lake", "Owasco Lake"),
                     lon = c(-76.4966, -76.5661, -76.7022, -76.6900, -76.5150),
                     lat = c(42.4430, 42.9317, 42.7537, 42.6300, 42.8250))
pxy <- utm(places$lon, places$lat); rownames(pxy) <- places$name
# ==== END BLOCK ====

# ==== BLOCK: s2_data ====
# Shared by the Sentinel-2 figures: the image of 15 August 2024 (slide 18), reflectance, NDVI (slide 21),
# ESA's map on the image's 20 m cells (slide 30), and one true-colour stretch used by every map of the box.
s2   <- rast(dpath("data/sentinel2/s2_20240815_cayuga_20m.tif"))
refl <- s2[[1:5]] / 10000
ndvi <- (refl$B8A - refl$B04) / (refl$B8A + refl$B04); names(ndvi) <- "NDVI"
wc   <- rast(dpath("data/worldcover/worldcover2021_cayuga.tif")); names(wc) <- "esa"
wc20 <- project(wc, s2, method = "mode")
eb   <- as.vector(ext(s2))                                     # the box, in metres
tc   <- refl[[c("B04", "B03", "B02")]]                          # true colour: red, green, blue
tc_lo <- c(0.01, 0.01, 0.01); tc_hi <- c(0.15, 0.15, 0.15)      # the same limits for the three bands, so grey stays grey
# ==== END BLOCK ====

# ==== BLOCK: water10 DEPS: s2_data ====
# ESA's water on 10 m cells and its water bodies, as on slide 36 (8 directions).
tm  <- rast(ext(s2), resolution = 10, crs = crs(s2))
w10 <- project(wc == 80, tm, method = "near")
p10 <- patches(w10, directions = 8, zeroAsNA = TRUE)
f10 <- freq(p10)
lake_id <- f10$value[which.max(f10$count)]
cat("  water10:", nrow(f10), "water bodies; lake", max(f10$count), "cells,", fmt(max(f10$count) * 100 / 4046.86, 2), "acres\n")
# ==== END BLOCK ====

# ==== BLOCK: sensor_helpers ====
# Drawing helpers of session 25's f26 block (ground, tree, satellite, waves), used by f30_active_passive.
wave <- function(x0, y0, x1, y1, col, amp = 0.07, n = 7, lwd = 2.6) {
  t <- seq(0, 1, length.out = 300); L <- sqrt((x1 - x0)^2 + (y1 - y0)^2)
  ux <- (x1 - x0) / L; uy <- (y1 - y0) / L
  s <- amp * sin(2 * pi * n * t) * pmin(1, (1 - t) * 8)
  lines(x0 + t * (x1 - x0) - s * uy, y0 + t * (y1 - y0) + s * ux, col = col, lwd = lwd)
  arrows(x1 - 0.12 * ux, y1 - 0.12 * uy, x1, y1, length = 0.13, col = col, lwd = lwd)
}
tree <- function(x) {
  rect(x - 0.07, 1.1, x + 0.07, 1.75, col = brown, border = NA)
  symbols(x, 2.15, circles = 0.48, inches = FALSE, add = TRUE, bg = leaf, fg = NA)
}
satellite <- function(x, y) {
  rect(x - 0.5, y - 0.1, x - 0.2, y + 0.1, col = blue, border = ink); rect(x + 0.2, y - 0.1, x + 0.5, y + 0.1, col = blue, border = ink)
  segments(x - 0.2, y, x + 0.2, y, lwd = 2)
  rect(x - 0.16, y - 0.2, x + 0.16, y + 0.2, col = "#8A939C", border = ink)
}
lab <- function(x, y, s, col = ink, font = 2, cex = 1) text(x, y, s, adj = c(0, 0.5), col = col, font = font, cex = cex)
# ==== END BLOCK ====

# ==== BLOCK: f30_active_passive DEPS: sensor_helpers ====
# Passive and active sensors (slide 5), session 25's figure, unchanged.
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

# ==== BLOCK: mosaic_data ====
# Shared by the drone figures: the corn-trial mosaic (4.1 cm pixels), an 8x reduced copy, and a drawing helper.
mo  <- rast(dpath("data/drone/willis_corn_trial.tif"))
mo8 <- aggregate(mo, 8, "mean")                                       # 33 cm pixels, black corners kept
blk8 <- aggregate(sum(mo) == 0, 8, "mean")                            # share of each reduced pixel outside the flight
# a three-layer 0-255 raster drawn as an image; NA cells transparent; interpolate = FALSE keeps cell edges crisp
rgbimg <- function(r, e = as.vector(ext(r))) {
  v <- values(r); ok <- stats::complete.cases(v)
  col <- rep("transparent", nrow(v)); col[ok] <- rgb(pmin(v[ok, 1:3], 255), maxColorValue = 255)
  rasterImage(as.raster(matrix(col, nrow(r), ncol(r), byrow = TRUE)), e[1], e[3], e[2], e[4], interpolate = FALSE)
}
rd   <- st_read(dpath("data_clean/drone/caldwell_roads_near_mosaic.gpkg"), quiet = TRUE)
pen  <- st_union(rd[rd$FULLNAME == "Pennell St NE", ])
off  <- read.csv(dpath("data_clean/drone/tiger_offset.csv"))
sq   <- ext(453170, 453180, 4e6 - 24240, 4e6 - 24230)                 # 10 x 10 m in the standing corn (f13, f01)
# ==== END BLOCK ====

# ==== BLOCK: f13_mosaic DEPS: mosaic_data ====
# The corn trial (slide 11): a. the whole mosaic, labelled; b. a 10 m square at full resolution.
mosq <- crop(mo, sq)
em <- as.vector(ext(mo))
fig("f13_mosaic.png", 11, 5.4, ps = 13)
layout(matrix(1:2, 1), widths = c(5.6, 5.4)); par(cex = 1)
par(mar = c(0.2, 0.3, 1.8, 0.3))
plot.new(); plot.window(em[1:2], em[3:4], asp = 1, xaxs = "i", yaxs = "i")
rgbimg(mo8)
rect(sq$xmin, sq$ymin, sq$xmax, sq$ymax, border = "white", lwd = 4.5); rect(sq$xmin, sq$ymin, sq$xmax, sq$ymax, border = acc, lwd = 2.2)
halo(sq$xmax + 4, sq$ymax + 3, "b", adj = c(0, 0), font = 2, cex = 1.1)
ang <- atan2(3975880 - 3975835, 453210 - 453126) * 180 / pi
halo(453150, 3975862, "Pennell St NE", srt = ang, font = 2)
halo(453178, 3975722, "Standing corn", font = 2)
halo(453245, 3975810, "Harvested", font = 2)
text(453024, 3975880, "Black corners:\noutside the flight", col = "white", font = 2, adj = c(0, 0.5))
# 50 m scale bar
rect(em[2] - 62, em[3] + 8, em[2] - 12, em[3] + 10.5, col = "white", border = NA)
text(em[2] - 37, em[3] + 14, "50 m", col = "white", font = 2, adj = c(0.5, 0))
mtext("a", side = 3, line = 0.3, adj = 0, font = 2, cex = 1.35)
mtext(sprintf("The whole mosaic, %.0f × %.0f m", em[2] - em[1], em[4] - em[3]), side = 3, line = 0.3, font = 2, cex = 1.1)
par(mar = c(0.2, 0.6, 1.8, 0.3))
plot.new(); plot.window(c(sq$xmin, sq$xmax), c(sq$ymin, sq$ymax), asp = 1, xaxs = "i", yaxs = "i")
rgbimg(mosq)
rect(sq$xmin, sq$ymin, sq$xmax, sq$ymax, border = acc, lwd = 2.2)
rect(sq$xmax - 3.3, sq$ymin + 0.35, sq$xmax - 0.3, sq$ymin + 0.5, col = "white", border = NA)
halo(sq$xmax - 1.8, sq$ymin + 0.65, "3 m", adj = c(0.5, 0), font = 2, col = ink)
mtext("b", side = 3, line = 0.3, adj = 0, font = 2, cex = 1.35)
mtext(sprintf("10 × 10 m at full resolution, %.1f cm pixels", 100 * res(mo)[1]), side = 3, line = 0.3, font = 2, cex = 1.1)
dev.off()
cat("  f13: mosaic", nrow(mo), "x", ncol(mo), "; pixel", round(100 * res(mo), 3), "cm; extent", round(em, 1),
    "; area ha", round((em[2] - em[1]) * (em[4] - em[3]) / 1e4, 2), "; square pixels", ncol(mosq), "x", nrow(mosq), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f14_mosaic_sizes DEPS: mosaic_data ====
# The field in 4 cm, 10 m and 30 m cells (slide 13), on one extent. The 10 m and 30 m grids are built
# as on the slide (black pixels to NA, then the mean of the rest); their cells are drawn with crisp edges.
# The masked mosaic is not shipped in the 26 folder, so it is made here from the raw file, as slide 12 does.
mom <- mask(mo, sum(mo) == 0, maskvalues = TRUE)
m10 <- aggregate(mom, fact = 243, fun = "mean", na.rm = TRUE)
m30 <- aggregate(mom, fact = 730, fun = "mean", na.rm = TRUE)
n10 <- global(!is.na(m10[[1]]), "sum")[[1]]; n30 <- global(!is.na(m30[[1]]), "sum")[[1]]
m4  <- mo8; m4[blk8 > 0.5] <- NA                                     # the 4 cm panel, drawn from 33 cm pixels
e30 <- as.vector(ext(m30))
g <- list(m4, m10, m30)
nm <- c("4 cm", sprintf("%.0f m: %d cells", res(m10)[1], n10), sprintf("%.0f m: %d cells", res(m30)[1], n30))
fig("f14_mosaic_sizes.png", 12, 4.4, ps = 13)
layout(matrix(1:3, 1)); par(cex = 1)
for (k in 1:3) {
  par(mar = c(0.3, 0.4, 2.0, 0.4))
  plot.new(); plot.window(e30[1:2], e30[3:4], asp = 1, xaxs = "i", yaxs = "i")
  rgbimg(g[[k]])
  rect(e30[1], e30[3], e30[2], e30[4], border = rule)
  mtext(letters[k], side = 3, line = 0.4, adj = 0, font = 2, cex = 1.35)
  mtext(nm[k], side = 3, line = 0.4, font = 2, cex = 1.1)
}
dev.off()
cat("  f14: cells with data", n10, n30, "; cell sizes", round(res(m10)[1], 3), round(res(m30)[1], 3), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f15_road DEPS: mosaic_data ====
# The Census line for Pennell St NE against the road in the image (slide 14): a 40 x 30 m window at the 50% point.
p5 <- off[off$point == 0.5, ]
w  <- ext(p5$x - 20, p5$x + 20, p5$y - 15, p5$y + 15)
mw <- crop(mo, w)
# the direction of the line at the 50% point, as session 25's tools/make_terrain.R measured it
ln <- st_cast(st_intersection(pen, st_as_sfc(st_bbox(ext(mo) - 10, crs = st_crs(rd)))), "LINESTRING")[1]
q0 <- st_coordinates(st_line_sample(ln, sample = 0.5))[1, 1:2]
q1 <- st_coordinates(st_line_sample(ln, sample = 0.51))[1, 1:2]
tv <- (q1 - q0) / sqrt(sum((q1 - q0)^2)); nv <- c(-tv[2], tv[1])     # unit normal, to the left (NW) of the line
cl <- rbind(q0 - 40 * tv, q0 + 40 * tv) + rep(1, 2) %o% (p5$offset_to_centre_m * nv)   # the measured centre line
fig("f15_road.png", 6.6, 5.2, ps = 15)
par(mar = c(0.2, 0.2, 0.2, 0.2))
plot.new(); plot.window(c(w$xmin, w$xmax), c(w$ymin, w$ymax), asp = 1, xaxs = "i", yaxs = "i")
rgbimg(mw)
op <- par(xpd = FALSE)
plot(st_geometry(pen), add = TRUE, col = "white", lwd = 6); plot(st_geometry(pen), add = TRUE, col = red, lwd = 3.2)
lines(cl, col = "white", lwd = 3, lty = 2)
par(op)
a1 <- q0 + 0.25 * nv; a2 <- q0 + (p5$offset_to_centre_m - 0.25) * nv
arrows(a1[1], a1[2], a2[1], a2[2], code = 3, length = 0.09, angle = 25, lwd = 4.5, col = "white")
arrows(a1[1], a1[2], a2[1], a2[2], code = 3, length = 0.09, angle = 25, lwd = 2.2, col = ink)
am <- q0 + 0.5 * p5$offset_to_centre_m * nv + 1.2 * tv
halo(am[1], am[2], paste0(sprintf("%.1f", p5$offset_to_centre_m), " m"), adj = c(0, 0.5), font = 2, cex = 1.2)
ang <- atan2(tv[2], tv[1]) * 180 / pi
t1 <- q0 + 11 * tv - 1.6 * nv; t2 <- q0 - 9 * tv + (p5$offset_to_centre_m + 1.6) * nv
halo(t1[1], t1[2], "Census (TIGER) line", srt = ang, font = 2, col = red, adj = c(0.5, 1))
halo(t2[1], t2[2], "Road centre in the image", srt = ang, font = 2, adj = c(0.5, 0))
rect(w$xmax - 7, w$ymin + 1.2, w$xmax - 2, w$ymin + 1.6, col = "white", border = NA)
halo(w$xmax - 4.5, w$ymin + 2.0, "5 m", font = 2, adj = c(0.5, 0))
rect(w$xmin, w$ymin, w$xmax, w$ymax, border = rule)
dev.off()
cat("  f15: offsets", off$offset_to_centre_m, "; widths", off$width_m, "; window centre", p5$x, p5$y, "\n")
# ==== END BLOCK ====

# ==== BLOCK: f01_platforms DEPS: mosaic_data,s2_data ====
# Cameras on a drone, a plane and a satellite (slide 6), three panels at the same printed size:
# a. 10 m of the corn trial at 4.1 cm; b. 200 m around the Arts Quad on the 2019 aerial photo (0.6 m);
# c. the same 200 m in our image of 15 August 2024 (20 m cells, cut to the photo's square, so edge cells are partial).
suppressPackageStartupMessages(library(png))
naip <- readPNG("../../_planning/session26_tests/fig/naip_usgs_artsquad.png")
aq   <- utm(-76.4855, 42.4489)[1, ]                                    # the Arts Quad point of the prep test
sqa  <- c(aq[1] - 100, aq[2] - 100, aq[1] + 100, aq[2] + 100)          # the photo's 200 m square, UTM 18N
s2c  <- crop(tc, ext(sqa[1], sqa[3], sqa[2], sqa[4]), snap = "out")
fig("f01_platforms.png", 8.4, 3.45, ps = 12)
layout(matrix(1:3, 1)); par(cex = 1)
ttl <- c("4.1 cm pixels from a drone", "0.6 m pixels from a plane", "20 m pixels from a satellite")
gnd <- c("A corn trial, 10 m across", "Arts Quad, NAIP 2019, 200 m", "Arts Quad, Sentinel-2 2024, 200 m")
for (k in 1:3) {
  par(mar = c(1.7, 0.5, 1.9, 0.5))
  if (k == 1) {
    plot.new(); plot.window(c(sq$xmin, sq$xmax), c(sq$ymin, sq$ymax), asp = 1, xaxs = "i", yaxs = "i")
    rgbimg(crop(mo, sq)); u <- par("usr")
    sbar(u[1] + 0.06 * 10, u[3] + 0.06 * 10, 2, "2 m")
  } else {
    plot.new(); plot.window(sqa[c(1, 3)], sqa[c(2, 4)], asp = 1, xaxs = "i", yaxs = "i"); u <- par("usr")
    op <- par(xpd = FALSE)
    if (k == 2) rasterImage(naip, sqa[1], sqa[2], sqa[3], sqa[4], interpolate = FALSE)
    else {
      rgbstretch(s2c, tc_lo, tc_hi)
      ec <- as.vector(ext(s2c)); abline(v = seq(ec[1], ec[2], 20), h = seq(ec[3], ec[4], 20), col = adjustcolor("white", 0.35), lwd = 0.6)
    }
    par(op)
    sbar(sqa[1] + 12, sqa[2] + 12, 50, "50 m")
  }
  rect(u[1], u[3], u[2], u[4], border = rule)
  ptitle(letters[k], ttl[k], cex = 1.0)
  mtext(gnd[k], side = 1, line = 0.55, cex = 1)
}
dev.off()
cat("  f01: drone square", ncol(crop(mo, sq)), "px; photo", dim(naip)[1:2], "px; satellite cells cut", ncol(s2c), "x", nrow(s2c), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f02_cloudy_radar DEPS: s2_data ====
# Cayuga Lake on a cloudy day (slide 7): a. the camera's true colour of 30 August 2024, almost all cloud;
# b. radar of 1 September 2024 (VV, dB), the lakes dark. Also f02_camera_only.png, the camera half alone (slide 4).
tci <- rast(dpath("data/sentinel2/s2_tci_20240830_cayuga.tif"))
tci3 <- aggregate(tci, 3, "mean")                                       # 30 m, enough for the printed size
vv  <- rast(dpath("data/sentinel1/s1_vv_db_20240901_cayuga_20m.tif")) / 10   # stored as dB x 10
vv2 <- aggregate(vv, 2, "mean")
scl30 <- NULL
camera_panel <- function(letter) {
  plot.new(); plot.window(eb[1:2], eb[3:4], asp = 1, xaxs = "i", yaxs = "i"); u <- par("usr")
  rect(eb[1], eb[3], eb[2], eb[4], col = "white", border = NA)
  v <- values(tci3); ok <- stats::complete.cases(v)
  col <- rep("transparent", nrow(v)); col[ok] <- rgb(pmin(v[ok, ], 255), maxColorValue = 255)
  rasterImage(as.raster(matrix(col, nrow(tci3), ncol(tci3), byrow = TRUE)), eb[1], eb[3], eb[2], eb[4], interpolate = FALSE)
  rect(eb[1], eb[3], eb[2], eb[4], border = "#8C8C8C", lwd = 2.2)
  halo(mean(eb[1:2]), mean(eb[3:4]) + 4000, "Cloud", font = 2, cex = 1.5, col = ink)
  ptitle(letter, "Camera, 30 August 2024")
}
fig("f02_cloudy_radar.png", 5.8, 5.4, ps = 12)
layout(matrix(1:2, 1)); par(cex = 1)
par(mar = c(0.3, 0.5, 1.9, 0.5))
camera_panel("a")
plot.new(); plot.window(eb[1:2], eb[3:4], asp = 1, xaxs = "i", yaxs = "i")
rimg(vv2, grey.colors(60, start = 0, end = 1), c(-Inf, seq(-25, 0, length.out = 59), Inf))
rect(eb[1], eb[3], eb[2], eb[4], border = rule)
halo(pxy["Cayuga Lake", 1] - 300, pxy["Cayuga Lake", 2], "Cayuga\nLake", font = 2, cex = 1.0)
halo(pxy["Owasco Lake", 1] - 1500, pxy["Owasco Lake", 2], "Owasco\nLake", font = 2, cex = 1.0, adj = c(1, 0.5))
for (p in c("Ithaca", "Auburn")) {
  points(pxy[p, 1], pxy[p, 2], pch = 21, bg = red, col = "white", cex = 1.5, lwd = 1.4)
}
halo(pxy["Ithaca", 1] - 900, pxy["Ithaca", 2] + 1300, "Ithaca", adj = c(1, 0.5), font = 2)
halo(pxy["Auburn", 1] - 900, pxy["Auburn", 2] - 1000, "Auburn", adj = c(1, 0.5), font = 2)
sbar(eb[1] + 1500, eb[3] + 1500, 10000, "10 km")
ptitle("b", "Radar, 1 September 2024")
dev.off()
fig("f02_camera_only.png", 2.6, 5.3, ps = 12)
par(mar = c(0.3, 0.5, 1.9, 0.5))
camera_panel(NULL)
dev.off()
cat("  f02: camera cells", ncol(tci), "x", nrow(tci), "; radar dB range", round(unlist(global(vv, range, na.rm = TRUE)), 1), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f03_bands ====
# What a band records (slide 8): a wavelength axis from 400 to 1,700 nm, the visible range in its colours,
# the drone camera's three bands above the axis and Sentinel-2's five bands of our file below it.
# Sentinel-2 centres and widths (nm) are Sentinel-2A's, from ESA's band table.
s2b <- data.frame(band = c("B02", "B03", "B04", "B8A", "B11"), name = c("blue", "green", "red", "near-infrared", "shortwave infrared"),
                  c = c(490, 560, 665, 865, 1610), w = c(66, 36, 31, 21, 91))
fig("f03_bands.png", 9.6, 3.7, ps = 13)
par(mar = c(3.0, 0.6, 0.3, 0.6))
plot.new(); plot.window(c(380, 1720), c(-3.6, 1.35), xaxs = "i", yaxs = "i")
# the visible range, shaded in its colours
wl <- seq(400, 700, 2)
hue <- approx(c(400, 440, 490, 510, 580, 645, 700), c(0.75, 0.66, 0.5, 0.33, 0.16, 0, 0), wl)$y
rect(wl - 1, -0.25, wl + 1, 0.25, col = hsv(hue, 0.85, 0.95), border = NA)
rect(700, -0.25, 1700, 0.25, col = "#E9E6E0", border = NA)
rect(400, -0.25, 1700, 0.25, border = rule)
axis(1, at = seq(400, 1700, 100), labels = c(fmt(seq(400, 1700, 100))), pos = -3.6, col = rule, col.ticks = ink, mgp = c(2, 0.6, 0))
mtext("Wavelength, nm (billionths of a metre)", side = 1, line = 1.9)
text(550, 0, "What our eyes see", font = 2, cex = 0.95)
text(1000, 0, "Near-infrared", font = 2, cex = 0.95)
text(1450, 0, "Shortwave infrared", font = 2, cex = 0.95)
# the drone camera above
dr <- data.frame(lo = c(400, 500, 600), hi = c(500, 600, 700), col = c("#3B6FD8", "#3BA74A", "#D8433B"), name = c("blue", "green", "red"))
rect(dr$lo + 4, 0.55, dr$hi - 4, 1.25, col = adjustcolor(dr$col, 0.85), border = NA)
text((dr$lo + dr$hi) / 2, 0.9, dr$name, col = "white", font = 2, cex = 0.95)
text(720, 0.9, "Drone camera: three bands", adj = c(0, 0.5), font = 2)
# Sentinel-2 below
bc <- c("#3B6FD8", "#3BA74A", "#D8433B", "#7A2E2E", "#5A5A5A")
rect(s2b$c - s2b$w / 2, -1.25, s2b$c + s2b$w / 2, -0.55, col = bc, border = NA)
segments(s2b$c, -1.3, s2b$c, -1.55, col = ink)
lx <- c(470, 575, 680, 865, 1590); ly <- c(-1.65, -2.75, -1.65, -1.65, -1.65)
text(lx, ly, paste0(s2b$band, " ", s2b$name, "\n", fmt(s2b$c), " nm"), cex = 0.95, adj = c(0.5, 1))
segments(560, -1.55, 575, -2.7, col = ink)
text(1150, -0.9, "Sentinel-2: our file's five bands", font = 2)
dev.off()
cat("  f03: Sentinel-2 centres", s2b$c, "\n")
# ==== END BLOCK ====

# ==== BLOCK: f04_box DEPS: s2_data ====
# The image of 15 August 2024 (slide 17): the whole box in true colour, places named, 10 km scale bar.
tc2 <- aggregate(tc, 2, "mean", na.rm = TRUE)
fig("f04_box.png", 2.8, 5.4, ps = 12)
par(mar = c(0.2, 0.2, 0.2, 0.2))
plot.new(); plot.window(eb[1:2], eb[3:4], asp = 1, xaxs = "i", yaxs = "i")
rgbstretch(tc2, tc_lo, tc_hi)
rect(eb[1], eb[3], eb[2], eb[4], border = rule)
halo(pxy["Cayuga Lake", 1] - 300, pxy["Cayuga Lake", 2], "Cayuga\nLake", font = 2)
halo(pxy["Owasco Lake", 1] - 1500, pxy["Owasco Lake", 2], "Owasco\nLake", font = 2, adj = c(1, 0.5))
for (p in c("Ithaca", "Auburn")) points(pxy[p, 1], pxy[p, 2], pch = 21, bg = red, col = "white", cex = 1.5, lwd = 1.4)
halo(pxy["Ithaca", 1] - 900, pxy["Ithaca", 2] + 1300, "Ithaca", adj = c(1, 0.5), font = 2)
halo(pxy["Auburn", 1] - 900, pxy["Auburn", 2] - 1000, "Auburn", adj = c(1, 0.5), font = 2)
sbar(eb[1] + 1500, eb[3] + 1500, 10000, "10 km")
dev.off()
cat("  f04: box", ncol(s2), "x", nrow(s2), "cells;", (eb[2] - eb[1]) / 1000, "x", (eb[4] - eb[3]) / 1000, "km; stretch", round(tc_lo, 3), "to", round(tc_hi, 3), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f05_reflectance DEPS: s2_data ====
# Reflectance of plants, bare ground and water (slide 19): the median of each band within ESA's classes 4, 5 and 6,
# computed as on the slide, one line per class over the five band centres.
m  <- zonal(refl, s2$SCL, fun = "median", na.rm = TRUE)
m  <- m[m$SCL >= 4 & m$SCL <= 6, ]
wl <- 1:5                                                       # the five bands, equally spaced
cc <- c(col_plants, col_bare, col_water)
fig("f05_reflectance.png", 4.4, 3.6, ps = 12)
par(mar = c(4.4, 4.0, 0.6, 0.6), las = 1, mgp = c(2.6, 0.6, 0), tcl = -0.3)
plot.new(); plot.window(c(0.6, 5.4), c(0, 0.45), xaxs = "i", yaxs = "i")
abline(h = seq(0.1, 0.4, 0.1), col = "#EEEEEE")
axis(2, at = seq(0, 0.4, 0.1), labels = sprintf("%.1f", seq(0, 0.4, 0.1)), col = rule, col.ticks = rule)
axis(1, at = wl, labels = FALSE, col = rule, col.ticks = rule)
mtext(c("B02\nblue", "B03\ngreen", "B04\nred", "B8A\nnear-\ninfrared", "B11\nshortwave\ninfrared"), side = 1, at = wl,
      line = 0.45, padj = 1, cex = 0.95)
box(col = rule, bty = "l")
mtext("Reflectance (median)", side = 2, line = 2.8, las = 0)
for (k in 1:3) {
  y <- unlist(m[k, 2:6])
  lines(wl, y, col = cc[k], lwd = 3); points(wl, y, pch = 21, bg = cc[k], col = "white", cex = 1.4, lwd = 1.2)
}
text(3.9, m$B8A[1] + 0.012, "plants (class 4)", adj = c(1, 0), col = col_plants, font = 2)
text(2.95, m$B04[2] + 0.05, "bare ground, roofs\nand roads (class 5)", adj = c(1, 0), col = col_bare, font = 2)
text(4.5, 0.06, "water (class 6)", adj = c(0.5, 0), col = col_water, font = 2)
dev.off()
print(m, digits = 3)
# ==== END BLOCK ====

# ==== BLOCK: f06_ndvi_forest_crops DEPS: s2_data ====
# NDVI of cropland and forest on 15 August (slide 30): the share of cells in each NDVI bin, for the 20 m cells that
# ESA's map calls tree cover (10) and cropland (40), with each type's median.
z  <- zonal(ndvi, wc20, fun = "median", na.rm = TRUE)
vv <- c(ndvi, wc20); vv <- as.data.frame(vv, na.rm = TRUE)
br <- seq(-0.2, 1, 0.02)
h  <- lapply(c(10, 40), function(k) { x <- vv$NDVI[vv$esa == k]; 100 * hist(pmax(x, -0.2), br, plot = FALSE)$counts / length(x) })
n  <- sapply(c(10, 40), function(k) sum(vv$esa == k))
md <- z$NDVI[match(c(10, 40), z$esa)]
cc <- c(col_forest, col_crops)
fig("f06_ndvi_forest_crops.png", 5.2, 3.6, ps = 12)
par(mar = c(3.3, 4.0, 0.6, 0.6), las = 1, mgp = c(2.1, 0.6, 0), tcl = -0.3)
plot.new(); plot.window(c(0, 1), c(0, max(unlist(h)) * 1.08), xaxs = "i", yaxs = "i")
axis(1, at = seq(0, 1, 0.2), labels = sprintf("%.1f", seq(0, 1, 0.2)), col = rule, col.ticks = rule)
axis(2, col = rule, col.ticks = rule)
box(col = rule, bty = "l")
mtext("NDVI on 15 August 2024", side = 1, line = 2.1)
mtext("Share of the type's cells, %", side = 2, line = 2.7, las = 0)
op <- par(xpd = FALSE)
for (k in 2:1) {
  lines(c(br, max(br)), c(0, h[[k]], 0), col = cc[k], lwd = 3, type = "s")
}
par(op)
u <- par("usr")
boxleg(0.03, u[4] * 0.96, c(sprintf("Forest (ESA: tree cover), median %.2f", md[1]), sprintf("Cropland, median %.2f", md[2])),
       lty = 1, lcol = cc, lwd = 3, corner = "tl")
dev.off()
cat("  f06: cells", n, "; medians", round(md, 4), "; all seven", paste(z$esa, round(z$NDVI, 2)), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f07_lights_scatter ====
# Lights and population in New York's counties (slide 27): the 2023 VIIRS lights summed over each county
# (data_clean/lights/ny_county_lights.csv, made by tools/make_counties.R with the slide's extract()) against 2023 people.
d  <- read.csv(dpath("data_clean/lights/ny_county_lights.csv"))
r  <- cor(log(d$lights_viirs2023), log(d$pop2023))
nm <- c("Suffolk", "Kings", "Tompkins", "Hamilton")
fig("f07_lights_scatter.png", 5.2, 3.7, ps = 12)
par(mar = c(3.3, 4.8, 0.6, 0.8), las = 1, mgp = c(2.1, 0.6, 0), tcl = -0.3)
plot(d$pop2023, d$lights_viirs2023, log = "xy", type = "n", axes = FALSE, xlab = "", ylab = "",
     xlim = c(4000, 4e6), ylim = c(3000, 2e5))
xt <- c(1e4, 1e5, 1e6); yt <- c(5e3, 2e4, 5e4, 1e5)
axis(1, at = xt, labels = c("10,000", "100,000", "1 million"), col = rule, col.ticks = rule)
axis(2, at = yt, labels = fmt(yt), col = rule, col.ticks = rule)
box(col = rule, bty = "l")
mtext("People in the county, 2023 (log scale)", side = 1, line = 2.1)
mtext("Light summed over the county (log scale)", side = 2, line = 3.8, las = 0)
points(d$pop2023, d$lights_viirs2023, pch = 21, bg = blue, col = "white", cex = 1.35, lwd = 1)
k <- match(nm, d$name)
points(d$pop2023[k], d$lights_viirs2023[k], pch = 21, bg = acc, col = "white", cex = 1.5, lwd = 1)
adj <- list(c(1.15, 0.5), c(1.15, 0.5), c(-0.15, 0.5), c(-0.15, 0.5))
for (i in seq_along(k)) text(d$pop2023[k[i]], d$lights_viirs2023[k[i]], nm[i], adj = adj[[i]], font = 2)
u <- par("usr")
text(10^(u[2] - 0.02 * (u[2] - u[1])), 10^(u[3] + 0.05 * (u[4] - u[3])), sprintf("62 counties\nCorrelation of the logs: %.2f", r),
     adj = c(1, 0), font = 2)
dev.off()
cat("  f07: correlation", r, "; Hamilton", d$pop2023[d$name == "Hamilton"], "people\n")
# ==== END BLOCK ====

# ==== BLOCK: f08_resolution DEPS: mosaic_data ====
# Types of resolution (slide 34), three small panels of our own data:
# a. spatial: 60 m of the corn trial at 4.1 cm, and the same ground averaged into 20 m cells;
# b. temporal: Sentinel-2's passes over our image in August 2024, the clear ones in blue;
# c. spectral: the drone's 3 bands against Sentinel-2's 13 (centres from ESA's band table, Sentinel-2A).
sq60 <- ext(453140, 453200, 3975730, 3975790)                          # 60 m of standing corn, inside the flight
c60  <- crop(mo, sq60)
t20  <- rast(sq60, resolution = 20, crs = crs(mo))
c20  <- resample(c60, t20, method = "average")
bx   <- read.csv(dpath("data_clean/catalog/s2_box_clear_2024.csv"))
bx$date <- as.Date(bx$date)
bx$clear <- bx$share_box_covered >= 0.9 & bx$share_clear > 0.9       # as tools/make_s2_season_2024.R counts it
au   <- bx[format(bx$date, "%Y-%m") == "2024-08", ]
s2all <- data.frame(band = c("B01", "B02", "B03", "B04", "B05", "B06", "B07", "B08", "B8A", "B09", "B10", "B11", "B12"),
                    c = c(443, 490, 560, 665, 705, 740, 783, 842, 865, 945, 1375, 1610, 2190))
fig("f08_resolution.png", 9.8, 3.0, ps = 12)
layout(matrix(1:3, 1), widths = c(3.2, 3.3, 3.3)); par(cex = 1)
# a. spatial
par(mar = c(1.6, 0.4, 1.9, 0.4))
plot.new(); plot.window(c(0, 130), c(0, 60), asp = 1, xaxs = "i", yaxs = "i")
rgbimg(c60, c(0, 60, 0, 60)); rect(0, 0, 60, 60, border = rule)
rgbimg(c20, c(70, 130, 0, 60)); cellrect(shift(c20, 70 - sq60$xmin, -sq60$ymin), NA, border = "white", lwd = 1)
text(30, -1.5, "4.1 cm pixels", adj = c(0.5, 1), font = 2)
text(100, -1.5, "20 m cells", adj = c(0.5, 1), font = 2)
ptitle("a", "Pixel size", cex = 1.0)
# b. temporal
par(mar = c(1.6, 0.6, 1.9, 0.6))
plot.new(); plot.window(as.numeric(as.Date(c("2024-07-31", "2024-09-01"))), c(0, 3), xaxs = "i", yaxs = "i")
segments(as.numeric(as.Date("2024-08-01")), 1, as.numeric(as.Date("2024-08-31")), 1, col = ink, lwd = 1.5)
dd <- as.numeric(au$date)
segments(dd, 1, dd, 1.75, col = ifelse(au$clear, col_water, "#9A9A9A"), lwd = ifelse(au$clear, 4.5, 2.5))
tk <- as.Date(c("2024-08-01", "2024-08-10", "2024-08-20", "2024-08-31"))
segments(as.numeric(tk), 1, as.numeric(tk), 0.85, col = ink)
text(as.numeric(tk), 0.7, paste(as.integer(format(tk, "%d")), "Aug"), adj = c(0.5, 1), cex = 0.95)
k <- which(au$clear)
text(dd[k], 1.9, paste(as.integer(format(au$date[k], "%d")), "Aug"), adj = c(0.5, 0), col = col_water, font = 2)
text(mean(dd), 2.6, sprintf("%d passes in August, %d clear", nrow(au), length(k)), font = 2)
ptitle("b", "Time between images", cex = 1.0)
# c. spectral
plot.new(); plot.window(c(380, 2300), c(0, 3), xaxs = "i", yaxs = "i")
rect(400, 1.35, 2250, 1.55, col = "#E9E6E0", border = rule)
wl <- seq(400, 700, 2); hue <- approx(c(400, 440, 490, 510, 580, 645, 700), c(0.75, 0.66, 0.5, 0.33, 0.16, 0, 0), wl)$y
rect(wl - 1, 1.35, wl + 1, 1.55, col = hsv(hue, 0.85, 0.95), border = NA)
rect(c(400, 500, 600) + 6, 1.75, c(500, 600, 700) - 6, 2.15, col = c("#3B6FD8", "#3BA74A", "#D8433B"), border = NA)
text(760, 1.95, "3 bands on the drone", adj = c(0, 0.5), font = 2)
segments(s2all$c, 0.95, s2all$c, 1.25, col = ink, lwd = 2.2)
text(1300, 0.65, "13 bands on Sentinel-2", font = 2)
axis(1, at = c(500, 1000, 1500, 2000), labels = c("500", "1,000", "1,500", "2,000 nm"), pos = 0.35, col = rule, col.ticks = ink,
     mgp = c(2, 0.4, 0), cex.axis = 0.95)
ptitle("c", "Bands", cex = 1.0)
dev.off()
cat("  f08: August passes", nrow(au), "; clear", format(au$date[au$clear]), "; 20 m cells", ncol(c20), "x", nrow(c20), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f09_size_vs_revisit ====
# Small pixels come less often (page only): pixel size against days between images, one dot per source of slide 35,
# with PlanetScope. Values as the outline's table gives them (midpoints where it gives a range); the drone flew once.
src <- data.frame(name = c("Aerial photos (NAIP)", "PlanetScope", "Sentinel-2", "Landsat", "MODIS", "VIIRS lights"),
                  px = c(0.6, 3, 10, 30, 250, 500), days = c(3 * 365, 2, 5, 8, 1.5, 1),
                  pos = c(4, 4, 4, 4, 2, 2))
fig("f09_size_vs_revisit.png", 7.0, 4.6, ps = 12)
par(mar = c(3.4, 5.2, 0.6, 1.0), las = 1, mgp = c(2.2, 0.6, 0), tcl = -0.3)
plot(src$px, src$days, log = "xy", type = "n", axes = FALSE, xlab = "", ylab = "", xlim = c(0.02, 2000), ylim = c(0.7, 6000))
xt <- c(0.04, 0.1, 1, 10, 100, 1000); xl <- c("4 cm", "10 cm", "1 m", "10 m", "100 m", "1 km")
axis(1, at = xt, labels = xl, col = rule, col.ticks = rule)
yt <- c(1, 7, 30, 365, 3 * 365); yl <- c("1 day", "1 week", "1 month", "1 year", "3 years")
axis(2, at = c(yt, 4000), labels = c(yl, "once"), col = rule, col.ticks = rule)
abline(h = 2300, col = rule, lty = 3)
box(col = rule, bty = "l")
mtext("Pixel size (log scale)", side = 1, line = 2.2)
mtext("Time between images (log scale)", side = 2, line = 4.2, las = 0)
points(src$px, src$days, pch = 21, bg = blue, col = "white", cex = 1.8, lwd = 1.2)
text(src$px, src$days, src$name, pos = src$pos, font = 2, offset = 0.7)
points(0.041, 4000, pch = 21, bg = acc, col = "white", cex = 1.8, lwd = 1.2)
text(0.041, 4000, "Drone (our corn trial)", pos = 4, font = 2, offset = 0.7)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f10_water_patches DEPS: water10 ====
# Separate water bodies at 10 m (slide 36): a 1 km square of ponds west of Cayuga Lake, each water body in its own
# colour, with where the square sits in our image and a 3 x 3 sketch of one cell's 8 neighbours.
win <- ext(355550, 356550, 4745750, 4746750)                           # a cluster of small ponds, picked by eye
pw  <- crop(p10, win)
ids <- sort(unique(values(pw, na.rm = TRUE)[, 1]))
set.seed(3); palp <- sample(hcl.colors(max(12, length(ids)), "Dark 3"))[seq_along(ids)]
ll  <- crds(project(vect(rbind(c(mean(c(win$xmin, win$xmax)), mean(c(win$ymin, win$ymax)))), crs = crs(s2)), "EPSG:4326"))
fig("f10_water_patches.png", 5.6, 4.1, ps = 14)
layout(rbind(c(1, 3), c(1, 4), c(2, 4)), widths = c(3.55, 2.05), heights = c(2.3, 1.15, 0.65)); par(cex = 1)
par(mar = c(0.3, 0.3, 0.3, 0.3))
plot.new(); plot.window(c(win$xmin, win$xmax), c(win$ymin, win$ymax), asp = 1, xaxs = "i", yaxs = "i")
rect(win$xmin, win$ymin, win$xmax, win$ymax, col = col_land, border = NA)
v <- values(pw, mat = FALSE); colv <- ifelse(is.na(v), "transparent", palp[match(v, ids)])
rasterImage(as.raster(matrix(colv, nrow(pw), ncol(pw), byrow = TRUE)), win$xmin, win$ymin, win$xmax, win$ymax, interpolate = FALSE)
rect(win$xmin, win$ymin, win$xmax, win$ymax, border = rule)
sbar(win$xmin + 40, win$ymin + 40, 200, "200 m")
par(mar = c(0, 0.3, 0, 0.3))
plot.new(); plot.window(c(0, 1), c(0, 1), xaxs = "i", yaxs = "i")
boxleg(0, 0.95, c("One colour per water body", "Land (no water on ESA's map)"), fill = c(palp[1], col_land), border = c(NA, rule),
       corner = "tl", cex = 0.95, gap = 1.3)
# where the square sits
par(mar = c(0.3, 0.6, 1.5, 0.3))
plot.new(); plot.window(eb[1:2], eb[3:4], asp = 1, xaxs = "i", yaxs = "i")
rect(eb[1], eb[3], eb[2], eb[4], col = col_land, border = rule)
lk <- aggregate(w10, 10, "max", na.rm = TRUE)
rimg(lk, c("transparent", col_water), c(-0.5, 0.5, 1.5))
rect(win$xmin - 1200, win$ymin - 1200, win$xmax + 1200, win$ymax + 1200, border = acc, lwd = 2.2)
mtext("Where the square is", side = 3, line = 0.2, font = 2, cex = 0.95)
# 8 neighbours
par(mar = c(1.2, 0.6, 1.5, 0.3))
plot.new(); plot.window(c(0, 3), c(-0.6, 3), asp = 1, xaxs = "i", yaxs = "i")
for (i in 0:2) for (j in 0:2) rect(i, j, i + 1, j + 1, col = if (i == 1 && j == 1) col_water else adjustcolor(col_water, 0.3), border = "white", lwd = 2)
text(1.5, 1.5, "cell", col = "white", font = 2, cex = 0.95)
text(1.5, -0.3, "8 neighbours", font = 2, cex = 0.95)
mtext("8 directions", side = 3, line = 0.2, font = 2, cex = 0.95)
dev.off()
cat("  f10: window centre lon/lat", round(ll, 4), "; water bodies in the square", length(ids), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f11_clear_by_month ====
# Clear images of the lake in 2024 (slide 38): Sentinel-2's passes over our image each month, from
# data_clean/catalog/s2_box_clear_2024.csv. A pass is clear when it covers at least 90% of the image and more than
# 90% of the covered cells are clear (tools/make_s2_season_2024.R's rule).
bx <- read.csv(dpath("data_clean/catalog/s2_box_clear_2024.csv"))
bx$m <- as.integer(substr(bx$date, 6, 7))
bx$full  <- bx$share_box_covered >= 0.9
bx$clear <- bx$full & bx$share_clear > 0.9
tab <- rbind(clear = tapply(bx$clear, bx$m, sum), cloudy = tapply(bx$full & !bx$clear, bx$m, sum),
             part = tapply(!bx$full, bx$m, sum))
cc <- c(col_water, "#9A9A9A", "#D9D9D9")
fig("f11_clear_by_month.png", 5.6, 3.7, ps = 14)
par(mar = c(2.4, 3.6, 0.6, 0.6), las = 1, mgp = c(2.2, 0.6, 0), tcl = -0.3)
b <- barplot(tab, col = cc, border = "white", names.arg = rep("", 12), ylim = c(0, 19), axes = FALSE, space = 0.25)
mtext(month.abb, side = 1, at = b, line = 0.5, cex = 0.82)
axis(2, at = seq(0, 12, 4), col = rule, col.ticks = rule)
mtext("Passes in the month", side = 2, line = 2.3, las = 0)
k <- tab["clear", ] > 0
text(b[k], tab["clear", k] / 2, tab["clear", k], col = "white", font = 2)
boxleg(par("usr")[1] + 0.3, 18.8, c(sprintf("Clear, covering all of our image (%d)", sum(bx$clear)),
                                     sprintf("Cloudy, covering all of it (%d)", sum(bx$full & !bx$clear)),
                                     sprintf("Covering only part of it (%d)", sum(!bx$full))),
       fill = cc, border = NA, corner = "tl", cex = 0.95, gap = 1.35)
dev.off()
print(tab)
g <- diff(c(as.Date("2024-01-01"), as.Date(bx$date[bx$clear])))
cat("  f11: passes", nrow(bx), "; whole image", sum(bx$full), "; clear", sum(bx$clear), "; longest gap between clear images",
    max(diff(as.Date(bx$date[bx$clear]))), "days\n")
# ==== END BLOCK ====

# ==== BLOCK: f12_light_spread DEPS: s2_data ====
# Light spreads past its cell (slides 40, 41): VIIRS lights of 2023 around the south end of Cayuga Lake, on a log
# colour scale, with ESA's water outlined. The lake has no people, yet near Ithaca it glows.
v   <- rast(dpath("data/lights/ntl_viirs_2023_ny.tif"))
e12 <- ext(-76.78, -76.40, 42.40, 42.62)
vc  <- crop(v, e12)
wl  <- crop(wc, e12) == 80
wa  <- resample(wl, vc, method = "average")                           # share of each light cell that is water
lake_cells <- which(values(wa, mat = FALSE) > 0.9)
lat <- yFromCell(vc, lake_cells); lv <- values(vc, mat = FALSE)[lake_cells]
glow <- tapply(lv, cut(lat, c(42.44, 42.50, 42.56, 42.62)), median)
lakepoly <- as.polygons(aggregate(wl, 5, "modal") == 1, dissolve = TRUE); lakepoly <- disagg(lakepoly[lakepoly[[1]] == 1, ])
lakepoly <- lakepoly[expanse(lakepoly, unit = "km") > 5, ]             # the lake only, not the ponds
br  <- c(0, 0.4, 0.5, 0.7, 1, 2, 5, 10, 20, 60)
pal <- hcl.colors(length(br) - 1, "Inferno")
lab <- c("", "0.4", "0.5", "0.7", "1", "2", "5", "10", "20", "")
fig("f12_light_spread.png", 4.8, 4.25, ps = 12)
par(mar = c(0.2, 0.2, 0.2, 0.2))
ev <- as.vector(e12)
plot.new(); plot.window(ev[1:2], c(ev[3] - 0.052, ev[4]), asp = 1 / cos(42.5 * pi / 180), xaxs = "i", yaxs = "i")
rimg(vc, pal, br)
op <- par(xpd = FALSE); plot(lakepoly, add = TRUE, border = "#7FB3E8", lwd = 1.8, col = NA); par(op)
rect(ev[1], ev[3], ev[2], ev[4], border = rule)
points(-76.4966, 42.4430, pch = 21, bg = "white", col = ink, cex = 1.3)
halo(-76.505, 42.432, "Ithaca", adj = c(1, 0.5), font = 2)
halo(-76.700, 42.585, "Cayuga Lake\n(outlined in blue)", font = 2, cex = 0.95)
halo(-76.60, 42.47, "Light over\nthe lake", adj = c(1, 0.5), font = 2, cex = 0.95)
arrows(-76.596, 42.47, -76.523, 42.474, length = 0.07, lwd = 1.8, col = "white")
# 5 km scale bar (in degrees of longitude at this latitude)
km <- 5 / (111.32 * cos(42.5 * pi / 180))
sbar(ev[1] + 0.012, ev[3] + 0.012, km, "5 km", h = 0.004)
# key under the map
y0 <- ev[3] - 0.036; xs <- seq(ev[1] + 0.03, ev[2] - 0.03, length.out = length(pal) + 1)
rect(xs[-length(xs)], y0, xs[-1], y0 + 0.012, col = pal, border = NA)
text(xs[lab != ""], y0 - 0.004, lab[lab != ""], adj = c(0.5, 1), cex = 0.9)
text(ev[1] + 0.03, y0 + 0.02, "Light at night, 2023 (nW/cm²/sr)", adj = c(0, 0), font = 2, cex = 0.95)
dev.off()
cat("  f12: median light over the lake by latitude", paste(names(glow), round(glow, 2)), "; land median",
    round(median(values(vc)[values(wa) < 0.01], na.rm = TRUE), 2), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f13_forest_loss ====
# Forest loss in Mexico (slide 42 or the page): a yes/no map against the truth, per 100 parcel-years, from
# Alix-García & Millimet's estimates (NBER conference version 2021, p. 31): the map catches 49 of 100 real losses
# and shows loss in 1.2 of 100 parcel-years without it. Their model puts the true share of loss near 34%.
tp <- 49; fpr <- 1.2; true_share <- 0.34
shown <- (tp / 100) * true_share + (fpr / 100) * (1 - true_share)
cells <- matrix(c(tp, 100 - tp, fpr, 100 - fpr), 2, byrow = TRUE)
fill  <- matrix(c("#D6E6F4", "#F2B8B0", "#F7D9A8", "#D6E6F4"), 2, byrow = TRUE)
what  <- matrix(c("Right", "Missed\n(false negative)", "False alarm\n(false positive)", "Right"), 2, byrow = TRUE)
fig("f13_forest_loss.png", 5.0, 4.3, ps = 13)
par(mar = c(0.2, 0.2, 0.2, 0.2))
plot.new(); plot.window(c(-0.85, 2.08), c(-0.62, 2.6), xaxs = "i", yaxs = "i")
for (i in 1:2) for (j in 1:2) {
  x0 <- j - 1; y0 <- 2 - i
  rect(x0, y0, x0 + 1, y0 + 1, col = fill[i, j], border = "white", lwd = 4)
  text(x0 + 0.5, y0 + 0.66, fmt(cells[i, j], ifelse(cells[i, j] %% 1 == 0, 0, 1)), font = 2, cex = 1.7)
  text(x0 + 0.5, y0 + 0.3, what[i, j], cex = 0.95)
}
text(c(0.5, 1.5), 2.2, c("Map shows\nloss", "Map shows\nno loss"), font = 2)
text(-0.12, c(1.5, 0.5), c("100 with\nreal loss", "100 with\nno loss"), font = 2, srt = 90)
text(-0.55, 1, "The truth", font = 2, srt = 90)
text(1, 2.47, "What a 30 m map shows", font = 2)
text(1, -0.32, sprintf("The map shows loss in %.0f%% of parcel-years.\nTheir model puts the true share near %.0f%%.",
                         100 * shown, 100 * true_share), cex = 0.95)
dev.off()
cat("  f13: share shown", round(shown, 4), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f14_lights_two_series ====
# Lights stop counting at 63 (slide 43): county lights against people, a. VIIRS 2023 against 2023 people;
# b. the older series of 2013 (Li et al. 2020, values 0 to 63) against 2013 people. New York City's five counties in red.
d   <- read.csv(dpath("data_clean/lights/ny_county_lights.csv"))
nyc <- d$name %in% c("Bronx", "Kings", "New York", "Queens", "Richmond")
r   <- c(cor(log(d$lights_viirs2023), log(d$pop2023)), cor(log(d$lights_li2013), log(d$pop2013)))
r_nyc <- c(cor(log(d$lights_viirs2023[!nyc]), log(d$pop2023[!nyc])), cor(log(d$lights_li2013[!nyc]), log(d$pop2013[!nyc])))
fig("f14_lights_two_series.png", 9.4, 3.9, ps = 12)
layout(matrix(1:2, 1)); par(cex = 1)
ys <- list(d$lights_viirs2023, d$lights_li2013); xs <- list(d$pop2023, d$pop2013)
ttl <- c(sprintf("VIIRS series, 2023 (correlation %.2f)", r[1]), sprintf("Older series, 2013 (correlation %.2f)", r[2]))
xl  <- c("People in the county, 2023", "People in the county, 2013")
for (k in 1:2) {
  par(mar = c(3.3, 4.9, 2.0, 0.8), las = 1, mgp = c(2.1, 0.6, 0), tcl = -0.3)
  plot(xs[[k]], ys[[k]], log = "xy", type = "n", axes = FALSE, xlab = "", ylab = "", xlim = c(4000, 4e6), ylim = c(3000, 2.5e5))
  axis(1, at = c(1e4, 1e5, 1e6), labels = c("10,000", "100,000", "1 million"), col = rule, col.ticks = rule)
  axis(2, at = c(5e3, 2e4, 5e4, 2e5), labels = fmt(c(5e3, 2e4, 5e4, 2e5)), col = rule, col.ticks = rule)
  box(col = rule, bty = "l")
  mtext(paste(xl[k], "(log scale)"), side = 1, line = 2.1)
  if (k == 1) mtext("Light summed over the county (log scale)", side = 2, line = 3.9, las = 0)
  points(xs[[k]][!nyc], ys[[k]][!nyc], pch = 21, bg = blue, col = "white", cex = 1.3, lwd = 1)
  points(xs[[k]][nyc], ys[[k]][nyc], pch = 21, bg = red, col = "white", cex = 1.5, lwd = 1)
  m <- which(d$name == "New York")
  if (k == 1) {                                                        # below and to the left, with a leader
    segments(xs[[k]][m], ys[[k]][m], xs[[k]][m] / 2.2, ys[[k]][m] / 2.6, col = red, lwd = 1.2)
    text(xs[[k]][m] / 2.2, ys[[k]][m] / 2.6, "Manhattan", adj = c(0.5, 1.3), font = 2, col = red)
  } else text(xs[[k]][m], ys[[k]][m], "Manhattan", pos = 2, offset = 0.6, font = 2, col = red)
  legend("topleft", c("New York City's five counties", "Other counties"), pch = 21, pt.bg = c(red, blue), col = "white",
         pt.cex = 1.4, bg = "white", box.col = rule, cex = 0.95, inset = c(0.02, 0.03))
  ptitle(letters[k], ttl[k], cex = 1.05)
}
dev.off()
cat("  f14: correlations", round(r, 4), "; without NYC", round(r_nyc, 4), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f15_lake_patch DEPS: water10 ====
# Cayuga Lake's area from ESA's map (slide 47): the largest water body on the 10 m cells in blue, the other 405 in
# orange (drawn at 40 m, any water in a 40 m cell, so small ponds stay visible), Ithaca, Aurora and the image's north edge.
lakeR  <- p10 == lake_id
otherR <- !is.na(p10) & !lakeR
l40 <- aggregate(lakeR, 4, "max", na.rm = TRUE); o40 <- aggregate(otherR, 4, "max", na.rm = TRUE)
acres <- max(f10$count) * 100 / 4046.86
fig("f15_lake_patch.png", 3.4, 5.4, ps = 12)
par(mar = c(0.2, 0.2, 0.2, 0.2))
plot.new(); plot.window(c(eb[1] - 600, eb[2] + 1500), c(eb[3] - 7900, eb[4] + 2600), asp = 1, xaxs = "i", yaxs = "i")
rect(eb[1], eb[3], eb[2], eb[4], col = col_land, border = NA)
rimg(o40, c("transparent", col_other), c(-0.5, 0.5, 1.5))
rimg(l40, c("transparent", col_water), c(-0.5, 0.5, 1.5))
rect(eb[1], eb[3], eb[2], eb[4], border = rule)
segments(eb[1], eb[4], eb[2], eb[4], col = acc, lwd = 2.4)
halo(mean(eb[1:2]), eb[4] + 1300, "North edge of our image, 42.955° N", font = 2, col = acc, cex = 0.95)
for (p in c("Ithaca", "Aurora")) points(pxy[p, 1], pxy[p, 2], pch = 21, bg = "white", col = ink, cex = 1.3, lwd = 1.4)
halo(pxy["Ithaca", 1] - 900, pxy["Ithaca", 2] + 900, "Ithaca", adj = c(1, 0.5), font = 2)
halo(pxy["Aurora", 1] + 900, pxy["Aurora", 2], "Aurora", adj = c(0, 0.5), font = 2)
halo(pxy["Owasco Lake", 1] - 1500, pxy["Owasco Lake", 2], "Owasco\nLake", font = 2, adj = c(1, 0.5), cex = 0.95)
sbar(eb[1] + 1200, eb[3] + 1500, 5000, "5 km")
boxleg(eb[1], eb[3] - 900, c(sprintf("Cayuga Lake: %s acres", fmt(acres)),
                             sprintf("The other %d water bodies", nrow(f10) - 1), "Land"),
       fill = c(col_water, col_other, col_land), border = c(NA, NA, rule), corner = "tl", cex = 0.95, gap = 1.3)
dev.off()
cat("  f15: lake", max(f10$count), "cells,", round(acres, 2), "acres; others", nrow(f10) - 1, "\n")
# ==== END BLOCK ====

# ==== BLOCK: f16_ndvi_season ====
# Crop output from NDVI (slide 29): the median NDVI of cropland and forest cells east of Cayuga Lake on each clear
# date of 2024 from April on (data_clean/ndvi/ndvi_season_2024.csv; tools/make_s2_season_2024.R), with the early
# value, the peak and their difference marked for cropland, as Asher & Novosad measure crop output.
sn <- read.csv(dpath("data_clean/ndvi/ndvi_season_2024.csv"))
sn$date <- as.Date(sn$date)
sn <- sn[sn$date >= as.Date("2024-04-01") & sn$share_clear >= 0.9, ]  # mostly clear dates, so a cloud edge does not pull the median
cr <- sn[sn$class == "cropland", ]; fo <- sn[sn$class == "forest", ]
ear <- cr[cr$date %in% as.Date(c("2024-05-24", "2024-06-01")), ]; ear <- ear[which.min(ear$median_ndvi), ]
pk  <- cr[which.max(cr$median_ndvi), ]
fe  <- fo[fo$date == ear$date, ]; fp <- max(fo$median_ndvi)
fig("f16_ndvi_season.png", 5.4, 3.8, ps = 12)
par(mar = c(2.6, 3.8, 0.6, 0.8), las = 1, mgp = c(2.4, 0.6, 0), tcl = -0.3)
xr <- as.numeric(as.Date(c("2024-04-01", "2024-12-20")))
plot.new(); plot.window(xr, c(0.2, 1.0), xaxs = "i", yaxs = "i")
mt <- seq(as.Date("2024-04-01"), as.Date("2024-12-01"), by = "month")
axis(1, at = as.numeric(mt), labels = format(mt, "%b"), col = rule, col.ticks = rule)
axis(2, at = seq(0.2, 1, 0.2), labels = sprintf("%.1f", seq(0.2, 1, 0.2)), col = rule, col.ticks = rule)
box(col = rule, bty = "l")
mtext("Median NDVI", side = 2, line = 2.6, las = 0)
lines(as.numeric(fo$date), fo$median_ndvi, col = col_forest, lwd = 2.6); points(as.numeric(fo$date), fo$median_ndvi, pch = 16, col = col_forest, cex = 0.9)
lines(as.numeric(cr$date), cr$median_ndvi, col = col_crops, lwd = 3); points(as.numeric(cr$date), cr$median_ndvi, pch = 16, col = col_crops, cex = 1)
# early, peak and the difference
xe <- as.numeric(ear$date); xp <- as.numeric(pk$date)
points(c(xe, xp), c(ear$median_ndvi, pk$median_ndvi), pch = 21, bg = "white", col = ink, cex = 1.6, lwd = 2)
text(xe, ear$median_ndvi - 0.04, sprintf("Early\n%d %s, %.2f", as.integer(format(ear$date, "%d")), format(ear$date, "%B"), ear$median_ndvi), adj = c(0.5, 1), font = 2, cex = 0.95)
text(xp + 3, pk$median_ndvi + 0.035, sprintf("Peak %d %s, %.2f", as.integer(format(pk$date, "%d")), format(pk$date, "%B"), pk$median_ndvi), adj = c(0, 0), font = 2, cex = 0.95)
xb <- xp + 10
arrows(xb, ear$median_ndvi, xb, pk$median_ndvi, code = 3, length = 0.07, angle = 25, lwd = 1.8, col = ink)
segments(xe, ear$median_ndvi, xb, ear$median_ndvi, lty = 3, col = ink)
text(xb + 3, (ear$median_ndvi + pk$median_ndvi) / 2, sprintf("Peak minus\nearly: %.2f", pk$median_ndvi - ear$median_ndvi),
     adj = c(0, 0.5), font = 2, cex = 0.95)
boxleg(as.numeric(as.Date("2024-09-20")), 0.36, c("Cropland", "Forest"), lty = 1, lcol = c(col_crops, col_forest), lwd = 3,
       corner = "bl", cex = 0.95, gap = 1.3)
dev.off()
cat("  f16: early", format(ear$date), ear$median_ndvi, "; peak", format(pk$date), pk$median_ndvi, "; difference",
    pk$median_ndvi - ear$median_ndvi, "; forest on the early date", fe$median_ndvi, "max", fp, "; dates", nrow(cr), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f18_lake_sizes DEPS: water10 ====
# Exercise 2's solution: the north end of the lake at 10, 30 and 250 m, built as in the exercise (a cell is water when
# at least half of it is), the lake in blue and every other water body in orange.
w30  <- aggregate(w10, fact = 3, fun = "mean", na.rm = TRUE) >= 0.5
w250 <- aggregate(w10, fact = 25, fun = "mean", na.rm = TRUE) >= 0.5
ws <- list(w10, w30, w250); sz <- c(10, 30, 250)
win <- ext(eb[1], eb[1] + 16000, eb[4] - 18000, eb[4])                 # the north-west corner: the lake's north end
fig("f18_lake_sizes.png", 9.6, 4.3, ps = 12)
layout(rbind(1:3, 4), heights = c(3.75, 0.55)); par(cex = 1)
res18 <- NULL
for (k in 1:3) {
  pk <- patches(ws[[k]], directions = 8, zeroAsNA = TRUE); fk <- freq(pk); lid <- fk$value[which.max(fk$count)]
  res18 <- rbind(res18, c(size = sz[k], bodies = nrow(fk), acres = max(fk$count) * sz[k]^2 / 4046.86))
  pc <- crop(pk, win); v <- values(pc, mat = FALSE)
  col <- ifelse(is.na(v), col_land, ifelse(v == lid, col_water, col_other))
  par(mar = c(0.3, 0.4, 2.0, 0.4))
  plot.new(); plot.window(c(win$xmin, win$xmax), c(win$ymin, win$ymax), asp = 1, xaxs = "i", yaxs = "i")
  ep <- as.vector(ext(pc))
  rasterImage(as.raster(matrix(col, nrow(pc), ncol(pc), byrow = TRUE)), ep[1], ep[3], ep[2], ep[4], interpolate = FALSE)
  rect(win$xmin, win$ymin, win$xmax, win$ymax, border = rule)
  if (k == 1) sbar(win$xmax - 5700, win$ymin + 700, 5000, "5 km")
  ptitle(letters[k], sprintf("%d m cells: %d water bodies", sz[k], nrow(fk)), cex = 1.05)
}
par(mar = c(0, 0, 0, 0))
plot.new(); plot.window(c(0, 1), c(0, 1), xaxs = "i", yaxs = "i")
legend("center", c("Cayuga Lake", "Other water bodies", "Land"), fill = c(col_water, col_other, col_land), border = c(NA, NA, rule),
       horiz = TRUE, bg = "white", box.col = rule, x.intersp = 0.6, text.width = c(0.12, 0.17, 0.06))
dev.off()
print(round(res18, 2))
# ==== END BLOCK ====

# ==== BLOCK: labels_data DEPS: s2_data ====
# The 200 labels and the tree, with the slides' own code (slides 50 to 52): set.seed(6850), 60 test points, rpart.
# The label blocks below draw only when data_clean/labels/labels_200.csv exists; otherwise they say so and skip.
f_lab <- dpath("data_clean/labels/labels_200.csv")
have_labels <- file.exists(f_lab)
if (have_labels) {
  suppressPackageStartupMessages(library(rpart))
  lab <- read.csv(f_lab)                                          # lon, lat, class
  lab$class <- factor(lab$class)
  pts <- project(vect(lab, geom = c("lon", "lat"), crs = "EPSG:4326"), crs(s2))
  lab <- cbind(lab, extract(refl, pts, ID = FALSE))               # five bands per point
  set.seed(6850)
  test  <- sample(nrow(lab), 60)
  train <- lab[-test, ]                                           # 140 points to learn from
  hold  <- lab[test, ]                                            # 60 test points
  fit  <- rpart(class ~ B02 + B03 + B04 + B8A + B11, data = train, method = "class")
  pred <- predict(fit, hold, type = "class")
  acc_test <- mean(pred == hold$class)
  ct <- table(true = hold$class, predicted = pred)
  lab$xy <- crds(pts)
  cat("  labels:", nrow(lab), "points;", paste(names(table(lab$class)), table(lab$class), collapse = ", "),
      "; train", paste(table(train$class), collapse = "/"), "; accuracy", acc_test, "\n")
  print(ct)
} else cat("  labels_data: no", f_lab, "yet; f17, f19 and f20 are skipped\n")
# ==== END BLOCK ====

# ==== BLOCK: f17_label_points DEPS: labels_data ====
# 200 points labelled on aerial photos (slide 49): a. the 200 points on our image, coloured by their label;
# b. eight of the 2019 aerial-photo chips (two per class, 100 m across, data/naip/chips/), the point's 20 m cell outlined.
if (have_labels) {
  suppressPackageStartupMessages(library(jpeg))
  ch <- read.csv(dpath("data/naip/chips.csv"))
  ch$x <- (ch$xmin + ch$xmax) / 2; ch$y <- (ch$ymin + ch$ymax) / 2
  # each label's chip: by id when the labels carry one, else the chip centred on the point
  if ("id" %in% names(lab)) lab$chip <- lab$id else
    lab$chip <- ch$id[sapply(seq_len(nrow(lab)), function(i) which.min((ch$x - lab$xy[i, 1])^2 + (ch$y - lab$xy[i, 2])^2))]
  pick <- unlist(lapply(classes, function(k) head(sort(lab$chip[lab$class == k & lab$chip %in% ch$id]), 2)))
  tc2 <- aggregate(tc, 4, "mean", na.rm = TRUE)
  fig("f17_label_points.png", 8.2, 4.9, ps = 12)
  layout(rbind(c(1, 2, 2, 2, 2), c(1, 3, 5, 7, 9), c(1, 4, 6, 8, 10), c(1, 11, 11, 11, 11)), widths = c(2.6, 1.4, 1.4, 1.4, 1.4),
         heights = c(0.4, 1.95, 1.95, 0.6)); par(cex = 1)
  # a. the map
  par(mar = c(0.3, 0.3, 1.8, 0.3))
  plot.new(); plot.window(eb[1:2], eb[3:4], asp = 1, xaxs = "i", yaxs = "i")
  rgbstretch(tc2, tc_lo, tc_hi, white = 0.45)
  rect(eb[1], eb[3], eb[2], eb[4], border = rule)
  points(lab$xy[, 1], lab$xy[, 2], pch = 21, bg = col_class[as.character(lab$class)], col = "white", cex = 1.05, lwd = 0.8)
  sbar(eb[1] + 1500, eb[3] + 1500, 10000, "10 km", cex = 0.95)
  ptitle("a", "The 200 points", cex = 1.0)
  # b. title of the chips
  par(mar = c(0, 0.3, 0, 0.3))
  plot.new(); plot.window(c(0, 1), c(0, 1), xaxs = "i", yaxs = "i")
  text(0.01, 0.45, "b", font = 2, cex = 1.35, adj = c(0, 0.5))
  text(0.52, 0.45, "2019 aerial photo, 100 m around a point, its 20 m cell outlined", font = 2, cex = 1.0)
  # the chips, one column per class
  for (j in seq_along(pick)) {
    k <- pick[j]; r <- ch[ch$id == k, ]; im <- readJPEG(dpath("data/naip/chips", paste0(k, ".jpg")))
    par(mar = c(0.3, 0.3, 1.6, 0.3))
    plot.new(); plot.window(c(r$xmin, r$xmax), c(r$ymin, r$ymax), asp = 1, xaxs = "i", yaxs = "i")
    rasterImage(im, r$xmin, r$ymin, r$xmax, r$ymax, interpolate = FALSE)
    rect(r$x - 10, r$y - 10, r$x + 10, r$y + 10, border = "white", lwd = 3.2)
    rect(r$x - 10, r$y - 10, r$x + 10, r$y + 10, border = col_class[classes[(j + 1) %/% 2]], lwd = 1.8)
    rect(r$xmin, r$ymin, r$xmax, r$ymax, border = rule)
    mtext(classes[(j + 1) %/% 2], side = 3, line = 0.25, font = 2, cex = 1.0, col = ink)
  }
  # the key: classes with their counts
  par(mar = c(0, 0.3, 0, 0.3))
  plot.new(); plot.window(c(0, 1), c(0, 1), xaxs = "i", yaxs = "i")
  n <- table(factor(lab$class, levels = classes))
  legend("center", paste0(classes, " (", n, ")"), pch = 21, pt.bg = col_class, col = "white", pt.cex = 1.6, horiz = TRUE,
         bg = "white", box.col = rule, x.intersp = 0.9, text.width = c(0.13, 0.14, 0.24, 0.12), cex = 0.95)
  dev.off()
  cat("  f17: chips", pick, "\n")
} else cat("  f17: skipped, no labels\n")
# ==== END BLOCK ====

# ==== BLOCK: f19_train_test DEPS: labels_data ====
# Training points and test points (slide 50): the 200 points as dots, coloured by label, split as the slide's
# set.seed(6850) draw splits them: 140 to learn from and 60 held back.
if (have_labels) {
  grid_dots <- function(cls, ncol, x0, y0) {
    cls <- cls[order(match(cls, classes))]
    i <- seq_along(cls) - 1
    points(x0 + (i %% ncol), y0 - (i %/% ncol), pch = 21, bg = col_class[cls], col = "white", cex = 2.1, lwd = 1)
  }
  ntr <- table(factor(as.character(train$class), levels = classes)); nho <- table(factor(as.character(hold$class), levels = classes))
  fig("f19_train_test.png", 6.6, 4.0, ps = 15)
  par(mar = c(0.2, 0.2, 0.2, 0.2))
  plot.new(); plot.window(c(-0.8, 22.8), c(-13.9, 2.2), xaxs = "i", yaxs = "i")
  grid_dots(as.character(train$class), 14, 0, 0)
  grid_dots(as.character(hold$class), 6, 16.5, 0)
  text(6.5, 1.3, sprintf("Training set: %d points", nrow(train)), font = 2)
  text(19, 1.3, sprintf("Test set: %d points", nrow(hold)), font = 2)
  segments(15.25, -9.5, 15.25, 0.8, col = rule, lwd = 1.5)
  legend(11, -11.9, paste0(classes, ": ", ntr, " + ", nho), pch = 21, pt.bg = col_class, col = "white", pt.cex = 1.6, ncol = 2,
         bg = "white", box.col = rule, x.intersp = 0.9, cex = 0.95,
         title = "Label: training + test points", title.font = 2, xjust = 0.5, yjust = 0.5)
  dev.off()
  cat("  f19: training", ntr, "; test", nho, "\n")
} else cat("  f19: skipped, no labels\n")
# ==== END BLOCK ====

# ==== BLOCK: f20_confusion DEPS: labels_data ====
# Accuracy and the confusion table (slide 52): the tree's predictions for the 60 test points against their labels,
# rows the true class, columns the tree's class, right answers on the shaded diagonal. Numbers from the slide's code.
if (have_labels) {
  m <- as.matrix(ct)[classes, classes]
  fig("f20_confusion.png", 5.4, 4.6, ps = 12)
  par(mar = c(0.2, 0.2, 0.2, 0.2))
  plot.new(); plot.window(c(-2.3, 4.2), c(-0.9, 5.4), xaxs = "i", yaxs = "i")
  for (i in 1:4) for (j in 1:4) {
    x0 <- j - 1; y0 <- 4 - i
    fc <- if (i == j) adjustcolor(col_water, 0.15 + 0.6 * m[i, j] / max(1, max(diag(m)))) else
      if (m[i, j] > 0) adjustcolor(col_built, 0.12 + 0.5 * m[i, j] / max(1, max(m[row(m) != col(m)]))) else "#F4F4F2"
    rect(x0, y0, x0 + 1, y0 + 1, col = fc, border = "white", lwd = 3)
    text(x0 + 0.5, y0 + 0.5, m[i, j], font = 2, cex = 1.35)
  }
  short <- c("water", "forest", "grass or\ncrops", "built")
  text(0:3 + 0.5, 4.35, short, font = 2, adj = c(0.5, 0), cex = 0.95)
  text(-0.1, 3:0 + 0.5, short, font = 2, adj = c(1, 0.5), cex = 0.95)
  text(2, 5.15, "The tree's class", font = 2)
  text(-1.95, 2, "The label (true class)", font = 2, srt = 90)
  text(2, -0.45, sprintf("%d of %d test points right: accuracy %.0f%%", sum(diag(m)), sum(m), 100 * sum(diag(m)) / sum(m)), font = 2)
  dev.off()
  cat("  f20: right", sum(diag(m)), "of", sum(m), "\n")
} else cat("  f20: skipped, no labels\n")
# ==== END BLOCK ====
