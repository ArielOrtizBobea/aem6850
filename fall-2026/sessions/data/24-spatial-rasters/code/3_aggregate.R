# AEM 6850, session 24 (Spatial II: rasters). Combining rasters and polygons
# Script 3 of 5 - county means with extract(), the timings, the cells of Tompkins County and their
# fractions, the mean by hand, Exercise 2, the matrix product, the weight matrix P for every county,
# sparse matrices, P %*% M, population weights
# Reads: data_clean/tmax_july2012.tif, data/census/cb_2024_us_county_500k.zip, data_clean/timings.csv,
#        data_clean/pop_2010.tif
# Writes: data_clean/counties/ (the county zip, unzipped, if script 1 has not done it)
# Open 24-spatial-rasters.Rproj first, so R starts in the project folder; then
#   source("code/3_aggregate.R")
# Every section matches a slide of the same name; the live script 24-spatial-rasters.R runs them all in order.
# Peak memory is about 3.5 GB: the national stack as a matrix (section 15) is 220 MB, and its copies add up.

# 1). Preliminary ----
# Clean up workspace and load or install necessary packages if necessary
  rm(list = ls())
  want <- c("terra", "sf", "exactextractr", "Matrix")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only = TRUE))
  rm(want, need)
  misc <- list()
  misc$july   <- "data_clean/tmax_july2012.tif"                # the 31 days of July 2012 in one file
  misc$county <- "data/census/cb_2024_us_county_500k.zip"      # the Census county outlines
  misc$shp    <- "data_clean/counties/cb_2024_us_county_500k.shp"

# 2). The layers from earlier scripts ----
  # tmax, the 31 days; co, the counties; ny, New York's; tny, the days cropped to New York; t17, 17 July
  tmax <- rast(misc$july)
  if (!file.exists(misc$shp)) unzip(misc$county, exdir = "data_clean/counties")
  co   <- st_read(misc$shp, quiet = TRUE)
  ny   <- co[co$STUSPS == "NY", ]
  tny  <- crop(tmax, ny)
  t17  <- tny[["2012-07-17"]]

# 3). County means with extract() ----
  ny$t17 <- extract(t17, ny, fun = mean, exact = TRUE, na.rm = TRUE, ID = FALSE)[, 1]
  round(ny$t17[ny$GEOID == "36109"], 2)           # Tompkins County
  round(range(ny$t17), 1)
  plot(ny["t17"], main = "")

# 4). Without na.rm, and with cell centres ----
  m0 <- suppressWarnings(extract(t17, ny, fun = mean, exact = TRUE, ID = FALSE)[, 1])   # without na.rm = TRUE
  ny$NAME[is.na(m0)]
  cc <- extract(t17, ny[ny$GEOID == "36109", ], ID = FALSE)   # the cells whose centre is inside
  c(cells = nrow(cc), mean = round(mean(cc[, 1]), 2))

# 5). The timings I measured ----
  read.csv("data_clean/timings.csv")

# 6). The area of Tompkins County from its cells ----
  tk  <- ny[ny$GEOID == "36109", ]
  tab <- exact_extract(t17, tk, include_cell = TRUE, progress = FALSE)[[1]]
  a   <- cellSize(t17, unit = "km")[tab$cell][, 1]     # each cell's area, km2
  round(c(from_cells = sum(a * tab$coverage_fraction), census = (tk$ALAND + tk$AWATER) / 1e6), 1)

# 7). The table of cells and fractions ----
  tk  <- ny[ny$GEOID == "36109", ]                            # Tompkins County
  tab <- exact_extract(t17, tk, include_cell = TRUE)[[1]]     # one row per cell the county touches
  head(tab, 3)
  c(cells = nrow(tab), whole = sum(tab$coverage_fraction == 1),
    partial = sum(tab$coverage_fraction < 1))
  f <- rast(t17)                                              # an empty grid with the same cells
  f[tab$cell] <- tab$coverage_fraction                        # the fractions go in by cell number
  plot(crop(f, tk, snap = "out")); lines(vect(tk))

# 8). terra's own table ----
  head(extract(t17, tk, cells = TRUE, exact = TRUE), 3)
  nrow(extract(t17, tk, cells = TRUE, exact = TRUE))

# 9). Tompkins County's mean by hand ----
  x <- tab$value; w <- tab$coverage_fraction
  sum(w * x) / sum(w)                             # value times fraction, over the sum of fractions
  ny$t17[ny$GEOID == "36109"]                     # extract()'s answer for Tompkins County
  mean(x)                                         # every cell counted as whole

