# AEM 6850, session 26 (Drone & satellite imagery). Resolution in space and time
# Script 5 of 7 - ESA's water put on 10 m cells and its separate water bodies counted with patches(),
# Exercise 2 (water bodies in 30 m and 250 m cells), clear images of the lake in 2024, Practice 6
# Reads: data/sentinel2/s2_20240815_cayuga_20m.tif (our image, for its box and its cells),
#        data/worldcover/worldcover2021_cayuga.tif (ESA WorldCover 2021, 10 m),
#        data_clean/catalog/s2_box_clear_2024.csv (each 2024 pass: share of our image covered and clear),
#        data_clean/catalog/s2_passes_2024_18TUN.csv (each 2024 pass over tile 18TUN, with the tile's cloud)
# Writes: nothing
# Open 26-satellite-local.Rproj first, so R starts in the project folder; then
#   source("code/5_resolution.R")
# Every section matches a slide of the same name. Takes about 15 seconds.

# 1). Preliminary ----
# Clean up workspace and load or install necessary packages if necessary
  rm(list = ls())
  want <- c("terra")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only=TRUE))
  rm(want, need)
  options(width = 100); terraOptions(progress = 0, memmax = 2)
  misc <- list()
  misc$s2     <- "data/sentinel2/s2_20240815_cayuga_20m.tif"
  misc$wc     <- "data/worldcover/worldcover2021_cayuga.tif"
  misc$box    <- "data_clean/catalog/s2_box_clear_2024.csv"     # made by tools/make_s2_season_2024.R
  misc$passes <- "data_clean/catalog/s2_passes_2024_18TUN.csv"  # made by tools/fetch_sentinel2.R
  misc$acre   <- 4046.86                                       # m2 in one acre
  # s2 and wc as in scripts 3 and 4 (Reading the image in R; NDVI of cropland and forest in August)
  s2 <- rast(misc$s2)
  wc <- rast(misc$wc)
  names(wc) <- "esa"

# 2). Separate water bodies at 10 m ----
  tm  <- rast(ext(s2), resolution = 10, crs = crs(s2))       # empty raster of 10 m cells
  w10 <- project(wc == 80, tm, method = "near")               # 1 = water, 0 = other
  f10 <- freq(patches(w10, directions = 8, zeroAsNA = TRUE))  # 8: corners touch; zeroAsNA leaves land out
  nrow(f10)                                                   # water bodies
  max(f10$count)                                              # cells in the largest, Cayuga Lake

# 3). Exercise 2, solution: water bodies in 30 m and 250 m cells ----
  # Larger cells erase small ponds. The lake hardly changes. w10 is from section 2.
  w30 <- aggregate(w10, fact = 3, fun = "mean", na.rm = TRUE) >= 0.5
  f30 <- freq(patches(w30, directions = 8, zeroAsNA = TRUE)); nrow(f30)
  max(f30$count) * 30^2 / 4046.86
  w250 <- aggregate(w10, fact = 25, fun = "mean", na.rm = TRUE) >= 0.5
  f250 <- freq(patches(w250, directions = 8, zeroAsNA = TRUE)); nrow(f250)
  max(f250$count) * 250^2 / 4046.86
  # half of the other 405 water bodies at 10 m are smaller than this many acres
  round(median(f10$count[-which.max(f10$count)]) * 100 / 4046.86, 3)

# 4). Clear images of the lake in 2024 ----
  # The cloud share is measured inside our image, from ESA's class for each cell. A pass counts as clear
  # when it covers at least 90% of our image and under 10% of what it covers is cloud.
  bx <- read.csv("data_clean/catalog/s2_box_clear_2024.csv")
  bx$date  <- as.Date(bx$date)
  bx$clear <- bx$share_box_covered >= 0.9 & bx$share_clear > 0.9
  c(passes = nrow(bx), whole_image = sum(bx$share_box_covered == 1), clear = sum(bx$clear))
  table(month = format(bx$date, "%m"), clear = bx$clear)
  cd <- bx$date[bx$clear]                                     # the clear dates
  cd
  gap <- diff(cd)                                             # days between clear images
  data.frame(days = as.numeric(max(gap)), from = cd[which.max(gap)], to = cd[which.max(gap) + 1])

# 5). Practice 6: clear images under 20% and 5% cloud ----
  # From data_clean/catalog/s2_passes_2024_18TUN.csv, count the dates under 20% and under 5% cloud.
  ps <- read.csv("data_clean/catalog/s2_passes_2024_18TUN.csv")
  c(under_20 = sum(ps$cloud < 20), under_5 = sum(ps$cloud < 5))
  # the same count inside our image, as on the slide (passes covering at least 90% of it)
  c(under_20 = sum(bx$share_box_covered >= 0.9 & bx$share_clear > 0.8),
    under_5  = sum(bx$share_box_covered >= 0.9 & bx$share_clear > 0.95))

# the end ----
