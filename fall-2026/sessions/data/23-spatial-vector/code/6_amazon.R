# AEM 6850, session 23 (Spatial I: vectors). Roads and forest clearing in the Amazon (a worked example on the page)
# Script 6 of 6 - repair the clearings, distance to the nearest road and along the roads
# Reads: data/inpe/*.json, data/osm/roads_cujubim_bbox.json
# Writes: data_clean/roads_cujubim.gpkg
# Open 23-spatial-vector.Rproj first, so R starts in the project folder; then
#   source("code/6_amazon.R")
# Every section matches a slide of the same name; the live script 23-spatial-vector.R runs them all in order.

# 1). Preliminary ----
# Clean up workspace and load or install necessary packages if necessary
  rm(list = ls())
  want <- c("sf", "igraph", "jsonlite")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only = TRUE))
  rm(want, need)

# 2). Building the road layer from the OpenStreetMap download ----
  js   <- fromJSON("data/osm/roads_cujubim_bbox.json", simplifyVector = FALSE)$elements
  ways <- Filter(function(e) e$type == "way", js)                     # roads; the town is a node
  line <- function(e) st_linestring(t(sapply(e$geometry, function(v) c(v$lon, v$lat))))
  rd <- st_sf(osm_id = sapply(ways, function(e) e$id), highway = sapply(ways, function(e) e$tags$highway),
              geometry = st_sfc(lapply(ways, line), crs = 4326))
  rd <- st_transform(rd[!rd$highway %in% c("path", "footway"), ], 31980)
  st_write(rd, "data_clean/roads_cujubim.gpkg", delete_dsn = TRUE, quiet = TRUE)

# 3). Reading and repairing the clearings ----
  mun   <- st_read("data/inpe/municipalities_RO.json", quiet = TRUE)   # Rondonia's 52 municipalities
  cu    <- st_transform(mun[mun$nome == "Cujubim", ], 31980)          # nome: name; metres, UTM zone 20S
  files <- list.files("data/inpe", "^yearly", full.names = TRUE)      # one download in four pages
  cl    <- do.call(rbind, lapply(files, st_read, quiet = TRUE))       # 6,401 clearings in Cujubim's box
  cl    <- st_transform(cl[c("year", "area_km")], 31980)
  sum(!st_is_valid(cl))                                               # invalid outlines
  cl <- st_make_valid(cl)                                             # repair them
  round(median(as.numeric(st_area(cl)) / 1e6 / cl$area_km), 4)        # area from the shapes over INPE's
  cl <- st_intersection(cl, st_geometry(cu))                          # the parts inside Cujubim
  nrow(cl)

# 4). One class, two spellings ----
  table(do.call(rbind, lapply(files, st_read, quiet = TRUE))$main_class)

# 5). Distance to the nearest road ----
  rd    <- st_read("data_clean/roads_cujubim.gpkg", quiet = TRUE)          # 1,162 OpenStreetMap roads, metres
  pt_cl <- st_point_on_surface(st_geometry(cl))                            # one point inside each clearing
  nr    <- st_nearest_feature(pt_cl, rd)                                   # row of the nearest road
  cl$road_m <- as.numeric(st_distance(pt_cl, rd[nr, ], by_element = TRUE)) # metres, one per clearing
  period <- cut(cl$year, c(2007, 2012, 2017, 2021, 2025), labels = c("2008-12", "2013-17", "2018-21", "2022-25"))
  round(tapply(cl$road_m, period, median))

# 6). Roads as a network ----
  xy   <- st_coordinates(rd)                              # every corner; L1 = the road it belongs to
  key  <- paste(round(xy[, "X"], 1), round(xy[, "Y"], 1)) # a name for each point, to 0.1 m
  same <- xy[-nrow(xy), "L1"] == xy[-1, "L1"]             # is the next corner on the same road?
  len  <- sqrt(diff(xy[, "X"])^2 + diff(xy[, "Y"])^2)     # metres from each corner to the next
  ed   <- data.frame(from = key[-nrow(xy)][same], to = key[-1][same], weight = len[same])
  gr   <- graph_from_data_frame(ed, directed = FALSE)
  c(nodes = vcount(gr), edges = ecount(gr), components = components(gr)$no)
  # a node's name is "x y": split it back into two numbers
  nodes <- st_as_sf(data.frame(x = as.numeric(sub(" .*", "", V(gr)$name)),
                               y = as.numeric(sub(".* ", "", V(gr)$name))), coords = c("x", "y"), crs = 31980)

# 7). Road distance to the town ----
  town <- st_transform(st_as_sf(data.frame(lon = -62.5832107, lat = -9.3687919),
                                coords = c("lon", "lat"), crs = 4326), 31980)   # the town, from OpenStreetMap
  town_m <- distances(gr, v = st_nearest_feature(town, nodes))[1, ]             # metres along roads, every node
  cl$road_km <- town_m[st_nearest_feature(pt_cl, nodes)] / 1000
  cl$line_km <- as.numeric(st_distance(pt_cl, town)) / 1000
  ok <- is.finite(cl$road_km); sum(ok)                                           # clearings joined by road
  round(median(cl$road_km[ok]), 1); round(median(cl$road_km[ok] / cl$line_km[ok]), 2)

# 8). Newer clearing lies farther from mapped roads ----
  gp   <- st_make_grid(cl, cellsize = 200, what = "centers")       # a point every 200 m across the box
  hit  <- st_intersects(gp, cl)                                    # the clearing each point falls in
  gp   <- gp[lengths(hit) > 0]                                     # keep the points inside a clearing
  yr   <- pmin(cl$year[sapply(hit[lengths(hit) > 0], `[`, 1)], 2024)   # each point's year; 2025 joins 2024
  d1   <- as.numeric(st_distance(gp, rd[st_nearest_feature(gp, rd), ], by_element = TRUE)) <= 1000
  share <- tapply(d1, yr, mean)                                    # share of each year's area within 1 km
  round(share[c("2008", "2016", "2024")], 2)

# 9). Clearing and the share near a road, by year ----
  km2 <- tapply(as.numeric(st_area(cl)) / 1e6, pmin(cl$year, 2024), sum)   # km2 cleared each year
  yrs <- as.numeric(names(km2))
  par(mfrow = c(1, 2), mar = c(3, 4.6, 1.8, 1.5), las = 1, bty = "n")
  barplot(km2, names.arg = sub("2024", "2024-25", names(km2)), col = "#C0392B", border = NA, cex.names = 0.7,
          ylab = "km² cleared that year")
  mtext("Area cleared", side = 3, line = 0.4, adj = 0, font = 2)
  plot(yrs, share, type = "b", pch = 16, col = "#3A6C9C", ylim = c(0, 1), xaxt = "n", xlab = "",
       ylab = "share within 1 km of a road", xlim = c(2008, 2025.5))
  axis(1, at = c(2008, 2012, 2016, 2020, 2024), labels = c(2008, 2012, 2016, 2020, "2024-25"))
  mtext("Share of the year's cleared area near a road", side = 3, line = 0.4, adj = 0, font = 2)

# the end ----
