# Figures for the session 23 page and slides (spatial data I: vector).
# Base R, sf and igraph. Run from fall-2026/sessions:
#   Rscript _figures-23.R              # every block
#   Rscript _figures-23.R f3_area      # setup, then one block (and its DEPS)
# Writes figures/23-spatial-vector/*.png. Inputs: data/23-spatial-vector/ (the session project).
# Drawn at res 200; 1 inch is about 100 px on the 1050 x 700 slide.
# Memory: nothing here buffers the roads or lists every tied route; peak well under 1 GB.

# ---- Run named blocks only: Rscript _figures-23.R <block> [<block> ...] ----
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
suppressPackageStartupMessages({library(sf); library(igraph)})
out <- "figures/23-spatial-vector"; dat <- "data/23-spatial-vector"
dir.create(out, showWarnings = FALSE, recursive = TRUE)
ink <- "#222222"; acc <- "#B31B1B"; grey <- "#666666"; light <- "#E4E2DC"; rule <- "#BBBBBB"
blue <- "#3A6C9C"; amber <- "#E6A700"; red <- "#C0392B"; teal <- "#2A9D8F"
fig <- function(name, w, h, mar = c(0, 0, 0, 0), ps = 11) {
  # ps: the text size; figures shown small on a slide get a larger one
  png(file.path(out, name), width = w, height = h, units = "in", res = 200, pointsize = ps)
  par(mar = mar, family = "sans")
}
canvas <- function(name, w, h, ps = 11) {
  fig(name, w, h, ps = ps); plot.new(); plot.window(xlim = c(0, w), ylim = c(0, h), xaxs = "i", yaxs = "i")
}
# an empty map frame on a box (an sfc or bbox), with a margin in map units
frame <- function(b, m = 0) {
  b <- st_bbox(b)
  plot(st_geometry(st_as_sfc(st_bbox(c(xmin = b[["xmin"]] - m, ymin = b[["ymin"]] - m,
                                         xmax = b[["xmax"]] + m, ymax = b[["ymax"]] + m), crs = st_crs(b)))),
       border = NA)
}
P <- function(...) file.path(dat, ...)
# ==== END BLOCK ====

# ==== BLOCK: us ====
co <- st_read(paste0("/vsizip/", P("data/census/cb_2024_us_county_500k.zip")), quiet = TRUE)
states <- st_read(paste0("/vsizip/", P("data/census/cb_2024_us_state_500k.zip")), quiet = TRUE)
off <- c("AK", "HI", "PR", "AS", "GU", "MP", "VI")
low <- st_transform(co[!co$STUSPS %in% off, ], 5070)
states_m <- st_transform(states, 5070)
wh <- st_as_sf(data.frame(name = "Warren Hall", lon = -76.4797, lat = 42.4490), coords = c("lon", "lat"), crs = 4326)
wh_m <- st_transform(wh, 5070)
tk <- co[co$GEOID == "36109", ]
# ==== END BLOCK ====

# ==== BLOCK: med DEPS: us ====
med <- read.csv(P("data_clean/medicaid_expansion.csv"))
exp14 <- med$state[med$group == "expanded 2014"]; not14 <- med$state[med$group == "not expanded by 2018"]
k <- low[low$STUSPS %in% c(exp14, not14), c("GEOID", "NAME", "STUSPS")]
k$exp14 <- k$STUSPS %in% exp14
nbk <- st_touches(k)
pairs <- data.frame(e = rep(seq_along(nbk), lengths(nbk)), n = unlist(nbk))
pairs <- pairs[k$exp14[pairs$e] & !k$exp14[pairs$n], ]
states_k <- states_m[states_m$STUSPS %in% c(exp14, not14), ]
ln <- st_intersection(st_union(states_k[states_k$STUSPS %in% exp14, ]), st_union(states_k[states_k$STUSPS %in% not14, ]))
pt_co <- st_point_on_surface(st_geometry(k))
k$dist_km <- ifelse(k$exp14, 1, -1) * as.numeric(st_distance(pt_co, ln)) / 1e3
# ==== END BLOCK ====

# ==== BLOCK: amazon ====
mun <- st_read(P("data/inpe/municipalities_RO.json"), quiet = TRUE)
cu <- st_transform(mun[mun$nome == "Cujubim", ], 31980)
files <- list.files(P("data/inpe"), "^yearly", full.names = TRUE)
cl <- do.call(rbind, lapply(files, st_read, quiet = TRUE))
cl <- st_make_valid(st_transform(cl[c("year", "area_km")], 31980))
cl <- suppressWarnings(st_intersection(cl, st_geometry(cu)))
acc_cl <- st_make_valid(st_transform(st_read(P("data/inpe/accumulated_2007_cujubim_bbox.json"), quiet = TRUE), 31980))
acc_cl <- suppressWarnings(st_intersection(st_geometry(acc_cl), st_geometry(cu)))
rd <- st_read(P("data_clean/roads_cujubim.gpkg"), quiet = TRUE)
town <- st_transform(st_as_sf(data.frame(lon = -62.5832107, lat = -9.3687919), coords = c("lon", "lat"), crs = 4326), 31980)
pt_cl <- st_point_on_surface(st_geometry(cl))
nr <- st_nearest_feature(pt_cl, rd)
cl$road_m <- as.numeric(st_distance(pt_cl, rd[nr, ], by_element = TRUE))
cl_col <- ifelse(cl$year <= 2015, amber, red)
# ==== END BLOCK ====

# ==== BLOCK: f1_types DEPS: us ====
# Points, lines and polygons, each with its row: Warren Hall, one TIGER row of I-90, Tompkins County.
it <- st_read(P("data_clean/interstates_ny_box.gpkg"), quiet = TRUE)
ny <- states[states$STUSPS == "NY", ]
i90 <- suppressWarnings(st_intersection(it[it$FULLNAME == "I- 90", ], st_geometry(st_transform(ny, st_crs(it)))))
i90 <- i90[st_geometry_type(i90) == "LINESTRING", ]
one <- i90[which.max(as.numeric(st_length(i90))), ]
xy1 <- st_coordinates(one)
w <- 9.6; h <- 3.9; pw <- w / 3
canvas("f1_types.png", w, h)
kv <- function(x0, y0, keys, vals) {
  # one row of the layer, written as column: value; the last line is the geometry
  n <- length(keys); y <- y0 - (seq_len(n) - 1) * 0.22
  rect(x0 - 0.04, min(y) - 0.13, x0 + pw - 0.12, y0 + 0.13, col = "#F7F6F2", border = rule)
  rect(x0 - 0.04, y[n] - 0.13, x0 + pw - 0.12, y[n] + 0.11, col = "#FBEDED", border = NA)
  text(x0, y, keys, adj = 0, family = "mono", cex = 0.74, col = c(rep(blue, n - 1), acc))
  text(x0 + 0.8, y, vals, adj = 0, family = "mono", cex = 0.74, col = ink)
}
titles <- c("Point", "Line (red: one row of I-90)", "Polygon")
for (i in 1:3) text((i - 0.5) * pw, h - 0.15, titles[i], font = 2, cex = 1.05, col = ink)
kv(0.12, 1.02, c("name", "geometry"), c('"Warren Hall"', "POINT (-76.4797 42.449)"))
kv(pw + 0.12, 1.02, c("FULLNAME", "RTTYP", "geometry"), c('"I- 90"', '"I"', sprintf("LINESTRING (%.2f %.2f, ...", xy1[1, 1], xy1[1, 2])))
kv(2 * pw + 0.12, 1.02, c("GEOID", "NAME", "ALAND", "geometry"), c('"36109"', '"Tompkins"', "1229321859", "MULTIPOLYGON (((-76.70 42.55, ..."))
text(w / 2, 0.1, "Each box is one row of a layer (one feature): blue names are attributes, the red line is its geometry",
     cex = 0.9, col = ink)
