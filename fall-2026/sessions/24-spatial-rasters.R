# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# AEM 6850 -- Empirical Methods for Applied Economists
# Prof. Ariel Ortiz-Bobea
# Session 24 -- Spatial II: rasters
# Thursday, November 19, 2026
#
# Run it one line at a time: put the cursor on a line and press Cmd-Return
# (Mac) or Ctrl-Enter (Windows).
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# Load or install the four packages ----
want <- c("terra", "sf", "exactextractr", "Matrix")
need <- want[!(want %in% installed.packages()[,"Package"])]
if (length(need)) install.packages(need)
lapply(want, function(i) require(i, character.only = TRUE))


# Reading one day of temperature ----
unzip("data/prism/prism_tmax_us_25m_20120717.zip", exdir = "data_clean/prism")   # seven files
r <- rast("data_clean/prism/prism_tmax_us_25m_20120717.tif")    # the .tif holds the grid
r


# What is in PRISM's zip ----
unzip("data/prism/prism_tmax_us_25m_20120717.zip", list = TRUE)$Name


# A raster is a matrix with coordinates ----
vals <- values(r)                               # every cell's value, row by row from the top left
c(rows = nrow(r), columns = ncol(r), cells = nrow(vals), with_value = sum(!is.na(vals)))
i <- cellFromXY(r, cbind(-76.4797, 42.4490))    # Warren Hall's cell (longitude, latitude)
i                                               # (180 - 1) x 1,405 + 1,165
rowColFromCell(r, i)                            # its row and column
vals[i]                                         # its value in the 17 July layer, degrees C


# One layer per day ----
tmax <- rast("data_clean/tmax_july2012.tif")    # the 31 daily grids of July 2012 in one file
nlyr(tmax)
names(tmax)[c(1, 2, 31)]
range(time(tmax))                               # the dates, stored as dates
dim(values(tmax))                               # cells by days
values(tmax)[i, 16:18]                          # Warren Hall's cell on 16, 17 and 18 July


# Cropping and masking to New York ----
unzip("data/census/cb_2024_us_county_500k.zip", exdir = "data_clean/counties")
co  <- st_read("data_clean/counties/cb_2024_us_county_500k.shp", quiet = TRUE)   # county outlines
ny  <- co[co$STUSPS == "NY", ]                  # New York's 62 counties
st_crs(ny) == st_crs(tmax)                      # do the counties and the grid share one CRS?
tny <- crop(tmax, ny)                           # the cells inside New York's bounding box
dim(tny)
cellFromXY(tny, cbind(-76.4797, 42.4490))       # Warren Hall's cell number in the smaller grid
tny_in <- mask(tny, ny)                         # NA in every cell whose centre is outside New York


# The crop and the mask on a map ----
par(mfrow = c(1, 2))
plot(tny[["2012-07-17"]], main = "crop()", legend = FALSE, axes = FALSE); lines(vect(ny), lwd = 0.5)
plot(tny_in[["2012-07-17"]], main = "mask()", axes = FALSE); lines(vect(ny), lwd = 0.5)
c(crop = sum(!is.na(values(tny[["2012-07-17"]]))),
  mask = sum(!is.na(values(tny_in[["2012-07-17"]]))))


# Daily temperature at Warren Hall ----
wh <- vect(cbind(lon = -76.4797, lat = 42.4490), crs = "EPSG:4326")   # Warren Hall: longitude first
wh <- project(wh, crs(tny))                     # the point in the grid's coordinate system
wh_t <- unlist(extract(tny, wh, ID = FALSE))    # the value of Warren Hall's cell in each layer
round(wh_t[16:19], 1)
data.frame(hottest = names(which.max(wh_t)), degrees = round(max(wh_t), 1),
           days_above_30 = sum(wh_t > 30))


