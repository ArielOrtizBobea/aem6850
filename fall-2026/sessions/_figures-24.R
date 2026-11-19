# Figures for the session 24 page and slides (Spatial II: rasters).
# Base R, terra, sf, exactextractr and Matrix. Run from fall-2026/sessions:
#   Rscript _figures-24.R              # every block
#   Rscript _figures-24.R f04_diff     # setup, then one block (and its DEPS)
# Writes figures/24-spatial-rasters/<block>.png. Inputs: data/24-spatial-rasters/ (the session project).
# Drawn at res 200. A figure W inches wide shown at about 100 * W px on the 1050 x 700 slide
# keeps its point sizes; every label is 10.5 pt or more at that width.

# ---- Run named blocks only: Rscript _figures-24.R <block> [<block> ...] ----
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
suppressPackageStartupMessages({library(terra); library(sf); library(exactextractr); library(Matrix)})
sf_use_s2(FALSE)
out <- "figures/24-spatial-rasters"; dat <- "data/24-spatial-rasters"
dir.create(out, showWarnings = FALSE, recursive = TRUE)
ink <- "#222222"; acc <- "#B31B1B"; grey <- "#666666"; light <- "#E4E2DC"; rule <- "#BBBBBB"
blue <- "#3A6C9C"; amber <- "#E6A700"; red <- "#C0392B"; teal <- "#2A9D8F"
land <- "#F1EFEA"; sea <- "#CFE0EC"; nodata <- "#E3E3E3"
heatpal <- function(n) hcl.colors(n, "YlOrRd", rev = TRUE)
fig <- function(name, w, h, mar = c(0, 0, 0, 0), ps = 12) {
  png(file.path(out, name), width = w, height = h, units = "in", res = 200, pointsize = ps)
  par(mar = mar, family = "sans", xpd = NA)
}
dpath <- function(...) file.path(dat, ...)
# a map window in longitude and latitude, true to shape at the window's latitude
mapwin <- function(xlim, ylim, lat = mean(ylim)) {
  plot.new(); plot.window(xlim, ylim, asp = 1 / cos(lat * pi / 180), xaxs = "i", yaxs = "i")
}
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
# undo clip(): allow drawing anywhere on the figure again
unclip <- function() clip(grconvertX(0, "ndc", "user"), grconvertX(1, "ndc", "user"),
                          grconvertY(0, "ndc", "user"), grconvertY(1, "ndc", "user"))
# draw over the whole figure in 0-1 coordinates, after the panels
overlay <- function() {
  par(fig = c(0, 1, 0, 1), mar = c(0, 0, 0, 0), new = TRUE)
  plot.window(c(0, 1), c(0, 1), xaxs = "i", yaxs = "i")
}
# white text on dark fills, ink on light ones
txtcol <- function(fill) ifelse(colSums(col2rgb(fill) * c(0.299, 0.587, 0.114)) < 140, "white", ink)
# a point at a distance (km) and bearing (degrees) from (lon, lat), flat at that latitude
dest <- function(lon, lat, km, b) cbind(lon + km * sin(b * pi / 180) / (111.32 * cos(lat * pi / 180)),
                                         lat + km * cos(b * pi / 180) / 111.2)
fmt <- function(x, d = 0) formatC(x, format = "f", digits = d, big.mark = ",")
# ==== END BLOCK ====

# ==== BLOCK: us ====
# The 31 days, the county and state outlines, New York, Tompkins County and Warren Hall.
tmax <- rast(dpath("data_clean/tmax_july2012.tif"))
co <- st_read(paste0("/vsizip/", dpath("data/census/cb_2024_us_county_500k.zip")), quiet = TRUE)
states <- st_read(paste0("/vsizip/", dpath("data/census/cb_2024_us_state_500k.zip")), quiet = TRUE)
off <- c("AK", "HI", "PR", "AS", "GU", "MP", "VI")
low <- co[!co$STUSPS %in% off, ]; st48 <- states[!states$STUSPS %in% off, ]
ny  <- co[co$STUSPS == "NY", ]; tk <- co[co$GEOID == "36109", ]
tny <- crop(tmax, ny)
t17 <- tny[["2012-07-17"]]
wh  <- cbind(-76.4797, 42.4490)
whv <- project(vect(wh, crs = "EPSG:4326"), crs(tmax))                    # Warren Hall as a point in the grid's CRS
tab <- exact_extract(t17, tk, include_cell = TRUE, progress = FALSE)[[1]]   # value, cell, coverage_fraction
# ==== END BLOCK ====

# ==== BLOCK: agg DEPS: us ====
# The table of cells and fractions for every county of the lower 48, the weight matrix P and M.
info <- exact_extract(tmax[[1]], low, include_cell = TRUE, progress = FALSE)
tabN <- data.frame(county = rep(seq_len(nrow(low)), sapply(info, nrow)), do.call(rbind, info))
tabN <- tabN[!is.na(tabN$value), ]
tabN$w <- tabN$coverage_fraction / ave(tabN$coverage_fraction, tabN$county, FUN = sum)
Pm <- sparseMatrix(i = tabN$county, j = tabN$cell, x = tabN$w, dims = c(nrow(low), ncell(tmax)))
M  <- values(tmax)
# ==== END BLOCK ====

# ==== BLOCK: f01_grid DEPS: us ====
# Slide 5. The national grid of the 17 July file with its extent; Tompkins County's cells;
# the nine cells around Warren Hall with their values.
zp  <- dpath("data/prism/prism_tmax_us_25m_20120717.zip")
r   <- rast(paste0("/vsizip/", zp, "/prism_tmax_us_25m_20120717.tif"))
i   <- cellFromXY(r, wh); rc <- rowColFromCell(r, i)
e   <- as.vector(ext(r))
rtk <- crop(r, tk, snap = "out")
nine <- matrix(r[cellFromRowColCombine(r, (rc[1] - 1):(rc[1] + 1), (rc[2] - 1):(rc[2] + 1))][, 1], 3, byrow = TRUE)
br1 <- c(9, 15, 20, 25, 28, 31, 34, 37, 40, 45); pal1 <- heatpal(9)
ztk <- range(tab$value); br2 <- seq(27.94, 31.14, length.out = 9); pal2 <- heatpal(8)
h <- res(r) / 2; c0 <- xyFromCell(r, i)
fig("f01_grid.png", 9.6, 3.9, ps = 12)
layout(matrix(1:3, 1), widths = c(4.85, 2.4, 2.35))
# (a) the whole grid
par(mar = c(0.3, 1.9, 0.6, 2.6))
mapwin(c(e[1], e[2]), c(e[3] - 7.6, e[4]), lat = 37)
rimg(r, pal1, br1)
plot(st_geometry(st48), border = "white", lwd = 0.5, add = TRUE)
rect(e[1], e[3], e[2], e[4], border = ink, lwd = 1.2)
text(mean(e[1:2]), e[4] + yinch(0.12), "49.94° N", cex = 0.95)
text(mean(e[1:2]), e[3] - yinch(0.12), "24.06° N", cex = 0.95)
text(e[1] - xinch(0.12), mean(e[3:4]), "125.02° W", srt = 90, cex = 0.95)
text(e[2] + xinch(0.12), mean(e[3:4]), "66.48° W", srt = 90, cex = 0.95)
bt <- st_bbox(tk)
rect(bt[1] - 0.25, bt[2] - 0.25, bt[3] + 0.25, bt[4] + 0.25, border = ink, lwd = 1.6)
halo(bt[1] - 0.6, bt[4] + 1.4, "Tompkins County", adj = c(1, 0.5), cex = 0.95, font = 2)
halo(-100, e[4] - 2.2, "621 rows by 1,405 columns", cex = 0.95)
hkey(e[1] + 1, e[1] + 26, e[3] - 5.6, 1.1, pal1, c("9", "", "20", "", "28", "", "34", "", "40", "45"),
     "Maximum temperature, °C", cex = 0.95, padx = 0.6)
# (b) Tompkins County's cells
par(mar = c(0.3, 0.4, 0.6, 0.4))
bb <- as.vector(ext(rtk))
mapwin(c(bb[1] - 0.02, bb[2] + 0.02), c(bb[3] - 0.13, bb[4] + 0.03), lat = 42.45)
vt <- values(rtk)[, 1]
cellrect(rtk, pal2[findInterval(vt, br2, all.inside = TRUE)], border = "white", lwd = 0.5)
plot(st_geometry(tk), border = ink, lwd = 2, add = TRUE)
rect(c0[1] - 3 * h[1], c0[2] - 3 * h[2], c0[1] + 3 * h[1], c0[2] + 3 * h[2], border = ink, lwd = 1.6)
rect(c0[1] - h[1], c0[2] - h[2], c0[1] + h[1], c0[2] + h[2], border = "white", lwd = 3.6)
rect(c0[1] - h[1], c0[2] - h[2], c0[1] + h[1], c0[2] + h[2], border = acc, lwd = 2)
text(mean(bb[1:2]), bb[4] + yinch(0.17), "Tompkins County", font = 2, cex = 1)
# one cell's size, on the bottom-right cell
j <- cellFromRowCol(rtk, nrow(rtk), ncol(rtk)); cj <- xyFromCell(rtk, j)
segments(cj[1] - h[1], bb[3] - 0.012, cj[1] + h[1], bb[3] - 0.012, lwd = 2)
segments(cj[1] + c(-h[1], h[1]), bb[3] - 0.006, cj[1] + c(-h[1], h[1]), bb[3] - 0.018, lwd = 2)
text(cj[1], bb[3] - 0.033, "3.4 km", cex = 0.95)
segments(bb[2] + 0.012, cj[2] - h[2], bb[2] + 0.012, cj[2] + h[2], lwd = 2)
segments(bb[2] + 0.006, cj[2] + c(-h[2], h[2]), bb[2] + 0.018, cj[2] + c(-h[2], h[2]), lwd = 2)
text(bb[2] + 0.024, cj[2], "4.6 km", cex = 0.95, srt = 90, adj = c(0.5, 1))
hkey(bb[1] + 0.005, bb[1] + 0.25, bb[3] - 0.105, 0.022, pal2, c("27.9", rep("", 7), "31.1"),
     "°C, 17 July 2012", cex = 0.95, padx = 0.012)
