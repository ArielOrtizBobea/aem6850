# Figures for the session 25 page and slides, part 4 (slope, views and watersheds).
# Base R, terra, sf and exactextractr. Run from fall-2026/sessions:
#   Rscript _figures-25b.R              # every block
#   Rscript _figures-25b.R f16_elevation  # setup, then one block (and its DEPS)
# Writes figures/25-lidar-drones/<block>.png. Inputs: data/25-lidar-drones/data_clean/terrain/ (the session
# project, after its tools/make_terrain.R has run) and data/usgs_gauge/.
# Drawn at res 200. A figure W inches wide shown at about 100 * W px on the 1050 x 700 slide
# keeps its point sizes; every label is 10.5 pt or more at that width.
# Cayuga Lake is drawn from the grid: the cells within 0.5 m of its flat surface (115.95 m), as on slide 37.

# ---- Run named blocks only: Rscript _figures-25b.R <block> [<block> ...] ----
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
# ==== END BLOCK ====

# ==== BLOCK: f16_elevation ====
# Slide 32: elevation with the ten towns named, the lake in blue and McGraw Tower marked.
mm <- unlist(global(dem, c("min", "max"), na.rm = TRUE))
brE <- c(mm[1], seq(150, 600, 50), mm[2]); palE <- hcl.colors(length(brE) - 1, "Terrain 2")
fig("f16_elevation.png", 6.5, 7.4, ps = 16)
par(mar = c(0.2, 0.2, 0.2, 0.2))
mapwin(6800)
rimg(hs, palHS, brHS)
rimg(dem, adjustcolor(palE, 0.72), brE)
rmask(lake, lakeblue)
towns_lines()
town_labels()
tower_mark()
halo(twc[1] + 900, twc[2] - 300, "McGraw\nTower", adj = c(0, 1), font = 2)
halo(368600, 4712600, "Cayuga\nLake", col = "#1F4E79", font = 4, srt = -62)
scalebar(388000, ext0[3] - 5200)
hkey(ext0[1] + 1500, ext0[1] + 26000, ext0[3] - 4600, 1400, palE,
     c(fmt(mm[1], 0), "", "200", "", "300", "", "400", "", "500", "", "", fmt(mm[2], 0)), "Elevation, m",
     cex = 1, padx = 700)
dev.off()
cat("  f16: range", round(mm, 2), "; lake cells", global(lake, "sum", na.rm = TRUE)[[1]],
    "=", round(global(lake, "sum", na.rm = TRUE)[[1]] * 900 / 1e6, 1), "km2\n")
# ==== END BLOCK ====

# ==== BLOCK: slope ====
slope_pct <- tan(terrain(dem, v = "slope", unit = "radians")) * 100     # percent
steep     <- slope_pct > 15
# ==== END BLOCK ====

# ==== BLOCK: f17_steep DEPS: slope ====
# Slide 33: the steep cells in red over grey hillshade, with town lines and names.
fig("f17_steep.png", 6.5, 7.3, ps = 16)
par(mar = c(0.2, 0.2, 0.2, 0.2))
mapwin(7600)
rimg(hs, palHS, brHS)
rmask(steep, adjustcolor(red, 0.85))
rmask(lake, lakeblue)
towns_lines()
town_labels()
tower_mark()
boxleg(ext0[1] + 500, ext0[3] - 600, c("Steeper than 15%", "Cayuga Lake"), fill = c(red, lakeblue))
scalebar(388000, ext0[3] - 4300)
dev.off()
cat("  f17: steep cells", global(steep, "sum", na.rm = TRUE)[[1]], "\n")
# ==== END BLOCK ====

