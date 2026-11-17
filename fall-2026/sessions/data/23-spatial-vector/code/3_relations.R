# AEM 6850, session 23 (Spatial I: vectors). Relations between places
# Script 3 of 6 - nearest feature, neighbours, routes, straight lines between cities, friendship links, Conley standard errors
# Reads: data/census/ county and state zips, co-est2024-alldata.csv, data_clean/interstates_ny_box.gpkg, data_clean/sci_tompkins.csv
# Writes: nothing
# Open 23-spatial-vector.Rproj first, so R starts in the project folder; then
#   source("code/3_relations.R")
# Every section matches a slide of the same name; the live script 23-spatial-vector.R runs them all in order.

# 1). Preliminary ----
# Clean up workspace and load or install necessary packages if necessary
  rm(list = ls())
  want <- c("sf", "igraph", "fixest")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only = TRUE))
  rm(want, need)

# 2). The layers from scripts 1 and 2 ----
  # the Census county file (unzipped once into data_clean/)
  if (!file.exists("data_clean/counties/cb_2024_us_county_500k.shp"))
    unzip("data/census/cb_2024_us_county_500k.zip", exdir = "data_clean/counties")
  co <- st_read("data_clean/counties/cb_2024_us_county_500k.shp", quiet = TRUE)
  if (!file.exists("data_clean/states/cb_2024_us_state_500k.shp"))
    unzip("data/census/cb_2024_us_state_500k.zip", exdir = "data_clean/states")
  states <- st_read("data_clean/states/cb_2024_us_state_500k.shp", quiet = TRUE)
  states_m <- st_transform(states, 5070)
  pop <- read.csv("data/census/co-est2024-alldata.csv", fileEncoding = "latin1",
                  colClasses = c(STATE = "character", COUNTY = "character"))   # codes stay text: "01"
  pop <- pop[pop$SUMLEV == 50, ]
  pop$GEOID <- paste0(pop$STATE, pop$COUNTY)
  wh_m  <- st_transform(st_as_sf(data.frame(name = "Warren Hall", lon = -76.4797, lat = 42.4490),
                                coords = c("lon", "lat"), crs = 4326), 5070)   # Warren Hall, in metres
  ny_m  <- states_m[states_m$STUSPS == "NY", ]
  it    <- st_read("data_clean/interstates_ny_box.gpkg", quiet = TRUE)
  it_ny <- suppressWarnings(st_intersection(st_transform(it, 5070), ny_m["STUSPS"]))   # Interstates inside New York
  ny_co <- st_transform(co[co$STUSPS == "NY", ], 5070)    # New York's counties, in metres
  pt_ny <- st_point_on_surface(st_geometry(ny_co))          # a point inside each

# 3). The nearest Interstate to Warren Hall ----
  k <- st_nearest_feature(wh_m, it_ny)                       # row of the nearest Interstate piece
  c(it_ny$FULLNAME[k], round(as.numeric(st_distance(wh_m, it_ny[k, ])) / 1e3, 1))   # name, km
  kk <- st_nearest_feature(pt_ny, it_ny)                     # every New York county at once
  ny_co$km_it <- as.numeric(st_distance(pt_ny, it_ny[kk, ], by_element = TRUE)) / 1e3
  head(sort(setNames(round(ny_co$km_it), ny_co$NAME), decreasing = TRUE), 2)   # km, farthest two

# 4). Counties that share a border ----
  off <- c("AK", "HI", "PR", "AS", "GU", "MP", "VI")        # Alaska, Hawaii and the five territories
  low <- st_transform(co[!co$STUSPS %in% off, ], 5070)     # the lower 48 and DC, in metres
  nrow(low)
  nb <- st_touches(low)                  # for each county, the rows of the counties it touches
  i  <- which(low$GEOID == "36109")      # Tompkins's row
  low$NAME[nb[[i]]]

# 5). Corner neighbours and island counties ----
  rook <- st_relate(low, pattern = "F***1****")          # neighbours that share a stretch of border
  c(touch = sum(lengths(nb)), share_border = sum(lengths(rook)))
  low$NAME[lengths(nb) == 0]                             # counties that touch no other

# 6). Counties as a graph ----
  g <- graph_from_adj_list(nb, mode = "all")     # node k is row k of low; an edge joins two neighbours
  c(nodes = vcount(g), edges = ecount(g))

# 7). First and second neighbours ----
  n2 <- as.numeric(ego(g, order = 2, nodes = i, mindist = 2)[[1]])   # rows of the second neighbours
  x    <- pop$POPESTIMATE2024[match(low$GEOID, pop$GEOID)]           # population, 2024
  x_nb <- sapply(nb, function(k) mean(x[k]))                         # first neighbours' average
  round(c(Tompkins = x[i], first = x_nb[i], second = mean(x[n2])))

# 8). Fewest county lines to Los Angeles ----
  la <- which(low$GEOID == "06037")                            # Los Angeles County
  distances(g, i, la)                                          # fewest county lines
  route <- shortest_paths(g, from = i, to = la)$vpath[[1]]     # one route with 57
  unique(low$STUSPS[route])
  cen <- st_centroid(st_geometry(low))                         # each county's centre

