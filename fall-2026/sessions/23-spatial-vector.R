# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# AEM 6850 -- Empirical Methods for Applied Economists
# Prof. Ariel Ortiz-Bobea
# Session 23 -- Spatial I: vectors
# Tuesday, November 17, 2026
#
# Run it one line at a time: put the cursor on a line and press Cmd-Return
# (Mac) or Ctrl-Enter (Windows).
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# Preliminary ----
# Clean up workspace and load or install necessary packages if necessary
  rm(list=ls())
  want <- c("magick")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only=TRUE))
  rm(want, need)


# Load or install sf ----
want <- c("sf")
need <- want[!(want %in% installed.packages()[,"Package"])]
if (length(need)) install.packages(need)
lapply(want, function(i) require(i, character.only = TRUE))


# Reading the county file ----
unzip("data/census/cb_2024_us_county_500k.zip", exdir = "data_clean/counties")   # seven files
co <- st_read("data_clean/counties/cb_2024_us_county_500k.shp", quiet = TRUE)
print(co, n = 0)                                      # the header alone, no rows


# An sf object is a data frame ----
class(co)
co[1:3, c("GEOID", "NAME", "STUSPS", "ALAND")]        # three rows, four columns: the geometry comes too


# The rows outside the 50 states and DC ----
table(co$STUSPS[!co$STUSPS %in% c(state.abb, "DC")])   # AS American Samoa, GU Guam, MP Northern Mariana
                                                       # Islands, PR Puerto Rico, VI US Virgin Islands


# Subsetting and plotting New York's counties ----
ny <- co[co$STUSPS == "NY", ]          # rows by a condition
nrow(ny)
tk <- ny[ny$NAME == "Tompkins", ]      # Tompkins County, used again below
par(mar = c(0, 0, 0, 0))
plot(st_geometry(ny), col = ifelse(ny$NAME == "Tompkins", "#B31B1B", "grey90"), border = "white")


# A polygon is a list of corners ----
xy <- st_coordinates(tk)          # one row per corner
nrow(xy)
head(xy, 2)
plot(st_geometry(tk))
points(xy[, "X"], xy[, "Y"], pch = 20, cex = 0.5)


# Points from longitude and latitude ----
wh <- st_as_sf(data.frame(name = "Warren Hall", lon = -76.4797, lat = 42.4490),
               coords = c("lon", "lat"), crs = 4326)        # x (longitude) first, then y (latitude)
wh


# The county that holds Warren Hall ----
wh <- st_transform(wh, st_crs(co))                          # the point in the counties' CRS
st_drop_geometry(st_join(wh, co[c("GEOID", "NAME", "STUSPS")]))


# County codes read as numbers ----
pop <- read.csv("data/census/co-est2024-alldata.csv", fileEncoding = "latin1")
pop <- pop[pop$SUMLEV == 50, ]                        # 50: county rows; 40: state rows
head(pop[, c("STATE", "COUNTY", "CTYNAME")], 3)
pop$GEOID <- paste0(pop$STATE, pop$COUNTY)            # should be 01001, 01003, 01005
head(pop$GEOID, 3)
nrow(merge(co, pop[c("GEOID", "POPESTIMATE2024")], by = "GEOID"))


# Merging population by GEOID ----
pop <- read.csv("data/census/co-est2024-alldata.csv", fileEncoding = "latin1",
                colClasses = c(STATE = "character", COUNTY = "character"))   # codes stay text: "01"