# ==== BLOCK: f18_hand_slope ====
# Slide 34: the 3 x 3 window at McGraw Tower's cell, its 1-2-1 weights and the two weighted differences.
rc <- rowColFromCell(dem, cellFromXY(dem, rbind(twc)))
w  <- matrix(values(dem, row = rc[1] - 1, nrows = 3, col = rc[2] - 1, ncols = 3), 3, byrow = TRUE)
k  <- c(1, 2, 1)
E <- sum(w[, 3] * k); W <- sum(w[, 1] * k); S <- sum(w[3, ] * k); N <- sum(w[1, ] * k)
dx <- (E - W) / (8 * 30); dy <- (S - N) / (8 * 30); sl <- 100 * sqrt(dx^2 + dy^2)
tr <- tan(terrain(dem, v = "slope", unit = "radians")) * 100
sl_terra <- extract(tr, rbind(twc))[1, 1]
wr <- round(w, 2)                                          # the sums as a reader adds the printed values
Er <- sum(wr[, 3] * k); Wr <- sum(wr[, 1] * k); Sr <- sum(wr[3, ] * k); Nr <- sum(wr[1, ] * k)
mns <- function(x, d) sub("^-", "−", sprintf(paste0("%.", d, "f"), x))
fig("f18_hand_slope.png", 10, 3.3, ps = 13)
par(mar = c(0, 0, 0, 0))
plot.new(); plot.window(c(0, 10), c(0, 3.3), asp = 1, xaxs = "i", yaxs = "i")
cs <- 0.7; x0 <- 1.0; y0 <- 0.6                         # cell size and the grid's bottom-left corner
for (i in 1:3) for (j in 1:3) {
  xl <- x0 + (j - 1) * cs; yt <- y0 + (4 - i) * cs
  rect(xl, yt - cs, xl + cs, yt, col = if (i == 2 && j == 2) "#F6E3B4" else "white", border = ink, lwd = 1.2)
  text(xl + cs / 2, yt - cs / 2, sprintf("%.2f", w[i, j]), font = if (i == 2 && j == 2) 2 else 1, cex = 0.92)
}
# the weights: west and east columns (blue), north and south rows (amber)
for (i in 1:3) {
  yy <- y0 + (3.5 - i) * cs
  text(x0 - 0.1, yy, paste0("×", k[i]), col = blue, font = 2, adj = c(1, 0.5))
  text(x0 + 3 * cs + 0.1, yy, paste0("×", k[i]), col = blue, font = 2, adj = c(0, 0.5))
  xx <- x0 + (i - 0.5) * cs
  text(xx, y0 + 3 * cs + 0.15, paste0("×", k[i]), col = "#9A6B00", font = 2)
  text(xx, y0 - 0.15, paste0("×", k[i]), col = "#9A6B00", font = 2)
}
text(x0 - 0.55, y0 + 1.5 * cs, "West", srt = 90, font = 2, col = blue)
text(x0 + 3 * cs + 0.55, y0 + 1.5 * cs, "East", srt = 90, font = 2, col = blue)
text(x0 + 1.5 * cs, y0 + 3 * cs + 0.43, "North", font = 2, col = "#9A6B00")
text(x0 + 1.5 * cs, y0 - 0.43, "South", font = 2, col = "#9A6B00")
# the arithmetic, beside the grid
tx <- 4.6
text(tx, 3.0, "Elevations in metres, McGraw Tower's cell in the middle", adj = c(0, 0.5))
text(tx, 2.45, "East minus west, over 8 × 30 m", adj = c(0, 0.5), font = 2, col = blue)
text(tx, 2.1, sprintf("(%s − %s) / 240 = %s", fmt(Er, 2), fmt(Wr, 2), mns(dx, 4)), adj = c(0, 0.5))
text(tx, 1.55, "South minus north, over 8 × 30 m", adj = c(0, 0.5), font = 2, col = "#9A6B00")
text(tx, 1.2, sprintf("(%s − %s) / 240 = %s", fmt(Sr, 2), fmt(Nr, 2), mns(dy, 4)), adj = c(0, 0.5))
text(tx, 0.55, sprintf("Slope = 100 × √(%s² + (%s)²) = %s%%", mns(dx, 4), mns(dy, 4), mns(sl, 3)),
     adj = c(0, 0.5), font = 2)
