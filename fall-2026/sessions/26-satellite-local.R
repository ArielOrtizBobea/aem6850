# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# AEM 6850 -- Empirical Methods for Applied Economists
# Prof. Ariel Ortiz-Bobea
# Session 26 -- Drone & satellite imagery
# Tuesday, Dec 1, 2026
#
# Run it one line at a time: put the cursor on a line and press Cmd-Return
# (Mac) or Ctrl-Enter (Windows).
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# Load or install the packages ----
want <- c("terra", "sf", "rpart")
need <- want[!(want %in% installed.packages()[,"Package"])]
if (length(need)) install.packages(need)
lapply(want, function(i) require(i, character.only = TRUE))
rm(want, need)
options(width = 100); terraOptions(progress = 0, memmax = 2)


# Reading the drone image in R ----
mo <- rast("data/drone/willis_corn_trial.tif")
mo
mo <- mask(mo, sum(mo) == 0, maskvalues = TRUE)   # black corners become NA


# The same field in 10 m and 30 m cells ----
m10 <- aggregate(mo, fact = 243, fun = "mean", na.rm = TRUE)   # 243 pixels x 4.1 cm = 10 m cells
m30 <- aggregate(mo, fact = 730, fun = "mean", na.rm = TRUE)   # 730 pixels x 4.1 cm = 30 m cells


# Counting the cells ----
n10 <- global(!is.na(m10[[1]]), "sum")[[1]]
n30 <- global(!is.na(m30[[1]]), "sum")[[1]]
c(cells_10m = n10, cells_30m = n30)


# A Census road on the drone image ----
rd <- st_read("data_clean/drone/caldwell_roads_near_mosaic.gpkg", quiet = TRUE)
ln <- st_cast(st_intersection(st_union(rd[rd$FULLNAME == "Pennell St NE", ]),
                              st_as_sfc(st_bbox(ext(mo) - 10, crs = st_crs(rd)))), "LINESTRING")[1]
off <- do.call(rbind, lapply(c(0.2, 0.5, 0.8), function(fr) {
  p0 <- st_coordinates(st_line_sample(ln, sample = fr))[1, 1:2]
  p1 <- st_coordinates(st_line_sample(ln, sample = fr + 0.01))[1, 1:2]
  tv <- (p1 - p0) / sqrt(sum((p1 - p0)^2)); nv <- c(-tv[2], tv[1])   # unit normal, left of the line
  s  <- seq(-25, 25, by = 0.04)
  v  <- extract(mo, cbind(p0[1] + s * nv[1], p0[2] + s * nv[2]))
  asph <- as.vector(stats::filter((v$blue > v$red) * 1, rep(1 / 25, 25)) > 0.5)
  asph[is.na(asph)] <- FALSE
  r <- rle(asph); en <- cumsum(r$lengths); stt <- en - r$lengths + 1
  runs <- data.frame(from = s[stt], to = s[en])[r$values, ]
  k <- 1
  while (k < nrow(runs)) {                       # join the two lanes across the centre stripe
    if (runs$from[k + 1] - runs$to[k] < 1) {
      runs$to[k] <- runs$to[k + 1]; runs <- runs[-(k + 1), ]
    } else k <- k + 1
  }
  runs <- runs[runs$to - runs$from > 3, ]
  runs <- runs[which.min(pmin(abs(runs$from), abs(runs$to),
                              ifelse(runs$from < 0 & runs$to > 0, 0, Inf))), ]
  data.frame(point = fr, width_m = round(runs$to - runs$from, 1),
             offset_to_centre_m = round((runs$from + runs$to) / 2, 1))
}))
off


# The image of 15 August 2024 ----
s2_search <- read.csv("data_clean/catalog/s2_search_20240810_20240820.csv")
print(s2_search[s2_search$tile == "18TUN", c("id", "date", "cloud")], row.names = FALSE)


# Reading the image in R ----
s2 <- rast("data/sentinel2/s2_20240815_cayuga_20m.tif")
s2
refl <- s2[[1:5]] / 10000                        # reflectance, from 0 to 1


# Reflectance of plants, bare ground and water ----
m <- zonal(refl, s2$SCL, fun = "median", na.rm = TRUE)   # about 6 seconds
m[m$SCL >= 4 & m$SCL <= 6, ]