pop <- pop[pop$SUMLEV == 50, ]
pop$GEOID <- paste0(pop$STATE, pop$COUNTY)
head(pop$GEOID, 3)
cp <- merge(co, pop[c("GEOID", "POPESTIMATE2024")], by = "GEOID")
nrow(cp)
st_drop_geometry(cp[cp$GEOID == "36109", c("NAME", "POPESTIMATE2024")])


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Exercise 1 (4 minutes) ----
# Exercise 1 (4 minutes). A place you know: its county by location, then its population by GEOID.
# Find the county and the population of a place you pick, with a spatial join and a merge.
# In the 23-spatial-vector folder, with co and pop as on the slides before
# (or run code/1_vector.R first).
# 1. Find a US place on a web map: right-click a spot to see its coordinates (most give latitude first).
# 2. p <- st_as_sf(data.frame(name = "my place", lon = -73.9855, lat = 40.7580),
#                  coords = c("lon", "lat"), crs = 4326)
#    p <- st_transform(p, st_crs(co))
# 3. j <- st_join(p, co[c("GEOID", "NAME", "STUSPS")]); st_drop_geometry(j)
# 4. merge(st_drop_geometry(j), pop[c("GEOID", "POPESTIMATE2024")], by = "GEOID")
# 5. Try a point on water near a coast, such as the middle of a bridge, and run steps 2 to 4 again.
# Two answers to compare with the room: the largest county population anyone found,
# and a place that returned no county, with the reason.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




# Area and perimeter of Tompkins County ----
tk_m <- st_transform(tk, 5070)                                  # Conus Albers: equal area, metres
round(c(albers       = as.numeric(st_area(tk_m)) / 1e6,         # km2
        web_mercator = as.numeric(st_area(st_transform(tk, 3857))) / 1e6,
        round_earth  = as.numeric(st_area(tk)) / 1e6,           # degrees: sf measures on a sphere
        census       = (tk$ALAND + tk$AWATER) / 1e6), 1)
round(as.numeric(st_length(st_boundary(tk_m))) / 1e3, 1)       # perimeter, km


# Each county's distance to Times Square ----
ts    <- st_as_sf(data.frame(name = "Times Square", lon = -73.9855, lat = 40.7580),
                  coords = c("lon", "lat"), crs = 4326)
ny_co <- st_transform(ny, 5070)                                   # New York's counties, in metres
pt_ny <- st_point_on_surface(st_geometry(ny_co))                  # a point inside each county
ny_co$km_ts <- as.numeric(st_distance(pt_ny, st_transform(ts, 5070))) / 1e3
km <- setNames(round(ny_co$km_ts), ny_co$NAME); km[c("Tompkins", names(which.max(km)))]


# Distance to a state and its border ----
unzip("data/census/cb_2024_us_state_500k.zip", exdir = "data_clean/states")
states   <- st_read("data_clean/states/cb_2024_us_state_500k.shp", quiet = TRUE)
states_m <- st_transform(states, 5070); wh_m <- st_transform(wh, 5070)      # Conus Albers, metres
ny_m <- states_m[states_m$STUSPS == "NY", ]
km <- function(a, b) round(as.numeric(st_distance(a, b)) / 1e3, 1)
c(to_PA = km(wh_m, states_m[states_m$STUSPS == "PA", ]), to_NY = km(wh_m, ny_m),
  to_NY_border = km(wh_m, st_boundary(ny_m)))


# A 50 km buffer around Warren Hall ----
b    <- st_buffer(wh_m, 50000)    # within 50,000 m
co_m <- st_transform(co, 5070)
near <- co_m[b, ]                 # the counties b reaches
table(near$STUSPS)


# The buffer on a map ----
par(mar = c(0, 0, 0, 0))
plot(st_geometry(st_buffer(wh_m, 85000)), border = NA)                      # sets the map's extent
plot(st_geometry(co_m[co_m$STUSPS %in% c("NY", "PA"), ]), col = "grey95", border = "white", add = TRUE)
plot(st_geometry(near), col = "#C9DAEA", border = "white", add = TRUE)
plot(st_boundary(st_geometry(ny_m)), lwd = 3, add = TRUE)                   # New York's boundary
plot(b, col = NA, border = "#B31B1B", lwd = 2, add = TRUE)
plot(st_geometry(wh_m), pch = 19, col = "#B31B1B", add = TRUE)
text(st_coordinates(st_point_on_surface(st_geometry(near))), near$NAME, cex = 0.7)