# Warren Hall's 31 days on a plot ----
par(mar = c(3, 4.2, 1, 1), las = 1, bty = "n")
plot(time(tny), wh_t, type = "b", pch = 19, xlab = "", ylab = "°C, Warren Hall's cell")
abline(h = 30, lty = 2)
text(time(tny)[which.max(wh_t)], max(wh_t), "35.8 °C", pos = 4)


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Exercise 1 (4 minutes) ----
# Exercise 1 (4 minutes). The hottest July 2012 layer at a place you pick.
# The heat of July 2012 peaked on different days in different places.
# In the 24-spatial-rasters folder, with tmax as on the slides before
# (or run code/1_raster.R first).
# 1. Pick any spot in the lower 48 states on a web map; right-click it to see its coordinates
#    (web maps show latitude first).
# 2. p <- vect(cbind(lon = -73.9855, lat = 40.7580), crs = "EPSG:4326")   # Times Square
#    p <- project(p, crs(tmax))
# 3. x <- unlist(extract(tmax, p, ID = FALSE))
# 4. names(which.max(x)); round(max(x), 1); sum(x > 30)
# Compare with the class: the hottest day anyone found, with the place and the date.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




# 17 July minus July's mean ----
t17 <- tny[["2012-07-17"]]
dev <- t17 - mean(tny)                          # mean() of a stack averages its 31 layers
round(range(values(dev), na.rm = TRUE), 1)
g <- c(t17, mean(tny), dev); names(g) <- c("day", "month_mean", "difference")   # c() stacks layers
round(unlist(extract(g, wh, ID = FALSE)), 1)    # Warren Hall
plot(g, nc = 3, fun = function() lines(vect(ny)))


# Days above 30 °C in New York ----
hot <- sum(tny > 30)                            # TRUE or FALSE per cell and day; sum() counts TRUE
range(values(hot), na.rm = TRUE)
unlist(extract(hot, wh, ID = FALSE))            # Warren Hall
plot(mask(hot, ny)); lines(vect(ny))


# Moving the wind onto the temperature grid ----
u <- rast("data_clean/u10_ny_20120717.tif")     # wind toward the east, m/s, one layer per hour
res(u); res(tny)                                # cell size in degrees
compareGeom(u, tny, stopOnError = FALSE)        # do the two grids have the same cells?
u4 <- project(u[["18:00"]], tny)                # weighted mean of nearby wind cells, in tny's CRS
compareGeom(u4, tny, stopOnError = FALSE)
round(c(before = extract(u[["18:00"]], project(wh, crs(u)), ID = FALSE)[1, 1],
        after = extract(u4, wh, ID = FALSE)[1, 1]), 2)        # Warren Hall, m/s


# The wind at Warren Hall ----
u    <- rast("data_clean/u10_ny_20120717.tif")  # wind toward the east, metres per second, one layer per hour
v10  <- rast("data_clean/v10_ny_20120717.tif")  # wind toward the north, metres per second
kmh  <- sqrt(u^2 + v10^2) * 3.6                 # speed: 1 metre per second is 3.6 km/h
from <- (atan2(-u, -v10) * 180 / pi) %% 360     # where the wind comes from, clockwise from north
now  <- c(u[["18:00"]], v10[["18:00"]], kmh[["18:00"]], from[["18:00"]])
names(now) <- c("u", "v", "kmh", "from")
round(unlist(extract(now, project(wh, crs(u)), ID = FALSE)), 1)    # Warren Hall at 18:00 UTC


# The cell as the unit of observation ----
dim(as.data.frame(t17, xy = TRUE))              # x, y and the value
dim(as.data.frame(tny, xy = TRUE))              # x, y and one column per day


# The cells around each cell ----
fo <- focal(t17, w = 3, fun = "mean")           # mean of each cell and its eight neighbours
round(c(cell = extract(t17, wh, ID = FALSE)[1, 1], around = extract(fo, wh, ID = FALSE)[1, 1]), 2)


# Categories in cells ----
cr  <- rast("data_clean/cropland_2011.tif")                  # percent of each cell under crops
nyw <- project(vect(ny), crs(cr))                            # New York in the grid's CRS
cl  <- classify(mask(crop(cr, nyw), nyw), c(-Inf, 1, 25, 50, Inf))   # four classes
f   <- freq(cl)
data.frame(class = c("1% or less", "1 to 25%", "25 to 50%", "over 50%"),
           percent_of_cells = round(100 * f$count / sum(f$count), 1))