panel_map <- function(i, draw) {
  par(fig = c((i - 1) / 3 + 0.02, i / 3 - 0.02, 1.32 / h, (h - 0.32) / h), new = TRUE, mar = c(0, 0, 0, 0))
  draw()
}
panel_map(1, function() {
  frame(st_buffer(st_transform(tk, 5070), 3000)); plot(st_geometry(st_transform(tk, 5070)), col = light, border = grey, add = TRUE)
  plot(st_geometry(wh_m), pch = 21, bg = acc, col = "white", cex = 1.8, add = TRUE)
  text(st_coordinates(wh_m)[1], st_coordinates(wh_m)[2] - 5500, "Warren Hall", cex = 0.8, col = ink)
})
panel_map(2, function() {
  frame(st_transform(ny, 5070), 5000); plot(st_geometry(st_transform(ny, 5070)), col = "#F4F2EC", border = rule, add = TRUE)
  plot(st_geometry(st_transform(i90, 5070)), col = "#8A8A8A", lwd = 1.6, add = TRUE)
  plot(st_geometry(st_transform(one, 5070)), col = acc, lwd = 5, add = TRUE)
})
par(fig = c(0, 1, 0, 1), new = TRUE, mar = c(0, 0, 0, 0)); plot.window(xlim = c(0, w), ylim = c(0, h), xaxs = "i", yaxs = "i")
panel_map(3, function() {
  frame(st_buffer(st_transform(tk, 5070), 3000)); plot(st_geometry(st_transform(tk, 5070)), col = NA, border = acc, lwd = 2.2, add = TRUE)
  cc <- st_coordinates(st_centroid(st_geometry(st_transform(tk, 5070))))
  text(cc[1], cc[2], "Tompkins County", cex = 0.8, col = ink)
})
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f2_globe ====
# The length of one degree on the globe: longitude in red (it shrinks toward the
# pole), latitude in blue (the same everywhere). Segments span 15 degrees.
w <- 7; h <- 3.3
canvas("f2_globe.png", w, h, ps = 12)
cx <- 3.5; cy <- 1.5; R <- 1.45
xy <- function(lon, lat) {                        # orthographic globe seen from the equator
  la <- lat * pi / 180; lo <- lon * pi / 180
  cbind(cx + R * cos(la) * sin(lo), cy + R * sin(la))
}
th <- seq(0, 2 * pi, length.out = 200)
polygon(cx + R * cos(th), cy + R * sin(th), col = "#F4F2EC", border = grey)
for (lon in seq(-75, 75, 15)) lines(xy(lon, seq(-90, 90, 2)), col = rule, lwd = 0.8)
for (lat in c(0, 42.45)) lines(xy(seq(-90, 90, 2), lat), col = rule, lwd = 0.8)
seg <- function(p, col) lines(p, col = col, lwd = 5, lend = 1)
# longitude: 15 degrees along the equator and along Ithaca's parallel, and the pole
e <- xy(seq(20, 35, 0.5), 0); i <- xy(seq(20, 35, 0.5), 42.45)
seg(e, acc); seg(i, acc)
points(cx, cy + R, pch = 16, col = acc, cex = 1.3)
text(mean(range(e[, 1])), cy + 0.15, "111 km", col = acc, font = 2, cex = 0.95)
text(mean(range(i[, 1])), i[1, 2] + 0.15, "82 km", col = acc, font = 2, cex = 0.95)
text(cx + 0.1, cy + R + 0.1, "0 km", adj = 0, col = acc, font = 2, cex = 0.95)
# latitude: 15 degrees along a meridian
l <- xy(-50, seq(10, 25, 0.5)); seg(l, blue)
text(max(l[, 1]) + 0.08, mean(range(l[, 2])), "111 km", adj = 0, col = blue, font = 2, cex = 0.95)
# place names, small, on the globe
text(cx - 0.1, cy + R + 0.1, "North Pole", adj = 1, col = ink, cex = 0.75)
text(xy(-55, 0)[1], cy - 0.12, "Equator", col = ink, cex = 0.75)
text(xy(-10, 42.45)[1], i[1, 2] - 0.12, "Ithaca, 42.45°N", adj = 1, col = ink, cex = 0.75)
# the two headings, one on each side of the globe
xr <- cx + R + 0.25; xl <- cx - R - 0.25
text(xr, 2.2, "One degree\nof longitude", adj = c(0, 0), col = acc, font = 2, cex = 1.25)
text(xr, 2.05, "shrinks toward\nthe poles", adj = c(0, 1), col = ink, cex = 0.9)
text(xl, 2.2, "One degree\nof latitude", adj = c(1, 0), col = blue, font = 2, cex = 1.25)
text(xl, 2.05, "is the same\neverywhere", adj = c(1, 1), col = ink, cex = 0.9)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f3_area DEPS: us ====
# Tompkins County in Conus Albers and in Web Mercator, drawn at one scale.
a <- st_geometry(st_transform(tk, 5070)); b <- st_geometry(st_transform(tk, 3857))
shift <- function(g, dx) { bb <- st_bbox(g); g - c(bb[["xmin"]] - dx, bb[["ymin"]]) }
a2 <- shift(a, 0); b2 <- shift(b, diff(st_bbox(a)[c(1, 3)]) + 8000)
st_crs(a2) <- NA; st_crs(b2) <- NA
fig("f3_area.png", 4.6, 3.0, mar = c(0.2, 0.2, 0.2, 0.2), ps = 18)
bb <- st_bbox(c(a2, b2))
plot(c(a2, b2), border = NA, xlim = c(bb[1], bb[3]), ylim = c(bb[2] - 9000, bb[4] + 3000))
plot(a2, col = "#F4F2EC", border = blue, lwd = 2, add = TRUE)
plot(b2, col = "#FBEDED", border = acc, lwd = 2, add = TRUE)
ca <- st_coordinates(st_centroid(a2)); cb <- st_coordinates(st_centroid(b2))
text(ca[1], ca[2] + 3000, "Conus Albers\n1,273 km²", col = blue, cex = 0.85, font = 2)
text(cb[1], cb[2] + 3000, "Web Mercator\n2,340 km²", col = acc, cex = 0.85, font = 2)
segments(bb[1], bb[2] - 6000, bb[1] + 10000, bb[2] - 6000, lwd = 3)
text(bb[1] + 5000, bb[2] - 8200, "10 km", cex = 0.75)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f4_border DEPS: us ====
# Warren Hall, the NY-PA line and the shortest segment to Pennsylvania.
pa_m <- states_m[states_m$STUSPS == "PA", ]; ny_m <- states_m[states_m$STUSPS == "NY", ]
seg <- st_nearest_points(wh_m, pa_m)
box <- st_buffer(wh_m, 75000)
fig("f4_border.png", 4.4, 3.2, ps = 16)
frame(box)
plot(st_geometry(low), col = "#F7F6F2", border = "white", lwd = 0.6, add = TRUE)
plot(st_geometry(ny_m), col = adjustcolor(blue, 0.10), border = NA, add = TRUE)
plot(st_geometry(pa_m), col = adjustcolor(amber, 0.12), border = NA, add = TRUE)
plot(st_geometry(low[low$STUSPS %in% c("NY", "PA"), ]), col = NA, border = rule, lwd = 0.6, add = TRUE)
plot(st_intersection(st_boundary(st_geometry(ny_m)), st_geometry(st_buffer(pa_m, 100))), col = ink, lwd = 3, add = TRUE)
plot(seg, col = acc, lwd = 2.5, add = TRUE)
plot(st_geometry(wh_m), pch = 21, bg = acc, col = "white", cex = 1.6, add = TRUE)
p <- st_coordinates(seg)
text(p[1, 1] + 5000, mean(p[, 2]), "50.3 km", adj = 0, col = acc, font = 2, cex = 0.95)
text(p[1, 1], p[1, 2] + 7000, "Warren Hall", col = ink, cex = 0.85)
bb <- st_bbox(box)
text(bb[["xmin"]] + 4000, bb[["ymax"]] - 8000, "New York", adj = 0, col = blue, font = 2)
text(bb[["xmin"]] + 4000, bb[["ymin"]] + 8000, "Pennsylvania", adj = 0, col = "#9A6B00", font = 2)
text(bb[["xmax"]] - 3000, p[2, 2] + 5000, "state line", adj = 1, col = ink, cex = 0.8)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f5_twin DEPS: us ====
# I-81 at Cortland: the two directions of a divided highway are two lines in the file.
it <- st_read(P("data_clean/interstates_ny_box.gpkg"), quiet = TRUE)
two <- st_transform(it[it$LINEARID %in% c("110784636091", "110784636096"), ], 5070)
ctr <- st_transform(st_sfc(st_point(c(-76.1768, 42.6092)), crs = 4326), 5070)
box <- st_buffer(ctr, 650)
fig("f5_twin.png", 3.6, 3.0, ps = 15)
frame(box)
cols <- c(acc, blue)
for (j in 1:2) plot(st_geometry(two[j, ]), col = cols[j], lwd = 2.2, add = TRUE)
bb <- st_bbox(box)
segments(bb[["xmin"]] + 60, bb[["ymin"]] + 70, bb[["xmin"]] + 560, bb[["ymin"]] + 70, lwd = 3)
text(bb[["xmin"]] + 310, bb[["ymin"]] + 140, "500 m", cex = 0.8)
text(bb[["xmax"]] - 40, bb[["ymax"]] - 70, "I-81 near Cortland, NY\ntwo rows of the file,\n44 to 46 m apart here", adj = c(1, 1), cex = 0.8, col = ink)
legend("bottomright", c("northbound", "southbound"), col = cols, lwd = 2.2, bty = "n", cex = 0.75, inset = 0.02)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f6_neighbours DEPS: us ====
# Tompkins County and the six counties that touch it.
nb <- st_touches(low); i <- which(low$GEOID == "36109")
sev <- low[c(i, nb[[i]]), ]
fig("f6_neighbours.png", 4.2, 3.4, ps = 16)
frame(sev, 12000)
plot(st_geometry(low[low$STUSPS %in% c("NY", "PA"), ]), col = "#F7F6F2", border = "white", add = TRUE)
plot(st_geometry(low[nb[[i]], ]), col = adjustcolor(blue, 0.25), border = "white", lwd = 1.5, add = TRUE)
plot(st_geometry(low[i, ]), col = acc, border = "white", lwd = 1.5, add = TRUE)
pp <- st_coordinates(st_point_on_surface(st_geometry(sev)))
text(pp[-1, 1], pp[-1, 2], sev$NAME[-1], cex = 0.78, col = ink)
for (a in seq(0, 2 * pi, length.out = 13)) text(pp[1, 1] + 700 * cos(a), pp[1, 2] - 9000 + 700 * sin(a), "Tompkins", cex = 0.85, font = 2, col = "white")
text(pp[1, 1], pp[1, 2] - 9000, "Tompkins", cex = 0.85, font = 2, col = acc)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f8_graph DEPS: us ====
# Central New York's counties as nodes, shared borders as edges.
nb <- st_touches(low); i <- which(low$GEOID == "36109")
ctr <- st_geometry(st_point_on_surface(st_geometry(low[i, ])))
near <- which(as.numeric(st_distance(st_point_on_surface(st_geometry(low)), ctr)) < 130000)
pts <- st_coordinates(st_point_on_surface(st_geometry(low)))
fig("f8_graph.png", 4.4, 3.4, ps = 16)
frame(st_buffer(ctr, 115000))
plot(st_geometry(low[near, ]), col = "#F7F6F2", border = "#D9D6CE", add = TRUE)
for (a in near) for (b in nb[[a]]) if (b %in% near && b > a) {
  tkedge <- a == i || b == i
  segments(pts[a, 1], pts[a, 2], pts[b, 1], pts[b, 2], col = if (tkedge) acc else grey, lwd = if (tkedge) 2.2 else 0.9)
}
points(pts[near, 1], pts[near, 2], pch = 21, bg = ifelse(near == i, acc, "white"), col = ink, cex = 1.1)
for (a in seq(0, 2 * pi, length.out = 13)) text(pts[i, 1] + 14000 + 900 * cos(a), pts[i, 2] - 11000 + 900 * sin(a), "Tompkins", cex = 0.85, font = 2, col = "white")
text(pts[i, 1] + 14000, pts[i, 2] - 11000, "Tompkins", cex = 0.85, col = acc, font = 2)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f12_medicaid DEPS: med ====
# Expansion status in the lower 48 and DC, with the line between the two groups.
st48 <- states_m[!states_m$STUSPS %in% off, ]
grp <- med$group[match(st48$STUSPS, med$state)]
fills <- ifelse(grp == "expanded 2014", adjustcolor(blue, 0.55), ifelse(grp == "not expanded by 2018", adjustcolor(amber, 0.55), "#E8E6E0"))
fig("f12_medicaid.png", 5.0, 3.3, ps = 17)
frame(st48)
plot(st_geometry(st48), col = fills, border = "white", lwd = 0.8, add = TRUE)
plot(ln, col = ink, lwd = 2.2, add = TRUE)
legend("bottomleft", c("expanded in 2014", "not expanded by the end of 2018", "expanded 2015-16, left out", "the line between the first two"),
       fill = c(adjustcolor(blue, 0.55), adjustcolor(amber, 0.55), "#E8E6E0", NA), border = NA,
       col = c(NA, NA, NA, ink), lwd = c(NA, NA, NA, 2.2), bty = "n", cex = 0.62, inset = c(-0.02, -0.03))
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f13_kytn DEPS: med ====
# The Kentucky-Tennessee line: border counties, their 30 pairs, two signed distances.
kt <- pairs[k$STUSPS[pairs$e] == "KY" & k$STUSPS[pairs$n] == "TN", ]
rows <- unique(c(kt$e, kt$n))
pc <- st_coordinates(pt_co)
lnkt <- st_intersection(ln, st_buffer(st_union(st_geometry(k[rows, ])), 2000))
fig("f13_kytn.png", 9.4, 2.6, ps = 14)
frame(k[rows, ], 9000)
plot(st_geometry(k[k$STUSPS %in% c("KY", "TN", "VA", "MO", "IL", "IN", "OH", "WV", "AR", "MS", "AL", "GA", "NC"), ]),
     col = "#F7F6F2", border = "white", add = TRUE)