# Interstate miles in New York ----
it    <- st_read("data_clean/interstates_ny_box.gpkg", quiet = TRUE)   # Census Interstate lines near New York
it_ny <- st_intersection(st_transform(it, 5070), ny_m["STUSPS"])      # the parts inside New York
# st_intersection() warns that attributes are assumed constant: expected here
it_ny$miles <- as.numeric(st_length(it_ny)) / 1609.344
round(sum(it_ny$miles), 1)
round(sort(tapply(it_ny$miles, it_ny$FULLNAME, sum), decreasing = TRUE)[1:3], 1)


# Direction from Warren Hall to Times Square ----
bearing <- function(a, b, crs) {   # degrees from map north
  d <- st_coordinates(st_transform(b, crs)) -
       st_coordinates(st_transform(a, crs))  # east, north (m)
  (atan2(d[1], d[2]) * 180 / pi) %% 360   # 0 to 360
}
round(c(utm_18N = bearing(wh, ts, 32618),
        albers  = bearing(wh, ts, 5070)), 1)


# The direction on the round Earth ----
r  <- pi / 180                                   # degrees to radians
p1 <- 42.4490 * r; p2 <- 40.7580 * r             # latitudes of Warren Hall and Times Square
dl <- (-73.9855 - -76.4797) * r                  # difference in longitude
round((atan2(sin(dl) * cos(p2), cos(p1) * sin(p2) - sin(p1) * cos(p2) * cos(dl)) / r) %% 360, 1)


# The nearest Interstate to Warren Hall ----
k <- st_nearest_feature(wh_m, it_ny)                       # row of the nearest Interstate piece
c(it_ny$FULLNAME[k], round(as.numeric(st_distance(wh_m, it_ny[k, ])) / 1e3, 1))   # name, km
kk <- st_nearest_feature(pt_ny, it_ny)                     # every New York county at once
ny_co$km_it <- as.numeric(st_distance(pt_ny, it_ny[kk, ], by_element = TRUE)) / 1e3
head(sort(setNames(round(ny_co$km_it), ny_co$NAME), decreasing = TRUE), 2)   # km, farthest two


# Counties that share a border ----
off <- c("AK", "HI", "PR", "AS", "GU", "MP", "VI")        # Alaska, Hawaii and the five territories
low <- st_transform(co[!co$STUSPS %in% off, ], 5070)     # the lower 48 and DC, in metres
nrow(low)
nb <- st_touches(low)                  # for each county, the rows of the counties it touches
i  <- which(low$GEOID == "36109")      # Tompkins's row
low$NAME[nb[[i]]]


# Corner neighbours and island counties ----
rook <- st_relate(low, pattern = "F***1****")          # neighbours that share a stretch of border
c(touch = sum(lengths(nb)), share_border = sum(lengths(rook)))
low$NAME[lengths(nb) == 0]                             # counties that touch no other


# Load or install igraph ----
want <- c("igraph")
need <- want[!(want %in% installed.packages()[,"Package"])]
if (length(need)) install.packages(need)
lapply(want, function(i) require(i, character.only = TRUE))


# Counties as a graph ----
g <- graph_from_adj_list(nb, mode = "all")     # node k is row k of low; an edge joins two neighbours
c(nodes = vcount(g), edges = ecount(g))


# First and second neighbours ----
n2 <- as.numeric(ego(g, order = 2, nodes = i, mindist = 2)[[1]])   # rows of the second neighbours
x    <- pop$POPESTIMATE2024[match(low$GEOID, pop$GEOID)]           # population, 2024
x_nb <- sapply(nb, function(k) mean(x[k]))                         # first neighbours' average
round(c(Tompkins = x[i], first = x_nb[i], second = mean(x[n2])))


