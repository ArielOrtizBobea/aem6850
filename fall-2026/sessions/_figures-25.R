# Figures for the session 25 page and slides (LiDAR & drone imagery).
# Base R, terra and lidR. Run from fall-2026/sessions:
#   Rscript _figures-25.R              # every block
#   Rscript _figures-25.R f02_side     # setup, then one block (and its DEPS)
# Writes figures/25-lidar-drones/<block>.png. Inputs: data/25-lidar-drones/ (the session project,
# after its tools/make_lidar.R has built data_clean/lidar/).
# Drawn at res 200. A figure W inches wide shown at about 100 * W px on the 1050 x 700 slide
# keeps its point sizes; every label is 10.5 pt or more at that width.

# ---- Run named blocks only: Rscript _figures-25.R <block> [<block> ...] ----
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
suppressPackageStartupMessages({library(terra); library(lidR)})
options(lidR.progress = FALSE)
out <- "figures/25-lidar-drones"; dat <- "data/25-lidar-drones"
dir.create(out, showWarnings = FALSE, recursive = TRUE)
ink <- "#222222"; acc <- "#B31B1B"; grey <- "#666666"; light <- "#E4E2DC"; rule <- "#BBBBBB"
blue <- "#3A6C9C"; amber <- "#E6A700"; red <- "#C0392B"; teal <- "#2A9D8F"
land <- "#F1EFEA"; sea <- "#CFE0EC"; nodata <- "#E3E3E3"
brown <- "#8B5A2B"; sky <- "#EAF2F8"; leaf <- "#5E8C4A"
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
# a vertical colour key: equal boxes, labels to the right of the box edges ("" skips one)
vkey <- function(x0, y0, y1, w, pal, lab, title, cex = 1) {
  n <- length(pal); ys <- seq(y0, y1, length.out = n + 1)
  rect(x0, ys[-(n + 1)], x0 + w, ys[-1], col = pal, border = NA)
  rect(x0, y0, x0 + w, y1, border = rule)
  k <- lab != ""
  segments(x0 + w, ys[k], x0 + w + xinch(0.06), ys[k], col = ink)
  text(x0 + w + xinch(0.1), ys[k], lab[k], adj = c(0, 0.5), cex = cex)
  text(x0, y1 + yinch(0.25), title, adj = c(0, 0.5), cex = cex, font = 2)
}
fmt <- function(x, d = 0) formatC(x, format = "f", digits = d, big.mark = ",")

# the campus box, McGraw Tower and the Arts Quad lawn point (EPSG:6347 metres; from tools/make_lidar.R)
box   <- c(xmin = 377600, ymin = 4700350, xmax = 378200, ymax = 4700950)
tower <- c(377876.1, 4700539.6)
lawn  <- c(377964.8, 4700674.7)
dtm <- rast(dpath("data_clean/lidar/campus_dtm.tif"))
dsm <- rast(dpath("data_clean/lidar/campus_dsm.tif"))
hgt <- rast(dpath("data_clean/lidar/campus_height.tif"))
# one colour scale for height above ground, used by every height map
brH  <- c(-3.5, 1, 3, 6, 10, 15, 20, 25, 30, 40, 51)
palH <- hcl.colors(10, "viridis")
labH <- c("", "1", "3", "6", "10", "15", "20", "25", "30", "40", "51")
# ==== END BLOCK ====

# ==== BLOCK: f01_pulse ====
# One laser pulse: the plane sends it down, the treetop sends back the first return, the ground the last.
# The tile metadata (data/lidar/*.xml) does not state the flying height, so 1,500 m is an example.
c0 <- 300000000                                   # speed of light, m/s (299,792,458, rounded)
H  <- 1500; tree <- 30                            # example flying height and tree height, m
t_first <- 2 * (H - tree) / c0; t_last <- 2 * H / c0
fig("f01_pulse.png", 9, 5, ps = 14)
plot.new(); plot.window(c(0, 9), c(0, 5), xaxs = "i", yaxs = "i")
# ground and tree
rect(0.25, 0.35, 4.6, 0.75, col = "#D9C6A5", border = NA)
segments(0.25, 0.75, 4.6, 0.75, col = brown, lwd = 2)
rect(2.53, 0.75, 2.67, 1.5, col = brown, border = NA)
symbols(2.6, 1.95, circles = 0.55, inches = FALSE, add = TRUE, bg = leaf, fg = NA)
# the plane, seen from the side
px <- 2.55; py <- 4.4
polygon(px + c(-0.75, 0.65, 0.85, 0.65, -0.75, -0.9), py + c(-0.1, -0.1, 0, 0.1, 0.1, 0.3), col = "#55606B", border = NA)
polygon(px + c(-0.15, 0.25, 0.05, -0.35), py + c(0.02, 0.02, -0.38, -0.38), col = "#3E4750", border = NA)
text(px - 1.05, py + 0.05, "Plane", font = 2, adj = c(1, 0.5))
# the pulse going down, and the two returns coming back
arrows(2.6, 4.2, 2.6, 2.58, length = 0.13, lwd = 2.4, col = red)
segments(2.6, 2.5, 2.6, 0.8, lwd = 2.4, col = red, lty = 2)
arrows(2.33, 2.55, 2.33, 4.2, length = 0.13, lwd = 2.4, col = blue)
arrows(2.87, 0.8, 2.87, 4.2, length = 0.13, lwd = 2.4, col = teal)
points(c(2.6, 2.6), c(2.5, 0.77), pch = 21, bg = "white", col = ink, cex = 1.4, lwd = 1.6)
text(2.2, 3.7, "Pulse", col = red, font = 2, adj = c(1, 0.5))
text(2.2, 2.85, "First return:\nthe treetop", adj = c(1, 0.5), col = blue, font = 2)
text(3.0, 1.0, "Last return:\nthe ground", adj = c(0, 0.5), col = teal, font = 2)
# flying height
arrows(0.45, 4.3, 0.45, 0.8, code = 3, length = 0.1, col = ink, lwd = 1.2)
text(0.6, 1.5, paste0("Flying height\n", fmt(H), " m\n(example)"), adj = c(0, 0.5), cex = 0.95)
# the arithmetic
segments(5.0, 0.45, 5.0, 4.6, col = rule)
text(5.3, 4.35, "Distance = speed of light × time ÷ 2", adj = 0, font = 2, cex = 1.05)
text(5.3, 3.9, "The time is out and back, so it is halved.", adj = 0, cex = 0.95)
text(5.3, 3.25, "First return (treetop)", adj = 0, font = 2, col = blue)
text(5.3, 2.85, sprintf("300,000,000 m/s × %s s ÷ 2", formatC(t_first, format = "f", digits = 7)), adj = 0, cex = 0.95)
text(5.3, 2.47, paste0("= ", fmt(c0 * t_first / 2), " m"), adj = 0, cex = 0.95, font = 2)
text(5.3, 1.85, "Last return (ground)", adj = 0, font = 2, col = teal)
text(5.3, 1.45, sprintf("300,000,000 m/s × %s s ÷ 2", formatC(t_last, format = "f", digits = 7)), adj = 0, cex = 0.95)
text(5.3, 1.07, paste0("= ", fmt(c0 * t_last / 2), " m"), adj = 0, cex = 0.95, font = 2)
text(5.3, 0.5, paste0("Tree height = ", fmt(H), " − ", fmt(H - tree), " = ", tree, " m"), adj = 0, font = 2)
dev.off()
cat("  f01: times", t_first, t_last, "; distances", c0 * t_first / 2, c0 * t_last / 2, "\n")
# ==== END BLOCK ====