# County means with extract() ----
ny$t17 <- extract(t17, ny, fun = mean, exact = TRUE, na.rm = TRUE, ID = FALSE)[, 1]
round(ny$t17[ny$GEOID == "36109"], 2)           # Tompkins County
round(range(ny$t17), 1)
plot(ny["t17"], main = "")


# Without na.rm, and with cell centres ----
m0 <- extract(t17, ny, fun = mean, exact = TRUE, ID = FALSE)[, 1]   # without na.rm = TRUE
ny$NAME[is.na(m0)]
cc <- extract(t17, ny[ny$GEOID == "36109", ], ID = FALSE)   # the cells whose centre is inside
c(cells = nrow(cc), mean = round(mean(cc[, 1]), 2))


# The timings I measured ----
read.csv("data_clean/timings.csv")


# The area of Tompkins County from its cells ----
tk  <- ny[ny$GEOID == "36109", ]
tab <- exact_extract(t17, tk, include_cell = TRUE, progress = FALSE)[[1]]
a   <- cellSize(t17, unit = "km")[tab$cell][, 1]     # each cell's area, km2
round(c(from_cells = sum(a * tab$coverage_fraction), census = (tk$ALAND + tk$AWATER) / 1e6), 1)


# The table of cells and fractions ----
tk  <- ny[ny$GEOID == "36109", ]                            # Tompkins County
tab <- exact_extract(t17, tk, include_cell = TRUE)[[1]]     # one row per cell the county touches
head(tab, 3)
c(cells = nrow(tab), whole = sum(tab$coverage_fraction == 1),
  partial = sum(tab$coverage_fraction < 1))
f <- rast(t17)                                              # an empty grid with the same cells
f[tab$cell] <- tab$coverage_fraction                        # the fractions go in by cell number
plot(crop(f, tk, snap = "out")); lines(vect(tk))


# terra's own table ----
head(extract(t17, tk, cells = TRUE, exact = TRUE), 3)
nrow(extract(t17, tk, cells = TRUE, exact = TRUE))


# Tompkins County's mean by hand ----
x <- tab$value; w <- tab$coverage_fraction
sum(w * x) / sum(w)                             # value times fraction, over the sum of fractions
ny$t17[ny$GEOID == "36109"]                     # extract()'s answer for Tompkins County
mean(x)                                         # every cell counted as whole


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Exercise 2 (4 minutes) ----
# Exercise 2 (4 minutes). Tompkins County's mean on each of the 31 days, from the one table of cells
# and fractions. Do not call extract() or exact_extract() again.
# In the 24-spatial-rasters folder, with tny, tab and w as on the slides before
# (or run code/3_aggregate.R up to this exercise).
# 1. head(tab): which of its three columns would change on another day?
# 2. Mny <- values(tny); dim(Mny)      # row k is cell k of tny, column d is day d
# 3. One day first: 17 July is column 17 of Mny. Its weighted mean from Mny, tab$cell and
#    tab$coverage_fraction should be 29.28.
# 4. Now all 31.
# Compare with the class: the county's mean on 18 July, its hottest day. Then say what you had to
# compute again for each new day.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




# The 31 daily means as a matrix product ----
Mny <- values(tny)                              # 20,710 cells by 31 days
w1  <- matrix(w / sum(w), nrow = 1)             # the weights as one row that sums to 1
dim(w1); dim(Mny[tab$cell, ])
out <- w1 %*% Mny[tab$cell, ]                   # (1 by 107) times (107 by 31) gives 1 by 31
round(out[1, 16:19], 2)


# The weight matrix P ----
low  <- co[!(co$STUSPS %in% c("AK", "HI", "PR", "GU", "VI", "AS", "MP")), ]    # lower 48 and DC
info <- exact_extract(tmax[[1]], low, include_cell = TRUE, progress = FALSE)   # a table per county
tabN <- data.frame(county = rep(1:nrow(low), sapply(info, nrow)),
                   do.call(rbind, info))        # stack the 3,109 tables into one