# Fewest county lines to Los Angeles ----
la <- which(low$GEOID == "06037")                            # Los Angeles County
distances(g, i, la)                                          # fewest county lines
route <- shortest_paths(g, from = i, to = la)$vpath[[1]]     # one route with 57
unique(low$STUSPS[route])
cen <- st_centroid(st_geometry(low))                         # each county's centre


# The route on a map ----
par(mar = c(0, 0, 0, 0))
plot(st_geometry(low), col = "grey92", border = NA)
plot(st_geometry(low[route, ]), col = "#B31B1B", border = NA, add = TRUE)
ends <- st_coordinates(cen[c(i, la)])
segments(ends[1, 1], ends[1, 2], ends[2, 1], ends[2, 2], lty = 2, lwd = 1.5)
text(ends[, 1], ends[, 2], c("Tompkins", "Los Angeles"), pos = c(4, 2), cex = 0.8)
round(as.numeric(st_distance(cen[i], cen[la])) / 1e3)        # km, straight line between the centres


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Exercise 2 (4 minutes) ----
# Exercise 2 (4 minutes). Fewest county lines from Tompkins to a county you pick, and kilometres per line.
# A county line counts one step whatever the county's size, so lines crossed and kilometres differ.
# In the 23-spatial-vector folder, with low, g, i and cen as on the slides before
# (or run code/3_relations.R first).
# 1. st_drop_geometry(low[low$NAME == "Cook", c("GEOID", "NAME", "STUSPS")])   # names repeat: pick by GEOID
#    j <- which(low$GEOID == "17031")
# 2. n <- distances(g, i, j); n                                            # fewest county lines
#    unique(low$STUSPS[shortest_paths(g, from = i, to = j)$vpath[[1]]])    # states on one route
# 3. d_km <- as.numeric(st_distance(cen[i], cen[j])) / 1e3                 # straight-line distance, km
#    round(d_km / n[1], 1)                                                 # kilometres per county line
# Two answers to compare with the room: the most county lines anyone found,
# and kilometres per line for a county in the east and one in the west.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




# County lines from Tompkins to every county ----
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


# Straight lines between New York's cities ----
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


# Tompkins County's friends, by county ----
sci <- read.csv("data_clean/sci_tompkins.csv", colClasses = c(GEOID = "character"))
k   <- match(sci$GEOID, low$GEOID)                           # NA outside the lower 48
sci$km <- as.numeric(st_distance(cen[i], cen))[k] / 1e3      # from Tompkins's centre
s <- sci[sci$GEOID != "36109" & !is.na(k), ]
coef(lm(log(sci) ~ log(km), s))["log(km)"]                   # % change in links per 1% more km
big <- pop$GEOID[pop$POPESTIMATE2024 > 40000]                # counties over 40,000 people
far <- s[s$km > 500 & s$GEOID %in% big, ]
head(low$NAME[match(far$GEOID[order(-far$sci)], low$GEOID)], 3)   # most linked, over 500 km away


# Load or install fixest ----
want <- c("fixest")
need <- want[!(want %in% installed.packages()[,"Package"])]
if (length(need)) install.packages(need)
lapply(want, function(i) require(i, character.only = TRUE))


# Conley standard errors with fixest ----
p  <- pop[match(low$GEOID, pop$GEOID), ]
ll <- st_coordinates(st_transform(st_point_on_surface(st_geometry(low)), 4326))  # degrees, as conley() needs
dd <- data.frame(growth = 100 * (p$POPESTIMATE2024 / p$POPESTIMATE2020 - 1),     # % change, 2020 to 2024
                 ldens  = log(p$POPESTIMATE2020 / (low$ALAND / 1e6)),            # log people per km2, 2020
                 lon = ll[, 1], lat = ll[, 2])
m <- feols(growth ~ ldens, dd); round(coef(m)["ldens"], 2)
round(sapply(list(robust = "hetero", within_100km = conley(100), within_500km = conley(500)),
             function(v) se(summary(m, vcov = v))["ldens"]), 3)