# A cell in mid-lake ----
lake <- project(vect(cbind(-76.715, 42.700), crs = "EPSG:4326"), crs(s2))
round(extract(refl, lake, ID = FALSE), 4)


# True and false colour ----
box   <- project(vect(ext(-76.56, -76.44, 42.43, 42.50), crs = "EPSG:4326"), crs(refl))
south <- crop(refl, box)                                     # the south end of the lake
par(mfrow = c(1, 2))                                         # two pictures side by side
plotRGB(south, r = 3, g = 2, b = 1, stretch = "lin", mar = c(0, 0, 2, 0), main = "True colour")
plotRGB(south, r = 4, g = 3, b = 2, stretch = "lin", mar = c(0, 0, 2, 0), main = "False colour")
par(mfrow = c(1, 1))                                         # back to one plot per page


# NDVI, a vegetation index ----
ndvi <- (refl$B8A - refl$B04) / (refl$B8A + refl$B04)
names(ndvi) <- "NDVI"                              # otherwise the layer keeps the name B8A
plot(ndvi, col = hcl.colors(50, "Greens", rev = TRUE), plg = list(title = "NDVI"))


# The range of NDVI and the Arts Quad ----
minmax(ndvi)
aq <- project(vect(cbind(-76.4855, 42.4489), crs = "EPSG:4326"), crs(s2))   # the Arts Quad
round(extract(ndvi, aq, ID = FALSE), 3)


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Exercise 1 (3 minutes) ----
# Exercise 1 (3 minutes). The median NDVI of plants, bare ground and water.
# NDVI puts plants far above bare ground and water. Water still sits above 0.
# In the 26-satellite-local folder, with s2 and ndvi as on the slides before
# (or run code/3_sentinel2.R first).
# 1. z <- zonal(ndvi, s2$SCL, fun = "median", na.rm = TRUE)   # median NDVI in each of ESA's classes
# 2. round(z[z$SCL >= 4 & z$SCL <= 6, ], 2)                   # plants (4), bare ground (5), water (6)
# 3. Write the three classes from lowest to highest NDVI as a comment.
# 4. Water's NDVI is above 0. Use water's median red and near-infrared from Reflectance of
#    plants, bare ground and water to say why, in one comment.
# Two answers to compare with the room: how far plants sit above the other two, and why
# water's NDVI is above 0.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




# Lights and population in New York's counties ----
viirs <- rast("data/lights/ntl_viirs_2023_ny.tif")             # mean light at night, 2023
ny    <- vect("data_clean/census/ny_counties.gpkg")            # 62 counties, 2023 population
s     <- extract(viirs, ny, fun = sum, na.rm = TRUE, exact = TRUE)  # exact: share of each cell inside
cor(log(s[, 2]), log(ny$pop2023))                              # column 2 holds the sums


# NDVI of cropland and forest in August ----
wc <- rast("data/worldcover/worldcover2021_cayuga.tif")
names(wc) <- "esa"
wc20 <- project(wc, s2, method = "mode")           # each 20 m cell takes its most common class
z <- zonal(ndvi, wc20, fun = "median", na.rm = TRUE)
z$type <- c("trees", "grass", "crops", "built", "bare", "water", "wetland")
z$NDVI <- round(z$NDVI, 2)
z[z$esa %in% c(10, 40, 80), c("type", "NDVI")]


# Separate water bodies at 10 m ----
tm  <- rast(ext(s2), resolution = 10, crs = crs(s2))       # empty raster of 10 m cells
w10 <- project(wc == 80, tm, method = "near")               # 1 = water, 0 = other
f10 <- freq(patches(w10, directions = 8, zeroAsNA = TRUE))  # 8: corners touch; zeroAsNA leaves land out
nrow(f10)                                                   # water bodies
max(f10$count)                                              # cells in the largest, Cayuga Lake


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Exercise 2 (3 minutes) ----
# Exercise 2 (3 minutes). Water bodies in 30 m and 250 m cells.
# Larger cells erase small ponds. The lake hardly changes.
# In the 26-satellite-local folder, with w10, the 10 m water map of the slide before
# (or run code/5_resolution.R first).
# 1. w30 <- aggregate(w10, fact = 3, fun = "mean", na.rm = TRUE) >= 0.5   # water if half is water
# 2. f30 <- freq(patches(w30, directions = 8, zeroAsNA = TRUE)); nrow(f30)
# 3. max(f30$count) * 30^2 / 4046.86                       # the lake in acres; an acre is 4,046.86 m2
# 4. The same for 250 m cells, MODIS's smallest pixel:
#    w250 <- aggregate(w10, fact = 25, fun = "mean", na.rm = TRUE) >= 0.5
#    then steps 2 and 3 with w250, f250 and 250^2.
# Two answers to compare with the room: how many of the 406 water bodies are left in
# 250 m cells, and how much the lake's area moves.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