# 9). The route on a map ----
  par(mar = c(0, 0, 0, 0))
  plot(st_geometry(low), col = "grey92", border = NA)
  plot(st_geometry(low[route, ]), col = "#B31B1B", border = NA, add = TRUE)
  ends <- st_coordinates(cen[c(i, la)])
  segments(ends[1, 1], ends[1, 2], ends[2, 1], ends[2, 2], lty = 2, lwd = 1.5)
  text(ends[, 1], ends[, 2], c("Tompkins", "Los Angeles"), pos = c(4, 2), cex = 0.8)
  round(as.numeric(st_distance(cen[i], cen[la])) / 1e3)        # km, straight line between the centres

# 10). Exercise 2: county lines and kilometres per line ----
  gid <- c("36061", "17031", "12086", "48201", "53033", "06037", "53009")
  j <- match(gid, low$GEOID)
  r <- data.frame(NAME = low$NAME[j], STUSPS = low$STUSPS[j], lines = as.vector(distances(g, i, j)),
                  km = round(as.numeric(st_distance(cen[i], cen[j])) / 1e3))
  r$km_per_line <- round(r$km / r$lines, 1); r

# 11). County lines from Tompkins to every county ----
  d  <- as.vector(distances(g, i))                       # county lines from Tompkins to every county
  br <- c(-1, 0, 5, 10, 20, 30, 40, 50, 63)
  pal <- hcl.colors(8, "YlOrRd", rev = TRUE)
  par(mar = c(0, 0, 0, 8))
  plot(st_geometry(low), col = ifelse(is.finite(d), pal[cut(d, br)], "grey60"), border = NA)
  legend("right", c("0", "1-5", "6-10", "11-20", "21-30", "31-40", "41-50", "51-63"), fill = pal, border = NA,
         bty = "n", cex = 0.85, title = "county lines\ncrossed from\nTompkins", title.adj = 0, xpd = TRUE, inset = -0.17)
  cl_wa <- st_coordinates(st_point_on_surface(st_geometry(low[which.max(replace(d, !is.finite(d), 0)), ])))
  text(cl_wa[1], cl_wa[2], "Clallam, 63", pos = 4, cex = 0.8)
  table(cut(d, br))

# 12). Straight lines between New York's cities ----
  city <- data.frame(name = c("New York", "Buffalo", "Rochester", "Syracuse", "Albany"),   # each city hall
                     lon = c(-74.0060, -78.8784, -77.6088, -76.1474, -73.7562),
                     lat = c(40.7128, 42.8864, 43.1566, 43.0481, 42.6526))
  city <- st_transform(st_as_sf(city, coords = c("lon", "lat"), crs = 4326), 5070)
  d_c  <- matrix(as.numeric(st_distance(city)), 5) / 1e3                   # km between every pair
  tree <- mst(graph_from_adjacency_matrix(d_c, mode = "undirected", weighted = TRUE))
  e  <- as_edgelist(tree, names = FALSE); xy <- st_coordinates(city)       # the 4 lines it keeps
  ln <- st_sfc(lapply(1:nrow(e), function(r) st_linestring(xy[e[r, ], ])), crs = 5070)
  ny_co$km_line <- apply(st_distance(pt_ny, ln), 1, min) / 1e3             # county to the nearest line
  round(cor(ny_co$km_line, ny_co$km_it), 2)

# 13). Tompkins County's friends, by county ----
  sci <- read.csv("data_clean/sci_tompkins.csv", colClasses = c(GEOID = "character"))
  k   <- match(sci$GEOID, low$GEOID)                           # NA outside the lower 48
  sci$km <- as.numeric(st_distance(cen[i], cen))[k] / 1e3      # from Tompkins's centre
  s <- sci[sci$GEOID != "36109" & !is.na(k), ]
  coef(lm(log(sci) ~ log(km), s))["log(km)"]                   # % change in links per 1% more km
  big <- pop$GEOID[pop$POPESTIMATE2024 > 40000]                # counties over 40,000 people
  far <- s[s$km > 500 & s$GEOID %in% big, ]
  head(low$NAME[match(far$GEOID[order(-far$sci)], low$GEOID)], 3)   # most linked, over 500 km away

# 14). Conley standard errors with fixest ----
  p  <- pop[match(low$GEOID, pop$GEOID), ]
  ll <- st_coordinates(st_transform(st_point_on_surface(st_geometry(low)), 4326))  # degrees, as conley() needs
  dd <- data.frame(growth = 100 * (p$POPESTIMATE2024 / p$POPESTIMATE2020 - 1),     # % change, 2020 to 2024
                   ldens  = log(p$POPESTIMATE2020 / (low$ALAND / 1e6)),            # log people per km2, 2020
                   lon = ll[, 1], lat = ll[, 2])
  m <- feols(growth ~ ldens, dd); round(coef(m)["ldens"], 2)
  round(sapply(list(robust = "hetero", within_100km = conley(100), within_500km = conley(500)),
               function(v) se(summary(m, vcov = v))["ldens"]), 3)

# the end ----