# Counties under smoke on 7 June 2023 ----
s <- st_read("/vsizip/data/noaa/hms/hms_smoke20230607.zip", quiet = TRUE)   # /vsizip/ reads inside the zip
s <- st_transform(st_make_valid(s), 5070)                      # 88 plumes, in metres
lev <- c(Light = 1, Medium = 2, Heavy = 3)                     # densities as numbers
densest <- function(s) sapply(st_within(low, s), function(k) if (length(k)) max(lev[s$Density[k]]) else 0)
d7 <- densest(s)
table(d7)                                                      # 0 none, 1 light, 2 medium, 3 heavy
low$pop <- pop$POPESTIMATE2023[match(low$GEOID, pop$GEOID)]   # people, July 2023
sum(low$pop[d7 == 3]) / 1e6                                    # millions under heavy smoke


# One day of smoke outlines ----
table(s$Density)
st_drop_geometry(st_join(wh_m, s[c("Density", "Start", "End")]))            # every plume over Warren Hall


# Thirty days, one table ----
hms_files <- list.files("data/noaa/hms", full.names = TRUE)        # one zip per day of June 2023
smoke <- function(f) st_transform(st_make_valid(st_read(paste0("/vsizip/", f), quiet = TRUE)), 5070)
day   <- as.Date(substr(basename(hms_files), 10, 17), "%Y%m%d")    # hms_smoke20230607.zip: 7 June
dens  <- sapply(hms_files, function(f) densest(smoke(f)))           # counties x days, about 6 seconds
colnames(dens) <- format(day); dim(dens)
heavy <- colSums(low$pop * (dens == 3), na.rm = TRUE) / 1e6        # millions under heavy smoke, each day
round(heavy[c("2023-06-07", "2023-06-15", "2023-06-29")])


# June 2023, day by day ----
want <- c("magick")                                             # joins the frames into a GIF
need <- want[!(want %in% installed.packages()[,"Package"])]
if (length(need)) install.packages(need)
pal <- c("#EDEBE6", "#FDE6A8", "#F4A03C", "#9C3D0B")            # none, light, medium, heavy
tmp <- file.path(tempdir(), "smoke"); dir.create(tmp, showWarnings = FALSE)
for (d in seq_along(day)) {
  png(file.path(tmp, sprintf("f%02d.png", d)), width = 900, height = 560, pointsize = 15)
  layout(matrix(1:2), heights = c(3.9, 1.7))
  par(mar = c(0, 0, 1.6, 0))
  plot(st_geometry(low), col = pal[dens[, d] + 1], border = NA)
  plot(st_geometry(states_m[states_m$STUSPS %in% low$STUSPS, ]), col = NA, border = "white", lwd = 0.5, add = TRUE)
  mtext(format(day[d], "%B %e, %Y"), side = 3, line = 0.2, font = 2, cex = 1.1, adj = 0.05)
  legend("bottomleft", c("no smoke", "light", "medium", "heavy"), fill = pal, border = "white", bty = "n", cex = 0.8)
  par(mar = c(2.2, 5.2, 0.8, 1), las = 1, bty = "n")
  barplot(heavy, col = ifelse(seq_along(heavy) == d, "#B31B1B", "#D9CFC4"), border = NA, ylim = c(0, 120),
          names.arg = format(day, "%e"), cex.names = 0.7, ylab = "millions under\nheavy smoke", cex.lab = 0.85)
  dev.off()
}
gif <- magick::image_animate(magick::image_read(list.files(tmp, full.names = TRUE)), fps = 2)
magick::image_write(gif, "smoke_june2023.gif")                  # two frames a second


