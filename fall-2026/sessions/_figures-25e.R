# Figures for the session 25 page and slides, part 6 (the wider view of campus from the same USGS flight).
# Base R, terra, sf and exactextractr; jpeg for the viewer's image layers. Run from fall-2026/sessions:
#   Rscript _figures-25e.R                    # every block
#   Rscript _figures-25e.R f37_campus_wide    # setup, then one block (and its DEPS)
# Writes figures/25-lidar-drones/<block>.png, and the image layers of the interactive viewer
#   figures/25-lidar-drones/campus_wide.html in figures/25-lidar-drones/campus_wide/.
# Inputs: data/25-lidar-drones/data_clean/lidar_wide/ (made by the project's tools/fetch_lidar_wide.R and
#   tools/make_lidar_wide.R; not in the class zip) and data_clean/radar/tompkins_copernicus_utm.tif.
# Landmarks: OpenStreetMap through the Overpass API, 2026-11-24; each object is listed in logs/prep_lidar_wide.txt.
# Drawn at res 200. A figure W inches wide shown at about 100 * W px on the 1050 x 700 slide
# keeps its point sizes; every label is 10.5 pt or more at that width.

# ---- Run named blocks only: Rscript _figures-25e.R <block> [<block> ...] ----
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
out <- "figures/25-lidar-drones"; dat <- "data/25-lidar-drones"
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

# ==== BLOCK: wide_data ====
# The 1.6 km box: ground, surface and height at 1 m (EPSG:6347), their hillshades, the landmarks
wdir <- dpath("data_clean/lidar_wide")
gw <- rast(file.path(wdir, "campus_wide_dtm.tif"))        # ground elevation, m (NAVD88)
sw <- rast(file.path(wdir, "campus_wide_dsm.tif"))        # surface elevation, m
hw <- rast(file.path(wdir, "campus_wide_height.tif"))     # height above ground, m
bw <- as.vector(ext(gw))                                  # xmin, xmax, ymin, ymax
sq <- c(377600, 378200, 4700350, 4700950)                 # the students' 600 m square: xmin, xmax, ymin, ymax
# hillshade 0..1, light from the north-west at 40 degrees; flat ground is about 0.64
hshade <- function(r) {
  h <- shade(terrain(r, "slope", unit = "radians"), terrain(r, "aspect", unit = "radians"), 40, 315)
  h <- values(h, mat = FALSE); h[is.na(h)] <- 0.64; pmin(1, pmax(0, h / 0.85))
}
hs_g <- hshade(gw); hs_s <- hshade(sw)
# colour classes: ground elevation in 10 m steps, height above ground in 7 classes from 2 m
brE <- seq(150, 290, 10); palE <- hcl.colors(length(brE) - 1, "Batlow")
brH <- c(2, 5, 10, 15, 20, 30, 40, 70); palH <- rev(hcl.colors(length(brH) - 1, "YlGnBu"))
rgb01 <- function(pal) col2rgb(pal) / 255
# an RGB array (rows x cols x 3) of a raster: classed colours times a hillshade; cells below `below` get `base`
img_of <- function(v, pal, br, shade, a = 0.45, below = -Inf, base = NULL, nr = nrow(gw), nc = ncol(gw)) {
  k <- findInterval(v, br, all.inside = TRUE); m <- rgb01(pal)[, k, drop = FALSE]
  f <- a + (1 - a) * shade; m <- sweep(m, 2, f, "*")
  if (!is.null(base)) { lo <- is.na(v) | v < below; m[, lo] <- base[, lo] }
  aperm(array(t(m), c(nc, nr, 3)), c(2, 1, 3))
}
grey_of <- function(shade, a, b) { g <- a + b * shade; rbind(g, g, g) }
# Landmarks (OpenStreetMap; see logs/prep_lidar_wide.txt), in EPSG:6347
lmw <- data.frame(name = c("McGraw Tower", "Arts Quad", "Ag Quad", "Warren Hall", "Libe Slope", "Beebe Lake",
                           "Cascadilla Gorge", "Fall Creek gorge", "Suspension Bridge", "Triphammer Falls",
                           "Bradfield Hall", "Mann Library", "Barton Hall", "Bailey Hall", "Baker Laboratory",
                           "Willard Straight Hall", "Schoellkopf Field", "Balch Hall", "Heating plant chimney"),
                  lon = c(-76.48504, -76.48448, -76.47799, -76.47715, -76.48649, -76.47646, -76.48545, NA, -76.48606,
                          -76.47968, -76.47579, -76.47608, -76.48074, -76.48012, -76.48177, -76.48565, -76.47858, -76.47968, -76.47487),
                  lat = c(42.44757, 42.44947, 42.44879, 42.44921, 42.44842, 42.45124, 42.44274, NA, 42.45205,
                          42.45185, 42.44787, 42.44883, 42.44594, 42.44926, 42.45045, 42.44657, 42.44409, 42.45339, 42.44288))
