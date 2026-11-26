# AEM 6850, session 26 (Drone & satellite imagery). An application to Cayuga Lake
# Script 7 of 7 - Cayuga Lake's area from ESA's map and from two water indices, where NDWI misses the lake,
# 200 points labelled on aerial photos split into 140 training and 60 test points, a decision tree with
# rpart(), its accuracy and confusion table, the tree applied to every cell against ESA's map,
# Practice 3 (the threshold moved), Practice 4 (Owasco Lake) and Practice 9 (a tree on the visible bands)
# Reads: data/sentinel2/s2_20240815_cayuga_20m.tif (our image of 15 August 2024),
#        data/worldcover/worldcover2021_cayuga.tif (ESA WorldCover 2021, 10 m),
#        data_clean/labels/labels_200.csv (id, lon, lat, class: 200 points labelled by hand on the 2019
#          aerial photos, 50 in each of water, forest, grass or crops, and built)
# Writes: nothing
# Open 26-satellite-local.Rproj first, so R starts in the project folder; then
#   source("code/7_lake.R")
# Every section matches a slide of the same name. Takes about 30 seconds.

# 1). Preliminary ----
# Clean up workspace and load or install necessary packages if necessary
  rm(list = ls())
  want <- c("terra", "rpart")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only=TRUE))
  rm(want, need)
  options(width = 100); terraOptions(progress = 0, memmax = 2)
  misc <- list()
  misc$s2     <- "data/sentinel2/s2_20240815_cayuga_20m.tif"
  misc$wc     <- "data/worldcover/worldcover2021_cayuga.tif"
  misc$labels <- "data_clean/labels/labels_200.csv"
  misc$acre   <- 4046.86          # m2 in one acre
  misc$state  <- 42956            # Cayuga Lake's area, acres (New York's DEC)
  # s2 and refl as in script 3 (Reading the image in R)
  s2   <- rast(misc$s2)
  refl <- s2[[1:5]] / 10000
  # wc and wc20 as in script 4 (NDVI of cropland and forest in August)
  wc <- rast(misc$wc)
  names(wc) <- "esa"
  wc20 <- project(wc, s2, method = "mode")
  # w10 and f10 as in script 5 (Separate water bodies at 10 m)
  tm  <- rast(ext(s2), resolution = 10, crs = crs(s2))
  w10 <- project(wc == 80, tm, method = "near")
  f10 <- freq(patches(w10, directions = 8, zeroAsNA = TRUE))

# 2). Cayuga Lake's area from ESA's map ----
  # page: the lake is the largest water body; each 10 m cell covers 100 m2
  max(f10$count) * 100 / 4046.86

# 3). Two water indices ----
  mndwi <- (refl$B03 - refl$B11) / (refl$B03 + refl$B11)
  ndwi  <- (refl$B03 - refl$B8A) / (refl$B03 + refl$B8A)
  fm <- freq(patches(mndwi > 0, directions = 8, zeroAsNA = TRUE))
  fn <- freq(patches(ndwi > 0, directions = 8, zeroAsNA = TRUE))
  round(c(mndwi = max(fm$count), ndwi = max(fn$count)) * 400 / 4046.86)   # acres; a 20 m cell is 400 m2
  # percent under the state's figure
  round(100 * (1 - c(mndwi = max(fm$count), ndwi = max(fn$count)) * 400 / 4046.86 / misc$state), 1)
  # page: NDWI finds this percent of ESA's water cells (on our 20 m cells) at the south end, in the middle
  # and in the north (latitude 42.45 to 42.50, 42.50 to 42.65 and 42.65 to 42.90)
  found <- function(ymin, ymax) {
    b <- project(vect(ext(-76.85, -76.40, ymin, ymax), crs = "EPSG:4326"), crs(s2))
    v <- values(crop(c(wc20 == 80, ndwi > 0), b))
    round(100 * mean(v[!is.na(v[, 1]) & v[, 1] == 1, 2] == 1, na.rm = TRUE))
  }
  c(south = found(42.45, 42.50), middle = found(42.50, 42.65), north = found(42.65, 42.90))
  # page: with the cloud mask of script 3, the two areas do not change
  cloud <- (s2$SCL == 3) | (s2$SCL >= 8 & s2$SCL <= 10)
  refl_masked <- mask(refl, cloud, maskvalues = TRUE)
  mm <- (refl_masked$B03 - refl_masked$B11) / (refl_masked$B03 + refl_masked$B11)
  nm <- (refl_masked$B03 - refl_masked$B8A) / (refl_masked$B03 + refl_masked$B8A)
  round(c(mndwi = max(freq(patches(mm > 0, directions = 8, zeroAsNA = TRUE))$count),
          ndwi  = max(freq(patches(nm > 0, directions = 8, zeroAsNA = TRUE))$count)) * 400 / 4046.86)

