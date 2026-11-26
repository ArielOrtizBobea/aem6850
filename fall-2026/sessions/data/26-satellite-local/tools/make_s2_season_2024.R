# AEM 6850, session 26. Every Sentinel-2 pass of 2024 over our image: how much of the box each pass covers and how much
# of it is clear, and the median NDVI of cropland and forest near Aurora on each clear pass.
# Run in the 26-satellite-local folder (open 26-satellite-local.Rproj first):
#   source("tools/make_s2_season_2024.R")
# Needs the network, no account. About 10 minutes: for each of the 146 dates it reads ESA's class for each cell (SCL)
#   over the box, and red (B04) and narrow near-infrared (B8A) over a small window, with range reads of the
#   cloud-optimised files on Amazon (Earth Search, collection sentinel-2-l2a, tile 18TUN).
# Reads: data_clean/catalog/s2_passes_2024_18TUN.csv (the 146 dates; tools/fetch_sentinel2.R writes it),
#        data/sentinel2/s2_20240815_cayuga_20m.tif (the box and its 20 m cells),
#        data/worldcover/worldcover2021_cayuga.tif (cropland 40 and tree cover 10).
# Writes: data_clean/catalog/s2_box_clear_2024.csv (one row per date: share of the box covered, share of covered
#           cells that SCL calls clear),
#         data_clean/ndvi/ndvi_season_2024.csv (one row per clear date and class: cells, median NDVI, share clear),
#         logs/make_s2_season_2024.txt.
# Clear means SCL is not 0 (no data), 1 (saturated or defective), 3 (cloud shadow), 8 or 9 (cloud) or 10 (thin cirrus).

# 1). Preliminary ----
  # Clean up workspace and load or install necessary packages if necessary
  rm(list = ls())
  want <- c("terra", "rstac")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only = TRUE))
  rm(want, need)
  options(width = 100, HTTPUserAgent = "aem6850-course-data-script")
  terraOptions(progress = 0, memmax = 2)
  setGDALconfig("GDAL_HTTP_USERAGENT", "aem6850-course-data-script")
  setGDALconfig("GDAL_DISABLE_READDIR_ON_OPEN", "EMPTY_DIR")
  misc <- list()
  misc$passes  <- "data_clean/catalog/s2_passes_2024_18TUN.csv"
  misc$s2      <- "data/sentinel2/s2_20240815_cayuga_20m.tif"
  misc$wc      <- "data/worldcover/worldcover2021_cayuga.tif"
  misc$stac    <- "https://earth-search.aws.element84.com/v1"
  misc$window  <- c(xmin = -76.690, xmax = -76.630, ymin = 42.720, ymax = 42.780)   # farmland east of the lake, Aurora to Poplar Ridge
  misc$cloud   <- c(0, 1, 3, 8, 9, 10)                                            # SCL classes that are not clear
  misc$min_clear <- 0.5                                                            # a date enters the NDVI file when half its window cells are clear
  misc$out_box  <- "data_clean/catalog/s2_box_clear_2024.csv"
  misc$out_ndvi <- "data_clean/ndvi/ndvi_season_2024.csv"
  misc$log      <- "logs/make_s2_season_2024.txt"
  dir.create("logs", showWarnings = FALSE); dir.create("data_clean/ndvi", showWarnings = FALSE)
  sink(misc$log, split = TRUE)

# 2). The dates, and each one's files ----
  ps <- read.csv(misc$passes)
  it <- stac(misc$stac) |>
    stac_search(collections = "sentinel-2-l2a", ids = ps$id, limit = 200) |>
    post_request() |> items_fetch(progress = FALSE)
  href <- setNames(lapply(it$features, function(f) f$assets), sapply(it$features, function(f) f$id))
  cat("dates:", nrow(ps), " items found:", length(href), "\n")