dev.off()
cat("  f18: cell row", rc[1], "col", rc[2], "; window", sprintf("%.2f", t(w)), "; E W S N", E, W, S, N,
    "; dx", round(dx, 4), "dy", round(dy, 4), "; by hand", round(sl, 3), "terrain", round(sl_terra, 3), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f19_steep_towns DEPS: slope ====
# The page: towns shaded by their share of land steeper than 15% (steep area / ALAND).
s <- exact_extract(steep * 900, towns, "sum", progress = FALSE)
towns$pct <- round(100 * s / towns$ALAND, 1)
brT <- c(0, 5, 10, 15, 20, 25, 30, 35); palT <- hcl.colors(7, "OrRd", rev = TRUE)
fig("f19_steep_towns.png", 6.5, 7.6, ps = 12)
par(mar = c(0.2, 0.2, 0.2, 0.2))
plot.new(); plot.window(c(360000, 398600), c(4672000, 4720900), asp = 1, xaxs = "i", yaxs = "i")
plot(st_geometry(towns), col = palT[findInterval(towns$pct, brT, all.inside = TRUE)], border = ink, add = TRUE)
rmask(crop(lake, ext(towns)), lakeblue)
towns_lines()
town_labels(setNames(paste0(fmt(towns$pct, 1), "%"), towns$NAMELSAD))
hkey(361000, 378000, 4673900, 1200, palT, c("0", "5", "10", "15", "20", "25", "30", "35"),
     "Share of land steeper than 15%", cex = 1, padx = 700)
dev.off()
print(towns[order(-towns$pct), c("NAMELSAD", "pct"), drop = TRUE], row.names = FALSE)
cat("  f19: county", round(100 * sum(s) / sum(towns$ALAND), 1), "%\n")
# ==== END BLOCK ====

# ==== BLOCK: views ====
top <- rast(dpath("data_clean/terrain/viewshed_tower_target0.tif"))   # observer 53 m, target 0
gnd <- rast(dpath("data_clean/terrain/viewshed_ground.tif"))          # observer 1.7 m, target 0
share <- function(v) round(100 * exact_extract(v * landm * 900, towns, "sum", progress = FALSE) / towns$ALAND, 1)
towns$top <- share(top); towns$gnd <- share(gnd)
km2 <- function(v) round(global(v, "sum", na.rm = TRUE)[[1]] * 900 / 1e6, 1)
view_map <- function(v, pct, key = TRUE, cex = 1, at = NULL) {
  mapwin(if (key) 9800 else 0)
  rimg(hs, palHS, brHS)
  rmask(v * landm, adjustcolor(orange, 0.9))
  rmask(lake, lakeblue)
  towns_lines()
  town_labels(setNames(paste0(fmt(pct, 1), "%"), towns$NAMELSAD), cex = cex, at = at)
  tower_mark()
}
# ==== END BLOCK ====

# ==== BLOCK: f20_view DEPS: views ====
# Slides 30 and 37: land in view from the top of McGraw Tower, each town labelled with its share in view.
fig("f20_view.png", 6.5, 7.7, ps = 16)
par(mar = c(0.2, 0.2, 0.2, 0.2))
# the city's label sits west of the tower and the town's well south of it, so the two do not touch
view_map(top, towns$top, cex = 1.12, at = list("Ithaca city" = c(370600, 4703100), "Ithaca town" = c(377600, 4694200),
                                            "Danby town" = c(379600, 4688300), "Newfield town" = c(365300, 4688300)))
legend(ext0[1] + 500, ext0[3] - 600, c("Land in view from the top of McGraw Tower", "Cayuga Lake", "McGraw Tower"),
       fill = c(orange, lakeblue, NA), border = c(ink, ink, NA), pch = c(NA, NA, 24), pt.bg = "white", col = ink,
       pt.cex = 1.5, bg = "white", box.col = rule, x.intersp = 0.8, y.intersp = 1.15)
dev.off()
print(towns[, c("NAMELSAD", "top", "gnd"), drop = TRUE])
cat("  f20: in view", km2(top), "km2 in the grid\n")
# ==== END BLOCK ====

# ==== BLOCK: f21_view_two DEPS: views ====
# Exercise 2's Solution: the view from the top and from the ground, same colours, one grid.
fig("f21_view_two.png", 12, 8.0, ps = 13)
layout(matrix(1:2, 1)); par(cex = 1)
ttl <-c("From the top (53 m)", "From the ground (1.7 m)")
sub <- c(sprintf("%s km² in view, land and lake", fmt(km2(top), 1)), sprintf("%s km² in view, land and lake", fmt(km2(gnd), 1)))
vv <- list(top, gnd); pp <- list(towns$top, towns$gnd)
for (k in 1:2) {
  par(mar = c(0.3, 0.5, 4.2, 0.5))
  view_map(vv[[k]], pp[[k]], key = TRUE, cex = 0.9)
  if (k == 1) legend(ext0[1] + 500, ext0[3] - 600, c("Land in view", "Cayuga Lake", "McGraw Tower"),
                     fill = c(orange, lakeblue, NA), border = c(ink, ink, NA), pch = c(NA, NA, 24), pt.bg = "white",
                     col = ink, pt.cex = 1.5, bg = "white", box.col = rule, x.intersp = 0.8, horiz = TRUE)
  mtext(ttl[k], side = 3, line = 2.2, font = 2, cex = 1.25)
  mtext(sub[k], side = 3, line = 0.6, cex = 1)
  mtext(letters[k], side = 3, line = 2.2, adj = 0, font = 2, cex = 1.6)
}
dev.off()
cat("  f21: top", km2(top), "ground", km2(gnd), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f22_view_polygons DEPS: views ====
# Slide 39: the view as polygons, outlined over the city of Ithaca and the south end of the lake.
view <- st_read(dpath("data_clean/terrain/viewshed_tower_polygons.gpkg"), quiet = TRUE)
win <- c(370500, 384500, 4694500, 4708500)
fig("f22_view_polygons.png", 6.5, 7.25, ps = 16)
par(mar = c(0.2, 0.2, 0.2, 0.2))
plot.new(); plot.window(win[1:2], c(win[3] - 2100, win[4]), asp = 1, xaxs = "i", yaxs = "i")
cw <- ext(win)
rimg(crop(hs, cw), palHS, brHS)
vin <- suppressWarnings(st_crop(view, st_bbox(c(xmin = win[1], ymin = win[3], xmax = win[2], ymax = win[4]), crs = st_crs(view))))
plot(st_geometry(vin), col = adjustcolor(orange, 0.75), border = NA, add = TRUE)
rmask(crop(lake, cw), lakeblue)                             # the lake drawn over the fill, as on F20
plot(st_geometry(vin), col = NA, border = "#5A2400", lwd = 0.9, add = TRUE)
ci <- towns[towns$NAMELSAD == "Ithaca city", ]
plot(st_geometry(st_intersection(towns, st_as_sfc(st_bbox(cw, crs = st_crs(towns))))), border = ink, lwd = 1.4, add = TRUE)
rect(win[1], win[3], win[2], win[4], border = rule)
tower_mark(2)
halo(twc[1] + 350, twc[2] - 150, "McGraw\nTower", adj = c(0, 1), font = 2)
halo(375300, 4700600, "Ithaca\ncity", font = 2)
halo(373700, 4705400, "Cayuga\nLake", col = "#1F4E79", font = 4)
legend(win[1] + 150, win[3] - 120, c(sprintf("One piece of the view, outlined (%s in all)", fmt(nrow(view))), "Cayuga Lake"),
       fill = c(adjustcolor(orange, 0.75), lakeblue), border = c("#5A2400", ink), bg = "white", box.col = rule,
       x.intersp = 0.8, y.intersp = 1.15)
rect(win[2] - 2150, win[3] - 1150, win[2] - 150, win[3] - 1050, col = ink, border = NA)
text(win[2] - 1150, win[3] - 950, "2 km", adj = c(0.5, 0), font = 2)
dev.off()
cat("  f22:", nrow(view), "pieces;", nrow(vin), "touch the window; area", round(sum(as.numeric(st_area(view))) / 1e6, 1), "km2\n")
# ==== END BLOCK ====

# ==== BLOCK: f23_profile ====
# Slide 40: a real elevation profile due east of McGraw Tower, from the 30 m grid. One sample per 30 m;
# heights lowered by the Earth's curve as viewshed() does (6/7 * d^2 / 12,742,000). A cell is in view when
# its angle from the eye is at least the steepest angle to any cell before it. Eye at the top of the tower (53 m).
profile_fig <- function(file, eye, eye_lab, L = 9000) {
  cl <- cellFromXY(dem, rbind(twc)); z0 <- dem[cl][[1]]; p0 <- twc
  d  <- seq(30, L, 30)
  z  <- extract(dem, cbind(p0[1] + d, p0[2]))[, 1]
  zc <- z - 6 / 7 * d^2 / 12742000
  a  <- (zc - (z0 + eye)) / d
  vis <- a >= c(-Inf, cummax(a)[-length(a)])
  r <- rle(vis); en <- cumsum(r$lengths); st <- en - r$lengths + 1
  runs <- data.frame(vis = r$values, from = d[st], to = d[en], z_from = z[st], z_to = z[en])
  last_vis <- max(which(vis)); h <- last_vis                 # the last cell in view is the ridge that hides the rest
  out <- list(z0 = z0, runs = runs, ridge_d = d[h], ridge_z = z[h])
  dd <- c(0, d) / 1000; zz <- c(z0, z); vv <- c(TRUE, vis)
  ylim <- c(200, 560)
  fig(file, 6.8, 4.6, ps = 12)
  par(mar = c(3.4, 4.2, 0.8, 0.8), las = 1, mgp = c(2.2, 0.5, 0), tcl = -0.3)
  plot.new(); plot.window(c(0, L / 1000), ylim, xaxs = "i", yaxs = "i")
  polygon(c(dd, rev(dd)), c(zz, rep(ylim[1], length(zz))), col = "#D9C6A5", border = NA)
  # the line of sight from the eye over the ridge, and the land it hides
  ye <- z0 + eye; sl <- (out$ridge_z - 6 / 7 * out$ridge_d^2 / 12742000 - ye) / out$ridge_d
  xs <- c(0, L / 1000); ys <- ye + sl * c(0, L)
  hid <- dd * 1000 > out$ridge_d
  polygon(c(dd[hid], rev(dd[hid])), c(pmin(ye + sl * dd[hid] * 1000, ylim[2]), rev(zz[hid])),
          col = adjustcolor(grey, 0.25), border = NA)
  lines(dd, zz, col = brown, lwd = 1.6)
  # the ground in view in orange
  zv <- ifelse(vv, zz, NA); lines(dd, zv, col = orange, lwd = 4.5)
  segments(xs[1], ys[1], xs[2], ys[2], col = ink, lwd = 1.6, lty = 2)
  # the eye and the tower
  segments(0, z0, 0, ye, col = ink, lwd = 3)
  points(0, ye, pch = 21, bg = "white", col = ink, cex = 1.6, lwd = 1.8)
  text(0.1, ye + 185, eye_lab, adj = c(0, 0), font = 2)
  segments(0.3, ye + 178, 0.06, ye + 8, col = ink, lwd = 0.8)
  points(out$ridge_d / 1000, out$ridge_z, pch = 21, bg = acc, col = "white", cex = 1.6, lwd = 1.5)
  text(out$ridge_d / 1000 - 0.15, out$ridge_z + 12, sprintf("Ridge, %.1f km east, %.0f m", out$ridge_d / 1000, out$ridge_z),
       adj = c(1, 0), font = 2)
  hx <- out$ridge_d / 1000 + 1.7; hy <- ye + sl * (hx + 0.95) * 1000 + 14     # above the line of sight, clear of it
  text(hx, hy, "Hidden by the ridge", font = 2, adj = c(0.5, 0))
  arrows(hx - 0.5, hy - 4, out$ridge_d / 1000 + 1.1, 0.5 * (ye + sl * (out$ridge_d + 1100)) + 0.5 * approx(dd, zz, out$ridge_d / 1000 + 1.1)$y,
         length = 0.1, lwd = 1.2, col = ink)
  axis(1, at = 0:(L / 1000), col = rule, col.ticks = rule)
  axis(2, at = seq(ylim[1], ylim[2], 50), col = rule, col.ticks = rule)
  box(col = rule)
  mtext("Kilometres east of McGraw Tower", side = 1, line = 2.1)
  mtext("Elevation, m", side = 2, line = 3.0, las = 0)
  legend("bottomright", c("Ground in view", "Ground out of view"), col = c(orange, brown), lwd = c(4.5, 1.6),
         bg = "white", box.col = rule, inset = c(0.02, 0.04))
  dev.off()
  out
}
p53 <- profile_fig("f23_profile.png", 53, "Eye at 53 m,\ntop of McGraw Tower")
cat("  f23: tower cell", round(p53$z0, 2), "m; eye", round(p53$z0 + 53, 2), "m; ridge", p53$ridge_d, "m east,",
    round(p53$ridge_z, 1), "m\n"); print(p53$runs[p53$runs$to - p53$runs$from >= 60, ], row.names = FALSE)
# the outline's eye at 1.7 m: the same calculation, printed only
d <- seq(30, 9000, 30); z <- extract(dem, cbind(twc[1] + d, twc[2]))[, 1]
a <- (z - 6 / 7 * d^2 / 12742000 - (p53$z0 + 1.7)) / d; vis <- a >= c(-Inf, cummax(a)[-length(a)])
cat("  f23, eye at 1.7 m: last cell in view", max(d[vis]), "m east at", round(z[max(which(vis))], 1),
    "m; cells in view", sum(vis), "of", length(vis), "\n")
# ==== END BLOCK ====

# ==== BLOCK: flow ====
filled <- rast(dpath("data_clean/terrain/fallcreek_dem_filled.tif"))   # 30 m, pits filled before class
fd  <- terrain(filled, v = "flowdir")
facc <- flowAccumulation(fd)
basin <- rast(dpath("data_clean/terrain/fallcreek_basin.tif"))
basin_v <- st_read(dpath("data_clean/terrain/fallcreek_basin.gpkg"), quiet = TRUE)
site <- read.delim(dpath("data/usgs_gauge/site_04234000.rdb"), comment.char = "#", colClasses = "character")[-1, ]
gauge <- project(vect(cbind(as.numeric(site$dec_long_va), as.numeric(site$dec_lat_va)), crs = "EPSG:4269"), crs(fd))
gc <- crds(gauge)[1, ]
extF <- as.vector(ext(filled))
lakeF <- rast(dpath("data_clean/terrain/fallcreek_dem_utm.tif")) <= global(dem, "min", na.rm = TRUE)[[1]] + 0.5
hsF <- shade(terrain(filled, "slope", unit = "radians"), terrain(filled, "aspect", unit = "radians"), 40, 315)
# ==== END BLOCK ====

# ==== BLOCK: f24_flow_window DEPS: flow ====
# Slide 42: a real 3 x 3 window on Fall Creek above the gauge, with the arrow to the lowest neighbour,
# beside the map of log(acc). The window: the cell with the most upstream cells, inside the basin, whose
# lowest neighbour is clearly lowest (0.3 m below the next), with no neighbour within 0.1 m of its own height
# (the fill leaves flats), and whose lowest neighbour is the one terrain() drains it to.
code <- c(32, 64, 128, 16, 0, 1, 8, 4, 2)                 # terra's flowdir codes, row by row (NW N NE / W . E / SW S SE)
cand <- which(values(basin, mat = FALSE) == 1 & values(facc, mat = FALSE) > 2000)
cand <- cand[order(-values(facc, mat = FALSE)[cand])]
pick <- NA
for (cl in cand) {
  rc <- rowColFromCell(filled, cl)
  if (rc[1] < 2 || rc[2] < 2) next
  w <- matrix(values(filled, row = rc[1] - 1, nrows = 3, col = rc[2] - 1, ncols = 3), 3, byrow = TRUE)
  nb <- as.vector(t(w)); nb[5] <- Inf; o <- order(nb)
  if (nb[o[2]] - nb[o[1]] >= 0.3 && w[2, 2] - nb[o[1]] >= 0.5 && min(abs(nb[-5] - w[2, 2])) >= 0.1 &&
      code[o[1]] == fd[cl][[1]]) { pick <- cl; break }
}
rc <- rowColFromCell(filled, pick); pxy <- xyFromCell(filled, pick)[1, ]
w <- matrix(values(filled, row = rc[1] - 1, nrows = 3, col = rc[2] - 1, ncols = 3), 3, byrow = TRUE)
nb <- as.vector(t(w)); nb[5] <- Inf; lo <- which.min(nb)
fig("f24_flow_window.png", 11, 5.2, ps = 13)
layout(matrix(1:2, 1), widths = c(4.6, 6.4)); par(cex = 1)
# a: the window
par(mar = c(0.3, 0.3, 2.6, 0.3))
plot.new(); plot.window(c(-0.75, 3.75), c(-0.9, 3.4), asp = 1, xaxs = "i", yaxs = "i")
for (i in 1:3) for (j in 1:3) {
  idx <- (i - 1) * 3 + j
  rect(j - 1, 3 - i, j, 4 - i, col = if (idx == 5) "#F6E3B4" else if (idx == lo) "#D6E6F2" else "white", border = ink, lwd = 1.2)
  text(j - 0.5, 3.5 - i, sprintf("%.2f", w[i, j]), font = if (idx %in% c(5, lo)) 2 else 1)
}
li <- (lo - 1) %/% 3 + 1; lj <- (lo - 1) %% 3 + 1
arrows(1.5 + 0.2 * (lj - 2), 1.5 - 0.2 * (li - 2), 1.5 + 0.74 * (lj - 2), 1.5 - 0.74 * (li - 2), length = 0.14, lwd = 3, col = blue)
text(1.5, -0.45, sprintf("Lowest neighbour: %.2f m, %.2f m below", nb[lo], w[2, 2] - nb[lo]), font = 2, cex = 0.95)
arrows(3.45, 2.4, 3.45, 2.95, length = 0.1, lwd = 2, col = ink); text(3.45, 3.12, "N", font = 2)
mtext("Elevations in metres, 30 m cells", side = 3, line = 0.6, font = 2, cex = 1.1)
mtext("a", side = 3, line = 0.6, adj = 0, font = 2, cex = 1.5)
# b: log flow accumulation over the whole grid
par(mar = c(0.3, 0.3, 2.6, 0.3))
plot.new(); plot.window(extF[1:2], extF[3:4], asp = 1, xaxs = "i", yaxs = "i")
la <- aggregate(log(facc), 2, "max")                     # 60 m, so one-cell streams survive the drawing
brA <- c(0, 3, 4, 5, 6, 7, 8, 9, 10, 11, 14); palA <- c("white", hcl.colors(9, "Blues 3", rev = TRUE)[c(2:9, 9)])
rimg(la, palA, brA)
rmask(lakeF, lakeblue)
plot(st_geometry(basin_v), border = ink, lwd = 1.3, add = TRUE)
symbols(pxy[1], pxy[2], circles = 900, inches = FALSE, add = TRUE, fg = acc, lwd = 2.5)
halo(pxy[1] + 1200, pxy[2] - 300, "The window in panel a", adj = c(0, 1), font = 2)
halo(392000, 4729000, "Fall Creek basin", font = 2)
rect(extF[1], extF[3], extF[2], extF[4], border = rule)
mtext("log(acc): cells draining through each cell", side = 3, line = 0.6, font = 2, cex = 1.1)
mtext("b", side = 3, line = 0.6, adj = 0, font = 2, cex = 1.5)
dev.off()
cat("  f24: window cell", pick, "row", rc[1], "col", rc[2], "at", round(pxy), "; acc", facc[pick][[1]], "; flowdir", fd[pick][[1]],
    "; elevations", sprintf("%.2f", t(w)), "; lowest", round(nb[lo], 2), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f25_basin DEPS: flow ====
# Slide 43: the Fall Creek basin over grey elevation, streams with more than 1 km2 upstream, towns, the gauge.
e <- extract(facc, buffer(gauge, 150), cells = TRUE)
ws_km2 <- round(global(basin, "sum", na.rm = TRUE)[[1]] * 900 / 1e6, 1)
streams <- focal(facc * 900 / 1e6 > 1, 3, "max", na.rm = TRUE)   # streams drawn three cells wide
win <- c(370000, 410000, 4694000, 4735000)
cw <- ext(win)
fig("f25_basin.png", 6.5, 7.2, ps = 16)
par(mar = c(0.2, 0.2, 0.2, 0.2))
plot.new(); plot.window(win[1:2], c(win[3] - 6600, win[4]), asp = 1, xaxs = "i", yaxs = "i")
rimg(crop(hsF, cw), palHS, quantile(values(hsF, mat = FALSE), seq(0, 1, length.out = 41), na.rm = TRUE))
rmask(crop(basin == 1, cw), adjustcolor("#4F8FC9", 0.45))
rmask(crop(streams, cw), "#1F4E79")
rmask(crop(lakeF, cw), lakeblue)
plot(st_geometry(st_intersection(towns, st_as_sfc(st_bbox(cw, crs = st_crs(towns))))), border = ink, lwd = 1, add = TRUE)
plot(st_geometry(basin_v), border = "#1F4E79", lwd = 1.6, add = TRUE)
rect(win[1], win[3], win[2], win[4], border = rule)
points(gc[1], gc[2], pch = 21, bg = red, col = "white", cex = 2, lwd = 1.5)
halo(gc[1] - 600, gc[2] + 400, "Gauge\n04234000", adj = c(1, 0), font = 2)
for (nm in c("Dryden", "Groton", "Lansing", "Ithaca town")) {
  p <- tl[tl$lab == nm | tl$lab == paste(nm), ]
  if (nm == "Dryden") p[, c("x", "y")] <- c(386000, 4697200)
  if (nm == "Groton") p[, c("x", "y")] <- c(386500, 4718800)
  if (nm == "Lansing") p[, c("x", "y")] <- c(375000, 4715000)
  if (nm == "Ithaca town") p[, c("x", "y")] <- c(373800, 4697200)
  halo(p$x, p$y, nm, font = 2)
}
halo(398000, 4729500, sprintf("Fall Creek basin\n%s km²", fmt(ws_km2, 1)), font = 2, col = "#1F4E79")
boxleg(win[1] + 300, win[3] - 300, c("Drains to the gauge", "Stream, over 1 km² upstream"),
       fill = c(adjustcolor("#4F8FC9", 0.45), "#1F4E79"))
rect(win[2] - 5300, win[3] - 3400, win[2] - 300, win[3] - 3150, col = ink, border = NA)
text(win[2] - 2800, win[3] - 2900, "5 km", adj = c(0.5, 0), font = 2)
dev.off()
cat("  f25: basin", ws_km2, "km2; outlet cells", max(e[[2]]), "\n")
# ==== END BLOCK ====