tabN <- tabN[!is.na(tabN$value), ]              # cells over water hold no temperature
tabN$w <- tabN$coverage_fraction / ave(tabN$coverage_fraction, tabN$county, FUN = sum)
c(counties = length(unique(tabN$county)), rows = nrow(tabN))
range(tapply(tabN$w, tabN$county, sum))         # each county's weights sum to 1


# The national table, counted ----
c(all_rows = sum(sapply(info, nrow)), kept = nrow(tabN),
  dropped = sum(sapply(info, nrow)) - nrow(tabN))
sum(table(tabN$cell) > 1)                       # cells with a weight in more than one county
which(low$GEOID == "36109")                     # Tompkins County's row


# P as a sparse matrix ----
sparseMatrix(i = c(1, 1, 1, 2, 2), j = c(1, 2, 3, 3, 4), x = c(1, 1, 0.35, 0.65, 1), dims = c(2, 4))
P <- sparseMatrix(i = tabN$county, j = tabN$cell, x = tabN$w, dims = c(nrow(low), ncell(tmax)))
c(rows = nrow(P), columns = ncol(P), not_zero = nnzero(P))
round(c(sparse_MB = as.numeric(object.size(P)) / 1e6, ordinary_GB = prod(dim(P)) * 8 / 1e9), 1)


# Every county's mean on every day ----
M <- values(tmax)                               # 872,505 cells by 31 days
system.time(cd <- P %*% M)                      # counties by days
round(cd[low$GEOID == "36109", 16:19], 2)       # Tompkins County
ee <- exact_extract(tmax, low, "mean", progress = FALSE)    # the packaged function, all 31 days
max(abs(as.matrix(cd) - as.matrix(ee)))         # the largest difference between the two, degrees C


# Every county's mean on 18 July, on a map ----
low$t18 <- as.vector(cd[, "2012-07-18"])
plot(low["t18"], main = "°C, layer dated 18 July 2012", border = NA)


# Population weights in P ----
popg <- project(rast("data_clean/pop_2010.tif"), tmax, method = "sum")  # people in each cell
tabN$wp <- tabN$coverage_fraction * values(popg)[tabN$cell]             # people in the part inside
tabN$wp <- tabN$wp / ave(tabN$wp, tabN$county, FUN = sum)               # sum to 1 in each county
Pp  <- sparseMatrix(i = tabN$county, j = tabN$cell, x = tabN$wp, dims = dim(P))
cdp <- Pp %*% M
k <- match(c("36109", "06053"), low$GEOID)      # Tompkins, New York and Monterey, California
data.frame(county = low$NAME[k], by_area = round(rowMeans(cd[k, ]), 1),
           by_people = round(rowMeans(cdp[k, ]), 1))        # July means, degrees C


# People before and after the move ----
pop0 <- rast("data_clean/pop_2010.tif")
round(c(before = global(pop0, "sum", na.rm = TRUE)[1, 1],
        after = global(popg, "sum", na.rm = TRUE)[1, 1]) / 1e6, 1)       # millions of people
sum(is.na(as.matrix(cdp)))                                               # counties with no value


# The 2012 yield against each county's 2002 to 2011 mean ----
y    <- read.csv("data_clean/corn_yield_2002_2012.csv", colClasses = c(GEOID = "character"))
yw   <- tapply(y$yield, list(y$GEOID, y$year), mean)                 # counties by years
base <- rowMeans(yw[, as.character(2002:2011)], na.rm = TRUE)        # each county's 2002-2011 mean
nb   <- rowSums(!is.na(yw[, as.character(2002:2011)]))               # years reported out of ten
chg  <- 100 * (yw[, "2012"] / base - 1)                              # 2012 against that mean, %
chg[nb < 8] <- NA
low$chg <- chg[match(low$GEOID, names(chg))]
c(report_2012 = sum(!is.na(yw[, "2012"])), with_8_years = sum(!is.na(low$chg)))


# Degree days from the 31 layers ----
heat <- sum((tmax - 29) * (tmax > 29))          # each day's degrees above 29, summed over 31 days
round(range(values(heat), na.rm = TRUE))
round(unlist(extract(heat, wh, ID = FALSE)), 1) # Warren Hall