xyw <- st_coordinates(st_transform(st_as_sf(lmw[!is.na(lmw$lon), ], coords = c("lon", "lat"), crs = 4326), 6347))
lmw$x <- NA; lmw$y <- NA; lmw$x[!is.na(lmw$lon)] <- xyw[, 1]; lmw$y[!is.na(lmw$lon)] <- xyw[, 2]
# "Fall Creek gorge" is a label, not an OSM point: on the creek between the Suspension Bridge and Triphammer Falls
lmw[lmw$name == "Fall Creek gorge", c("x", "y")] <- c(378060, 4701020)
L <- function(n) unlist(lmw[lmw$name == n, c("x", "y")])
# zoom boxes: xmin, xmax, ymin, ymax
zb <- list(b = c(378120, 378820, 4700530, 4700780),    # the Ag Quad, Warren Hall, Mann Library, Bradfield Hall
           c = c(377640, 378740, 4700860, 4701253))    # Fall Creek gorge, Suspension Bridge to Beebe Lake
# a map window in inches on the current figure (fig given in inches from the bottom-left)
panel <- function(x0, x1, y0, y1, xl, yl, W, H) {
  par(fig = c(x0 / W, x1 / W, y0 / H, y1 / H), mar = c(0, 0, 0, 0), new = TRUE)
  plot.new(); plot.window(xl, yl, asp = 1, xaxs = "i", yaxs = "i")
}
title_at <- function(x0, x1, y, letter, s, W, H, cex = 1.15) {
  par(fig = c(0, 1, 0, 1), mar = c(0, 0, 0, 0), new = TRUE); plot.new(); plot.window(c(0, W), c(0, H), xaxs = "i", yaxs = "i")
  text(x0 - 0.22, y, letter, adj = c(0, 0.5), font = 2, cex = 2)
  text((x0 + x1) / 2, y, s, adj = c(0.5, 0.5), font = 2, cex = cex)
}
sbar <- function(x, y, m, cex = 1, lab = paste(m, "m")) {
  h <- yinch(0.07)
  rect(x, y, x + m, y + h, col = ink, border = "white", lwd = 1.5)
  halo(x + m / 2, y + h + yinch(0.12), lab, font = 2, cex = cex)
}
# ==== END BLOCK ====

# ==== BLOCK: viewer_layers DEPS: wide_data ====
# The three image layers of campus_wide.html: 1600 x 1600 px, 1 px = 1 m, north up, JPEG
vdir <- file.path(out, "campus_wide"); dir.create(vdir, showWarnings = FALSE)
base_light <- grey_of(hs_g, 0.62, 0.38)
lay <- list(ground  = img_of(values(gw, mat = FALSE), palE, brE, hs_g, a = 0.25),
            surface = { g <- grey_of(hs_s, 0.12, 0.88); aperm(array(t(g), c(ncol(gw), nrow(gw), 3)), c(2, 1, 3)) },
            height  = img_of(values(hw, mat = FALSE), palH, brH, hs_s, a = 0.55, below = 2, base = base_light))
for (k in names(lay)) {
  f <- file.path(vdir, paste0(k, ".jpg"))
  a <- lay[[k]]; a[a < 0] <- 0; a[a > 1] <- 1
  jpeg::writeJPEG(a, f, quality = 0.88)
  cat(k, dim(lay[[k]])[1:2], round(file.size(f) / 1e6, 2), "MB\n")
}
# the landmarks in viewer pixels (column from the west edge, row from the north edge), for the HTML
cat(sprintf('{n:"%s", px:%d, py:%d},', lmw$name, round(lmw$x - bw[1]), round(bw[4] - lmw$y)), sep = "\n")
# ==== END BLOCK ====