# Ground monitors under the plumes ----
pm  <- read.csv("data_clean/pm25_june2023.csv", colClasses = c(site = "character"))   # site, date, pm25, lon, lat
mon <- st_transform(st_as_sf(pm, coords = c("lon", "lat"), crs = 4326), 5070)
mon$smoke <- NA
for (k in seq_along(hms_files)) {                                # day by day: that day's monitors, that day's plumes
  s <- smoke(hms_files[k]); w <- which(mon$date == format(day[k]))
  over <- st_intersects(mon[w, ], s)                             # plumes over each monitor that day
  mon$smoke[w] <- sapply(over, function(j) if (length(j)) max(lev[s$Density[j]]) else 0)
}
hv <- mon[mon$smoke == 3, ]                                      # monitor-days under a heavy plume
round(tapply(hv$pm25, hv$date, median)[c("2023-06-08", "2023-06-15", "2023-06-28")])


# Cross-border county pairs ----
med   <- read.csv("data_clean/medicaid_expansion.csv")   # state, month, group: I typed it from KFF's table
exp14 <- med$state[med$group == "expanded 2014"]
not14 <- med$state[med$group == "not expanded by 2018"]
k <- low[low$STUSPS %in% c(exp14, not14), c("GEOID", "NAME", "STUSPS")]
k$exp14 <- k$STUSPS %in% exp14                           # TRUE in a state that expanded in 2014
nbk   <- st_touches(k)
pairs <- data.frame(e = rep(seq_along(nbk), lengths(nbk)), n = unlist(nbk))   # every touching pair
pairs <- pairs[k$exp14[pairs$e] & !k$exp14[pairs$n], ]   # keep each pair once: expansion county first
nrow(pairs)


# Signed distance to the state line ----
states_k <- states_m[states_m$STUSPS %in% c(exp14, not14), ]
ln <- st_intersection(st_union(states_k[states_k$STUSPS %in% exp14, ]),   # the expansion states as one shape
                      st_union(states_k[states_k$STUSPS %in% not14, ]))   # where it meets the rest: a line
round(as.numeric(st_length(ln)) / 1e3)                                    # km
pt_co <- st_point_on_surface(st_geometry(k))                              # one point inside each county
k$dist_km <- ifelse(k$exp14, 1, -1) * as.numeric(st_distance(pt_co, ln)) / 1e3   # minus: did not expand


# Uninsured share by county and year ----
sahie <- read.csv("data_clean/sahie_uninsured.csv", colClasses = c(GEOID = "character"))  # GEOID, year, pctui
pp <- data.frame(GEOID_e = k$GEOID[pairs$e], GEOID_n = k$GEOID[pairs$n])
pp <- merge(pp, setNames(sahie, c("GEOID_e", "year", "pctui_e")), by = "GEOID_e")             # expansion side
pp <- merge(pp, setNames(sahie, c("GEOID_n", "year", "pctui_n")), by = c("GEOID_n", "year"))  # its neighbour
nrow(pp)                                                  # 377 pairs x 11 years
sp <- pp$GEOID_e == "21213" & pp$GEOID_n == "47147"       # Simpson, KY, and Robertson, TN
pp[sp & pp$year %in% 2013:2016, c("year", "pctui_e", "pctui_n")]


# Uninsured share fell more where Medicaid expanded ----
w  <- merge(sahie[sahie$year == 2013, c("GEOID", "pctui")], sahie[sahie$year == 2016, c("GEOID", "pctui")],
            by = "GEOID", suffixes = c("_2013", "_2016"))
kd <- merge(st_drop_geometry(k), w, by = "GEOID")
nrow(kd)                                                                  # of 2,830 counties
kd$change <- kd$pctui_2016 - kd$pctui_2013                                # percentage points
m  <- tapply(kd$change, cut(kd$dist_km, seq(-150, 150, 25)), mean)        # mean change in 25 km bands
round(m, 1)
par(mar = c(4.2, 6, 0.5, 0.5), las = 1, bty = "n")
x <- seq(-137.5, 137.5, 25)
plot(x, m, pch = 16, cex = 1.4, col = ifelse(x > 0, "#3A6C9C", "#9A6B00"), ylim = c(-22, 0),
     xlab = "distance from a county to the line, km (minus: did not expand)",
     ylab = "change in uninsured share,\n2013 to 2016 (points)")