# 4). Where NDWI misses the lake (page only) ----
  miss  <- (wc20 == 80) & (ndwi <= 0)          # water on ESA's map, missed by NDWI
  south <- project(vect(ext(-76.60, -76.44, 42.43, 42.55), crs = "EPSG:4326"), crs(miss))
  plot(crop(miss, south), col = c("grey90", "red"),
       levels = c("other", "water on ESA's map, missed by NDWI"))
  global(miss, "sum", na.rm = TRUE)            # ESA-water cells NDWI misses, whole image
  # the median green, near-infrared and shortwave infrared of ESA's water cells, whole image and south end
  wt <- c(refl$B03, refl$B8A, refl$B11, wc20 == 80)
  v  <- values(wt)
  vs <- values(crop(wt, south))
  round(rbind(whole_image = apply(v[!is.na(v[, 4]) & v[, 4] == 1, 1:3], 2, median, na.rm = TRUE),
              south_end   = apply(vs[!is.na(vs[, 4]) & vs[, 4] == 1, 1:3], 2, median, na.rm = TRUE)), 3)

# 5). Training points and test points ----
  lab <- read.csv("data_clean/labels/labels_200.csv")             # lon, lat, class
  lab$class <- factor(lab$class)
  pts <- project(vect(lab, geom = c("lon", "lat"), crs = "EPSG:4326"), crs(s2))
  lab <- cbind(lab, extract(refl, pts, ID = FALSE))               # five bands per point
  set.seed(6850)
  test  <- sample(nrow(lab), 60)
  train <- lab[-test, ]                                           # 140 points to learn from
  hold  <- lab[test, ]                                            # 60 test points
  table(train$class)

# 6). A decision tree on our labels ----
  fit <- rpart(class ~ B02 + B03 + B04 + B8A + B11, data = train, method = "class")   # the answer is a class
  par(mar = c(0, 0, 0, 0))                     # no blank margin around the tree
  plot(fit, uniform = TRUE, margin = 0.08)     # uniform: every level of the tree as tall
  text(fit, cex = 0.9)
  fit                                                             # page: the splits as printed

# 7). Accuracy and the confusion table ----
  pred <- predict(fit, hold, type = "class")
  mean(pred == hold$class)
  table(true = hold$class, predicted = pred)
  sum(pred == hold$class)                                         # page: right answers of the 60

# 8). Our map against ESA's map (page only) ----
  map <- predict(refl, fit, type = "class", na.rm = TRUE)     # our class for every cell
  names(map) <- "tree"
  crosstab(c(map, wc20))                                      # rows: our tree; columns: ESA
  fq <- freq(map)
  data.frame(class = fq$value, pct = round(100 * fq$count / sum(fq$count), 1))   # share of cells
  round(100 * global(wc20 == 50, "mean", na.rm = TRUE)[[1]], 1)                # ESA's built, percent

# 9). Practice 3: move the threshold ----
  # Measure the lake with MNDWI above -0.1 and above 0.1. How much does the area move?
  for (th in c(-0.1, 0.1)) {
    f <- freq(patches(mndwi > th, directions = 8, zeroAsNA = TRUE))
    print(c(threshold = th, acres = round(max(f$count) * 400 / 4046.86)))
  }

# 10). Practice 4: Owasco Lake ----
  # Owasco Lake is the second-largest water body in f10. How many acres does ESA's map give it?
  o <- sort(f10$count, decreasing = TRUE)[2]
  c(cells = o, acres = round(o * 100 / 4046.86))                  # DEC publishes 6,665 acres

# 11). Practice 9: a tree that sees only the visible bands ----
  # Refit the tree with only the visible bands (B02, B03 and B04). Compare its accuracy on the same 60 test
  # points with the five-band tree's.
  fit3  <- rpart(class ~ B02 + B03 + B04, data = train, method = "class")
  pred3 <- predict(fit3, hold, type = "class")
  c(five_bands = mean(pred == hold$class), visible_only = mean(pred3 == hold$class))
  table(true = hold$class, predicted = pred3)

# the end ----