# 3). The box, the window and ESA's classes on the window's 20 m cells ----
  s2  <- rast(misc$s2)
  box <- ext(s2)                                            # UTM zone 18N, metres
  win <- ext(project(vect(ext(misc$window), crs = "EPSG:4326"), crs(s2)))
  win <- align(win, s2[[1]], snap = "out")
  wc  <- project(rast(misc$wc), crop(s2[[1]], win), method = "mode")
  cat("window, UTM 18N:", as.vector(win), " cells:", ncell(wc), "\n")
  print(freq(wc))

# 4). Each date: the box's cover and clear share, and NDVI in the window ----
  rd <- function(a, e) crop(rast(paste0("/vsicurl/", a$href)), e, snap = "out")
  box_rows <- list(); ndvi_rows <- list()
  t0 <- Sys.time()
  for (i in seq_len(nrow(ps))) {
    a   <- href[[ps$id[i]]]
    scl <- rd(a$scl, box)
    v   <- values(scl, mat = FALSE)
    cov <- !is.na(v) & v != 0
    clr <- cov & !(v %in% misc$cloud)
    box_rows[[i]] <- data.frame(id = ps$id[i], date = ps$date[i], cloud_tile = round(ps$cloud[i], 1),
                                share_box_covered = round(mean(cov), 4),
                                share_clear = round(ifelse(any(cov), sum(clr) / sum(cov), NA), 4))
    sw  <- crop(scl, win)
    okw <- !(values(sw, mat = FALSE) %in% misc$cloud) & !is.na(values(sw, mat = FALSE))
    if (mean(okw) >= misc$min_clear) {
      red <- aggregate(rd(a$red, win), 2, fun = "mean")     # 10 m to 20 m, as in the shipped image
      nir <- rd(a$nir08, win)
      red <- resample(red, sw, method = "near"); nir <- resample(nir, sw, method = "near")
      nd  <- values((nir - red) / (nir + red), mat = FALSE)
      for (k in c(40, 10)) {
        cl <- values(wc, mat = FALSE) == k
        ndvi_rows[[length(ndvi_rows) + 1]] <- data.frame(
          date = ps$date[i], class = ifelse(k == 40, "cropland", "forest"),
          n_cells = sum(cl & okw, na.rm = TRUE),
          median_ndvi = round(median(nd[cl & okw], na.rm = TRUE), 4),
          share_clear = round(sum(cl & okw, na.rm = TRUE) / sum(cl, na.rm = TRUE), 4))
      }
    }
    cat(sprintf("%3d %s covered %5.1f%%  clear %5.1f%%  window clear %5.1f%%  %4.0f s\n", i, ps$date[i],
                100 * mean(cov), 100 * box_rows[[i]]$share_clear, 100 * mean(okw),
                as.numeric(Sys.time() - t0, units = "secs")))
  }
  bx <- do.call(rbind, box_rows); nv <- do.call(rbind, ndvi_rows)
  write.csv(bx, misc$out_box, row.names = FALSE)
  write.csv(nv, misc$out_ndvi, row.names = FALSE)

# 5). Counts for the slides ----
  bx$date <- as.Date(bx$date)
  good <- bx[bx$share_box_covered >= 0.9 & bx$share_clear > 0.9, ]
  cat("\ndates:", nrow(bx), " covering 90% of the box or more:", sum(bx$share_box_covered >= 0.9),
      " of those under 10% cloud:", nrow(good), "\n")
  print(table(month = factor(format(bx$date, "%m"), levels = sprintf("%02d", 1:12)),
              clear = bx$share_box_covered >= 0.9 & bx$share_clear > 0.9))
  g <- diff(c(as.Date("2024-01-01"), good$date, as.Date("2024-12-31")))
  k <- which.max(g)
  cat("longest run with no clear image:", max(g), "days, after", format(c(as.Date("2024-01-01"), good$date)[k]),
      "\n")
  print(good, row.names = FALSE)
  print(nv, row.names = FALSE)
  sink()

# the end ----