plot(st_geometry(k[rows, ]), col = ifelse(k$exp14[rows], adjustcolor(blue, 0.35), adjustcolor(amber, 0.35)), border = "white", add = TRUE)
plot(lnkt, col = ink, lwd = 2.5, add = TRUE)
segments(pc[kt$e, 1], pc[kt$e, 2], pc[kt$n, 1], pc[kt$n, 2], col = grey, lwd = 1)
points(pc[rows, 1], pc[rows, 2], pch = 16, cex = 0.5, col = ink)
for (g in c("21213", "47147")) {
  r <- which(k$GEOID == g); sg <- st_coordinates(st_nearest_points(pt_co[r], ln))
  arrows(sg[1, 1], sg[1, 2], sg[2, 1], sg[2, 2], length = 0.06, col = acc, lwd = 2)
  lab <- sprintf("%s, %s: %+.1f km", k$NAME[r], k$STUSPS[r], k$dist_km[r])
  text(sg[1, 1], sg[1, 2] + ifelse(k$exp14[r], 9000, -9000), lab, col = acc, font = 2, cex = 0.85)
}
bb <- st_bbox(k[rows, ])
text(bb[["xmin"]], bb[["ymax"]] + 5000, "Kentucky (expanded 2014): 17 border counties", adj = 0, col = blue, font = 2, cex = 0.85)
text(bb[["xmin"]], bb[["ymin"]] - 7000, "Tennessee (not expanded): 14 border counties", adj = 0, col = "#9A6B00", font = 2, cex = 0.85)
text(bb[["xmax"]], bb[["ymin"]] - 7000, "grey links: the 30 pairs that touch across the line", adj = 1, col = ink, cex = 0.9)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f23_pairs DEPS: med ====
# From the list st_touches() returns to rows of pairs: Simpson County, KY.
s <- which(k$GEOID == "21213"); nbs <- nbk[[s]]
canvas("f23_pairs.png", 4.6, 2.9, ps = 15)
text(0.15, 2.75, sprintf("nbk[[%d]]  Simpson, KY", s), adj = 0, family = "mono", font = 2, cex = 0.82)
for (j in seq_along(nbs)) {
  y <- 2.45 - (j - 1) * 0.3; keep <- !k$exp14[nbs[j]]
  text(0.15, y, sprintf("%4d  %s, %s", nbs[j], k$NAME[nbs[j]], k$STUSPS[nbs[j]]), adj = 0, family = "mono", cex = 0.78,
       col = if (keep) ink else "#9C9A94")
  if (keep) arrows(2.45, y, 2.8, y, length = 0.06, col = acc, lwd = 1.5)
  else text(2.45, y, "same side: dropped", adj = 0, cex = 0.68, col = "#9C9A94")
}
text(2.9, 2.75, "rows of pairs", adj = 0, family = "mono", font = 2, cex = 0.82)
text(2.9, 2.55, sprintf("%4s  %4s", "e", "n"), adj = 0, family = "mono", cex = 0.78, col = grey)
kk <- 0
for (j in seq_along(nbs)) if (!k$exp14[nbs[j]]) {
  y <- 2.45 - (j - 1) * 0.3
  text(2.9, y, sprintf("%4d  %4d", s, nbs[j]), adj = 0, family = "mono", cex = 0.78, col = acc)
}
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f14_signed DEPS: med ====
# Counties within 150 km of the line, by signed distance.
near <- abs(k$dist_km) <= 150
br <- seq(-150, 150, 25)
pal <- c(colorRampPalette(c("#9A6B00", "#F3DFA8"))(6), colorRampPalette(c("#C9DAEA", "#1F4E79"))(6))
fig("f14_signed.png", 5.0, 3.3, ps = 17)
frame(low)
plot(st_geometry(states_m[!states_m$STUSPS %in% off, ]), col = "#F4F2EC", border = "white", add = TRUE)
plot(st_geometry(k[near, ]), col = pal[cut(k$dist_km[near], br)], border = NA, add = TRUE)
plot(ln, col = ink, lwd = 1.4, add = TRUE)
bb <- st_bbox(low); x0 <- bb[["xmin"]] + 0.02 * diff(bb[c(1, 3)]); y0 <- bb[["ymin"]] + 0.02 * diff(bb[c(2, 4)])
cw <- 0.035 * diff(bb[c(1, 3)]); ch <- 0.035 * diff(bb[c(2, 4)])
rect(x0 + (0:11) * cw, y0, x0 + (1:12) * cw, y0 + ch, col = pal, border = NA)
text(x0 + c(0, 6, 12) * cw, y0 - 0.6 * ch, c("-150 km", "0", "+150 km"), cex = 0.62)
text(x0, y0 + 2.0 * ch, "signed distance to the line\nminus: the side that did not expand", adj = c(0, 0), cex = 0.62)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f17_cujubim DEPS: amazon ====
# Cujubim: clearings by period, OpenStreetMap roads, the town, and where it sits in Rondonia.
fig("f17_cujubim.png", 9.4, 4.6, ps = 15)
par(fig = c(0, 0.62, 0, 1))
frame(cu, 1500)
plot(st_geometry(cu), col = "#EEF3E8", border = ink, lwd = 1.4, add = TRUE)
plot(acc_cl, col = "grey72", border = NA, add = TRUE)
plot(st_geometry(cl), col = cl_col, border = NA, add = TRUE)
plot(st_geometry(rd), col = blue, lwd = 0.6, add = TRUE)
plot(st_geometry(town), pch = 21, bg = "white", col = ink, cex = 1.5, add = TRUE)
bb <- st_bbox(cu)
segments(bb[["xmin"]], bb[["ymin"]] - 500, bb[["xmin"]] + 20000, bb[["ymin"]] - 500, lwd = 3)
text(bb[["xmin"]] + 10000, bb[["ymin"]] + 1800, "20 km", cex = 0.75)
par(fig = c(0.6, 1, 0.36, 0.98), new = TRUE, mar = c(0, 0, 0, 0))
plot.new()
legend("left", c("cleared by 2007", "cleared 2008-2015", "cleared 2016-2025", "road (OpenStreetMap)", "the town of Cujubim", "Cujubim's boundary"),
       fill = c("grey72", amber, red, NA, NA, NA), border = NA, col = c(NA, NA, NA, blue, ink, ink),
       lwd = c(NA, NA, NA, 1.5, NA, 1.4), pch = c(NA, NA, NA, NA, 21, NA), pt.bg = "white", bty = "n", cex = 0.85,
       title = "Clearings (forest cut to the ground) by the\nyear PRODES mapped them", title.adj = 0)