# corners of the nine-cell block, in figure coordinates, for the leader lines
lk <- cbind(grconvertX(c0[1] + 3 * h[1], "user", "ndc"), grconvertY(c0[2] + c(3, -3) * h[2], "user", "ndc"))
# (c) the nine cells
par(mar = c(0.3, 0.9, 0.6, 0.3))
plot.new(); plot.window(c(0, 3), c(-0.9, 3.25), asp = 3.42 / 4.63 * 1, xaxs = "i", yaxs = "i")
for (rr in 1:3) for (cc in 1:3) {
  v <- nine[rr, cc]; fl <- pal2[findInterval(v, br2, all.inside = TRUE)]
  rect(cc - 1, 3 - rr, cc, 4 - rr, col = fl, border = "white", lwd = 2)
  text(cc - 0.5, 3.5 - rr, sprintf("%.1f", v), col = txtcol(fl), cex = 1.25, font = ifelse(rr == 2 & cc == 2, 2, 1))
}
rect(1, 1, 2, 2, border = "white", lwd = 5); rect(1, 1, 2, 2, border = acc, lwd = 3)
text(1.5, 3.17, "The nine cells around Warren Hall", font = 2, cex = 1)
text(1.5, -0.25, "Warren Hall's cell: 31.0 °C", col = acc, font = 2, cex = 1)
lc <- cbind(grconvertX(0, "user", "ndc"), grconvertY(c(3, 0), "user", "ndc"))
overlay()
segments(lk[, 1], lk[, 2], lc[, 1], lc[, 2], col = grey, lwd = 1, lty = 2)
dev.off()
cat("  f01: range", range(values(r), na.rm = TRUE), "; Tompkins cells", round(ztk, 2), "; box", round(range(vt), 2),
    "; nine", round(t(nine), 1), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f02_cellnum DEPS: us ====
# Slide 8. How R numbers the cells: the grid's top-left corner, then row 180 with Warren Hall's cell.
r <- rast(paste0("/vsizip/", dpath("data/prism/prism_tmax_us_25m_20120717.zip"), "/prism_tmax_us_25m_20120717.tif"))
i <- cellFromXY(r, wh); rc <- rowColFromCell(r, i); nc <- ncol(r)
fig("f02_cellnum.png", 5.6, 3.8, ps = 13)
par(mar = c(0, 0, 0, 0))
plot.new(); plot.window(c(-1.2, 6.2), c(0.75, 7.2), xaxs = "i", yaxs = "i")
cw <- 1.0; ch <- 0.8
colx <- c(0, 1, 2, 3, 4.6)                         # columns 1 to 4, then the last column
for (rr in 1:3) {
  y <- 6.2 - rr * ch
  for (k in 1:5) {
    cl <- if (k < 5) k else nc
    rect(colx[k], y, colx[k] + cw, y + ch, col = "#F6F5F1", border = grey)
    text(colx[k] + cw / 2, y + ch / 2, fmt((rr - 1) * nc + cl), cex = 0.95)
  }
  text(4.3, y + ch / 2, "…", cex = 1.1)
  text(-0.15, y + ch / 2, paste("row", rr), adj = 1, cex = 0.95)
}
text(colx[1:4] + cw / 2, 6.45, 1:4, cex = 0.95); text(colx[5] + cw / 2, 6.45, fmt(nc), cex = 0.95)
text(-0.15, 6.45, "column", adj = 1, cex = 0.95)
# reading order: along row 1, then the next row
arrows(0.15, 6.85, 5.45, 6.85, length = 0.09, lwd = 1.6, col = acc)
text(2.8, 7.03, "numbered left to right, then the next row", col = acc, cex = 0.95)
points(rep(2.5, 3), 3.55 + c(-0.17, 0, 0.17), pch = 19, cex = 0.45)
# row 180
y <- 1.6
for (k in -1:1) {
  x <- 1.0 + (k + 1) * 1.5
  rect(x, y, x + 1.5, y + ch, col = if (k == 0) "#F6DADA" else "#F6F5F1", border = if (k == 0) acc else grey,
       lwd = if (k == 0) 2.4 else 1)
  text(x + 0.75, y + ch / 2, fmt(i + k), cex = 0.95, font = if (k == 0) 2 else 1, col = if (k == 0) acc else ink)
  text(x + 0.75, y + ch + 0.25, fmt(rc[2] + k), cex = 0.95)
}
text(0.75, y + ch / 2, "…", cex = 1.1); text(5.75, y + ch / 2, "…", cex = 1.1)
text(-0.15, y + ch / 2, paste("row", rc[1]), adj = 1, cex = 0.95)
text(-0.15, y + ch + 0.25, "column", adj = 1, cex = 0.95)
text(3.25, y - 0.45, sprintf("Warren Hall, %.3f °C", r[i][1, 1]), col = acc, font = 2, cex = 1)
dev.off()
cat("  f02: cell", i, "row", rc[1], "col", rc[2], "value", r[i][1, 1], "\n")
# ==== END BLOCK ====

# ==== BLOCK: f03_stack DEPS: us ====
# Slide 9. Five daily layers drawn as a stack of sheets, Warren Hall's value beside each.
days <- c("2012-07-01", "2012-07-16", "2012-07-17", "2012-07-18", "2012-07-31")
lab  <- c("1 July", "16 July", "17 July", "18 July", "31 July")
ra <- aggregate(tmax[[days]], 4, fun = "mean", na.rm = TRUE)
xw <- unlist(extract(tmax[[days]], whv, ID = FALSE))
br <- c(9, 15, 20, 25, 28, 31, 34, 37, 40, 45); pal <- heatpal(9)
sh <- 0.32; sy <- 0.5; gap <- 10.5                  # shear, vertical squash, spacing of the sheets
tf <- function(lon, lat, k) cbind((lon + 96) * 0.8 + sh * (lat - 37), sy * (lat - 37) - (k - 1) * gap)
xy <- xyFromCell(ra, 1:ncell(ra)); hx <- res(ra)[1] / 2; hy <- res(ra)[2] / 2
corners <- function(k, keep) {                       # each cell as a sheared parallelogram
  a <- tf(xy[keep, 1] - hx, xy[keep, 2] - hy, k); b <- tf(xy[keep, 1] + hx, xy[keep, 2] - hy, k)
  c <- tf(xy[keep, 1] + hx, xy[keep, 2] + hy, k); d <- tf(xy[keep, 1] - hx, xy[keep, 2] + hy, k)
  n <- sum(keep)
  list(x = as.vector(rbind(a[, 1], b[, 1], c[, 1], d[, 1], NA)), y = as.vector(rbind(a[, 2], b[, 2], c[, 2], d[, 2], NA)))
}
sl <- st_coordinates(st_cast(st_geometry(suppressWarnings(st_simplify(st48, dTolerance = 0.05))), "MULTILINESTRING"))
fig("f03_stack.png", 5.6, 4.3, ps = 13)
par(mar = c(0, 0, 0, 0))
plot.new(); plot.window(c(-40, 43.5), c(-4 * gap - 21, 12.5), xaxs = "i", yaxs = "i")
for (k in 5:1) {
  v <- values(ra[[k]])[, 1]; keep <- !is.na(v)
  ed <- rbind(tf(-125.02, 24.06, k), tf(-66.48, 24.06, k), tf(-66.48, 49.94, k), tf(-125.02, 49.94, k))
  polygon(ed, col = "white", border = rule, lwd = 0.8)
  pc <- corners(k, keep)
  cl <- pal[findInterval(v[keep], br, all.inside = TRUE)]
  polygon(pc$x, pc$y, col = cl, border = cl, lwd = 0.25)
  ln <- tf(sl[, 1], sl[, 2], k); grp <- interaction(sl[, "L1"], sl[, "L2"], drop = TRUE)
  for (g in split(seq_len(nrow(ln)), grp)) lines(ln[g, ], col = "white", lwd = 0.35)
  text(-28.5, tf(-125, 37, k)[2], lab[k], adj = 1, cex = 1, font = 2)
}
pw <- t(sapply(1:5, function(k) tf(wh[1], wh[2], k)))
segments(pw[1, 1], pw[1, 2] + 3.6, pw[1, 1], pw[5, 2], col = ink, lwd = 1.3)
points(pw, pch = 21, bg = "white", col = ink, cex = 1.0, lwd = 1.4)
for (k in 1:5) {
  segments(pw[k, 1] + 0.8, pw[k, 2], 31.5, pw[k, 2], col = grey, lty = 3)
  text(32, pw[k, 2], sprintf("%.1f °C", xw[k]), adj = 0, cex = 1, font = 2)
}
text(pw[1, 1], pw[1, 2] + 5.2, "Warren Hall", cex = 1, font = 2)
hkey(-36.5, -6, -4 * gap - 16, 2.0, pal, c("9", "", "20", "", "28", "", "34", "", "40", "45"),
     "Maximum temperature, °C", cex = 0.95, padx = 0.8)
dev.off()
cat("  f03: Warren Hall", round(xw, 2), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f04_diff DEPS: us ====
# Slide 16. The 17 July layer minus July's mean gives the difference, cell by cell, over New York's box.
mn <- mean(tny); dv <- t17 - mn
g  <- c(t17, mn, dv)
xw <- unlist(extract(g, whv, ID = FALSE))
brT <- c(22, 24, 26, 28, 30, 32, 34.5); palT <- heatpal(6)
brD <- c(-1.25, -0.5, 0, 0.5, 1, 2, 3, 4.6); palD <- c("#7B5AA6", "#C9B9DD", "#FBE3D6", "#F4A582", "#E2604A", "#B2182B", "#67001F")
e  <- as.vector(ext(tny)); nyst <- st_geometry(st48[st48$STUSPS %in% c("NY", "PA", "NJ", "CT", "MA", "VT"), ])
nm <- c("17 July", "July's mean", "Difference")
lb <- c(sprintf("%.1f", xw[1]), sprintf("%.1f", xw[2]), sprintf("%+.1f", xw[3]))
fig("f04_diff.png", 9.6, 3.3, ps = 12)
layout(matrix(1:5, 1), widths = c(3, 0.3, 3, 0.3, 3))
for (k in 1:3) {
  par(mar = c(0, 0, 0, 0))
  mapwin(e[1:2] + c(-0.05, 0.05), c(e[3] - 1.75, e[4] + 0.5), lat = 42.7)
  rimg(g[[k]], if (k < 3) palT else palD, if (k < 3) brT else brD)
  clip(e[1], e[2], e[3], e[4])
  plot(st_geometry(ny), border = "white", lwd = 0.5, add = TRUE)
  plot(nyst, border = ink, lwd = 0.9, add = TRUE)
  unclip()
  rect(e[1], e[3], e[2], e[4], border = rule, lwd = 0.8)
  text(mean(e[1:2]), e[4] + 0.25, nm[k], font = 2, cex = 1.05)
  points(wh, pch = 21, bg = "white", col = ink, cex = 1.1, lwd = 1.5)
  halo(wh[1] + 0.18, wh[2] - 0.05, lb[k], adj = c(0, 1), font = 2, cex = 1.05)
  if (k == 1) hkey(e[1] + 0.2, e[1] + 4.4, e[3] - 1.05, 0.26, palT, c("22", "24", "26", "28", "30", "32", "34.5"),
                   "°C, the first two maps", cex = 0.95, padx = 0.12)
  if (k == 3) hkey(e[1] + 0.2, e[1] + 4.9, e[3] - 1.05, 0.26, palD, c("-1.2", "-0.5", "0", "0.5", "1", "2", "3", "4.6"),
                   "°C above July's mean", cex = 0.95, padx = 0.12)
  if (k < 3) { plot.new(); plot.window(c(0, 1), c(0, 1)); text(0.5, 0.56, c("−", "=")[k], cex = 3, font = 2) }
}
dev.off()
cat("  f04: range of the difference", round(range(values(dv), na.rm = TRUE), 2), "; Warren Hall", round(xw, 2),
    "; day", round(range(values(t17), na.rm = TRUE), 1), "; mean", round(range(values(mn), na.rm = TRUE), 1), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f05_windgrid DEPS: us ====
# Slide 19. The 0.25-degree wind cells over the 4 km temperature cells around Tompkins County.
u  <- rast(dpath("data_clean/u10_ny_20120717.tif"))
u4 <- project(u[["18:00"]], tny)
before <- extract(u[["18:00"]], vect(wh, crs = "EPSG:4326"), ID = FALSE)[1, 1]
after  <- extract(u4, whv, ID = FALSE)[1, 1]
cu <- xyFromCell(u, cellFromXY(u, wh))
xl <- c(-76.875, -76.125); yl <- c(42.125, 42.875)
nbr <- co[co$STUSPS == "NY" & co$NAME %in% c("Tompkins", "Cortland", "Seneca", "Schuyler", "Chemung", "Tioga", "Cayuga"), ]
fig("f05_windgrid.png", 5.6, 4.3, ps = 13)
par(mar = c(0.2, 0.2, 0.2, 0.2))
mapwin(c(xl[1], xl[2] + 0.62), yl, lat = 42.5)
rect(xl[1], yl[1], xl[2], yl[2], col = land, border = NA)
rect(cu[1] - 0.125, cu[2] - 0.125, cu[1] + 0.125, cu[2] + 0.125, col = adjustcolor(amber, 0.45), border = NA)
gx <- -125.0208333 + (0:2000) / 24; gx <- gx[gx > xl[1] & gx < xl[2]]
gy <- 24.0625 + (0:1000) / 24; gy <- gy[gy > yl[1] & gy < yl[2]]
segments(gx, yl[1], gx, yl[2], col = grey, lwd = 0.5); segments(xl[1], gy, xl[2], gy, col = grey, lwd = 0.5)
plot(st_geometry(st_crop(nbr, xmin = xl[1], xmax = xl[2], ymin = yl[1], ymax = yl[2])), border = "#8C8C8C", lwd = 1.2, add = TRUE)
plot(st_geometry(tk), border = acc, lwd = 2.4, add = TRUE)
wx <- seq(xl[1], xl[2], 0.25); wy <- seq(yl[1], yl[2], 0.25)
segments(wx, yl[1], wx, yl[2], col = ink, lwd = 2.6); segments(xl[1], wy, xl[2], wy, col = ink, lwd = 2.6)
points(wh, pch = 21, bg = acc, col = "white", cex = 1.4, lwd = 1.5)
halo(wh[1] + 0.02, wh[2] - 0.035, "Warren Hall", adj = c(0, 0.5), cex = 0.95, font = 2)
halo(-76.33, 42.30, "Tompkins\nCounty", cex = 0.95, col = acc, font = 2)
# labels at the right, with leaders to the shaded cell
x0 <- xl[2] + 0.05
segments(cu[1] + 0.125, cu[2] + 0.09, x0 - 0.01, 42.72, col = ink, lwd = 1)
text(x0, 42.72, "1 wind cell =\n36 temperature\ncells", adj = c(0, 0.5), cex = 0.95, font = 2)
segments(cu[1] + 0.125, cu[2] - 0.03, x0 - 0.01, 42.42, col = ink, lwd = 1)
text(x0, 42.42, sprintf("%.2f m/s toward the\neast; %.2f in Warren\nHall's cell after\nproject()", before, after),
     adj = c(0, 0.5), cex = 0.95)
legend(x0 - 0.02, 42.29, c("wind cell, 0.25°", "temperature cell", "Tompkins County"), lwd = c(2.6, 0.6, 2.4),
       col = c(ink, grey, acc), bg = "white", box.col = rule, cex = 0.86, seg.len = 1.4, y.intersp = 1.1, x.intersp = 0.6)
dev.off()
cat("  f05: wind cell centre", cu, "; before", round(before, 3), "after", round(after, 3), "; wind cells", ncell(u) / 1,
    "per layer", nrow(u) * ncol(u), "; temperature cells", ncell(tny), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f06_windarrows DEPS: us ====
# Slide 21. The wind at Warren Hall at 18:00 UTC on 17 July 2012: u, v, their sum, and the two directions.
u <- rast(dpath("data_clean/u10_ny_20120717.tif"))[["18:00"]]; v <- rast(dpath("data_clean/v10_ny_20120717.tif"))[["18:00"]]
p <- vect(wh, crs = "EPSG:4326")
uu <- extract(u, p, ID = FALSE)[1, 1]; vv <- extract(v, p, ID = FALSE)[1, 1]
kmh <- sqrt(uu^2 + vv^2) * 3.6; from <- (atan2(-uu, -vv) * 180 / pi) %% 360; to <- (atan2(uu, vv) * 180 / pi) %% 360
R <- 6.2; hd <- c(uu, vv)                          # the arrows in m/s
fig("f06_windarrows.png", 5.6, 4.3, ps = 13)
par(mar = c(0, 0, 0, 0))
plot.new(); plot.window(c(-8.9, 9.9), c(-7.2, 7.2), asp = 1)
th <- seq(0, 2 * pi, length.out = 200)
lines(R * sin(th), R * cos(th), col = rule, lwd = 1.2)
for (b in c(0, 90, 180, 270)) segments(0.94 * R * sin(b * pi / 180), 0.94 * R * cos(b * pi / 180),
                                     R * sin(b * pi / 180), R * cos(b * pi / 180), col = grey, lwd = 1.2)
text(0, R + 0.5, "0° north", cex = 0.95); text(0, -R - 0.5, "180° south", cex = 0.95)
text(R + 0.3, -0.5, "90° east", adj = 0, cex = 0.95); text(-R - 0.3, 0, "270° west", adj = 1, cex = 0.95)
# the two directions on the circle, dotted from Warren Hall
for (b in c(from, to)) segments(0, 0, R * sin(b * pi / 180), R * cos(b * pi / 180), col = grey, lty = 3, lwd = 1.2)
points(R * sin(c(from, to) * pi / 180), R * cos(c(from, to) * pi / 180), pch = 19, col = grey, cex = 0.8)
# u toward the east, then v toward the north, then their sum
arrows(0, 0, hd[1], 0, length = 0.08, col = grey, lwd = 1.8)
arrows(hd[1], 0, hd[1], hd[2], length = 0.06, col = grey, lwd = 1.8)
text(hd[1] / 2, -0.55, sprintf("u = %.1f m/s east", uu), cex = 0.95)
halo(hd[1] + 0.2, hd[2] * 0.5, sprintf("v = %.1f m/s north", vv), adj = 0, cex = 0.95)
arrows(0, 0, hd[1], hd[2], length = 0.14, col = acc, lwd = 4)
text(hd[1] / 2 - 0.1, hd[2] / 2 + 0.6, sprintf("%.1f km/h", kmh), col = acc, font = 2, cex = 1.15,
     srt = atan2(vv, uu) * 180 / pi)
points(0, 0, pch = 21, bg = "white", col = ink, cex = 1.2, lwd = 1.5)
text(-0.3, 0.45, "Warren Hall", adj = c(1, 0), cex = 0.95, font = 2)
text(R * sin(from * pi / 180) - 0.2, R * cos(from * pi / 180) - 0.45, sprintf("from %.0f°", from), adj = 1, cex = 1, font = 2)
text(R * sin(to * pi / 180) - 0.1, R * cos(to * pi / 180) + 0.6, sprintf("toward %.0f°", to), adj = c(0, 0.5), cex = 1, font = 2)
dev.off()
cat("  f06: u", round(uu, 2), "v", round(vv, 2), "km/h", round(kmh, 1), "from", round(from, 1), "toward", round(to, 1), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f07_times ====
# Slide 26. terra's extract(exact = TRUE) on the 3,109 counties of the lower 48, timed once each (tools/time_methods.R).
tm <- read.csv(dpath("data_clean/timings.csv"))
a  <- tm[tm$method == "terra extract(exact = TRUE)", ]
s  <- c(a$seconds[a$days == 1], a$seconds[a$days == 31], a$seconds[a$days == 3])
lab <- c("1 call on 1 day", "1 call on all 31 days", "3 calls, 1 day each")
fig("f07_times.png", 8.0, 2.9, mar = c(2.6, 10.6, 0.3, 1.0), ps = 13)
par(las = 1, bty = "n", mgp = c(1.8, 0.5, 0))
plot(NA, xlim = c(0, 100), ylim = c(0.45, 3.55), xaxs = "i", axes = FALSE, xlab = "", ylab = "")
segments(seq(20, 100, 20), 0.45, seq(20, 100, 20), 3.55, col = light, lwd = 1)
y <- 3:1
rect(0, y - 0.32, s, y + 0.32, col = c("#8C7B6B", "#8C7B6B", acc), border = NA)
axis(1, at = seq(0, 100, 20), col = rule, col.ticks = rule, cex.axis = 0.95)
axis(2, at = y, labels = lab, tick = FALSE, line = -0.1, cex.axis = 1)
text(s, y, sprintf("%.1f s", s), pos = 4, font = 2, cex = 1)
mtext("seconds", side = 1, line = 1.6, cex = 0.95)
dev.off()
cat("  f07:", round(s, 1), "s\n")
# ==== END BLOCK ====

# ==== BLOCK: f08_frac DEPS: us ====
# Slide 27. Tompkins County's 107 cells shaded by the fraction of each inside the county; three cells labelled.
f <- rast(t17); f[tab$cell] <- tab$coverage_fraction; f <- crop(f, tk, snap = "out")
bb <- unname(as.vector(ext(f))); h <- res(f) / 2
v <- values(f)[, 1]
brF <- seq(0, 1, 0.1); palF <- colorRampPalette(c("#FAF8FC", "#C6B8DE", "#6A51A3", "#2F1F5E"))(10)
ct <- exact_extract(t17, co[co$GEOID == "36023", ], include_cell = TRUE, progress = FALSE)[[1]]
nb <- co[co$STUSPS == "NY" & co$NAME %in% c("Cortland", "Cayuga", "Seneca", "Schuyler", "Chemung", "Tioga"), ]
fr <- function(x) sub("^0", "", sprintf("%.2f", x))
lab <- data.frame(cell = c(10905, 11669, 11675))
lab$f <- tab$coverage_fraction[match(lab$cell, tab$cell)]
lab$x <- xyFromCell(t17, lab$cell)[, 1]; lab$y <- xyFromCell(t17, lab$cell)[, 2]
xl <- c(bb[1] - 0.15, bb[2] + 0.175); yl <- c(bb[3] - 0.118, bb[4] + 0.045)
fig("f08_frac.png", 5.2, 4.3, ps = 13)
par(mar = c(0, 0, 0, 0))
mapwin(xl, yl, lat = 42.45)
cellrect(f, ifelse(is.na(v), "white", palF[findInterval(v, brF, all.inside = TRUE)]), border = rule, lwd = 0.5)
nbl <- suppressWarnings(st_crop(st_cast(st_geometry(nb), "MULTILINESTRING"), xmin = bb[1], xmax = bb[2], ymin = bb[3], ymax = bb[4]))
plot(nbl, col = grey, lwd = 1, add = TRUE)
plot(st_geometry(tk), border = acc, lwd = 2.2, add = TRUE)
for (k in 1:3) {
  fl <- palF[findInterval(lab$f[k], brF, all.inside = TRUE)]
  rect(lab$x[k] - h[1], lab$y[k] - h[2], lab$x[k] + h[1], lab$y[k] + h[2], border = ink, lwd = 1.8)
  text(lab$x[k], lab$y[k], if (lab$f[k] == 1) "1" else fr(lab$f[k]), col = txtcol(fl), font = 2, cex = 0.82)
}
# callouts
segments(lab$x[1], lab$y[1] + h[2], lab$x[1], bb[4] + 0.012, col = ink)
text(lab$x[1] - 0.012, bb[4] + 0.017, "cell 10,905", adj = c(0, 0), cex = 0.95, font = 2)
segments(lab$x[2] - h[1], lab$y[2], bb[1] - 0.006, lab$y[2], col = ink)
text(bb[1] - 0.01, lab$y[2], "cell 11,669,\nWarren Hall", adj = c(1, 0.5), cex = 0.95, font = 2)
segments(lab$x[3] + h[1], lab$y[3], bb[2] + 0.006, lab$y[3], col = ink)
text(bb[2] + 0.01, lab$y[3] + 0.034, "cell 11,675", adj = c(0, 0.5), cex = 0.95, font = 2)
text(bb[2] + 0.01, lab$y[3], sprintf("%s in Tompkins", fr(lab$f[3])), adj = c(0, 0.5), cex = 0.95)
text(bb[2] + 0.01, lab$y[3] - 0.034, sprintf("%s in Cortland", fr(ct$coverage_fraction[ct$cell == 11675])), adj = c(0, 0.5), cex = 0.95)
text(bb[2] + 0.085, bb[4] - 0.03, "Cortland\nCounty", cex = 0.95, col = grey, font = 3)
halo(-76.33, 42.30, "Tompkins\nCounty", cex = 0.95, col = acc, font = 2)
hkey(xl[1] + 0.02, xl[1] + 0.32, yl[1] + 0.036, 0.022, palF, c("0", rep("", 4), ".5", rep("", 4), "1"),
     "Fraction of the cell inside the county", cex = 0.95, padx = 0.012)
dev.off()
cat("  f08: cells", nrow(tab), "whole", sum(tab$coverage_fraction == 1), "partial", sum(tab$coverage_fraction < 1),
    "; labelled", round(lab$f, 4), "; Cortland 11675", round(ct$coverage_fraction[ct$cell == 11675], 4), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f09_weighted DEPS: us ====
# Slide 29. Tompkins County's mean written out as a weighted sum of the table's rows.
x <- tab$value; w <- tab$coverage_fraction
k <- match(11669, tab$cell)
num <- sprintf("%.2f × %.2f  +  %.2f × %.2f  +  %.2f × %.2f  +  …  +  1 × %.2f  +  …", w[1], x[1], w[2], x[2], w[3], x[3], x[k])
fig("f09_weighted.png", 9.6, 1.75, ps = 15)
par(mar = c(0, 0, 0, 0))
plot.new(); plot.window(c(0, 1), c(0, 1), xaxs = "i", yaxs = "i")
xn <- 0.03; wn <- strwidth(num)
text(xn, 0.66, num, adj = c(0, 0.5))
segments(xn, 0.5, xn + wn, 0.5, lwd = 1.6)
text(xn + wn / 2, 0.34, sprintf("%.2f", sum(w)), font = 1)
text(xn + wn + 0.02, 0.5, sprintf("=  %.2f °C", sum(w * x) / sum(w)), adj = c(0, 0.5), font = 2, col = acc)
# where the Warren Hall term sits in the numerator
pre <- sub("1 × .*", "", num); x1 <- xn + strwidth(pre); x2 <- x1 + strwidth(sprintf("1 × %.2f", x[k]))
segments(x1, 0.83, x2, 0.83, col = grey); segments(c(x1, x2), 0.83, c(x1, x2), 0.79, col = grey)
text((x1 + x2) / 2, 0.92, "Warren Hall's cell", cex = 0.8, col = ink)
x3 <- xn + strwidth(sprintf("%.2f × %.2f", w[1], x[1]))
segments(xn, 0.83, x3, 0.83, col = grey); segments(c(xn, x3), 0.83, c(xn, x3), 0.79, col = grey)
text(xn, 0.92, "fraction × temperature", cex = 0.8, adj = c(0, 0.5))
text(xn + wn / 2, 0.14, "the sum of the 107 fractions", cex = 0.8)
dev.off()
cat("  f09: sum of fractions", round(sum(w), 4), "mean", round(sum(w * x) / sum(w), 5), "; first three",
    round(w[1:3], 2), round(x[1:3], 2), "; Warren Hall", w[k], x[k], "\n")
# ==== END BLOCK ====

# ==== BLOCK: f10_product DEPS: us ====
# Slide 31. A row of 107 weights times 107 cells by 31 days gives Tompkins County's 31 means.
Mny <- values(tny); w <- tab$coverage_fraction; w1 <- w / sum(w)
B <- Mny[tab$cell, ]; outm <- as.vector(w1 %*% B)
d4 <- c(1, 17, 18, 31); dl <- c("1 July", "17 July", "18 July", "31 July")
f4 <- function(z) sprintf("%.4f", z); f2 <- function(z) sprintf("%.2f", z)
fig("f10_product.png", 9.6, 2.8, ps = 12)
par(mar = c(0, 0, 0, 0))
plot.new(); plot.window(c(0, 9.6), c(0, 2.8), xaxs = "i", yaxs = "i")
wy <- c(1.2, 1.6)
# the weights: one row of 107
sw <- c(0.62, 0.62, 0.62, 0.3, 0.62, 0.3); wx <- 0.05 + c(0, cumsum(sw))
rect(wx[1], wy[1], wx[7], wy[2], col = "#F6F5F1", border = ink, lwd = 1.2)
cx <- (wx[-1] + wx[-7]) / 2
text(cx, mean(wy), c(f4(w1[1:3]), "…", f4(w1[match(11669, tab$cell)]), "…"), cex = 0.95)
text(mean(wx[c(1, 7)]), wy[2] + 0.22, "weights, 1 × 107", font = 2, cex = 1)
text(cx[2], wy[1] - 0.22, "they sum to 1", cex = 0.95)
segments(cx[5], wy[1] - 0.04, cx[5], wy[1] - 0.3, col = grey)
text(cx[5], wy[1] - 0.42, "a whole cell", cex = 0.95)
text(3.38, mean(wy), "×", cex = 2.2)
# the temperatures: 107 cells by 31 days
bx <- c(3.6, 6.78); by <- c(0.2, 2.6)
rect(bx[1], by[1], bx[2], by[2], col = "#F6F5F1", border = ink, lwd = 1.2)
colx <- bx[1] + 1.06 + (0:3) * 0.6
text(c(bx[1] + 0.4, colx), by[2] - 0.2, c("cell", dl), cex = 0.9)
ry <- by[2] - 0.2 - (1:2) * 0.36
for (rr in 1:2) text(colx, ry[rr], f2(B[rr, d4]), cex = 0.95)
text(bx[1] + 0.4, ry, c("10,905", "10,906"), cex = 0.95)
for (cc in colx) points(rep(cc, 3), ry[2] - 0.3 - c(0, 0.09, 0.18), pch = 19, cex = 0.3)
points(rep(bx[1] + 0.4, 3), ry[2] - 0.3 - c(0, 0.09, 0.18), pch = 19, cex = 0.3)
text(mean(bx), by[1] + 0.32, "temperatures, 107 cells × 31 days", font = 2, cex = 1)
text(6.99, mean(wy), "=", cex = 2.2)
# the result: one row of 31 means
rx <- c(7.2, 9.56)
rect(rx[1], wy[1], rx[2], wy[2], col = "#F6DADA", border = acc, lwd = 1.4)
rcx <- seq(rx[1], rx[2], length.out = 5); rcx <- (rcx[-1] + rcx[-5]) / 2
text(rcx, mean(wy), f2(outm[d4]), cex = 0.95, font = 2)
text(rcx, wy[1] - 0.2, dl, cex = 0.9)
text(mean(rx), wy[2] + 0.22, "Tompkins County, 1 × 31", font = 2, cex = 1)
dev.off()
cat("  f10: weights", f4(w1[1:3]), f4(max(w1)), "sum", sum(w1), "; cells", f2(B[1, d4]), "|", f2(B[2, d4]), "; means", f2(outm[d4]), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f11_P DEPS: us ====
# Slide 32. New York's weight matrix: 62 counties by 20,710 cells, a dot at each entry that is not zero,
# Tompkins County's row in red and enlarged below.
infy <- exact_extract(t17, ny, include_cell = TRUE, progress = FALSE)
tb <- data.frame(county = rep(seq_len(nrow(ny)), sapply(infy, nrow)), do.call(rbind, infy))
tb <- tb[!is.na(tb$value), ]
tb$w <- tb$coverage_fraction / ave(tb$coverage_fraction, tb$county, FUN = sum)
k <- which(ny$GEOID == "36109"); tr <- tb[tb$county == k, ]
fig("f11_P.png", 5.6, 4.4, ps = 13)
layout(matrix(1:2, 2), heights = c(2.75, 1.65))
par(mar = c(2.3, 2.6, 1.5, 1.6), las = 1, mgp = c(1.4, 0.45, 0), tcl = -0.3)
plot(NA, xlim = c(1, ncell(tny)), ylim = c(62.5, 0.5), xaxs = "i", yaxs = "i", axes = FALSE, xlab = "", ylab = "")
rect(1, 0.5, ncell(tny), 62.5, col = "#F6F5F1", border = rule)
segments(tb$cell, tb$county - 0.4, tb$cell, tb$county + 0.4, col = ifelse(tb$county == k, acc, ink), lwd = 0.6)
rect(min(tr$cell) - 60, k - 0.9, max(tr$cell) + 60, k + 0.9, border = acc, lwd = 1.2)
axis(1, at = c(1, 5000, 10000, 15000, 20710), labels = c("1", "5,000", "10,000", "15,000", "20,710"),
     col = rule, col.ticks = rule, cex.axis = 0.9)
axis(2, at = c(1, 62), labels = c("1", "62"), col = rule, col.ticks = rule, cex.axis = 0.9)
mtext("columns: the cells of New York's grid", side = 1, line = 1.35, cex = 0.9)
mtext("rows: 62 counties", side = 3, line = 0.3, adj = 0, cex = 0.9)
halo(max(tr$cell) + 300, k, sprintf("Tompkins, row %d", k), adj = 0, col = acc, font = 2, cex = 0.9)
pk <- grconvertX(range(tr$cell) + c(-60, 60), "user", "ndc"); pky <- grconvertY(k + 0.9, "user", "ndc")
par(mar = c(2.6, 4.2, 1.6, 1.6))
plot(NA, xlim = c(10850, 12680), ylim = c(0, 0.0165), xaxs = "i", yaxs = "i", axes = FALSE, xlab = "", ylab = "")
segments(tr$cell, 0, tr$cell, tr$w, col = acc, lwd = 1.6)
axis(1, at = c(10905, 11500, 12000, 12621), labels = c("10,905", "11,500", "12,000", "12,621"), col = rule,
     col.ticks = rule, cex.axis = 0.9)
axis(2, at = c(0, 0.0125), labels = c("0", "0.0125"), col = rule, col.ticks = rule, cex.axis = 0.9)
mtext("cell number", side = 1, line = 1.45, cex = 0.9)
iw <- tr[tr$cell == 11669, ]
segments(iw$cell, 0, iw$cell, iw$w, col = ink, lwd = 2.2)
segments(iw$cell, iw$w, iw$cell + 50, iw$w + 0.0026, col = ink)
halo(iw$cell + 60, iw$w + 0.0026, sprintf("Warren Hall's cell, weight %.4f", iw$w), adj = c(0, 0.5), cex = 0.9, font = 2)
mtext("Tompkins County's row: 107 weights", side = 3, line = 0.4, adj = 0, cex = 0.9, col = acc, font = 2)
qx <- grconvertX(par("usr")[1:2], "user", "ndc"); qy <- grconvertY(par("usr")[4], "user", "ndc")
overlay()
segments(pk, pky - 0.012, qx, qy + 0.06, col = acc, lty = 2, lwd = 0.9)
dev.off()
cat("  f11: entries not zero", nrow(tb), "of", 62 * ncell(tny), "=", round(100 * nrow(tb) / (62 * ncell(tny)), 2),
    "%; Tompkins row", k, "entries", nrow(tr), "; Warren Hall weight", round(iw$w, 4), "; cells", range(tr$cell), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f11b_sparse DEPS: us ====
# Slide 33. Four cells of New York's grid, 11,673 to 11,676, cut by the Tompkins-Cortland line,
# and the five entries a sparse matrix stores for them.
cl <- co[co$GEOID == "36023", ]
ft <- tab$coverage_fraction[match(11673:11676, tab$cell)]
fc <- exact_extract(t17, cl, include_cell = TRUE, progress = FALSE)[[1]]
fc <- fc$coverage_fraction[match(11673:11676, fc$cell)]
xy <- xyFromCell(t17, 11673:11676); h <- res(t17) / 2
win <- unname(c(xy[1, 1] - h[1] - 0.004, xy[4, 1] + h[1] + 0.004, xy[1, 2] - h[2] - 0.012, xy[1, 2] + h[2] + 0.024))
fr <- function(z) ifelse(z == 1, "1", sub("^0", "", sprintf("%.2f", z)))
fig("f11b_sparse.png", 5.8, 2.7, ps = 13)
layout(matrix(1:2, 1), widths = c(3.0, 2.8))
par(mar = c(0.2, 0.3, 0.2, 0.2))
mapwin(win[1:2], c(win[3] - 0.018, win[4]), lat = xy[1, 2])
clip(win[1], win[2], win[3], win[4])
plot(st_geometry(tk), col = "#F6DADA", border = NA, add = TRUE)
plot(st_geometry(cl), col = "#E2E8D8", border = NA, add = TRUE)
unclip()
rect(xy[, 1] - h[1], xy[, 2] - h[2], xy[, 1] + h[1], xy[, 2] + h[2], border = ink, lwd = 1.6)
bl <- st_intersection(st_cast(st_geometry(tk), "MULTILINESTRING"),
                      st_as_sfc(st_bbox(c(xmin = win[1], xmax = win[2], ymin = win[3], ymax = win[4]), crs = st_crs(tk))))
clip(win[1], win[2], xy[1, 2] - h[2] - 0.006, xy[1, 2] + h[2] + 0.003)
plot(bl, col = acc, lwd = 2.6, add = TRUE)
unclip()
text(xy[, 1], xy[, 2] + h[2] + 0.009, fmt(11673:11676), cex = 0.95, font = 2)
text(xy[1:2, 1], xy[1:2, 2], fr(ft[1:2]), cex = 1)
text(xy[3, 1] - h[1] * 0.75, xy[3, 2] - h[2] - 0.0055, fr(ft[3]), cex = 1, col = acc, font = 2)
text(xy[3, 1] + h[1] * 0.35, xy[3, 2], fr(fc[3]), cex = 1, col = "#3E6B2F", font = 2)
text(xy[4, 1], xy[4, 2], fr(fc[4]), cex = 1)
text(mean(xy[1:2, 1]), win[3] - 0.009, "Tompkins", col = acc, font = 2, cex = 1)
text(xy[4, 1] - 0.003, win[3] - 0.009, "Cortland", col = "#3E6B2F", font = 2, cex = 1)
par(mar = c(0.2, 0.6, 0.2, 0.2))
plot.new(); plot.window(c(0, 1), c(0, 1))
tbl <- data.frame(row = c(1, 1, 1, 2, 2), col = c(1, 2, 3, 3, 4), val = c(ft[1:3], fc[3:4]))
yy <- 0.95 - (0:5) * 0.13
text(c(0.12, 0.45, 0.82), yy[1], c("row", "column", "value"), font = 2, cex = 1)
segments(0.0, yy[1] - 0.065, 0.98, yy[1] - 0.065, col = rule)
for (q in 1:5) text(c(0.12, 0.45, 0.82), yy[q + 1], c(tbl$row[q], tbl$col[q], fr(tbl$val[q])), cex = 1,
                    col = if (tbl$row[q] == 1) acc else "#3E6B2F")
text(0.0, 0.08, "row 1 = Tompkins, row 2 = Cortland\ncolumn k = the k-th of the four cells", adj = c(0, 0.5), cex = 0.85)
dev.off()
cat("  f11b: Tompkins", round(ft, 4), "; Cortland", round(fc, 4), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f12_monterey DEPS: agg ====
# Slide 36. Monterey County: each cell's July mean, with a dot sized by the people in the county's part of it.
popg <- project(rast(dpath("data_clean/pop_2010.tif")), tmax, method = "sum")
mo <- which(low$GEOID == "06053"); tm <- tabN[tabN$county == mo, ]
jm <- rowMeans(M[tm$cell, ]); pp <- tm$coverage_fraction * values(popg)[tm$cell]; pp[is.na(pp)] <- 0
xy <- xyFromCell(tmax, tm$cell); h <- res(tmax) / 2
brM <- c(13, 18, 21, 24, 27, 30, 33, 37); palM <- heatpal(7)
sh_cool <- 100 * c(people = sum(pp[jm < 24]) / sum(pp),
                   area = sum(tm$coverage_fraction[jm < 24]) / sum(tm$coverage_fraction))
bm <- which.max(values(popg)[tm$cell])
ca <- co[co$STUSPS == "CA", ]
xl <- c(-122.95, -120.15); yl <- c(35.72, 36.98)
fig("f12_monterey.png", 5.6, 4.2, ps = 13)
par(mar = c(0, 0, 0, 0))
mapwin(xl, yl, lat = 36.35); us <- par("usr")
rect(us[1], us[3], us[2], us[4], col = sea, border = NA)
plot(st_geometry(st_crop(ca, xmin = us[1] - 0.5, xmax = us[2] + 0.5, ymin = us[3] - 0.5, ymax = us[4] + 0.5)),
     col = land, border = "#9A9A9A", lwd = 0.8, add = TRUE)
rect(xy[, 1] - h[1], xy[, 2] - h[2], xy[, 1] + h[1], xy[, 2] + h[2], col = palM[findInterval(jm, brM, all.inside = TRUE)],
     border = NA)
plot(st_geometry(low[mo, ]), border = ink, lwd = 2, add = TRUE)
dc <- function(n) 0.25 + 2.6 * sqrt(n / 33418)
o <- order(-pp); keep <- pp[o] >= 50
points(xy[o[keep], ], pch = 21, bg = adjustcolor(ink, 0.55), col = "white", lwd = 0.6, cex = dc(pp[o[keep]]))
halo(xy[bm, 1] + 0.07, xy[bm, 2] + 0.05, sprintf("Salinas: %s people, %.1f °C", fmt(values(popg)[tm$cell][bm]), jm[bm]),
     adj = c(0, 0), cex = 0.9, font = 2)
halo(-122.02, 36.66, sprintf("the coast: cool,\n%.0f%% of the people", sh_cool[1]), adj = c(1, 0.5), cex = 0.95, font = 2)
halo(-120.72, 36.17, "inland: hot,\nmost of the land", cex = 0.95, font = 2)
halo(-121.02, 35.87, "Monterey County", font = 2, cex = 0.95)
lg <- legend(us[1] + 0.03, us[3] + 0.03, c("13.9 to 18", "18 to 21", "21 to 24", "24 to 27", "27 to 30", "30 to 33", "33 to 36.1"),
       fill = palM, border = NA, bg = "white", box.col = rule, cex = 0.82, title = "July mean, °C", title.adj = 0.1,
       y.intersp = 0.95, yjust = 0)
legend(lg$rect$left + lg$rect$w + 0.04, us[3] + 0.03, c("1,000", "10,000", "33,418"), pch = 21, pt.bg = adjustcolor(ink, 0.55),
       col = "white", pt.cex = dc(c(1000, 10000, 33418)), bg = "white", box.col = rule, cex = 0.82, title = "people in the cell",
       title.adj = 0.1, y.intersp = 1.35, x.intersp = 1.3, yjust = 0)
dev.off()
cat("  f12: cells", nrow(tm), "range", round(range(jm), 1), "; under 24 C:", round(sh_cool, 1),
    "; Salinas", round(values(popg)[tm$cell][bm]), round(jm[bm], 1), "; by area", round(sum(tm$w * jm), 1), "\n")
# ==== END BLOCK ====

# ==== BLOCK: corn DEPS: agg ====
# July 2012 heat over each county's cropland, and the 2012 corn yield against the 2002-2011 mean.
y    <- read.csv(dpath("data_clean/corn_yield_2002_2012.csv"), colClasses = c(GEOID = "character"))
yw   <- tapply(y$yield, list(y$GEOID, y$year), mean)
base <- rowMeans(yw[, as.character(2002:2011)], na.rm = TRUE)
nb   <- rowSums(!is.na(yw[, as.character(2002:2011)]))
chg  <- 100 * (yw[, "2012"] / base - 1); chg[nb < 8] <- NA
low$chg <- chg[match(low$GEOID, names(chg))]
heat  <- sum((tmax - 29) * (tmax > 29))
cropg <- project(rast(dpath("data_clean/cropland_2011.tif")), tmax, method = "average")
tabN$wc <- tabN$coverage_fraction * values(cropg)[tabN$cell]
tabN$wc <- tabN$wc / ave(tabN$wc, tabN$county, FUN = sum)
Pc <- sparseMatrix(i = tabN$county, j = tabN$cell, x = tabN$wc, dims = dim(Pm))
low$heat <- as.vector(Pc %*% values(heat))
lon <- suppressWarnings(st_coordinates(st_centroid(st_geometry(low)))[, 1])
d <- st_drop_geometry(low[!is.na(low$chg) & !is.na(low$heat) & lon > -100, ])
# ==== END BLOCK ====

# ==== BLOCK: f13_yield DEPS: corn ====
# Slide 39. Each county's 2012 corn yield against its own 2002-2011 mean; six state medians; Champaign County.
low_m <- st_transform(low, 5070); st_m <- st_transform(st48, 5070)
brY <- c(-100, -60, -40, -20, 0, 20, 1000)
palY <- c("#67000D", "#C0392B", "#F07B62", "#FCC5B0", "#C7E3B9", "#4E9A4C")
fl <- ifelse(is.na(low$chg), nodata, palY[findInterval(low$chg, brY, all.inside = TRUE)])
dd <- st_drop_geometry(low[!is.na(low$chg), ])
med <- round(tapply(dd$chg, dd$STUSPS, median)[c("MO", "KY", "IL", "IN", "IA", "MN")])
sn <- c(MO = "Missouri", KY = "Kentucky", IL = "Illinois", IN = "Indiana", IA = "Iowa", MN = "Minnesota")
ctr <- st_coordinates(suppressWarnings(st_point_on_surface(st_m[match(names(med), st_m$STUSPS), ])))[, 1:2, drop = FALSE]
# label positions (metres, EPSG:5070): offsets from each state's centre, with a leader where it moves
rownames(ctr) <- names(med)
off13 <- rbind(MO = c(-330000, -230000), KY = c(380000, -300000), IL = c(150000, 420000),
               IN = c(520000, 230000), IA = c(-40000, 20000), MN = c(0, 0))
lp <- ctr[, 1:2] + off13[names(med), ]
cp <- st_coordinates(suppressWarnings(st_point_on_surface(low_m[low_m$GEOID == "17019", ])))
bx <- st_bbox(st_m)
fig("f13_yield.png", 6.4, 3.9, ps = 13)
par(mar = c(0, 0, 0, 0))
plot.new(); plot.window(c(bx[1] - 1.75e6, bx[3] + 0.03e6), c(bx[2] - 0.45e6, bx[4] + 0.02e6), asp = 1, xaxs = "i", yaxs = "i")
plot(st_geometry(low_m), col = fl, border = NA, add = TRUE)
plot(st_geometry(st_m), col = NA, border = "#555555", lwd = 0.6, add = TRUE)
for (s in names(med)) {
  lb <- sprintf("%s %s%%", sn[s], sub("-", "−", sprintf("%+d", med[[s]])))
  if (any(off13[s, ] != 0) && !s %in% "IA") segments(ctr[s, 1], ctr[s, 2], lp[s, 1], lp[s, 2], col = ink, lwd = 1)
  halo(lp[s, 1], lp[s, 2], lb, cex = 0.85, font = 2, r = 0.012)
}
points(cp, pch = 21, bg = "white", col = ink, cex = 1.1, lwd = 1.6)
ly <- bx[2] - 0.2e6
segments(cp[1], cp[2], cp[1], ly + 0.1e6, col = ink)
text(bx[3], ly - 0.03e6, sprintf("Champaign County, Illinois:\n%.1f to %.1f bushels per acre, %s%%",
     base[["17019"]], yw["17019", "2012"], sub("-", "−", sprintf("%.0f", chg[["17019"]]))), adj = c(1, 0.5), cex = 0.85)
us <- par("usr")
legend(us[1] + 0.04e6, us[4] - 0.06e6, c("60% lower or more", "40 to 60% lower", "20 to 40% lower", "0 to 20% lower",
       "0 to 20% higher", "20% higher or more", "not in the 1,508"), fill = c(palY, nodata), border = NA, bg = "white",
       box.col = rule, cex = 0.82, title = "2012 corn yield against\nthe 2002-2011 mean", title.adj = 0.1, y.intersp = 1.0)
dev.off()
cat("  f13: counties", sum(!is.na(low$chg)), "; medians", med, "; Champaign", round(base[["17019"]], 1),
    round(yw["17019", "2012"], 1), round(chg[["17019"]], 1), "; median all", round(median(dd$chg), 1), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f14_heat DEPS: corn ====
# Slide 40. Degree days above 29 °C: Warren Hall's 31 days as bars, then the national map of July's total.
xw <- unlist(extract(tmax, whv, ID = FALSE))
hw <- extract(heat, whv, ID = FALSE)[1, 1]
brH <- c(0, 1e-6, 25, 50, 100, 200, 300, 556); palH <- c("#F4F1E8", heatpal(7)[2:7])
e <- as.vector(ext(tmax))
fig("f14_heat.png", 5.4, 5.6, ps = 13)
layout(matrix(1:2, 2), heights = c(2.25, 3.35))
par(mar = c(2.0, 3.1, 1.7, 0.4), las = 1, mgp = c(1.6, 0.45, 0), tcl = -0.3)
plot(NA, xlim = c(0.4, 31.6), ylim = c(15, 43), xaxs = "i", yaxs = "i", axes = FALSE, xlab = "", ylab = "")
rect(1:31 - 0.4, 15, 1:31 + 0.4, pmin(xw, 29), col = "#CFC8BD", border = NA)
rect(1:31 - 0.4, 29, 1:31 + 0.4, pmax(xw, 29), col = acc, border = NA)
segments(0.4, 29, 31.6, 29, lty = 2, col = ink)
axis(1, at = c(1, 10, 17, 20, 31), labels = c("1", "10", "17", "20", "31"), col = rule, col.ticks = rule, cex.axis = 0.9)
axis(2, at = c(15, 20, 25, 29, 35), col = rule, col.ticks = rule, cex.axis = 0.9)
mtext("July 2012, layer date", side = 1, line = 1.15, cex = 0.85)
mtext("Warren Hall's cell, maximum °C", side = 3, line = 0.55, adj = 0, at = -2.6, cex = 0.9, font = 2)
dd3 <- pmax(xw - 29, 0)[17:19]
text(16.6, 38.4, sprintf("17 July: %.1f", dd3[1]), adj = c(1, 0.5), cex = 0.85)
text(18, 41.4, sprintf("18 July: %.1f", dd3[2]), adj = c(0.5, 0.5), cex = 0.85)
text(19.4, 38.4, sprintf("19 July: %.1f", dd3[3]), adj = c(0, 0.5), cex = 0.85)
segments(c(16.4, 18, 19.6), c(37.5, 40.5, 37.5), c(17, 18, 19), c(xw[17] + 0.4, xw[18] + 0.4, xw[19] + 0.4), col = grey)
text(31.4, 41.4, sprintf("total %.1f", sum(pmax(xw - 29, 0))), adj = 1, cex = 0.95, font = 2, col = acc)
par(mar = c(0, 0, 0.2, 0))
mapwin(c(e[1], e[2]), c(e[3] - 8.8, e[4]), lat = 37)
rimg(heat, palH, brH)
plot(st_geometry(st48), border = "white", lwd = 0.5, add = TRUE)
points(wh, pch = 21, bg = "white", col = ink, cex = 0.9, lwd = 1.4)
hx <- xyFromCell(heat, which.max(values(heat)))
points(hx, pch = 21, bg = "white", col = ink, cex = 0.9, lwd = 1.4)
halo(hx[1] + 0.8, hx[2] - 1.4, "Death Valley, 555", adj = c(0.5, 1), cex = 0.85, font = 2)
halo(wh[1], wh[2] + 1.1, sprintf("Warren Hall, %.1f", hw), adj = c(0.5, 0), cex = 0.85, font = 2)
legend(e[1] + 0.3, par("usr")[3] + 0.2, yjust = 0, c("0", "up to 25", "25 to 50", "50 to 100", "100 to 200", "200 to 300", "300 to 555"),
       fill = palH, border = rule, bg = "white", box.col = rule, cex = 0.82, ncol = 4, x.intersp = 0.5,
       title = "Degree days above 29 °C, July 2012", title.adj = 0.03)
dev.off()
cat("  f14: range", round(range(values(heat), na.rm = TRUE)), "; Warren Hall", round(hw, 1), "; 17-19 July", round(dd3, 1),
    "; hottest at", round(hx, 2), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f15_scatter DEPS: corn ====
# Slide 43. Heat over cropland against the yield change, one dot per county east of the 100th meridian.
fit <- lm(chg ~ heat, d)
mh <- tapply(d$heat, d$STUSPS, median); mc <- tapply(d$chg, d$STUSPS, median)
ss <- c(MO = "Missouri", IL = "Illinois", IA = "Iowa", MN = "Minnesota")
cha <- d[d$GEOID == "17019", ]
fig("f15_scatter.png", 5.6, 4.3, mar = c(3.2, 3.4, 1.6, 0.8), ps = 13)
par(las = 1, bty = "n", mgp = c(2.0, 0.55, 0), tcl = -0.3)
yl <- c(-100, max(d$chg) + 5)
plot(d$heat, d$chg, pch = 16, cex = 0.55, col = adjustcolor("#8A8A8A", 0.55), xlab = "", ylab = "",
     xlim = c(0, 320), ylim = yl, axes = FALSE)
axis(1, at = seq(0, 300, 50), col = rule, col.ticks = rule, cex.axis = 0.9)
axis(2, at = seq(-100, 100, 50), labels = sub("-", "−", seq(-100, 100, 50)), col = rule, col.ticks = rule, cex.axis = 0.9)
abline(h = 0, col = ink, lty = 3, xpd = FALSE)
clip(0, 320, yl[1], yl[2]); abline(fit, col = acc, lwd = 3); unclip()
mtext("Degree days above 29 °C over cropland, July 2012", side = 1, line = 2.0, cex = 0.9)
mtext("2012 yield against the 2002-2011 mean, %", side = 3, line = 0.45, adj = 0, at = -40, cex = 0.9)
points(cha$heat, cha$chg, pch = 21, bg = "white", col = ink, cex = 1.1, lwd = 1.6)
segments(cha$heat, cha$chg - 3, cha$heat, -86, col = ink)
halo(cha$heat, -92, sprintf("Champaign, Illinois (%.0f, −%.0f%%)", cha$heat, abs(cha$chg)), adj = c(0.5, 0.5), cex = 0.85)
pos <- rbind(MN = c(6, 12, 0), IA = c(-6, -12, 1), IL = c(-6, -15, 1), MO = c(6, -14, 0))
for (s in names(ss)) {
  points(mh[s], mc[s], pch = 21, bg = ink, col = "white", cex = 2.0, lwd = 1.5)
  halo(mh[s] + pos[s, 1], mc[s] + pos[s, 2], sprintf("%s (%.0f, %s%.0f)", ss[s], mh[s], ifelse(mc[s] > 0, "+", "−"),
       abs(mc[s])), adj = c(pos[s, 3], 0.5), cex = 0.85, font = 2)
}
legend("topright", c("a county", "a state's median county", "fitted line"), pch = c(16, 21, NA), lty = c(NA, NA, 1),
       lwd = c(NA, 1.5, 3), col = c("#8A8A8A", "white", acc), pt.bg = c(NA, ink, NA), pt.cex = c(0.8, 1.6, NA),
       bg = "white", box.col = rule, cex = 0.82, inset = c(0, 0), seg.len = 1.6)
dev.off()
cat("  f15: n", nrow(d), "cor", round(cor(d$heat, d$chg), 3), "slope", round(coef(fit)[2], 3), "R2",
    round(summary(fit)$r.squared, 3), "; heat", round(range(d$heat)), "; chg", round(range(d$chg)), "; MO IL IA MN",
    round(mh[names(ss)]), round(mc[names(ss)]), "; Champaign", round(cha$heat, 1), round(cha$chg, 1), "\n")
# ==== END BLOCK ====

# ==== BLOCK: eaton DEPS: co_us ====
# The Eaton fire on 9 January 2025: NASA's Terra picture, ERA5's wind at the fire, the cells downwind.
img  <- rast(dpath("data/nasa/worldview_terra_20250109.tif"))
fire <- vect(cbind(-118.069155, 34.203483), crs = "EPSG:4326"); f0 <- crds(fire)
u <- rast(dpath("data_clean/u10_la_20250109.tif")); v <- rast(dpath("data_clean/v10_la_20250109.tif"))
uf <- extract(u[["18:00"]], fire, ID = FALSE)[1, 1]; vf <- extract(v[["18:00"]], fire, ID = FALSE)[1, 1]
to <- (atan2(uf, vf) * 180 / pi) %% 360; from <- (atan2(-uf, -vf) * 180 / pi) %% 360; kmh <- sqrt(uf^2 + vf^2) * 3.6
people <- crop(rast(dpath("data_clean/pop_2010.tif")), img)
km   <- values(distance(people, fire))[, 1] / 1000
xy   <- xyFromCell(people, 1:ncell(people))
east <- (xy[, 1] - f0[1]) * cos(f0[2] * pi / 180); north <- xy[, 2] - f0[2]
bear <- (atan2(east, north) * 180 / pi) %% 360
down <- km <= 100 & abs((bear - to + 180) %% 360 - 180) <= 20
dwr  <- rast(people); values(dwr) <- ifelse(down, 1, NA)
rgbm <- as.array(img[[1:3]]) / 255
ie   <- as.vector(ext(img))
lac  <- co[co$STUSPS == "CA" & co$NAME %in% c("Los Angeles", "Orange", "Ventura", "San Bernardino", "Riverside", "Kern"), ]
pl   <- rbind(downtown = c(-118.2427, 34.0537), pasadena = c(-118.1445, 34.1478), long_beach = c(-118.1937, 33.7701))
photo <- function(xl = ie[1:2], yl = ie[3:4]) {
  mapwin(xl, yl, lat = 34)
  rasterImage(as.raster(rgbm), ie[1], ie[3], ie[2], ie[4], interpolate = TRUE)
  clip(xl[1], xl[2], yl[1], yl[2])
  plot(st_geometry(lac), border = adjustcolor("white", 0.55), lwd = 0.8, add = TRUE)
}
lab <- function(x, y, s, ...) halo(x, y, s, col = "white", bg = "black", r = 0.012, ...)
# ==== END BLOCK ====

# ==== BLOCK: co_us ====
co <- st_read(paste0("/vsizip/", dpath("data/census/cb_2024_us_county_500k.zip")), quiet = TRUE)
# ==== END BLOCK ====

# ==== BLOCK: f16_eaton DEPS: co_us,eaton ====
# Slide 46. NASA's Terra picture of the Los Angeles basin on the morning of 9 January 2025, with four labels.
fig("f16_eaton.png", 6.0, 4.83, ps = 13)
photo()
points(fire, pch = 21, bg = acc, col = "white", cex = 1.6, lwd = 1.5)
lab(f0[1] + 0.06, f0[2] + 0.06, "Eaton fire", adj = 0, font = 2, cex = 1.05)
lab(-118.6, 34.15, "Palisades fire", adj = 0.5, font = 2, cex = 1.05)
points(pl["downtown", 1], pl["downtown", 2], pch = 21, bg = "white", col = "black", cex = 0.9)
lab(pl["downtown", 1] + 0.04, pl["downtown", 2] - 0.02, "downtown\nLos Angeles", adj = c(0, 1), cex = 0.95)
lab(-119.05, 33.55, "Pacific Ocean", font = 3, cex = 1.05)
lab(ie[2] - 0.03, ie[3] + 0.04, "NASA Worldview, MODIS on Terra", adj = c(1, 0), cex = 0.8)
unclip()
legend("bottomleft", "where the Eaton fire started", pch = 21, pt.bg = acc, col = "white", pt.cex = 1.6, pt.lwd = 1.5,
       bg = "white", box.col = rule, cex = 0.82, inset = 0.015)
dev.off()
cat("  f16: picture", dim(img), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f17_windfire DEPS: co_us,eaton ====
# Slide 47. The picture near the fire, the wind cell that holds the fire, and the wind's arrow.
cu <- xyFromCell(u, cellFromXY(u, f0))
xl <- c(-118.48, -117.72); yl <- c(33.93, 34.45)
tail <- dest(f0[1], f0[2], 13, from); head <- dest(f0[1], f0[2], 17, to)
fig("f17_windfire.png", 5.6, 4.4, ps = 13)
photo(xl, yl)
rect(cu[1] - 0.125, cu[2] - 0.125, cu[1] + 0.125, cu[2] + 0.125, border = "#FFD84D", lwd = 3)
arrows(tail[1], tail[2], head[1], head[2], col = "white", lwd = 6.5, length = 0.16)
arrows(tail[1], tail[2], head[1], head[2], col = acc, lwd = 3.6, length = 0.15)
points(fire, pch = 21, bg = acc, col = "white", cex = 1.8, lwd = 1.6)
lab(f0[1] + 0.025, f0[2] + 0.012, "Eaton fire", adj = 0, font = 2, cex = 1)
lab(tail[1] + 0.012, tail[2] + 0.012, sprintf("from %.0f°", from), adj = c(0, 0), font = 2, cex = 1)
lab(head[1] + 0.02, head[2] - 0.005, sprintf("toward %.0f°", to), adj = c(0, 1), font = 2, cex = 1)
mid <- dest(f0[1], f0[2], 12, to)
lab(mid[1] + 0.025, mid[2], sprintf("%.1f km/h", kmh), adj = c(0, 0.5), font = 2, cex = 1.1)
for (p in c("downtown", "pasadena")) points(pl[p, 1], pl[p, 2], pch = 21, bg = "white", col = "black", cex = 0.9)
lab(pl["pasadena", 1] - 0.015, pl["pasadena", 2] + 0.012, "Pasadena", adj = c(1, 0), cex = 0.95)
lab(pl["downtown", 1] - 0.015, pl["downtown", 2], "downtown\nLos Angeles", adj = c(1, 0.5), cex = 0.95)
unclip()
legend(xl[1] + 0.005, yl[2] - 0.005, c("the wind cell that holds the fire", "where the fire started"),
       pch = c(22, 21), pt.bg = c(NA, acc), col = c("#FFD84D", "white"), pt.cex = c(2.2, 1.6), pt.lwd = c(2.5, 1.5),
       bg = "white", box.col = rule, cex = 0.82, inset = 0)
dev.off()
cat("  f17: wind cell centre", cu, "; u", round(uf, 2), "v", round(vf, 2), "km/h", round(kmh, 1), "from", round(from, 1),
    "toward", round(to, 1), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f18_geometry DEPS: co_us,eaton ====
# Slide 48. The downwind rule drawn on a plain map: the wind's direction, 20 degrees each side, 100 km.
xl <- c(-119.3, -117.45); yl <- c(33.22, 34.45)
ca <- co[co$STUSPS == "CA", ]
bw <- seq(to - 20, to + 20, length.out = 60)
wedge <- rbind(f0, dest(f0[1], f0[2], 100, bw), f0)
gp <- function(b) abs((b - to + 180) %% 360 - 180)
pk <- t(sapply(rownames(pl), function(p) {
  e1 <- (pl[p, 1] - f0[1]) * cos(f0[2] * pi / 180); n1 <- pl[p, 2] - f0[2]; b <- (atan2(e1, n1) * 180 / pi) %% 360
  unname(c(distance(fire, vect(matrix(pl[p, ], 1), crs = "EPSG:4326"))[1, 1] / 1000, b, gp(b)))
})); colnames(pk) <- c("km", "bear", "gap")
fig("f18_geometry.png", 5.6, 4.5, ps = 13)
par(mar = c(0, 0, 0, 0))
mapwin(xl, yl, lat = 33.85)
rect(par("usr")[1], par("usr")[3], par("usr")[2], par("usr")[4], col = sea, border = NA)
plot(st_geometry(st_crop(ca, xmin = xl[1] - 0.3, xmax = xl[2] + 0.3, ymin = yl[1] - 0.3, ymax = yl[2] + 0.3)),
     col = land, border = "#A0A0A0", lwd = 0.8, add = TRUE)
polygon(wedge, col = adjustcolor(amber, 0.35), border = NA)
for (b in c(to - 20, to + 20)) { q <- dest(f0[1], f0[2], 100, b); segments(f0[1], f0[2], q[1], q[2], col = ink, lty = 2, lwd = 1.4) }
lines(dest(f0[1], f0[2], 100, bw), col = ink, lwd = 1.4, lty = 2)
ah <- dest(f0[1], f0[2], 62, to)
arrows(f0[1], f0[2], ah[1], ah[2], col = acc, lwd = 3.4, length = 0.13)
halo(ah[1] - 0.03, ah[2] - 0.03, sprintf("wind toward %.0f°", to), col = acc, adj = c(0.5, 1), font = 2, cex = 0.9)
q <- dest(f0[1], f0[2], 101, to + 20); halo(q[1] - 0.02, q[2], "20°\nto each side", adj = c(1, 0.5), cex = 0.85)
q <- dest(f0[1], f0[2], 104, to - 6); halo(q[1], q[2] - 0.01, "100 km", adj = c(0.5, 1), cex = 0.85)
points(fire, pch = 21, bg = acc, col = "white", cex = 1.6, lwd = 1.5)
halo(f0[1] + 0.03, f0[2] + 0.04, "Eaton fire", adj = c(0, 0.5), font = 2, cex = 0.95)
points(pl[, 1], pl[, 2], pch = 21, bg = ink, col = "white", cex = 1.1, lwd = 1.2)
L <- function(p) sprintf("%.0f km, %.0f°\n%.0f° from the wind", pk[p, "km"], pk[p, "bear"], pk[p, "gap"])
segments(pl["pasadena", 1], pl["pasadena", 2], -117.93, 34.04, col = ink, lwd = 0.8)
halo(-117.925, 34.04, paste0("Pasadena\n", L("pasadena")), adj = c(0, 0.5), cex = 0.82)
halo(pl["downtown", 1] - 0.03, pl["downtown", 2] + 0.03, paste0("downtown Los Angeles\n", L("downtown")),
     adj = c(1, 0), cex = 0.82)
halo(pl["long_beach", 1] + 0.035, pl["long_beach", 2] - 0.005, paste0("Long Beach, outside\n", L("long_beach")),
     adj = c(0, 1), cex = 0.82)
halo(-119.0, 33.5, "Pacific Ocean", font = 3, cex = 0.9, col = "#3D5A73")
legend("topleft", "within 100 km and 20°\nof the wind's direction", fill = adjustcolor(amber, 0.35), border = NA,
       bg = "white", box.col = rule, cex = 0.82, inset = c(0.01, 0.015))
dev.off()
cat("  f18: toward", round(to, 1), ";", apply(round(pk), 1, paste, collapse = "/"), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f19_downwind DEPS: co_us,eaton ====
# Slide 50. The 194 downwind cells outlined over the picture, with both fires labelled.
fig("f19_downwind.png", 6.0, 4.83, ps = 13)
photo()
plot(as.polygons(dwr), add = TRUE, border = "#FFD84D", lwd = 2.6)
points(fire, pch = 21, bg = acc, col = "white", cex = 1.6, lwd = 1.5)
lab(f0[1] + 0.06, f0[2] + 0.06, "Eaton fire", adj = 0, font = 2, cex = 1.05)
lab(-118.6, 34.15, "Palisades fire", adj = 0.5, font = 2, cex = 1.05)
lab(-118.43, 33.30, "Santa Catalina\nIsland", adj = c(1, 0.5), cex = 0.9)
unclip()
legend("bottomright", c("the 194 downwind cells", "where the Eaton fire started"), pch = c(22, 21),
       pt.bg = c(NA, acc), col = c("#FFD84D", "white"), pt.cex = c(2.2, 1.6), pt.lwd = c(2.5, 1.5),
       bg = "white", box.col = rule, cex = 0.82, inset = 0.015)
dev.off()
cat("  f19: wind toward", round(to, 1), "; downwind cells", sum(down), "; on land", sum(down & !is.na(values(people)[, 1])),
    "; people", round(sum(values(people)[down, 1], na.rm = TRUE)), "\n")
# ==== END BLOCK ====