abline(v = 0, lty = 2); abline(h = 0, col = "grey80")
text(x, m, sprintf("%.1f", m), pos = 1, cex = 0.75)


# Pair gap by year ----
gap <- tapply(pp$pctui_e - pp$pctui_n, pp$year, mean)     # expansion county minus its neighbour, mean over pairs
round(gap - gap["2013"], 2)                                # relative to 2013
yr <- as.numeric(names(gap)); y <- gap - gap["2013"]
par(mar = c(3, 6, 0.5, 0.5), las = 1, bty = "n")
plot(yr, y, type = "b", pch = 16, cex = 1.3, col = "#B31B1B", ylim = c(-11.5, 2), xaxt = "n",
     xlab = "", ylab = "pair gap minus its 2013 value\n(percentage points)")
axis(1, at = yr); abline(h = 0, col = "grey60"); abline(v = 2013.5, lty = 2)
text(2013.6, 1.6, "Medicaid expansion, January 2014", adj = 0, cex = 0.8)
text(yr, y, sprintf("%.2f", y), pos = ifelse(yr < 2014, 3, 1), cex = 0.75)


# Reading and repairing the clearings ----
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


# One class, two spellings ----
table(do.call(rbind, lapply(files, st_read, quiet = TRUE))$main_class)


# Distance to the nearest road ----
rd    <- st_read("data_clean/roads_cujubim.gpkg", quiet = TRUE)          # 1,162 OpenStreetMap roads, metres
pt_cl <- st_point_on_surface(st_geometry(cl))                            # one point inside each clearing
nr    <- st_nearest_feature(pt_cl, rd)                                   # row of the nearest road
cl$road_m <- as.numeric(st_distance(pt_cl, rd[nr, ], by_element = TRUE)) # metres, one per clearing
period <- cut(cl$year, c(2007, 2012, 2017, 2021, 2025), labels = c("2008-12", "2013-17", "2018-21", "2022-25"))
round(tapply(cl$road_m, period, median))


# Roads as a network ----
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


# Road distance to the town ----
town <- st_transform(st_as_sf(data.frame(lon = -62.5832107, lat = -9.3687919),
                              coords = c("lon", "lat"), crs = 4326), 31980)   # the town, from OpenStreetMap
town_m <- distances(gr, v = st_nearest_feature(town, nodes))[1, ]             # metres along roads, every node
cl$road_km <- town_m[st_nearest_feature(pt_cl, nodes)] / 1000
cl$line_km <- as.numeric(st_distance(pt_cl, town)) / 1000
ok <- is.finite(cl$road_km); sum(ok)                                           # clearings joined by road
round(median(cl$road_km[ok]), 1); round(median(cl$road_km[ok] / cl$line_km[ok]), 2)


# Newer clearing lies farther from mapped roads ----
gp   <- st_make_grid(cl, cellsize = 200, what = "centers")       # a point every 200 m across the box
hit  <- st_intersects(gp, cl)                                    # the clearing each point falls in
gp   <- gp[lengths(hit) > 0]                                     # keep the points inside a clearing
yr   <- pmin(cl$year[sapply(hit[lengths(hit) > 0], `[`, 1)], 2024)   # each point's year; 2025 joins 2024
d1   <- as.numeric(st_distance(gp, rd[st_nearest_feature(gp, rd), ], by_element = TRUE)) <= 1000
share <- tapply(d1, yr, mean)                                    # share of each year's area within 1 km
round(share[c("2008", "2016", "2024")], 2)


# Clearing and the share near a road, by year ----
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


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Practice ----
# Practice. Run in the 23-spatial-vector folder after the slides' code has built
# co, cp, ny, low, nb, g, i, la, states_m, k, pairs, pp, cl, pt_cl, rd, hms_files, day, lev, smoke and dens.