par(fig = c(0.66, 0.98, 0.0, 0.36), new = TRUE, mar = c(0, 0, 0, 0))
ro <- st_transform(mun, 31980)
plot(st_geometry(ro), col = "#F4F2EC", border = "white", lwd = 0.4)
plot(st_geometry(cu), col = acc, border = NA, add = TRUE)
plot(st_geometry(st_union(ro)), col = NA, border = grey, add = TRUE)
text(st_bbox(ro)[["xmin"]], st_bbox(ro)[["ymin"]], "Rondonia, Brazil", adj = c(0, 0), cex = 0.7, col = grey)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f24_nearest DEPS: amazon ====
# One clearing near the 2013-17 median distance, its interior point and the gap to its nearest road.
cand <- which(cl$year %in% 2013:2017 & abs(cl$road_m - 664) < 15 & as.numeric(st_area(cl)) > 2e5 & as.numeric(st_area(cl)) < 1.2e6)
j <- cand[1]
seg <- st_nearest_points(pt_cl[j], rd[nr[j], ])
box <- st_buffer(st_centroid(st_geometry(cl[j, ])), 1600)
fig("f24_nearest.png", 3.6, 3.0, ps = 15)
frame(box)
plot(st_geometry(cl[lengths(st_intersects(cl, box)) > 0, ]), col = adjustcolor(cl_col[lengths(st_intersects(cl, box)) > 0], 0.35), border = NA, add = TRUE)
plot(st_geometry(cl[j, ]), col = cl_col[j], border = ink, add = TRUE)
plot(st_intersection(st_geometry(rd), box), col = blue, lwd = 1.8, add = TRUE)
plot(seg, col = ink, lwd = 2, lty = 1, add = TRUE)
plot(pt_cl[j], pch = 21, bg = "white", col = ink, cex = 1.3, add = TRUE)
p <- st_coordinates(seg)
halo <- function(x, y, lab, col = ink, ...) {   # white outline behind a label
  for (a in seq(0, 2 * pi, length.out = 13)) text(x + 22 * cos(a), y + 22 * sin(a), lab, col = "white", ...)
  text(x, y, lab, col = col, ...)
}
halo(mean(p[, 1]), mean(p[, 2]) + 150, paste0(round(cl$road_m[j]), " m"), font = 2, cex = 0.9, col = ink)
bb <- st_bbox(box)
halo(bb[["xmin"]] + 900, bb[["ymin"]] + 140, sprintf("one clearing, %d, %.2f km²", cl$year[j], as.numeric(st_area(cl[j, ])) / 1e6),
     cex = 0.75, col = ink)