# The heat as a matrix ----
nlyr(max(tmax - 29, 0))                         # one layer: a different quantity
system.time(hm <- rowSums(pmax(M - 29, 0)))     # the same heat, from the matrix of cells by days
max(abs(hm - values(heat)[, 1]), na.rm = TRUE)


# Cropland on the temperature grid ----
crops <- rast("data_clean/cropland_2011.tif")   # percent of each cell under crops, 0 to 100
res(crops)
cropg <- project(crops, tmax, method = "average")   # the average share over each temperature cell
round(unlist(extract(cropg, wh, ID = FALSE)), 1)    # Warren Hall's cell, percent under crops


# Cropland on a map, and the two grids compared ----
compareGeom(crops, tmax, stopOnError = FALSE)
compareGeom(cropg, tmax, stopOnError = FALSE)
unzip("data/census/cb_2024_us_state_500k.zip", exdir = "data_clean/states")
st <- st_read("data_clean/states/cb_2024_us_state_500k.shp", quiet = TRUE)
plot(cropg, axes = FALSE, col = hcl.colors(50, "YlGn", rev = TRUE))
lines(vect(st[st$STUSPS %in% low$STUSPS, ]), lwd = 0.4)


# County heat over cropland ----
tabN$wc <- tabN$coverage_fraction * values(cropg)[tabN$cell]   # fraction times cropland share
tabN$wc <- tabN$wc / ave(tabN$wc, tabN$county, FUN = sum)      # 0/0 in a county with no cropland
Pc <- sparseMatrix(i = tabN$county, j = tabN$cell, x = tabN$wc, dims = dim(P))
low$heat      <- as.vector(Pc %*% values(heat))                # heat over each county's cropland
low$heat_area <- as.vector(P %*% values(heat))                 # heat over the whole county
k <- match(c("17019", "47153"), low$GEOID)                     # Champaign, IL and Sequatchie, TN
data.frame(county = low$NAME[k], over_cropland = round(low$heat[k], 1),
           whole_county = round(low$heat_area[k], 1))


# County heat over cropland, on a map ----
east <- low[st_coordinates(st_centroid(st_geometry(low)))[, 1] > -100, ]   # east of 100 W
plot(east["heat"], main = "", border = NA, key.pos = 1,                     # the key below the map
     breaks = seq(0, 320, 40), pal = hcl.colors(8, "YlOrRd", rev = TRUE))     # light to dark: more heat
sum(is.na(low$heat))                                    # counties with no cropland
paste(low$NAME, low$STUSPS)[is.na(low$heat)]


# Heat against the yield change ----
lon <- st_coordinates(st_centroid(st_geometry(low)))[, 1]      # each county's centre, longitude
d   <- st_drop_geometry(low[!is.na(low$chg) & !is.na(low$heat) & lon > -100, ])
fit <- lm(chg ~ heat, d)
c(counties = nrow(d), correlation = round(cor(d$heat, d$chg), 2), slope = round(coef(fit)[[2]], 2))
round(tapply(d$chg, d$STUSPS, median)[c("MO", "KY", "IL", "IN", "IA", "MN")])


# The Eaton fire on 9 January 2025 ----
img  <- rast("data/nasa/worldview_terra_20250109.tif")         # NASA's Terra, 9 January 2025
dim(img)                                                       # rows, columns, layers
fire <- vect(cbind(lon = -118.069155, lat = 34.203483), crs = "EPSG:4326")   # the fire's origin
plotRGB(img); points(fire, pch = 21, bg = "red", col = "white", cex = 1.6)


# The wind at the fire at 10 am ----
u_la <- rast("data_clean/u10_la_20250109.tif")                 # wind toward the east, by hour
v_la <- rast("data_clean/v10_la_20250109.tif")                 # wind toward the north
uf <- extract(u_la[["18:00"]], fire, ID = FALSE)[1, 1]         # 18:00 UTC is 10 am in Los Angeles
vf <- extract(v_la[["18:00"]], fire, ID = FALSE)[1, 1]
to <- (atan2(uf, vf) * 180 / pi) %% 360                        # the direction the wind blows toward
round(c(u = uf, v = vf, kmh = sqrt(uf^2 + vf^2) * 3.6,
        from = (atan2(-uf, -vf) * 180 / pi) %% 360, toward = to), 1)