# Counties and their data
#  1. People per km2 for New York's counties: cp$POPESTIMATE2024 / (cp$ALAND / 1e6).
#     Which two are densest, which two least dense, and where is Tompkins?
#  2. Compactness, 4 * pi * area / perimeter^2 (1 for a circle), for New York's counties in 5070.
#     Which three are least compact, which three most?
#  3. The neighbours' average: for each county in low, the mean 2024 population of its
#     neighbours, with sapply(nb, function(j) mean(...)). Compare Tompkins with its six.
# Measuring and routes
#  4. Interstate miles in Pennsylvania, cut as on the Interstate slide. Download the full
#     primary-roads file first (tools/fetch_data.R, section 2) and subset RTTYP "I".
#  5. Each New York county's distance to Pennsylvania, from a point inside the county.
#     Which three are nearest, which two farthest?
#  6. Every county on some 57-line route from Tompkins to Los Angeles:
#     which(distances(g, i) + distances(g, la) == 57).
# The Medicaid border
#  7. The pair gap relative to 2013 for one border at a time: KY-TN, NM-TX, MN-WI.
#  8. The pair gap without the pairs on Wisconsin's border.
# Distance by sea
#  9. The distance from the Port of Los Angeles (-118.27, 33.74) to Shanghai (121.49, 31.23)
#     on the round Earth, and as a straight line in Web Mercator (3857). Then a route through
#     the water only (the worked example below the solutions).
# Cujubim
# 10. The share of each period's cleared area more than 2 km from a mapped road, and the median
#     road distance to town by period against the straight line.
# Smoke
# 11. The number of days in June 2023 each New York county was fully under heavy smoke:
#     rowSums(dens == 3) for the rows of low in New York. Which counties had the most?
# 12. The people under heavy smoke on 7 June with a point inside each county (st_intersects(pt, s))
#     in place of the whole county (st_within(low, s)). Which rule counts more, and why?
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




# A route through the water only ----
want <- c("spData")
need <- want[!(want %in% installed.packages()[,"Package"])]
if (length(need)) install.packages(need)
invisible(lapply(want, function(i) require(i, character.only = TRUE)))
ports <- st_as_sf(data.frame(name = c("Los Angeles", "Shanghai"), lon = c(-118.27, 121.49), lat = c(33.74, 31.23)),
                  coords = c("lon", "lat"), crs = 4326)
gd  <- expand.grid(lon = seq(-179.5, 179.5, 1), lat = seq(-79.5, 84.5, 1))   # a point every degree
oc  <- gd[lengths(st_intersects(st_as_sf(gd, coords = c("lon", "lat"), crs = 4326), st_geometry(world))) == 0, ]
oc$id <- seq_len(nrow(oc)); idx <- setNames(oc$id, paste(oc$lon, oc$lat))
ed  <- do.call(rbind, lapply(list(c(1, 0), c(0, 1), c(1, 1), c(1, -1)), function(s) {   # 8 neighbours, once each
  nl <- oc$lon + s[1]; nl[nl > 180] <- nl[nl > 180] - 360                       # wrap across 180 degrees
  to <- idx[paste(nl, oc$lat + s[2])]; data.frame(from = oc$id[!is.na(to)], to = to[!is.na(to)]) }))
p   <- st_as_sf(oc, coords = c("lon", "lat"), crs = 4326)
ed$weight <- as.numeric(st_distance(p[ed$from, ], p[ed$to, ], by_element = TRUE)) / 1e3   # km on the sphere
sea <- graph_from_data_frame(ed, directed = FALSE, vertices = data.frame(name = oc$id))
nn  <- st_nearest_feature(ports, p)                                           # each port's nearest ocean point
round(distances(sea, v = as.character(nn[1]), to = as.character(nn[2]))[1, 1])   # km, through the water


# The end