dev.off()
cat("f24 clearing", j, cl$year[j], round(cl$road_m[j]), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f19_network DEPS: amazon ====
# Left: corners of one road become nodes, stretches become edges. Right: one clearing's route to the town.
xy <- st_coordinates(rd)
key <- paste(round(xy[, "X"], 1), round(xy[, "Y"], 1))
same <- xy[-nrow(xy), "L1"] == xy[-1, "L1"]
len <- sqrt(diff(xy[, "X"])^2 + diff(xy[, "Y"])^2)
ed <- data.frame(from = key[-nrow(xy)][same], to = key[-1][same], weight = len[same])
gr <- graph_from_data_frame(ed, directed = FALSE)
nodes <- st_as_sf(data.frame(x = as.numeric(sub(" .*", "", V(gr)$name)), y = as.numeric(sub(".* ", "", V(gr)$name))),
                  coords = c("x", "y"), crs = 31980)
tn <- st_nearest_feature(town, nodes)
town_m <- distances(gr, v = tn)[1, ]
cn <- st_nearest_feature(pt_cl, nodes)
cl$road_km <- town_m[cn] / 1000
cl$line_km <- as.numeric(st_distance(pt_cl, town)) / 1000
ok <- is.finite(cl$road_km)
med_km <- median(cl$road_km[ok])
j <- which(ok & cl$year == 2016)[which.min(abs(cl$road_km[ok & cl$year == 2016] - med_km))]
path <- shortest_paths(gr, from = tn, to = cn[j], output = "vpath")$vpath[[1]]
pxy <- st_coordinates(nodes[as.integer(path), ])
fig("f19_network.png", 9.4, 3.4, ps = 16)
# left panel: the first road's first corners
par(fig = c(0, 0.36, 0, 1))
r1 <- xy[xy[, "L1"] == 1, ][1:5, ]
plot(r1[, 1], r1[, 2], type = "n", asp = 1, axes = FALSE, xlab = "", ylab = "",
     xlim = range(r1[, 1]) + c(-900, 300), ylim = range(r1[, 2]) + c(-160, 160))
lines(r1[, 1], r1[, 2], col = blue, lwd = 2.5)
points(r1[, 1], r1[, 2], pch = 21, bg = "white", col = ink, cex = 1.4)
for (q in 1:3) text(mean(r1[q:(q + 1), 1]), mean(r1[q:(q + 1), 2]), paste0(round(len[q]), " m"), pos = 4, cex = 0.8, col = acc, font = 2)
text(r1[1, 1], r1[1, 2], paste0('"', key[1], '"'), pos = 2, cex = 0.72, family = "mono")
text(r1[2, 1], r1[2, 2], paste0('"', key[2], '"'), pos = 2, cex = 0.72, family = "mono")
mtext("corners: nodes; stretches: edges", side = 1, line = -1, cex = 0.9, col = ink)
# right panel: the median clearing's route
par(fig = c(0.36, 1, 0, 1), new = TRUE)
box <- st_buffer(st_as_sfc(st_bbox(c(st_geometry(town), pt_cl[j]))), 4000)
frame(box)
plot(st_intersection(st_geometry(rd), box), col = "#B9CBDD", lwd = 0.7, add = TRUE)
lines(pxy[, 1], pxy[, 2], col = acc, lwd = 2.6)
tc <- st_coordinates(town); cc <- st_coordinates(pt_cl[j])
segments(tc[1], tc[2], cc[1], cc[2], lty = 2, lwd = 1.6, col = ink)
points(tc[1], tc[2], pch = 21, bg = "white", col = ink, cex = 1.5); points(cc[1], cc[2], pch = 22, bg = red, col = ink, cex = 1.3)
text(tc[1], tc[2], "town", pos = 4, cex = 0.8)
text(cc[1], cc[2], sprintf("a %d clearing", cl$year[j]), pos = 2, cex = 0.8)
legend("bottomright", c(sprintf("along the roads: %.1f km", cl$road_km[j]), sprintf("straight line: %.1f km", cl$line_km[j])),
       col = c(acc, ink), lty = c(1, 2), lwd = c(2.6, 1.6), bty = "n", cex = 0.8)
dev.off()
cat("f19 median", round(med_km, 1), "example", round(cl$road_km[j], 1), round(cl$line_km[j], 1), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f21_north DEPS: amazon ====
# The block north of 9 degrees south: newest clearing, fewest mapped roads.
s9 <- st_transform(st_sfc(st_linestring(rbind(c(-63.2, -9), c(-62.2, -9))), crs = 4326), 31980)
north <- st_as_sfc(st_bbox(c(xmin = -63.2, ymin = -9, xmax = -62.2, ymax = -8.6), crs = st_crs(4326)))
north <- st_intersection(st_geometry(cu), st_transform(north, 31980))
rest <- st_difference(st_geometry(cu), north)
dens <- function(a) as.numeric(sum(st_length(st_intersection(st_geometry(rd), a)))) / 1e3 / (as.numeric(st_area(a)) / 1e8)
dn <- dens(north); ds <- dens(rest)
fig("f21_north.png", 5.4, 3.4, ps = 15)
frame(cu, 600)
plot(st_geometry(cu), col = "#EEF3E8", border = ink, add = TRUE)
plot(acc_cl, col = "grey80", border = NA, add = TRUE)
plot(st_geometry(cl[cl$year >= 2016, ]), col = red, border = NA, add = TRUE)
plot(st_geometry(cl[cl$year <= 2015, ]), col = amber, border = NA, add = TRUE)
plot(st_geometry(rd), col = blue, lwd = 0.8, add = TRUE)
plot(s9, col = ink, lty = 2, lwd = 1.6, add = TRUE)
bb <- st_bbox(north)
text(bb[["xmax"]] - 500, bb[["ymin"]] + 1500, "9°S", adj = 1, cex = 0.8)
legend("topleft", c(sprintf("north of 9°S: %.0f km of mapped road per 100 km²", dn), sprintf("the rest of Cujubim: %.0f km per 100 km²", ds),
       "cleared 2016-2025", "cleared 2008-2015", "road (OpenStreetMap)"), fill = c(NA, NA, red, amber, NA), border = NA,
       col = c(NA, NA, NA, NA, blue), lwd = c(NA, NA, NA, NA, 1.2), bg = "white", box.col = rule, cex = 0.72, inset = 0.01)
dev.off()
cat("f21 densities", round(dn, 1), round(ds, 1), "\n")
# ==== END BLOCK ====

# ==== BLOCK: f22_join DEPS: us ====
# Warren Hall and the county that holds it, among New York's 62 counties.
ny_co <- st_transform(co[co$STUSPS == "NY", ], 5070)
tk_m <- ny_co[ny_co$GEOID == "36109", ]
lab_halo <- function(xy, lab, col = ink, d = 2500, ...) {   # white outline behind a label
  for (a in seq(0, 2 * pi, length.out = 13)) text(xy[1] + d * cos(a), xy[2] + d * sin(a), lab, col = "white", ...)
  text(xy[1], xy[2], lab, col = col, ...)
}
fig("f22_join.png", 4.2, 3.4, mar = c(0, 0, 1.3, 0), ps = 18)
plot(st_geometry(ny_co), col = "#F4F2EC", border = "#9A9A9A", lwd = 0.6)
plot(st_geometry(tk_m), col = acc, border = acc, lwd = 1, add = TRUE)
xy_w <- st_coordinates(wh_m)
lab_halo(xy_w + c(0, 38000), "Warren Hall", col = blue, cex = 0.8, font = 2)
points(xy_w[1], xy_w[2], pch = 21, bg = blue, col = "white", cex = 1.0, lwd = 1)   # last, so no label covers it
mtext("Red: Tompkins County, 36109", side = 3, line = 0.2, col = acc, font = 2, cex = 0.85)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f25_direction DEPS: us ====
# In Conus Albers, map north at Warren Hall tilts about 12 degrees from true north (the meridian),
# so the map's angle to Times Square (120) misses the true direction (131).
ny_m <- states_m[states_m$STUSPS == "NY", ]
ts_m <- st_transform(st_as_sf(data.frame(lon = -73.9855, lat = 40.7580), coords = c("lon", "lat"), crs = 4326), 5070)
xy_w <- st_coordinates(wh_m)[1, ]; xy_t <- st_coordinates(ts_m)[1, ]
mer <- st_coordinates(st_transform(st_sfc(st_linestring(cbind(-76.4797, seq(42.449, 43.90, length.out = 20))), crs = 4326), 5070))
L <- sqrt(sum((mer[nrow(mer), 1:2] - xy_w)^2))                 # arrow length, metres
halo <- function(x, y, lab, col = ink, d = 2500, ...) {
  for (a in seq(0, 2 * pi, length.out = 13)) text(x + d * cos(a), y + d * sin(a), lab, col = "white", ...)
  text(x, y, lab, col = col, ...)
}
arc <- function(a0, a1, r, ...) {                               # angles clockwise from map north, degrees
  a <- seq(a0, a1, length.out = 40) * pi / 180
  lines(xy_w[1] + r * sin(a), xy_w[2] + r * cos(a), ...)
}
fig("f25_direction.png", 3.7, 3.0, mar = c(0, 0, 1.4, 0), ps = 18)
frame(st_union(st_geometry(ny_m)), m = 5000)
plot(st_geometry(ny_m), col = "#F4F2EC", border = "#9A9A9A", lwd = 0.8, add = TRUE)
arrows(xy_w[1], xy_w[2], xy_w[1], xy_w[2] + L, length = 0.08, col = grey, lwd = 2)               # map north
lines(mer[, 1], mer[, 2], col = blue, lwd = 2)                                                       # true north
arrows(mer[nrow(mer) - 1, 1], mer[nrow(mer) - 1, 2], mer[nrow(mer), 1], mer[nrow(mer), 2], length = 0.08, col = blue, lwd = 2)
segments(xy_w[1], xy_w[2], xy_t[1], xy_t[2], col = acc, lwd = 2.4)                             # to Times Square
arc(-11.8, 0, 0.55 * L, col = ink, lwd = 1.2)
halo(xy_w[1] - 0.17 * L, xy_w[2] + 0.70 * L, "12°", cex = 0.75, font = 2)
halo(xy_w[1] + 0.05 * L, xy_w[2] + 1.10 * L, "map north", col = grey, cex = 0.7, font = 2, adj = 0)
halo(mer[nrow(mer), 1] - 0.05 * L, mer[nrow(mer), 2] + 0.10 * L, "true north", col = blue, cex = 0.7, font = 2, adj = 1)
points(xy_w[1], xy_w[2], pch = 21, bg = blue, col = "white", cex = 1.1, lwd = 1)
points(xy_t[1], xy_t[2], pch = 21, bg = acc, col = "white", cex = 1.1, lwd = 1)
halo(xy_w[1] - 0.08 * L, xy_w[2] - 0.16 * L, "Warren Hall", col = blue, cex = 0.7, font = 2, adj = 1)
halo(xy_t[1] - 0.10 * L, xy_t[2] - 0.10 * L, "Times Square", col = acc, cex = 0.7, font = 2, adj = 1)
mtext("New York in Conus Albers", side = 3, line = 0.25, col = ink, font = 2, cex = 0.8)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f26_order DEPS: us ====
# Tompkins County, its 6 first neighbours and its 12 second neighbours (9 in New York, 3 in Pennsylvania).
nb_o <- st_touches(low); i_o <- which(low$GEOID == "36109")
g_o <- graph_from_adj_list(nb_o, mode = "all")
ord <- as.vector(distances(g_o, i_o))
near_o <- low[ord <= 3, ]
cols_o <- c(acc, blue, "#A9C4DE", "#F1EFEA")[pmin(ord[ord <= 3], 3) + 1]
fig("f26_order.png", 4.4, 3.0, mar = c(0, 0, 0, 0), ps = 18)
b2 <- st_bbox(st_union(st_geometry(low[ord <= 2, ])))
b2[["xmin"]] <- b2[["xmin"]] - 135000; b2[["ymax"]] <- b2[["ymax"]] + 50000   # room for the legend
frame(st_as_sfc(b2), m = 8000)
plot(st_geometry(low[ord > 3 | !is.finite(ord), ]), col = "#F1EFEA", border = "white", lwd = 0.8, add = TRUE)
plot(st_geometry(near_o), col = cols_o, border = "white", lwd = 0.8, add = TRUE)
plot(st_boundary(st_geometry(states_m[states_m$STUSPS == "NY", ])), col = ink, lwd = 2, add = TRUE)
bb <- st_bbox(st_union(st_geometry(low[ord <= 2, ])))
text(bb[["xmax"]] - 6000, bb[["ymin"]] + 12000, "Pennsylvania", adj = c(1, 0), cex = 0.72, font = 2, col = ink)
text(b2[["xmin"]] + 50000, bb[["ymin"]] + 120000, "New York", adj = c(0, 0), cex = 0.72, font = 2, col = ink)
legend("topleft", c("Tompkins", "first neighbours (6)", "second neighbours (12)"),
       fill = c(acc, blue, "#A9C4DE"), border = "white", bg = "white", box.col = rule, cex = 0.72, inset = 0.01)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: ny DEPS: us ====
# New York's counties, a point inside each, Times Square and the Interstates cut at the state line.
ny_m  <- states_m[states_m$STUSPS == "NY", ]
nym   <- st_transform(co[co$STUSPS == "NY", ], 5070)
pt_ny <- st_point_on_surface(st_geometry(nym))
ts_m  <- st_transform(st_as_sf(data.frame(lon = -73.9855, lat = 40.7580), coords = c("lon", "lat"), crs = 4326), 5070)
it    <- st_read(P("data_clean/interstates_ny_box.gpkg"), quiet = TRUE)
it_ny <- suppressWarnings(st_intersection(st_transform(it, 5070), ny_m["STUSPS"]))
halo <- function(x, y, lab, col = ink, d = 2500, ...) {          # white outline behind a label
  for (a in seq(0, 2 * pi, length.out = 13)) text(x + d * cos(a), y + d * sin(a), lab, col = "white", ...)
  text(x, y, lab, col = col, ...)
}
shade <- function(v, br, pal) pal[cut(v, br, include.lowest = TRUE)]
# ==== END BLOCK ====

# ==== BLOCK: f27_ts DEPS: ny ====
# Each New York county's distance to Times Square, from a point inside the county.
km_ts <- as.numeric(st_distance(pt_ny, ts_m)) / 1e3
br <- c(0, 100, 200, 300, 400, 500); pal <- hcl.colors(7, "Blues 3", rev = TRUE)[2:6]
fig("f27_ts.png", 4.4, 3.0, mar = c(0, 0, 0, 0), ps = 18)
plot(st_geometry(nym), col = shade(km_ts, br, pal), border = "white", lwd = 0.6)
plot(st_geometry(nym[nym$GEOID == "36109", ]), border = acc, lwd = 2.2, add = TRUE)
xy <- st_coordinates(ts_m)
points(xy[1], xy[2], pch = 21, bg = acc, col = "white", cex = 1.2, lwd = 1)
halo(xy[1] - 15000, xy[2] + 15000, "Times Square", col = acc, cex = 0.7, font = 2, adj = 1)
legend("topleft", c("0-100 km", "100-200", "200-300", "300-400", "400-500"), fill = pal, border = "white",
       bty = "n", cex = 0.65, inset = c(0, 0.0))
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f28_nearest DEPS: ny ====
# Each New York county's distance to the nearest Interstate, and Warren Hall's nearest, I-81 at 30 km.
kk <- st_nearest_feature(pt_ny, it_ny)
km_it <- as.numeric(st_distance(pt_ny, it_ny[kk, ], by_element = TRUE)) / 1e3
br <- c(0, 10, 20, 40, 80); pal <- hcl.colors(6, "Purples 3", rev = TRUE)[2:5]
k_wh <- st_nearest_feature(wh_m, it_ny)
seg <- st_nearest_points(wh_m, it_ny[k_wh, ])
fig("f28_nearest.png", 4.4, 3.0, mar = c(0, 0, 0, 0), ps = 18)
plot(st_geometry(nym), col = shade(km_it, br, pal), border = "white", lwd = 0.6)
plot(st_geometry(it_ny), col = ink, lwd = 1.1, add = TRUE)
plot(seg, col = acc, lwd = 2.6, add = TRUE)
xy <- st_coordinates(wh_m)
points(xy[1], xy[2], pch = 21, bg = acc, col = "white", cex = 1.2, lwd = 1)
halo(xy[1] - 12000, xy[2] - 22000, "Warren Hall", col = acc, cex = 0.7, font = 2, adj = 1)
legend("topleft", c("county to nearest", "Interstate: 0-10 km", "10-20", "20-40", "40-80"),
       fill = c(NA, pal), border = c(NA, rep("white", 4)), bty = "n", cex = 0.62)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f29_lines DEPS: ny ====
# Straight lines joining New York's five largest metro areas' main cities, the shortest network that
# connects them (a minimum spanning tree), drawn over the Interstates.
city <- st_transform(st_as_sf(data.frame(name = c("New York", "Buffalo", "Rochester", "Syracuse", "Albany"),
          lon = c(-74.0060, -78.8784, -77.6088, -76.1474, -73.7562), lat = c(40.7128, 42.8864, 43.1566, 43.0481, 42.6526)),
          coords = c("lon", "lat"), crs = 4326), 5070)
d_c <- matrix(as.numeric(st_distance(city)), 5) / 1e3
tree <- mst(graph_from_adjacency_matrix(d_c, mode = "undirected", weighted = TRUE))
e_c <- as_edgelist(tree, names = FALSE); xy_c <- st_coordinates(city)
ln_c <- st_sfc(lapply(seq_len(nrow(e_c)), function(r) st_linestring(xy_c[e_c[r, ], ])), crs = 5070)
fig("f29_lines.png", 4.4, 3.0, mar = c(0, 0, 0, 0), ps = 18)
plot(st_geometry(nym), col = "#F4F2EC", border = "white", lwd = 0.6)
plot(st_geometry(it_ny), col = "#8A8A8A", lwd = 1.4, add = TRUE)
plot(ln_c, col = acc, lwd = 2.6, lty = 2, add = TRUE)
points(xy_c[, 1], xy_c[, 2], pch = 21, bg = acc, col = "white", cex = 1.2, lwd = 1)
off_c <- rbind(c(25000, -5000), c(0, -30000), c(-10000, 28000), c(5000, -30000), c(10000, 26000))
adj_c <- c(0, 0.5, 0.5, 0.5, 0.5)
for (r in 1:5) halo(xy_c[r, 1] + off_c[r, 1], xy_c[r, 2] + off_c[r, 2], city$name[r], col = acc, cex = 0.62, font = 2, adj = adj_c[r])
legend("bottomleft", c("straight lines between cities", "Interstates"), col = c(acc, "#8A8A8A"), lty = c(2, 1),
       lwd = c(2.6, 1.4), bty = "n", cex = 0.62, inset = c(0, 0.02))
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f30_sci DEPS: us ====
# Facebook friendship links between Tompkins County and every county of the lower 48 (Meta's
# Social Connectedness Index), in quintile bands. College towns stand out far away.
sci <- read.csv(P("data_clean/sci_tompkins.csv"), colClasses = c(GEOID = "character"))
v <- sci$sci[match(low$GEOID, sci$GEOID)]
q <- quantile(v[low$GEOID != "36109"], c(0, 0.5, 0.8, 0.95, 0.99, 1), na.rm = TRUE)
pal <- hcl.colors(5, "YlGnBu", rev = TRUE)
cl_s <- ifelse(is.na(v), "grey85", pal[cut(v, q, include.lowest = TRUE)])
cl_s[low$GEOID == "36109"] <- acc
fig("f30_sci.png", 5.0, 3.0, mar = c(0, 0, 0, 0), ps = 18)
plot(st_geometry(low), col = cl_s, border = NA)
plot(st_geometry(states_m[!states_m$STUSPS %in% off, ]), col = NA, border = "white", lwd = 0.5, add = TRUE)
lab <- c("51540" = "Charlottesville, VA", "08013" = "Boulder, CO", "37135" = "Orange, NC")
xy <- st_coordinates(st_point_on_surface(st_geometry(low[match(names(lab), low$GEOID), ])))
halo <- function(x, y, lab, col = ink, d = 12000, ...) {
  for (a in seq(0, 2 * pi, length.out = 13)) text(x + d * cos(a), y + d * sin(a), lab, col = "white", ...)
  text(x, y, lab, col = col, ...)
}
points(xy[, 1], xy[, 2], pch = 21, bg = ink, col = "white", cex = 0.9)
halo(xy[1, 1] - 40000, xy[1, 2] + 25000, lab[1], cex = 0.55, font = 2, adj = 1)
halo(xy[2, 1], xy[2, 2] + 110000, lab[2], cex = 0.55, font = 2)
halo(xy[3, 1] - 40000, xy[3, 2] - 45000, lab[3], cex = 0.55, font = 2, adj = 1)
legend("bottomleft", c("Tompkins", "top 1%", "top 5%", "top 20%", "top 50%", "bottom 50%"),
       fill = c(acc, rev(pal)), border = "white", bty = "n", cex = 0.55, inset = c(0.01, 0.0))
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: smoke DEPS: us ====
# NOAA's Hazard Mapping System (HMS) smoke plumes, June 2023: for each county of the lower 48 and each
# day, the densest plume that covers the whole county (0 none, 1 light, 2 medium, 3 heavy), as in
# Borgschulte, Molitor & Zou (REStat, 2024).
pop <- read.csv(P("data/census/co-est2024-alldata.csv"), fileEncoding = "latin1",
                colClasses = c(STATE = "character", COUNTY = "character"))
pop <- pop[pop$SUMLEV == 50, ]; pop$GEOID <- paste0(pop$STATE, pop$COUNTY)
low$pop <- pop$POPESTIMATE2023[match(low$GEOID, pop$GEOID)]
sm_files <- sort(list.files(P("data/noaa/hms"), full.names = TRUE))
sm_day <- as.Date(substr(basename(sm_files), 10, 17), "%Y%m%d")
lev <- c(Light = 1, Medium = 2, Heavy = 3)
read_smoke <- function(f) st_transform(st_make_valid(st_read(paste0("/vsizip/", f), quiet = TRUE)), 5070)
dens <- sapply(sm_files, function(f) {
  s <- read_smoke(f)
  sapply(st_within(low, s), function(k) if (length(k)) max(lev[s$Density[k]]) else 0)
})                                                                # counties x days: plumes covering the whole county
heavy_m <- colSums(low$pop * (dens == 3), na.rm = TRUE) / 1e6     # millions under heavy smoke, each day
sm_pal <- c("#EDEBE6", "#FDE6A8", "#F4A03C", "#9C3D0B")           # none, light, medium, heavy
# ==== END BLOCK ====

# ==== BLOCK: f32_hms0607 DEPS: smoke ====
# The plumes HMS analysts drew for 7 June 2023, over the lower 48 and southern Canada.
s7 <- read_smoke(sm_files[sm_day == as.Date("2023-06-07")])
bx <- st_as_sfc(st_bbox(c(xmin = -2400000, ymin = 250000, xmax = 2450000, ymax = 3300000), crs = st_crs(5070)))
s7 <- suppressWarnings(st_intersection(s7, bx)); s7 <- s7[order(lev[s7$Density]), ]   # heavy drawn last
fig("f32_hms0607.png", 5.4, 3.4, mar = c(0, 0, 0, 0), ps = 18)
plot(bx, border = NA)
plot(st_geometry(states_m[!states_m$STUSPS %in% off, ]), col = "#F4F2EC", border = "#9A9A9A", lwd = 0.5, add = TRUE)
plot(st_geometry(s7), col = adjustcolor(sm_pal[lev[s7$Density] + 1], 0.75), border = NA, add = TRUE)
plot(st_geometry(states_m[!states_m$STUSPS %in% off, ]), col = NA, border = adjustcolor(ink, 0.35), lwd = 0.5, add = TRUE)
xy <- st_coordinates(wh_m)
points(xy[1], xy[2], pch = 21, bg = blue, col = "white", cex = 1.1, lwd = 1)
text(xy[1] + 60000, xy[2] - 120000, "Warren Hall", col = blue, cex = 0.62, font = 2, adj = 0)
text(-300000, 3150000, "Canada", col = grey, cex = 0.62, font = 3)
legend("bottomleft", c("light", "medium", "heavy"), fill = sm_pal[2:4], border = "white", bty = "n",
       cex = 0.62, title = "smoke, 7 June 2023", title.adj = 0, inset = c(0.01, 0.02))
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f33_counties0607 DEPS: smoke ====
# Each county's densest plume on 7 June 2023, among the plumes that cover the whole county.
fig("f33_counties0607.png", 5.0, 3.0, mar = c(0, 0, 0, 0), ps = 18)
plot(st_geometry(low), col = sm_pal[dens[, sm_day == as.Date("2023-06-07")] + 1], border = NA)
plot(st_geometry(states_m[!states_m$STUSPS %in% off, ]), col = NA, border = "white", lwd = 0.5, add = TRUE)
legend("bottomleft", c("no smoke", "light", "medium", "heavy"), fill = sm_pal, border = "white", bty = "n",
       cex = 0.6, inset = c(0.01, 0.0))
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f34_people DEPS: smoke ====
# Millions of people in counties under heavy smoke, each day of June 2023.
fig("f34_people.png", 8.0, 3.0, mar = c(2.6, 4.6, 0.6, 0.5), ps = 13)
par(las = 1, bty = "n")
bp <- barplot(heavy_m, names.arg = format(sm_day, "%d"), col = ifelse(heavy_m >= 90, acc, "#C9B8A6"),
              border = NA, ylim = c(0, 125), ylab = "millions of people", cex.names = 0.8)
pk <- which(heavy_m >= 60)
text(bp[pk], heavy_m[pk], round(heavy_m[pk]), pos = 3, cex = 0.8, xpd = TRUE)
mtext("day of June 2023", side = 1, line = 1.7, cex = 0.85)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f35_gif DEPS: smoke ====
# The animation: one frame per day, counties by smoke density, with the people under heavy smoke below.
if (!requireNamespace("magick", quietly = TRUE)) install.packages("magick")
tmp <- file.path(tempdir(), "smoke"); dir.create(tmp, showWarnings = FALSE)
for (d in seq_along(sm_files)) {
  png(file.path(tmp, sprintf("f%02d.png", d)), width = 9, height = 5.6, units = "in", res = 100, pointsize = 15)
  layout(matrix(1:2), heights = c(3.9, 1.7))
  par(mar = c(0, 0, 1.6, 0), family = "sans")
  plot(st_geometry(low), col = sm_pal[dens[, d] + 1], border = NA)
  plot(st_geometry(states_m[!states_m$STUSPS %in% off, ]), col = NA, border = "white", lwd = 0.5, add = TRUE)
  mtext(format(sm_day[d], "%B %e, %Y"), side = 3, line = 0.2, font = 2, cex = 1.1, adj = 0.05)
  legend("bottomleft", c("no smoke", "light", "medium", "heavy"), fill = sm_pal, border = "white", bty = "n",
         cex = 0.8, inset = c(0.01, 0.0))
  par(mar = c(2.2, 5.2, 0.8, 1), las = 1, bty = "n")
  barplot(heavy_m, col = ifelse(seq_along(heavy_m) == d, acc, "#D9CFC4"), border = NA, ylim = c(0, 120),
          names.arg = format(sm_day, "%e"), cex.names = 0.7, ylab = "millions under\nheavy smoke", cex.lab = 0.85)
  dev.off()
}
gif <- magick::image_animate(magick::image_read(list.files(tmp, full.names = TRUE)), fps = 2, optimize = TRUE)
magick::image_write(gif, file.path(out, "f35_smoke.gif"))
# ==== END BLOCK ====

# ==== BLOCK: f36_monitors DEPS: smoke ====
# EPA ground monitors, June 2023: the median daily PM2.5 at monitors under a heavy plume and at
# monitors under no plume, on days with at least 10 monitors under a heavy plume.
pm  <- read.csv(P("data_clean/pm25_june2023.csv"), colClasses = c(site = "character"))
mon <- st_transform(st_as_sf(pm, coords = c("lon", "lat"), crs = 4326), 5070)
mon$smoke <- NA
for (k in seq_along(sm_files)) {
  s <- read_smoke(sm_files[k]); w <- which(mon$date == format(sm_day[k]))
  mon$smoke[w] <- sapply(st_intersects(mon[w, ], s), function(j) if (length(j)) max(lev[s$Density[j]]) else 0)
}
md <- function(z) tapply(mon$pm25[mon$smoke == z], factor(mon$date[mon$smoke == z], format(sm_day)), median)
nh <- table(factor(mon$date[mon$smoke == 3], format(sm_day)))
h3 <- ifelse(nh >= 10, md(3), NA); h0 <- md(0)
dd <- as.numeric(format(sm_day, "%d"))
fig("f36_monitors.png", 8.0, 3.0, mar = c(2.8, 4.8, 0.6, 0.5), ps = 13)
par(las = 1, bty = "n")
plot(dd, h3, type = "n", ylim = c(0, 125), xlim = c(1, 30), xlab = "", ylab = "PM2.5, µg/m³")
abline(h = 35, lty = 2, col = grey)
text(30, 38, "EPA daily standard, 35", adj = c(1, 0), cex = 0.75, col = grey)
points(dd, h0, pch = 16, col = "#B5B5B5", cex = 1.1)
points(dd, h3, pch = 16, col = acc, cex = 1.4)
for (d in c(8, 15, 28)) text(d, h3[d], sprintf("%.0f", h3[d]), pos = ifelse(d == 15, 3, 4), cex = 0.85, col = acc, font = 2)
mtext("day of June 2023", side = 1, line = 1.8, cex = 0.85)
legend("topleft", c("monitors under a heavy plume (median)", "monitors under no plume (median)"),
       pch = 16, col = c(acc, "#B5B5B5"), pt.cex = c(1.4, 1.1), bty = "n", cex = 0.8)
dev.off()
print(round(h3, 1)); print(nh)
# ==== END BLOCK ====

# ==== BLOCK: f31_resid DEPS: us ====
# Residuals of county population growth 2020-24 on log density 2020: neighbours err alike.
pop <- read.csv(P("data/census/co-est2024-alldata.csv"), fileEncoding = "latin1",
                colClasses = c(STATE = "character", COUNTY = "character"))
pop <- pop[pop$SUMLEV == 50, ]; pop$GEOID <- paste0(pop$STATE, pop$COUNTY)
p <- pop[match(low$GEOID, pop$GEOID), ]
growth <- 100 * (p$POPESTIMATE2024 / p$POPESTIMATE2020 - 1)
ldens <- log(p$POPESTIMATE2020 / (low$ALAND / 1e6))
r <- resid(lm(growth ~ ldens))
br <- c(-Inf, -6, -2, 2, 6, Inf); pal <- c("#2B5C8A", "#9DBEDB", "#F2F0EB", "#E8A08F", "#A8322A")
fig("f31_resid.png", 5.6, 3.0, mar = c(0, 0, 0, 0), ps = 18)
b_r <- st_bbox(low); b_r[["xmin"]] <- b_r[["xmin"]] - 1000000      # room on the left for the legend
frame(st_as_sfc(b_r))
plot(st_geometry(low), col = pal[cut(r, br)], border = NA, add = TRUE)
plot(st_geometry(states_m[!states_m$STUSPS %in% off, ]), col = NA, border = "white", lwd = 0.5, add = TRUE)
legend("bottomleft", c("grew 6+ points more", "2 to 6 more", "within 2", "2 to 6 less", "6+ less"),
       fill = rev(pal), border = "white", bty = "n", cex = 0.55, title = "growth vs. the fit", title.adj = 0)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f37_crs ====
# Two levels: a geographic CRS (degrees, no projection) and three projected ones
# (metres), grouped by what they keep correct. Each is a small world map: the United States
# in red and Greenland in blue, so the area distortion shows. The equidistant map
# draws circles 5,000 km apart around Ithaca.
sf_use_s2(FALSE)
wd <- st_make_valid(spData::world[c("name_long")])
types <- list(
  list(t = "No projection", sub = "Longitude and latitude (4326)", crs = 4326,
       adv = "Positions in degrees,\nas GPS records them"),
  list(t = "Equal-area", sub = "Equal Earth (8857)", crs = "+proj=eqearth",
       adv = "Areas are correct\neverywhere"),
  list(t = "Conformal", sub = "Web Mercator (3857)", crs = 3857,
       adv = "Angles and local shapes\nare correct"),
  list(t = "Equidistant", sub = "Centred on Ithaca", crs = "+proj=aeqd +lat_0=42.45 +lon_0=-76.48",
       adv = "Distances from Ithaca\nare correct"))
grat <- function(ymin, ymax) st_graticule(st_bbox(c(xmin = -180, ymin = ymin, xmax = 180, ymax = ymax), crs = st_crs(4326)),
                                          lon = seq(-180, 180, 30), lat = seq(-60, 60, 30))
fig("f37_crs.png", 10, 4.4, ps = 14)
par(mfrow = c(1, 4), oma = c(0, 0, 4.4, 0))           # the top outer margin holds the two group headers
for (ty in types) {
  merc <- identical(ty$crs, 3857); aeqd <- grepl("aeqd", ty$crs)
  x <- if (merc) suppressWarnings(st_crop(wd, xmin = -180, xmax = 180, ymin = -60, ymax = 84)) else wd
  x <- st_transform(x, ty$crs)
  par(mar = c(3.6, 0.4, 3.0, 0.4))
  fill <- ifelse(x$name_long == "United States", acc, ifelse(x$name_long == "Greenland", blue, "#D9D6CE"))
  plot(st_geometry(x), col = fill, border = NA)
  if (aeqd) {                                      # circles every 5,000 km around Ithaca
    th <- seq(0, 2 * pi, length.out = 200)
    for (r in c(5, 10, 15)) lines(r * 1e6 * cos(th), r * 1e6 * sin(th), col = grey, lwd = 0.6, lty = 2)
    lines(pi * 6371000 * cos(th), pi * 6371000 * sin(th), col = grey, lwd = 0.6)
    points(0, 0, pch = 16, cex = 0.7, col = ink)
    text(c(5, 10, 15) * 1e6 * cos(pi / 4), c(5, 10, 15) * 1e6 * sin(pi / 4), c("5,000 km", "10,000", "15,000"),
         cex = 0.75, col = grey, pos = 4, offset = 0.15)
  } else {
    y0 <- if (merc) -60 else -90; y1 <- if (merc) 84 else 90
    gr <- st_transform(grat(y0, y1), ty$crs)
    plot(st_geometry(gr), col = rule, lwd = 0.4, add = TRUE)
    ys <- seq(y0, y1, 1); xs <- seq(-180, 180, 1)
    edge <- st_sfc(st_polygon(list(rbind(cbind(-180, ys), cbind(xs, y1), cbind(180, rev(ys)), cbind(rev(xs), y0)))),
                   crs = 4326)
    plot(st_transform(edge, ty$crs), border = grey, lwd = 0.6, add = TRUE)   # the map's outline
  }
  mtext(ty$t, side = 3, line = 1.5, font = 2, cex = 1.15, col = ink)
  mtext(ty$sub, side = 3, line = 0.4, cex = 0.85, col = grey)
  mtext(ty$adv, side = 1, line = 1.9, cex = 0.95, col = ink)
}
# the two groups: one header over the first map, one over the other three
mtext(c("Geographic CRS", "Projected CRS"), side = 3, outer = TRUE, line = 1.9,
      at = c(0.125, 0.625), font = 2, cex = 1.35, col = ink)
par(xpd = NA)
yl <- 1 - (par("omi")[3] - 0.12) / par("din")[2]          # just under the headers, in device units
X <- function(v) grconvertX(v, "ndc", "user"); Y <- function(v) grconvertY(v, "ndc", "user")
segments(X(c(0.015, 0.265)), Y(yl), X(c(0.235, 0.985)), Y(yl), col = ink, lwd = 1.2)
segments(X(0.25), Y(0.04), X(0.25), Y(yl + 0.02), col = rule, lwd = 1)   # a rule between the groups
dev.off()
# ==== END BLOCK ====