# 10). Exercise 2: Tompkins County's mean on each of the 31 days ----
  Mny  <- values(tny)                             # 20,710 cells by 31 days
  dim(Mny)
  sum(w * Mny[tab$cell, 17]) / sum(w)             # one day: 17 July is column 17
  tk31 <- numeric(31); names(tk31) <- names(tny)
  for (d in 1:31) tk31[d] <- sum(w * Mny[tab$cell, d]) / sum(w)   # the same line, once per day
  round(tk31[16:19], 2)
  data.frame(hottest = names(which.max(tk31)), degrees = round(max(tk31), 1),
             days_above_30 = sum(tk31 > 30))

# 11). The 31 daily means as a matrix product ----
  Mny <- values(tny)                              # 20,710 cells by 31 days
  w1  <- matrix(w / sum(w), nrow = 1)             # the weights as one row that sums to 1
  dim(w1); dim(Mny[tab$cell, ])
  out <- w1 %*% Mny[tab$cell, ]                   # (1 by 107) times (107 by 31) gives 1 by 31
  round(out[1, 16:19], 2)

# 12). The weight matrix P ----
  low  <- co[!(co$STUSPS %in% c("AK", "HI", "PR", "GU", "VI", "AS", "MP")), ]    # lower 48 and DC
  info <- exact_extract(tmax[[1]], low, include_cell = TRUE, progress = FALSE)   # a table per county
  tabN <- data.frame(county = rep(1:nrow(low), sapply(info, nrow)),
                     do.call(rbind, info))        # stack the 3,109 tables into one
  tabN <- tabN[!is.na(tabN$value), ]              # cells over water hold no temperature
  tabN$w <- tabN$coverage_fraction / ave(tabN$coverage_fraction, tabN$county, FUN = sum)
  c(counties = length(unique(tabN$county)), rows = nrow(tabN))
  range(tapply(tabN$w, tabN$county, sum))         # each county's weights sum to 1

# 13). The national table, counted ----
  c(all_rows = sum(sapply(info, nrow)), kept = nrow(tabN),
    dropped = sum(sapply(info, nrow)) - nrow(tabN))
  sum(table(tabN$cell) > 1)                       # cells with a weight in more than one county
  which(low$GEOID == "36109")                     # Tompkins County's row

# 14). Sparse matrices ----
  sparseMatrix(i = c(1, 1, 1, 2, 2), j = c(1, 2, 3, 3, 4), x = c(1, 1, 0.35, 0.65, 1), dims = c(2, 4))
  P <- sparseMatrix(i = tabN$county, j = tabN$cell, x = tabN$w, dims = c(nrow(low), ncell(tmax)))
  c(rows = nrow(P), columns = ncol(P), not_zero = nnzero(P))
  round(c(sparse_MB = as.numeric(object.size(P)) / 1e6, ordinary_GB = prod(dim(P)) * 8 / 1e9), 1)

# 15). Every county's mean on every day ----
  M <- values(tmax)                               # 872,505 cells by 31 days
  system.time(cd <- P %*% M)                      # counties by days
  round(cd[low$GEOID == "36109", 16:19], 2)       # Tompkins County
  ee <- exact_extract(tmax, low, "mean", progress = FALSE)    # the packaged function, all 31 days
  max(abs(as.matrix(cd) - as.matrix(ee)))         # the largest difference between the two, degrees C

# 16). Every county's mean on 18 July, on a map ----
  low$t18 <- as.vector(cd[, "2012-07-18"])
  plot(low["t18"], main = "", border = NA)

# 17). Population weights in P ----
  popg <- project(rast("data_clean/pop_2010.tif"), tmax, method = "sum")  # people in each cell
  tabN$wp <- tabN$coverage_fraction * values(popg)[tabN$cell]             # people in the part inside
  tabN$wp <- tabN$wp / ave(tabN$wp, tabN$county, FUN = sum)               # sum to 1 in each county
  Pp  <- sparseMatrix(i = tabN$county, j = tabN$cell, x = tabN$wp, dims = dim(P))
  cdp <- Pp %*% M
  k <- match(c("36109", "06053"), low$GEOID)      # Tompkins, New York and Monterey, California
  data.frame(county = low$NAME[k], by_area = round(rowMeans(cd[k, ]), 1),
             by_people = round(rowMeans(cdp[k, ]), 1))        # July means, degrees C

# 18). People before and after the move ----
  pop0 <- rast("data_clean/pop_2010.tif")
  round(c(before = global(pop0, "sum", na.rm = TRUE)[1, 1],
          after = global(popg, "sum", na.rm = TRUE)[1, 1]) / 1e6, 1)       # millions of people
  sum(is.na(as.matrix(cdp)))                                               # counties with no value

# the end ----