# ==== BLOCK: f02_side ====
# The real points in a 10 m wide west-east strip through McGraw Tower, ground against everything else.
# Panel a is a map of the 600 m square with the strip drawn on it; panel b is the strip seen from the south.
las <- readLAS(dpath("data_clean/lidar/campus.laz"), select = "xyzc", filter = "-drop_class 7 18")
st  <- filter_poi(las, abs(Y - tower[2]) < 5)
d   <- data.frame(x = st$X - box[["xmin"]], z = st$Z, c = st$Classification)
d   <- d[order(d$c == 2), ]                      # ground drawn last, on top
ve  <- 2                                          # vertical exaggeration
fig("f02_side.png", 11, 4.3, ps = 13)
layout(matrix(1:2, 1), widths = c(3.5, 7.5)); par(cex = 1)
# a. where the strip is
par(mar = c(0.4, 0.4, 1.9, 0.6))
plot.new(); plot.window(c(box[["xmin"]], box[["xmax"]]), c(box[["ymin"]], box[["ymax"]]), asp = 1, xaxs = "i", yaxs = "i")
rimg(hgt, palH, brH)
rect(box[["xmin"]], box[["ymin"]], box[["xmax"]], box[["ymax"]], border = rule)
segments(box[["xmin"]], tower[2], box[["xmax"]], tower[2], col = "white", lwd = 5)
segments(box[["xmin"]], tower[2], box[["xmax"]], tower[2], col = acc, lwd = 2.6)
halo(box[["xmin"]] + 18, tower[2] - 26, "West", adj = c(0, 0.5), font = 2, cex = 0.95)
halo(box[["xmax"]] - 18, tower[2] - 26, "East", adj = c(1, 0.5), font = 2, cex = 0.95)
halo(mean(box[c("xmin", "xmax")]) + 150, tower[2] + 30, "The strip", font = 2, col = acc)
symbols(tower[1], tower[2], circles = 11, inches = FALSE, add = TRUE, fg = "white", lwd = 3.5)
symbols(tower[1], tower[2], circles = 11, inches = FALSE, add = TRUE, fg = ink, lwd = 1.6)
halo(tower[1] + 4, tower[2] - 62, "McGraw Tower", font = 2, cex = 0.95)
halo(377930, 4700740, "Arts Quad", font = 2, cex = 0.95)
rect(box[["xmin"]] + 25, box[["ymin"]] + 25, box[["xmin"]] + 125, box[["ymin"]] + 33, col = "white", border = ink)
halo(box[["xmin"]] + 75, box[["ymin"]] + 55, "100 m", font = 2, cex = 0.95)
mtext("a", side = 3, line = 0.4, adj = 0, font = 2, cex = 1.35)
mtext("Where the strip is", side = 3, line = 0.4, font = 2, cex = 1.05)
# b. the strip seen from the south
par(mar = c(3.2, 4.2, 1.9, 0.8), las = 1, mgp = c(2.2, 0.5, 0), tcl = -0.3)
plot.new(); plot.window(c(0, 600), c(203, 305), asp = ve, xaxs = "i", yaxs = "i")
points(d$x, d$z, pch = 16, cex = 0.18, col = ifelse(d$c == 2, brown, adjustcolor(teal, 0.7)))
axis(1, at = seq(0, 600, 100), col = rule, col.ticks = rule)
axis(2, at = seq(210, 300, 20), col = rule, col.ticks = rule)
box(col = rule)
mtext("Metres east along the strip", side = 1, line = 2.0)
mtext(paste0("Elevation (m), vertical scale × ", ve), side = 2, line = 3.0, las = 0)
tx <- tower[1] - box[["xmin"]]
# direct labels with thin leader lines
text(tx + 14, 298, "McGraw Tower", adj = c(0, 0.5), font = 2)
segments(tx + 12, 298, tx + 3, 295, col = ink, lwd = 0.8)
text(205, 284, "Uris Library", adj = c(0.5, 0), font = 2)
segments(215, 283, 243, 260, col = ink, lwd = 0.8)
text(80, 240, "Libe Slope", adj = c(0.5, 0), font = 2)
segments(84, 239, 95, 219.5, col = ink, lwd = 0.8)
text(140, 262, "Trees", adj = c(0.5, 0), font = 2)
segments(142, 261, 148, 243, col = ink, lwd = 0.8)
text(430, 286, "Trees", adj = c(0.5, 0), font = 2)
segments(425, 285, 404, 269, col = ink, lwd = 0.8)
legend("bottomright", c("Ground points (class 2)", "Other points (class 1)"), pch = 15, col = c(brown, teal),
       pt.cex = 1.8, bg = "white", box.col = rule, inset = c(0.012, 0.05))