# ==== BLOCK: f37_campus_wide DEPS: wide_data ====
# a: the 1.6 km box, height above ground over the ground's hillshade; b: the Ag Quad; c: Fall Creek gorge, ground elevation
img_box <- function(kind, b = bw[c(1, 2, 3, 4)]) {
  e <- ext(b[1], b[2], b[3], b[4]); g <- crop(gw, e); s <- crop(sw, e); h <- crop(hw, e)
  hg <- hshade(g); hsf <- hshade(s)
  a <- if (kind == "height") img_of(values(h, mat = FALSE), palH, brH, hsf, a = 0.55, below = 2,
                                     base = grey_of(hg, 0.62, 0.38), nr = nrow(g), nc = ncol(g))
       else img_of(values(g, mat = FALSE), palE, brE, hg, a = 0.25, nr = nrow(g), nc = ncol(g))
  a[a < 0] <- 0; a[a > 1] <- 1; list(img = a, e = as.vector(e))
}
draw_img <- function(m) rasterImage(m$img, m$e[1], m$e[3], m$e[2], m$e[4], interpolate = TRUE)
lab <- function(n, dx = 0, dy = 0, adj = c(0.5, 0.5), dot = FALSE, cex = 0.85, s = n, font = 2, col = ink) {
  p <- L(n)
  if (dot) points(p[1], p[2], pch = 21, bg = "white", col = ink, cex = 1.1, lwd = 1.8)
  halo(p[1] + dx, p[2] + dy, s, adj = adj, cex = cex, font = font, col = col)
}
W <- 11; H <- 5.4
fig("f37_campus_wide.png", W, H, ps = 14)
plot.new()
# panel a
A <- c(0.30, 4.62, 0.80, 5.02)
panel(A[1], A[2], A[3], A[4], bw[1:2], bw[3:4], W, H)
draw_img(img_box("height"))
rect(bw[1], bw[3], bw[2], bw[4], border = ink, lwd = 1)
rect(sq[1], sq[3], sq[2], sq[4], border = acc, lwd = 2.5)
halo(sq[1] + 5, sq[3] - 18, "the 600 m square\nwe read in R", adj = c(0, 1), cex = 0.85, font = 2, col = acc)
for (k in names(zb)) {
  z <- zb[[k]]; rect(z[1], z[3], z[2], z[4], border = ink, lwd = 2.2)
  halo(z[2] + 12, z[4] + 8, k, adj = c(0, 0), cex = 1.25, font = 2)
}
lab("McGraw Tower", dx = -12, dy = -16, adj = c(1, 1), dot = TRUE)
lab("Arts Quad")
lab("Ag Quad", dy = -20)
lab("Fall Creek gorge", dy = 0, font = 4, col = "#123f6b")
lab("Beebe Lake", dy = 0, font = 4, col = "#123f6b")
lab("Cascadilla Gorge", dy = 0, font = 4, col = "#123f6b")
lab("Libe Slope", dx = -10, font = 4, col = "#123f6b")
lab("Heating plant chimney", dx = -18, adj = c(1, 0.5), dot = TRUE, s = "Heating plant\nchimney, 68 m")
sbar(bw[1] + 40, bw[3] + 40, 500, cex = 0.85)
# keys under panel a
par(fig = c(0, 1, 0, 1), mar = c(0, 0, 0, 0), new = TRUE); plot.new(); plot.window(c(0, W), c(0, H), xaxs = "i", yaxs = "i")
hkey(0.45, 2.05, 0.27, 0.13, palH, c(brH[-length(brH)], "70"), "Height (m), a and b", cex = 0.8)
hkey(2.62, 4.45, 0.27, 0.13, palE, ifelse(brE %% 40 == 0, brE, ""), "Ground elevation (m), c", cex = 0.8)
# panel b: the Ag Quad
Bp <- c(5.13, 10.90, 2.95, 5.02)
z <- zb$b; panel(Bp[1], Bp[2], Bp[3], Bp[4], z[1:2], z[3:4], W, H)
draw_img(img_box("height", z)); rect(z[1], z[3], z[2], z[4], border = ink, lwd = 1)
lab("Ag Quad", dy = -10)
lab("Warren Hall", dx = 10, dy = 8, adj = c(0, 0), dot = TRUE)
lab("Mann Library", dx = -10, dy = 10, adj = c(1, 0), dot = TRUE)
lab("Bradfield Hall", dx = -14, adj = c(1, 0.5), dot = TRUE, s = "Bradfield Hall, 52 m")
sbar(z[1] + 15, z[3] + 15, 100, cex = 0.85)
# panel c: Fall Creek gorge
Cp <- c(5.13, 10.90, 0.10, 2.17)
z <- zb$c; panel(Cp[1], Cp[2], Cp[3], Cp[4], z[1:2], z[3:4], W, H)
draw_img(img_box("ground", z)); rect(z[1], z[3], z[2], z[4], border = ink, lwd = 1)
lab("Suspension Bridge", dx = -20, dy = 24, adj = c(0, 0), dot = TRUE, s = "Suspension Bridge: the gorge is 41 m deep")
lab("Triphammer Falls", dx = 12, dy = -8, adj = c(0, 1), dot = TRUE)
lab("Beebe Lake", font = 4, col = "#123f6b")
halo(378050, 4701140, "Fall Creek", cex = 0.85, font = 4, col = "#123f6b")
sbar(z[1] + 15, z[3] + 15, 100, cex = 0.85)
# titles
title_at(A[1], A[2], 5.22, "a", "Height above ground", W, H)
title_at(Bp[1], Bp[2], 5.22, "b", "The Ag Quad and Warren Hall", W, H)
title_at(Cp[1], Cp[2], 2.48, "c", "Fall Creek gorge, ground elevation", W, H)
dev.off()
# ==== END BLOCK ====
