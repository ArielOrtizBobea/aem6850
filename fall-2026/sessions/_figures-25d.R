# Figures for the session 25 page and slides, part 5: the radar grids behind the hail pilot.
# Base R, terra, sf and exactextractr. Run from fall-2026/sessions:
#   Rscript _figures-25d.R                    # every block
#   Rscript _figures-25d.R f36_radar_hail     # setup, then one block (and its DEPS)
# Writes figures/25-radar-lidar/<block>.png. Inputs: data/25-radar-lidar/data_clean/hail/ (the session project,
# after its tools/make_hail.R and tools/fetch_mrms.R have run).
# Drawn at res 200. A figure W inches wide shown at about 100 * W px on the 1050 x 700 slide
# keeps its point sizes; every label is 10.5 pt or more at that width.
# The setup block is a copy of the one in _figures-25c.R, so each script runs on its own.

# ---- Run named blocks only: Rscript _figures-25d.R <block> [<block> ...] ----
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

# ==== BLOCK: f36_radar_hail ====
# The radar grids behind the county map of f31, 12 June 2022, in the seven Plains states of the hail pilot.
# a. Composite reflectivity (NOAA MRMS MergedReflectivityQCComposite), the strongest echo above each 0.01 degree cell,
#    at 05:00 UTC 13 June (midnight CDT): of the hourly snapshots from 21:00 to 06:00 UTC, the one with the most
#    km2 of 50 dBZ or more (logs/prep_mrms.txt).
# b. MESH_Max_1440min: the largest hail estimated in each cell over the radar day, 12:00 UTC 12 June to 12:00 UTC 13 June,
#    the grid the pilot summed by county. Both projected to Albers equal area (EPSG:5070) on 1 km cells,
#    nearest neighbour for MESH and bilinear for reflectivity, and cut to the seven states.
cty7 <- st_transform(st_read(dpath("data_clean/hail/counties_7states.gpkg"), quiet = TRUE), 5070)
st7  <- aggregate(cty7["ALAND"], by = list(st = cty7$STUSPS), FUN = sum)
bb   <- st_bbox(cty7)
tmpl <- rast(ext(bb[["xmin"]], bb[["xmax"]], bb[["ymin"]], bb[["ymax"]]), res = 1000, crs = "EPSG:5070")
in7  <- vect(st_union(st7))
mesh <- mask(project(rast(dpath("data_clean/hail/mesh_20220612.tif")), tmpl, method = "near"), in7)
refl <- mask(project(rast(dpath("data_clean/hail/reflectivity_20220612.tif")), tmpl, method = "bilinear"), in7)
mesh[mesh <= 0] <- NA; refl[refl < 10] <- NA
# reflectivity: the usual weather-radar steps, greens for light rain, yellow and red for heavy, purple for hail cores
brZ  <- c(10, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 80)
palZ <- c("#9BE39B", "#3CCB3C", "#139A13", "#0B6B0B", "#F5E400", "#E5B400", "#FD8A00", "#F00000", "#B80000",
          "#E000E0", "#8A3CC0")
labZ <- c("10", "", "", "30", "", "", "", "50", "", "", "65", "")
# MESH, mm, at the pilot's thresholds 0.75, 1, 1.5 and 2 inches
brM  <- c(0, 19.05, 25.4, 38.1, 50.8, 200)
palM <- c("#FFE08A", "#FDA65A", "#F05A30", "#C0102A", "#5E0A62")
labM <- c("0", "0.75", "1", "1.5", "2", "")
pan  <- c("Radar reflectivity at 12 am Central, 13 June 2022", "Largest hail in 24 hours, estimated by radar")
dy   <- 330000                                                # room under the map for the key
fig("f36_radar_hail.png", 11, 5.2, ps = 14)
layout(matrix(1:2, 1)); par(cex = 1)
for (k in 1:2) {
  par(mar = c(0.1, 0.3, 2.0, 0.3))
  plot.new(); plot.window(c(bb[["xmin"]], bb[["xmax"]]), c(bb[["ymin"]] - dy, bb[["ymax"]]), asp = 1, xaxs = "i", yaxs = "i")
  plot(st_geometry(st7), col = land, border = NA, add = TRUE)
  if (k == 1) rimg(refl, palZ, brZ) else rimg(mesh, palM, brM)
  plot(st_geometry(st7), border = ink, lwd = 1.2, add = TRUE, col = NA)
  lab <- st_coordinates(st_point_on_surface(st_geometry(st7)))
  for (i in seq_len(nrow(st7))) halo(lab[i, 1], lab[i, 2], st7$st[i], font = 2, cex = 1.05)
  u <- par("usr")
  mtext(pan[k], side = 3, line = 0.45, font = 2, cex = 1, at = mean(u[1:2]) + 60000)
  mtext(letters[k], side = 3, line = 0.3, font = 2, cex = 1.7, adj = 0)
  if (k == 1) hkey(u[1] + 110000, u[1] + 1050000, bb[["ymin"]] - 175000, 60000, palZ, labZ, "Reflectivity, dBZ", padx = 30000)
  if (k == 2) hkey(u[1] + 110000, u[1] + 950000, bb[["ymin"]] - 175000, 60000, palM, labM,
                   "Largest hail, inches", padx = 30000)
  # a 300 km scale bar, bottom right
  x0 <- u[2] - 420000; y0 <- bb[["ymin"]] - 190000
  rect(x0, y0, x0 + 300000, y0 + 14000, col = ink, border = NA)
  text(x0 + 150000, y0 + 30000, "300 km", adj = c(0.5, 0), font = 2)
}
dev.off()
cat("  f36: reflectivity cells >= 10 dBZ", global(!is.na(refl), "sum")[[1]], "; hail cells", global(!is.na(mesh), "sum")[[1]],
    "; max hail mm", round(global(mesh, "max", na.rm = TRUE)[[1]], 1), "\n")
# ==== END BLOCK ====