# Clear images of the lake in 2024 ----
bx <- read.csv("data_clean/catalog/s2_box_clear_2024.csv")
bx$date  <- as.Date(bx$date)
bx$clear <- bx$share_box_covered >= 0.9 & bx$share_clear > 0.9
c(passes = nrow(bx), whole_image = sum(bx$share_box_covered == 1), clear = sum(bx$clear))
table(month = format(bx$date, "%m"), clear = bx$clear)
cd <- bx$date[bx$clear]                                     # the clear dates
cd
gap <- diff(cd)                                             # days between clear images
data.frame(days = as.numeric(max(gap)), from = cd[which.max(gap)], to = cd[which.max(gap) + 1])


# Dropping cloudy cells ----
cloud <- (s2$SCL == 3) | (s2$SCL >= 8 & s2$SCL <= 10)
global(cloud, "sum", na.rm = TRUE)                 # 44
refl_masked <- mask(refl, cloud, maskvalues = TRUE)


# Forest loss in Mexico ----
0.49 * 0.34 + 0.012 * 0.66


# Lights stop counting at 63 ----
li <- rast("data/lights/ntl_li2020_2013_ny.tif")             # older series, 0 to 63
ny <- vect("data_clean/census/ny_counties.gpkg")
x  <- extract(li, ny[ny$NAME == "New York", ])               # Manhattan's cells
c(cells = nrow(x), at_63 = sum(x[[2]] == 63))


# Lights and population without New York City ----
nyc <- ny$NAME %in% c("Bronx", "Kings", "New York", "Queens", "Richmond")   # New York City
sl  <- extract(li, ny, fun = sum, na.rm = TRUE, exact = TRUE)
round(c(all = cor(log(sl[, 2]), log(ny$pop2013)),
        without_nyc = cor(log(sl[!nyc, 2]), log(ny$pop2013[!nyc]))), 3)


# Cayuga Lake's area from ESA's map ----
max(f10$count) * 100 / 4046.86


# Two water indices ----
mndwi <- (refl$B03 - refl$B11) / (refl$B03 + refl$B11)
ndwi  <- (refl$B03 - refl$B8A) / (refl$B03 + refl$B8A)
fm <- freq(patches(mndwi > 0, directions = 8, zeroAsNA = TRUE))
fn <- freq(patches(ndwi > 0, directions = 8, zeroAsNA = TRUE))
round(c(mndwi = max(fm$count), ndwi = max(fn$count)) * 400 / 4046.86)   # acres; a 20 m cell is 400 m2


# Where NDWI finds the lake ----
round(100 * (1 - c(mndwi = max(fm$count), ndwi = max(fn$count)) * 400 / 4046.86 / 42956), 1)
found <- function(ymin, ymax) {
  b <- project(vect(ext(-76.85, -76.40, ymin, ymax), crs = "EPSG:4326"), crs(s2))
  v <- values(crop(c(wc20 == 80, ndwi > 0), b))
  round(100 * mean(v[!is.na(v[, 1]) & v[, 1] == 1, 2] == 1, na.rm = TRUE))
}
c(south = found(42.45, 42.50), middle = found(42.50, 42.65), north = found(42.65, 42.90))


# Where NDWI misses the lake ----
miss  <- (wc20 == 80) & (ndwi <= 0)          # water on ESA's map, missed by NDWI
south <- project(vect(ext(-76.60, -76.44, 42.43, 42.55), crs = "EPSG:4326"), crs(miss))
plot(crop(miss, south), col = c("grey90", "red"),
     levels = c("other", "water on ESA's map, missed by NDWI"))