# The cells downwind of the fire ----
people <- crop(rast("data_clean/pop_2010.tif"), img)           # people per cell, 2010
km    <- values(distance(people, fire))[, 1] / 1000            # km from the fire to each cell
xy    <- xyFromCell(people, 1:ncell(people))                   # each cell's centre: lon, lat
east  <- (xy[, 1] - crds(fire)[1]) * cos(crds(fire)[2] * pi / 180)   # degrees east, shrunk at 34 N
north <-  xy[, 2] - crds(fire)[2]                              # degrees north of the fire
bear  <- (atan2(east, north) * 180 / pi) %% 360                # direction from the fire to the cell
gap   <- abs((bear - to + 180) %% 360 - 180)                   # degrees away from the wind
down  <- km <= 100 & gap <= 20
c(cells = ncell(people), downwind = sum(down))


# 3.6 million people lived downwind ----
n <- values(people)[, 1]
round(c(downwind = sum(n[down], na.rm = TRUE), in_the_picture = sum(n, na.rm = TRUE)))
round(100 * sum(n[down], na.rm = TRUE) / sum(n, na.rm = TRUE), 1)


# The downwind cells over the picture ----
dw <- rast(people); values(dw) <- ifelse(down, 1, NA)          # 1 downwind, NA elsewhere
plotRGB(img); lines(as.polygons(dw), col = "yellow", lwd = 2)
points(fire, pch = 21, bg = "red", col = "white", cex = 1.6)


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Practice ----
# Practice. Run in the 24-spatial-rasters folder after the slides' code has built
# tmax, tny, tny_in, ny, wh, i, t17, u, v10, tab, w, low, tabN, P, M, cd, cdp, heat, cropg,
# fire, u_la, v_la, people, km, bear, gap and n.

# One grid
#  1. The hottest day in each New York cell: which.max(tny_in) returns, in each cell, the number
#     of its hottest layer. Which layers are hottest in the most cells?
#  2. The hottest and the coolest cell of New York in the layer dated 18 July (tny_in):
#     which.max(values(...)) and which.min(), then xyFromCell(). Which counties are they in?
#  3. Days above 32 °C in each New York cell, sum(tny_in > 32): the range, the share of cells
#     with five or more, and Warren Hall's cell.
# Computing on grids
#  4. Days above 35 °C across the country, sum(tmax > 35): the share of cells with at least one,
#     the share with all 31, Warren Hall and St. Louis (-90.1848, 38.6247).
#  5. The month's range in each New York cell, max(tny_in) - min(tny_in). Where is it largest?
#  6. The wind at Warren Hall hour by hour: the speed at each of the 24 hours from u and v10.
#     The strongest and weakest hour, the mean of the 24 speeds, and the speed and direction
#     of the mean u and mean v.
# Cells to counties
#  7. Cell centres against exact fractions: extract(t17, ny, fun = mean, na.rm = TRUE) without
#     exact = TRUE. Which New York counties move most? How many cell centres does New York
#     County (Manhattan) have, and how many cells does it touch?
#  8. A weight matrix for New York's 62 counties on tny's 20,710 cells, built as P was.
#     The hottest and coolest county-day, and each county's days with a mean above 30 °C.
#  9. Use tab, the table of Tompkins County's cells in New York's grid, on the national matrix M:
#     sum(w * M[tab$cell, 17]) / sum(w). What comes out, and where is cell 10,905 in each grid?
# Weights
# 10. Counting hot days before and after averaging: P %*% (M > 30), with NA set to 0, against
#     the days each county's mean is above 30. Compare Tompkins and Santa Barbara, California.
# 11. The counties that population weights move most: the July mean by people minus by area.
#     Which four move most, and in what share of counties do the two differ by more than 1 °C?
# The two applications
# 12. The Eaton fire with 30° and 100 km, with 20° and 50 km, and with the wind at 12:00 UTC.
#     Heat and corn with a 32 °C threshold: Tompkins and Champaign, with area weights.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =


# The end