mtext("b", side = 3, line = 0.4, adj = 0, font = 2, cex = 1.35)
mtext("The points in the strip, seen from the south", side = 3, line = 0.4, font = 2, cex = 1.05)
dev.off()
cat("  f02:", nrow(d), "points; ground", sum(d$c == 2), "; top", round(max(d$z), 2), "at x", round(d$x[which.max(d$z)], 1), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f03_three_grids ====
# Ground, surface and height above ground, side by side on the same 600 x 600 m box.
brG <- seq(205, 265, 5); palG <- hcl.colors(12, "Terrain 2")
brS <- seq(205, 305, 10); palS <- hcl.colors(10, "Lajolla", rev = TRUE)
labG <- c("205", "", "215", "", "225", "", "235", "", "245", "", "255", "", "265")
labS <- c("205", "", "225", "", "245", "", "265", "", "285", "", "305")
g  <- list(dtm, dsm, hgt); br <- list(brG, brS, brH); pal <- list(palG, palS, palH); lab <- list(labG, labS, labH)
nm <- c("Ground", "Surface", "Height above ground")
kt <- c("Ground elevation, m", "Surface elevation, m", "Height above ground, m")
fig("f03_three_grids.png", 14, 5.2, ps = 12)
layout(matrix(1:3, 1)); par(cex = 1)            # layout() with 3 columns would shrink text to 0.66
for (k in 1:3) {
  par(mar = c(0.2, 0.35, 0.5, 0.35))
  plot.new(); plot.window(c(box[["xmin"]] - 40, box[["xmax"]] + 40), c(box[["ymin"]] - 150, box[["ymax"]] + 70), asp = 1,
                          xaxs = "i", yaxs = "i")
  rimg(g[[k]], pal[[k]], br[[k]])
  rect(box[["xmin"]], box[["ymin"]], box[["xmax"]], box[["ymax"]], border = rule)
  text(mean(box[c(1, 3)]), box[["ymax"]] + 35, nm[k], font = 2, cex = 1.3)
  text(box[["xmin"]], box[["ymax"]] + 35, letters[k], font = 2, cex = 1.6, adj = c(0, 0.5))
  symbols(tower[1], tower[2], circles = 12, inches = FALSE, add = TRUE, fg = "white", lwd = 3.5)
  symbols(tower[1], tower[2], circles = 12, inches = FALSE, add = TRUE, fg = acc, lwd = 1.8)
  halo(tower[1] + 22, tower[2] - 14, "McGraw Tower", adj = c(0, 1), font = 2, cex = 1.05)
  hkey(box[["xmin"]] + 25, box[["xmax"]] - 25, box[["ymin"]] - 92, 22, pal[[k]], lab[[k]], kt[k], cex = 1, padx = 18)
}
dev.off()
cat("  f03: ground", round(unlist(global(dtm, range)), 1), "; surface", round(unlist(global(dsm, range)), 1),
    "; height", round(unlist(global(hgt, range)), 1), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f04_height_map ====
# The height grid alone, with the places the slides name.
fig("f04_height_map.png", 5.6, 4.6, ps = 12)        # small canvas, so the labels read at the slide's 370 px
par(mar = c(0.3, 0.3, 0.3, 0.3))
plot.new(); plot.window(c(box[["xmin"]] - 10, box[["xmax"]] + 170), c(box[["ymin"]] - 10, box[["ymax"]] + 10), asp = 1,
                        xaxs = "i", yaxs = "i")
rimg(hgt, palH, brH)
rect(box[["xmin"]], box[["ymin"]], box[["xmax"]], box[["ymax"]], border = rule)
# the places
symbols(tower[1], tower[2], circles = 9, inches = FALSE, add = TRUE, fg = "white", lwd = 3.5)
symbols(tower[1], tower[2], circles = 9, inches = FALSE, add = TRUE, fg = acc, lwd = 1.8)
halo(tower[1] + 14, tower[2] - 12, "McGraw Tower", adj = c(0, 1), font = 2)
segments(377800, 4700612, 377842, 4700566, col = "white", lwd = 1.6)
halo(377800, 4700616, "Uris Library", adj = c(0.5, 0), font = 2)
halo(377930, 4700730, "Arts Quad", font = 2)
halo(377705, 4700505, "Libe Slope", font = 2)
points(lawn[1], lawn[2], pch = 3, cex = 1.6, lwd = 3.5, col = "white")
points(lawn[1], lawn[2], pch = 3, cex = 1.6, lwd = 1.8, col = acc)
halo(lawn[1] + 10, lawn[2] - 8, "0 m here", adj = c(0, 1), font = 2)
# scale bar and north arrow, in the margin to the right of the map
sx <- box[["xmax"]] + 30
rect(sx, box[["ymin"]] + 20, sx + 100, box[["ymin"]] + 30, col = ink, border = NA)
text(sx + 50, box[["ymin"]] + 45, "100 m", adj = c(0.5, 0), font = 2)
arrows(sx + 50, box[["ymin"]] + 110, sx + 50, box[["ymin"]] + 170, length = 0.1, lwd = 2.2, col = ink)
text(sx + 50, box[["ymin"]] + 185, "N", font = 2, cex = 1.2, adj = c(0.5, 0))
vkey(sx, box[["ymax"]] - 330, box[["ymax"]] - 50, 26, palH, labH, "Height, m", cex = 1)
dev.off()
cat("  f04: lawn", round(extract(hgt, rbind(lawn))[[1]], 2), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f05_tower_cells ====
# The 60 x 60 m around the tower in 1 m, 5 m and 10 m cells (the mean of the 1 m cells), on one colour scale.
win <- ext(377850, 377910, 4700510, 4700570)    # on the 10 m grid's edges, so every coarse cell is whole
g <- list(crop(hgt, win), crop(aggregate(hgt, 5, "mean", na.rm = TRUE), win), crop(aggregate(hgt, 10, "mean", na.rm = TRUE), win))
# the tallest cell whose centre lies within 20 m of the tower, as in tools/make_lidar.R
# (at 10 m, Uris Library's roof cell, 20.4 m, is taller than any cell that holds the tower)
near <- function(r) { xy <- xyFromCell(r, 1:ncell(r)); v <- values(r, mat = FALSE)
  v[(xy[, 1] - tower[1])^2 + (xy[, 2] - tower[2])^2 > 20^2] <- NA; which.max(v) }
ti  <- sapply(g, near)
top <- mapply(function(r, i) values(r, mat = FALSE)[i], g, ti)
nm <- paste0(c(1, 5, 10), " m cells: tower ", sprintf("%.1f", top), " m")
fig("f05_tower_cells.png", 12, 4.5, ps = 13)
layout(matrix(1:4, 1), widths = c(3.5, 3.5, 3.5, 1.5)); par(cex = 1)
for (k in 1:3) {
  par(mar = c(0.3, 0.6, 2.2, 0.6))
  plot.new(); plot.window(c(377850, 377910), c(4700510, 4700570), asp = 1, xaxs = "i", yaxs = "i")
  cl <- palH[findInterval(values(g[[k]], mat = FALSE), brH, all.inside = TRUE)]
  if (k == 1) rimg(g[[k]], palH, brH) else cellrect(g[[k]], cl, border = "white", lwd = 1)
  rect(377850, 4700510, 377910, 4700570, border = rule)
  xy <- xyFromCell(g[[k]], ti[k]); h <- res(g[[k]])[1] / 2
  rect(xy[1] - h, xy[2] - h, xy[1] + h, xy[2] + h, border = acc, lwd = 3)
  mtext(nm[k], side = 3, line = 0.5, font = 2, cex = 1.05)
  mtext(letters[k], side = 3, line = 0.5, adj = 0, font = 2, cex = 1.35)
}
par(mar = c(0.3, 0, 2.0, 0))
plot.new(); plot.window(c(0, 1), c(4700510, 4700570), xaxs = "i", yaxs = "i")
vkey(0.08, 4700512, 4700560, 0.18, palH, labH, "Height, m", cex = 1)
dev.off()
cat("  f05: tower", round(top, 2), "; whole window", round(sapply(g, function(r) max(values(r), na.rm = TRUE)), 2), "\n")
# ==== END BLOCK ====

# ==== BLOCK: map_data ====
# Shared by the maps of slides 7 to 9: sf, the state outlines, the period colours, Ithaca and New York City.
suppressPackageStartupMessages(library(sf))
sf_use_s2(FALSE)
states <- st_read(file.path("data/23-spatial-vector/data_clean/states/cb_2024_us_state_500k.shp"), quiet = TRUE)
off    <- c("AK", "HI", "PR", "VI", "GU", "MP", "AS")
st48   <- st_transform(states[!states$STUSPS %in% off, ], 5070)
# periods, oldest to newest; viridis mixed 25% toward white so black dots and red marks read on top
periods <- c("2011 or earlier", "2012–2014", "2015–2017", "2018–2020", "2021 or later")
palP <- mapply(function(c1) { v <- col2rgb(c1) / 255; rgb(t(0.75 * v + 0.25)) }, hcl.colors(5, "viridis"))
cities <- st_sf(name = c("Ithaca", "New York City"),
                geometry = st_sfc(st_point(c(-76.5019, 42.4440)), st_point(c(-73.98566, 40.74844)), crs = 4326))
# plot geometries without spilling outside the plot region
mapdraw <- function(g, ...) { op <- par(xpd = FALSE); plot(st_geometry(g), add = TRUE, ...); par(op) }
# a boxed legend drawn by hand: filled squares, lines or points, one row each.
# (x, y) is the corner named by `corner` ("tl", "tr", "bl", "br"); returns the box as c(x0, y0, x1, y1).
boxleg <- function(x, y, lab, fill = NA, border = ink, pch = NA, pcol = ink, pbg = NA, pcex = 1.3, lty = NA, lcol = ink,
                   lwd = 2, title = NULL, cex = 1, gap = 1.45, pad = 0.4, corner = "tl") {
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
# ==== END BLOCK ====

# ==== BLOCK: f07_world DEPS: map_data ====
# Countries with free national LiDAR, and the band GEDI samples from the space station.
# Both panels use the same projection (longitude and latitude at equal scale) and the same width.
# Country names sit in one column on the right of panel b, each joined to its country by a thin leader.
suppressPackageStartupMessages(library(rnaturalearth))
world <- ne_countries(scale = 110, returnclass = "sf")
units <- ne_countries(scale = 50, type = "map_units", returnclass = "sf")
four  <- c("England", "Netherlands", "Switzerland", "Spain")
nat   <- units[units$name %in% four & units$type != "Dependency", ]
nat   <- nat[match(four, nat$name), ]
stopifnot(nrow(nat) == 4, !anyNA(nat$name))
gedi  <- 51.6                                     # degrees N and S, the station's orbit inclination
gcol  <- "#8A6500"                                # GEDI lines and labels
wa    <- c(-180, 180, -58, 84)                    # panel a, lon and lat
eu    <- c(-14, 44, 34.5, 59.5)                   # panel b: same width, so it is a wide strip of Europe
pw <- 5.4 - 0.08                                  # plot width in inches, both panels
ha <- pw * diff(wa[3:4]) / diff(wa[1:2]); hb <- pw * diff(eu[3:4]) / diff(eu[1:2])
fig("f07_world.png", 5.4, ha + hb + 0.6, ps = 12)  # tall enough that neither panel is narrowed by its aspect
layout(matrix(2:1, 2), heights = c(ha + 0.3, hb + 0.3)); par(cex = 1)   # panel b drawn first, so a can outline it
# b. Europe
par(mai = c(0.02, 0.04, 0.28, 0.04))
plot.new(); plot.window(eu[1:2], eu[3:4], asp = 1, xaxs = "i", yaxs = "i")
ub <- par("usr")                                  # asp = 1 may widen the window: draw to what R actually shows
rect(ub[1], ub[3], ub[2], ub[4], col = sea, border = NA)
mapdraw(units, col = land, border = "#B9B4A8", lwd = 0.5)
rect(ub[1], gedi, ub[2], ub[4], col = adjustcolor("white", 0.55), border = NA)
mapdraw(nat, col = acc, border = "white", lwd = 0.6)
segments(ub[1], gedi, ub[2], gedi, col = gcol, lwd = 1.6, lty = 2)
# the label column, top to bottom in latitude order, and a dot on each country where its leader ends
lab <- data.frame(name = c("England", "Netherlands", "Switzerland", "Spain"),
                  px = c(-1.3, 5.6, 8.2, -3.6), py = c(52.6, 52.3, 46.8, 40.2),
                  ly = c(56.6, 53.6, 46.8, 40.2))
lx <- 22
for (i in 1:4) {
  segments(lx - 0.6, lab$ly[i], lab$px[i], lab$py[i], col = ink, lwd = 0.8)
  points(lab$px[i], lab$py[i], pch = 21, bg = "white", col = ink, cex = 0.7, lwd = 1)
  halo(lx, lab$ly[i], lab$name[i], adj = c(0, 0.5), font = 2, cex = 1.05)
}
halo(ub[1] + 0.8, gedi + 1.1, paste0(gedi, "° N"), adj = c(0, 0.5), font = 2, col = gcol, cex = 1.05)
rect(ub[1], ub[3], ub[2], ub[4], border = ink, lwd = 1.4)
mtext("b", side = 3, line = 0.25, adj = 0, font = 2, cex = 1.3)
mtext("Europe", side = 3, line = 0.25, font = 2, cex = 1.05)
# a. the world
par(mai = c(0.02, 0.04, 0.28, 0.04))
plot.new(); plot.window(wa[1:2], wa[3:4], asp = 1, xaxs = "i", yaxs = "i")
rect(wa[1], wa[3], wa[2], wa[4], col = sea, border = NA)
mapdraw(world, col = land, border = "#B9B4A8", lwd = 0.4)
rect(wa[1], c(wa[3], gedi), wa[2], c(-gedi, wa[4]), col = adjustcolor("white", 0.55), border = NA)   # outside the band
mapdraw(nat, col = acc, border = acc, lwd = 0.6)
segments(wa[1], c(-gedi, gedi), wa[2], c(-gedi, gedi), col = gcol, lwd = 1.6, lty = 2)
rect(ub[1], ub[3], ub[2], ub[4], border = ink, lwd = 1.2)   # the area of panel b
halo(wa[1] + 4, gedi + 5.5, paste0(gedi, "° N"), adj = c(0, 0.5), font = 2, col = gcol, cex = 1.05)
halo(wa[1] + 4, -gedi + 5.5, paste0(gedi, "° S"), adj = c(0, 0.5), font = 2, col = gcol, cex = 1.05)
halo(-118, -8, "GEDI samples\nbetween the lines", font = 2, col = gcol, cex = 1.05)
rect(wa[1], wa[3], wa[2], wa[4], border = rule)
mtext("a", side = 3, line = 0.25, adj = 0, font = 2, cex = 1.3)
mtext("The world", side = 3, line = 0.25, font = 2, cex = 1.05)
dev.off()
cat("  f07:", paste(nat$name, collapse = ", "), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f08_coverage DEPS: map_data ====
# Where USGS has flown: project outlines by period, Ithaca and New York City. (The 300-place test of these
# outlines is in tools/check_coverage.R and logs/prep_coverage_test.txt; its points are no longer drawn.)
cov <- st_read(dpath("data_clean/coverage/usgs_lidar_by_year.gpkg"), quiet = TRUE)
cov <- cov[match(gsub("–", "-", periods), cov$period), ]            # oldest first, so the newest is drawn on top
stopifnot(!anyNA(cov$period))
cx  <- st_coordinates(st_transform(cities, 5070))
bb  <- st_bbox(st48)
# five distinct hues, oldest to newest, so neighbouring periods do not blur (purple, blue, green, yellow, orange)
palC <- c("#8E6BB8", "#5B9BD5", "#6CC07A", "#F2D45C", "#F4A261")
fig("f08_coverage.png", 7.4, 5.0, ps = 12)
par(mar = c(0.1, 0.1, 0.1, 0.1))
plot.new(); plot.window(c(bb[1] - 20e3, bb[3] + 60e3), c(bb[2] - 560e3, bb[4] + 20e3), asp = 1, xaxs = "i", yaxs = "i")
u <- par("usr")
mapdraw(st48, col = "#EDEBE6", border = NA)
mapdraw(cov, col = palC, border = NA)
mapdraw(st48, col = NA, border = "#55554F", lwd = 0.5)
points(cx, pch = 21, bg = red, col = "white", cex = 1.7, lwd = 1.4)
halo(cx[1, 1] - 40e3, cx[1, 2] + 70e3, "Ithaca", adj = c(1, 0), font = 2, cex = 1.25)
halo(cx[2, 1] + 10e3, cx[2, 2] - 80e3, "New York\nCity", adj = c(0, 1), font = 2, cex = 1.25)
boxleg(u[1] + 20e3, u[3] + 20e3, paste0(periods, " (", cov$projects, ")"), fill = palC, border = "#55554F",
       title = "Projects, by year flown", corner = "bl", cex = 1.3, gap = 1.35)
dev.off()
cat("  f08: periods", cov$projects, "sum", sum(cov$projects), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f09_zoom DEPS: map_data ====
# From New York to the campus (slide 9): a. New York's projects, the Finger Lakes flight in red;
# b. Tompkins County with the flight and the clip; c. the clip, the 1 m height grid.
nyp  <- st_read(dpath("data_clean/coverage/ny_projects.gpkg"), quiet = TRUE)
ny   <- st_union(st48[st48$STUSPS == "NY", ])
fl   <- nyp[nyp$name == "NY_FingerLakes_1_2020", ]
nyin <- suppressWarnings(st_intersection(st_make_valid(nyp), ny))      # the 54 projects, cut to the state
towns <- st_read(dpath("data_clean/terrain/tompkins_towns.gpkg"), quiet = TRUE)
county <- st_union(towns)
fl_t <- st_transform(fl, st_crs(towns))
dem  <- rast(dpath("data_clean/terrain/tompkins_dem_utm.tif"))
lake <- ifel(dem <= 116.5, 1, NA)                                       # Cayuga Lake's flat surface, 116 m
lakev <- st_as_sf(as.polygons(lake)); lakev <- st_intersection(lakev, county)
ctr_box <- c(mean(box[c(1, 3)]), mean(box[c(2, 4)]))
cxy <- st_coordinates(st_transform(cities, 5070))
fig("f09_zoom.png", 13, 4.9, ps = 12)
layout(matrix(1:3, 1), widths = c(4.6, 4.0, 4.4)); par(cex = 1)
# a. New York State
par(mar = c(0.2, 0.3, 1.7, 0.3))
bny <- st_bbox(st_transform(ny, 5070))
plot.new(); plot.window(c(bny[1] - 20e3, bny[3] + 20e3), c(bny[2] - 140e3, bny[4] + 20e3), asp = 1, xaxs = "i", yaxs = "i")
u <- par("usr")
mapdraw(st48, col = "#F4F2EC", border = "#B9B4A8", lwd = 0.6)
mapdraw(nyin, col = adjustcolor(teal, 0.16), border = adjustcolor(teal, 0.7), lwd = 0.5)
mapdraw(st_transform(st_intersection(st_make_valid(fl), ny), 5070), col = adjustcolor(red, 0.35), border = red, lwd = 2)
mapdraw(ny, col = NA, border = ink, lwd = 1.2)
mapdraw(st_transform(county, 5070), col = NA, border = ink, lwd = 1.6)
points(cxy, pch = 21, bg = red, col = "white", cex = 1.6, lwd = 1.3)
halo(cxy[1, 1] + 18e3, cxy[1, 2] - 28e3, "Ithaca", adj = c(0, 1), font = 2)
halo(cxy[2, 1] - 20e3, cxy[2, 2] + 8e3, "New York City", adj = c(1, 0), font = 2)
boxleg(u[1] + 8e3, u[3] + 8e3, c(paste0("USGS project (", nrow(nyp), ")"), "Finger Lakes flight, May 2020"),
       fill = c(adjustcolor(teal, 0.3), adjustcolor(red, 0.45)), border = c(teal, red), corner = "bl")
mtext("a", side = 3, line = 0.3, adj = 0, font = 2, cex = 1.35)
mtext("New York State", side = 3, line = 0.3, font = 2, cex = 1.1)
# b. Tompkins County
bt <- st_bbox(county)
plot.new(); plot.window(c(bt[1] - 1500, bt[3] + 1500), c(bt[2] - 9000, bt[4] + 1000), asp = 1, xaxs = "i", yaxs = "i")
u <- par("usr")
mapdraw(towns, col = "#F4F2EC", border = NA)
mapdraw(fl_t, col = adjustcolor(red, 0.12), border = NA)
mapdraw(lakev, col = sea, border = "#7FA7C6", lwd = 0.6)
mapdraw(towns, col = NA, border = "#8C877C", lwd = 0.8)
mapdraw(fl_t, col = NA, border = red, lwd = 2)
mapdraw(county, col = NA, border = ink, lwd = 1.4)
tc <- st_coordinates(st_point_on_surface(st_geometry(towns)))
tl <- ifelse(towns$NAMELSAD == "Ithaca city", "", towns$NAME)
nudge <- cbind(ifelse(towns$NAMELSAD == "Ithaca town", -1800, 0), ifelse(towns$NAME == "Lansing", 2500, ifelse(towns$NAMELSAD == "Ithaca town", 2600, 0)))
halo(tc[, 1] + nudge[, 1], tc[, 2] + nudge[, 2], tl, cex = 0.95, col = "#444444")
halo(365400, 4713500, "Cayuga\nLake", col = "#2F5F86", font = 3, cex = 0.95)
points(ctr_box[1], ctr_box[2], pch = 22, bg = red, col = "white", cex = 2.1, lwd = 1.4)
halo(ctr_box[1] + 1300, ctr_box[2] - 600, "Campus clip", adj = c(0, 1), font = 2)
boxleg(u[1] + 400, u[3] + 300, c("Finger Lakes flight", "Town line", "Campus clip"), fill = c(adjustcolor(red, 0.15), NA, NA),
       border = c(red, NA, NA), lty = c(NA, 1, NA), lcol = "#8C877C", lwd = 1.2, pch = c(NA, NA, 22), pbg = red,
       pcol = "white", pcex = 1.6, corner = "bl")
mtext("b", side = 3, line = 0.3, adj = 0, font = 2, cex = 1.35)
mtext("Tompkins County", side = 3, line = 0.3, font = 2, cex = 1.1)
# c. the clip: height above ground, 1 m cells
plot.new(); plot.window(c(box[["xmin"]] - 15, box[["xmax"]] + 15), c(box[["ymin"]] - 150, box[["ymax"]] + 10), asp = 1,
                        xaxs = "i", yaxs = "i")
rimg(hgt, palH, brH)
rect(box[["xmin"]], box[["ymin"]], box[["xmax"]], box[["ymax"]], border = rule)
symbols(tower[1], tower[2], circles = 11, inches = FALSE, add = TRUE, fg = "white", lwd = 3.5)
symbols(tower[1], tower[2], circles = 11, inches = FALSE, add = TRUE, fg = acc, lwd = 1.8)
halo(tower[1] + 16, tower[2] - 14, "McGraw Tower", adj = c(0, 1), font = 2)
segments(377800, 4700612, 377842, 4700566, col = "white", lwd = 1.6)
halo(377800, 4700616, "Uris Library", adj = c(0.5, 0), font = 2)
halo(377945, 4700760, "Arts Quad", font = 2)
halo(377700, 4700480, "Libe Slope", font = 2)
# the 600 m side, as a dimension line under the box
yd <- box[["ymin"]] - 28
arrows(box[["xmin"]], yd, box[["xmax"]], yd, code = 3, length = 0.08, angle = 25, col = ink, lwd = 1.2)
segments(box[c("xmin", "xmax")], yd - 10, box[c("xmin", "xmax")], box[["ymin"]] - 4, col = ink, lwd = 0.8)
lw <- strwidth("600 m", font = 2) / 2 + 12
rect(mean(box[c(1, 3)]) - lw, yd - 14, mean(box[c(1, 3)]) + lw, yd + 14, col = "white", border = NA)
text(mean(box[c(1, 3)]), yd, paste0(fmt(box[["xmax"]] - box[["xmin"]]), " m"), font = 2)
hkey(box[["xmin"]] + 40, box[["xmax"]] - 40, box[["ymin"]] - 112, 20, palH, labH, "Height above ground, m", cex = 1, padx = 16)
mtext("c", side = 3, line = 0.3, adj = 0, font = 2, cex = 1.35)
mtext("The campus clip, 1 m cells", side = 3, line = 0.3, font = 2, cex = 1.1)
dev.off()
cat("  f09:", nrow(nyp), "projects touch NY; clip", box[["xmax"]] - box[["xmin"]], "m; lake km2", round(sum(st_area(lakev)) / 1e6, 1), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f10_lawn_crop ====
# The 60 m around the Arts Quad lawn point (slide 16), on f04's colour scale, the point marked.
win <- ext(lawn[1] - 30, lawn[1] + 30, lawn[2] - 30, lawn[2] + 30)
hc  <- crop(hgt, win)
v0  <- extract(c(dtm, dsm, hgt), rbind(lawn))
fig("f10_lawn_crop.png", 2.6, 2.75, ps = 12)
par(mar = c(0.1, 0.1, 0.1, 0.1))
plot.new(); plot.window(c(win$xmin, win$xmax), c(win$ymin - 9, win$ymax), asp = 1, xaxs = "i", yaxs = "i")
rimg(hc, palH, brH)
rect(win$xmin, win$ymin, win$xmax, win$ymax, border = rule)
points(lawn[1], lawn[2], pch = 3, cex = 2.2, lwd = 4.5, col = "white")
points(lawn[1], lawn[2], pch = 3, cex = 2.2, lwd = 2.2, col = acc)
halo(lawn[1] + 3, lawn[2] - 4, paste0(fmt(v0[[3]], 0), " m here"), adj = c(0, 1), font = 2)
# 10 m scale bar under the crop
rect(win$xmin + 1, win$ymin - 6.5, win$xmin + 11, win$ymin - 5, col = ink, border = NA)
text(win$xmin + 13, win$ymin - 5.75, "10 m", adj = c(0, 0.5), font = 2)
text(win$xmax, win$ymin - 5.75, "Arts Quad", adj = c(1, 0.5), font = 2)
dev.off()
cat("  f10: lawn ground, surface, height", round(unlist(v0), 2), "; max height in the crop", round(global(hc, max, na.rm = TRUE)[[1]], 2), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f11_tower_side ====
# f02's strip cropped to McGraw Tower (slide 20), true scale, with the ground and surface of the tallest cell within 20 m.
las <- readLAS(dpath("data_clean/lidar/campus.laz"), select = "xyzc", filter = "-drop_class 7 18")
st  <- filter_poi(las, abs(Y - tower[2]) < 5 & abs(X - tower[1]) < 42)
d   <- data.frame(x = st$X - tower[1], z = st$Z, c = st$Classification)
d   <- d[order(d$c == 2), ]
e   <- extract(c(dtm, dsm, hgt), buffer(vect(rbind(tower), crs = crs(hgt)), 20))
top <- e[which.max(e[[4]]), ]                      # ground, surface, height of the tallest cell
g0 <- top[[2]]; s0 <- top[[3]]; h0 <- top[[4]]
fig("f11_tower_side.png", 5.3, 5.0, ps = 13)
par(mar = c(3.2, 4.0, 0.6, 0.6), las = 1, mgp = c(2.1, 0.5, 0), tcl = -0.3)
plot.new(); plot.window(c(-42, 42), c(226, 300), asp = 1, xaxs = "i", yaxs = "i")
points(d$x, d$z, pch = 16, cex = 0.35, col = ifelse(d$c == 2, brown, adjustcolor(teal, 0.75)))
axis(1, at = seq(-40, 40, 20), col = rule, col.ticks = rule)
axis(2, at = seq(240, 300, 20), col = rule, col.ticks = rule)
box(col = rule)
mtext("Metres east of the tower", side = 1, line = 2.0)
mtext("Elevation, m", side = 2, line = 2.9, las = 0)
# the two readings of the tallest cell, and the height between them
segments(-6, s0, 3, s0, col = acc, lwd = 2); segments(-6, g0, 3, g0, col = acc, lwd = 2)
halo(5, s0, paste0("Surface ", sprintf("%.1f", s0), " m"), adj = c(0, 0.5), font = 2)
halo(5, g0 - 1.6, paste0("Ground ", sprintf("%.1f", g0), " m"), adj = c(0, 1), font = 2)
arrows(-12, g0, -12, s0, code = 3, length = 0.08, angle = 25, lwd = 1.6, col = acc)
halo(-14, (g0 + s0) / 2, paste0(sprintf("%.1f", h0), " m"), adj = c(1, 0.5), font = 2, col = acc)
legend("bottomleft", c("Ground (class 2)", "Everything else (class 1)"), pch = 15, col = c(brown, teal), pt.cex = 1.6,
       bg = "white", box.col = rule, inset = c(0.02, 0.03), cex = 0.9)
dev.off()
cat("  f11: tallest cell ground", round(g0, 3), "surface", round(s0, 3), "height", round(h0, 3), "; cells", nrow(e),
    "; points", nrow(d), "; top point", round(max(d$z), 2), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f12_esb_side ====
# The Empire State Building from the side (slide 21): every point within 60 m of its centre, heights above the street.
# Noise (classes 7 and 18, mostly street-level returns east of the building) is left out.
ctrE <- c(585631.7, 4511326.9)                     # from logs/prep_nyc.txt
le   <- readLAS(dpath("data_clean/lidar_nyc/esb.laz"), select = "xyzc")
d2   <- (le$X - ctrE[1])^2 + (le$Y - ctrE[2])^2
street <- median(le$Z[le$Classification == 2 & d2 < 150^2])
inb  <- d2 < 60^2
dn   <- sum(inb & le$Classification %in% c(7, 18))
b    <- data.frame(x = le$X[inb] - ctrE[1], z = le$Z[inb] - street, c = le$Classification[inb])
b    <- b[!b$c %in% c(7, 18), ]; b <- b[order(b$c == 2), ]
hE   <- rast(dpath("data_clean/lidar_nyc/esb_height.tif"))
top1 <- max(extract(hE, buffer(vect(rbind(ctrE), crs = crs(hE)), 60))[[2]], na.rm = TRUE)
oth  <- sort(setdiff(unique(b$c), 2))
lab_oth <- paste0("Everything else (class", ifelse(length(oth) > 1, "es ", " "), paste(oth, collapse = " and "), ")")
ft <- 0.3048
fig("f12_esb_side.png", 5.15, 5.6, ps = 13)
par(mar = c(3.4, 4.0, 0.6, 0.4), las = 1, mgp = c(2.1, 0.5, 0), tcl = -0.3)
plot.new(); plot.window(c(-62, 345), c(-5, 470), asp = 1, xaxs = "i", yaxs = "i")
rect(-62, -5, 62, 470, border = rule)
points(b$x, b$z, pch = 16, cex = 0.12, col = ifelse(b$c == 2, brown, adjustcolor("#3C4650", 0.55)))
axis(1, at = c(-50, 0, 50), col = rule, col.ticks = rule)
axis(2, at = seq(0, 450, 50), col = rule, col.ticks = rule, pos = -62)
mtext("Metres east of the centre", side = 1, line = 2.0, at = -62, adj = 0)
mtext("Metres above the street", side = 2, line = 2.9, las = 0)
hl <- c(tip = 1454 * ft, floor = 1250 * ft)
segments(-62, hl, 75, hl, lty = 2, lwd = 1.6, col = blue)
text(80, hl[1] + 5, paste0("1,454 ft = ", sprintf("%.1f", hl[1]), " m"), adj = c(0, 0), col = blue, font = 2)
text(80, hl[1] - 5, "(antenna tip)", adj = c(0, 1), col = blue)
text(80, hl[2] + 5, paste0("1,250 ft = ", sprintf("%.0f", hl[2]), " m"), adj = c(0, 0), col = blue, font = 2)
text(80, hl[2] - 5, "(highest occupied floor)", adj = c(0, 1), col = blue)
# the grid's tallest 1 m cell: a short solid mark at its height
segments(-12, top1, 12, top1, col = acc, lwd = 2.6)
arrows(75, 330, 8, top1 - 6, length = 0.08, col = acc, lwd = 1.3)
text(80, 330, paste0("Tallest 1 m cell:\n", sprintf("%.1f", top1), " m"), adj = c(0, 0.5), col = acc, font = 2)
legend(68, 120, c("Ground (class 2)", lab_oth), pch = 15, col = c(brown, "#3C4650"), pt.cex = 1.6,
       bg = "white", box.col = rule, cex = 0.9)
dev.off()
cat("  f12: street", round(street, 2), "; points within 60 m", nrow(b), "; noise left out", dn, "; classes", oth,
    "; tallest 1 m cell", round(top1, 2), "; top point", round(max(b$z), 2), "\n")
# ==== END BLOCK ====

# ==== BLOCK: mosaic_data ====
# Shared by slides 24 to 27: the corn-trial mosaic (4.1 cm pixels), an 8x reduced copy, and a drawing helper.
suppressPackageStartupMessages(library(sf)); terraOptions(progress = 0)
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
# ==== END BLOCK ====

# ==== BLOCK: f13_mosaic DEPS: mosaic_data ====
# The corn trial (slide 24): a. the whole mosaic, labelled; b. a 10 m square at full resolution.
sq <- ext(453170, 453180, 4e6 - 24240, 4e6 - 24230)                  # 10 x 10 m in the standing corn
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
# The field in 4 cm, 10 m and 30 m cells (slides 26, 28), on one extent. The 10 m and 30 m grids are built
# as on the slide (black pixels to NA, then the mean of the rest); their cells are drawn with crisp edges.
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
# The Census line for Pennell St NE against the road in the image (slide 27): a 40 x 30 m window at the 50% point.
p5 <- off[off$point == 0.5, ]
w  <- ext(p5$x - 20, p5$x + 20, p5$y - 15, p5$y + 15)
mw <- crop(mo, w)
# the direction of the line at the 50% point, as tools/make_terrain.R measured it
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