global(miss, "sum", na.rm = TRUE)            # ESA-water cells NDWI misses, whole image
wt <- c(refl$B03, refl$B8A, refl$B11, wc20 == 80)
v  <- values(wt)
vs <- values(crop(wt, south))
round(rbind(whole_image = apply(v[!is.na(v[, 4]) & v[, 4] == 1, 1:3], 2, median, na.rm = TRUE),
            south_end   = apply(vs[!is.na(vs[, 4]) & vs[, 4] == 1, 1:3], 2, median, na.rm = TRUE)), 3)


# Training points and test points ----
lab <- read.csv("data_clean/labels/labels_200.csv")             # lon, lat, class
lab$class <- factor(lab$class)
pts <- project(vect(lab, geom = c("lon", "lat"), crs = "EPSG:4326"), crs(s2))
lab <- cbind(lab, extract(refl, pts, ID = FALSE))               # five bands per point
set.seed(6850)
test  <- sample(nrow(lab), 60)
train <- lab[-test, ]                                           # 140 points to learn from
hold  <- lab[test, ]                                            # 60 test points
table(train$class)


# A decision tree on our labels ----
fit <- rpart(class ~ B02 + B03 + B04 + B8A + B11, data = train, method = "class")   # the answer is a class
par(mar = c(0, 0, 0, 0))                     # no blank margin around the tree
plot(fit, uniform = TRUE, margin = 0.08)     # uniform: every level of the tree as tall
text(fit, cex = 0.9)


# The tree's splits ----
fit


# Accuracy and the confusion table ----
pred <- predict(fit, hold, type = "class")
mean(pred == hold$class)
table(true = hold$class, predicted = pred)


# Our map against ESA's map ----
map <- predict(refl, fit, type = "class", na.rm = TRUE)     # our class for every cell
names(map) <- "tree"
crosstab(c(map, wc20))                                      # rows: our tree; columns: ESA
fq <- freq(map)
data.frame(class = fq$value, pct = round(100 * fq$count / sum(fq$count), 1))   # share of cells
round(100 * global(wc20 == 50, "mean", na.rm = TRUE)[[1]], 1)                # ESA's built, percent


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Practice ----
# Practice. Run in the 26-satellite-local folder after the slides' code has built
# s2, refl, ndvi, wc, wc20, w10, f10, mndwi, ny, s, li, nyc, sl, bx, train, hold and pred.

# NDVI and bands
#  1. NDVI at four places: mid-lake (-76.654, 42.600), Sapsucker Woods (-76.444, 42.485),
#     the Shops at Ithaca Mall parking lot (-76.4917, 42.4840) and a field near Aurora
#     (-76.6817, 42.7601). Rank them by NDVI.
#  2. The five bands at those points. Which band separates the parking lot from the lake?
# Lake areas
#  3. Move the threshold: measure the lake with MNDWI above -0.1 and above 0.1.
#     How much does the area move?
#  4. Owasco Lake is the second-largest water body in f10. How many acres does ESA's map
#     give it? DEC publishes 6,665 acres.
# Lights and clouds
#  5. Lights without New York City: drop Bronx, Kings, New York, Queens and Richmond and
#     recompute both correlations (VIIRS with pop2023, the older series with pop2013).
#  6. Clear images: count the dates under 20% and under 5% cloud in
#     data_clean/catalog/s2_passes_2024_18TUN.csv (the tile's cloud). Then count the same
#     inside our image with bx, the table of Clear images of the lake in 2024.
# Land cover
#  7. The median of each band within ESA's types: zonal(refl, wc20, fun = "median",
#     na.rm = TRUE). Which band puts built cells (50) furthest from crops (40)?
#  8. Urban sprawl: Burchfield et al.'s index from ESA's map. Put it on 30 m cells, call a
#     cell developed when at least half of it is built-up (class 50), then average the share
#     of undeveloped land in the square kilometre around each developed cell (a focal()
#     window of 33 x 33 cells). Compare Ithaca with Auburn.
# Classification
#  9. Refit the tree with only the visible bands (B02, B03 and B04). Compare its accuracy
#     on the same 60 test points with the five-band tree's.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =


# The end
