# AEM 6850, session 26. Searches the Earth Search catalog for Sentinel-2 images of Cayuga Lake and downloads our image
# of 15 August 2024 (five bands and ESA's class for each cell, 20 m) and the cloudy true-colour image of 30 August 2024.
# Run in the 26-satellite-local folder (open 26-satellite-local.Rproj first):
#   source("tools/fetch_sentinel2.R")
# Needs the network, no account. About 30 seconds. A file already on disk is never fetched again.
# Source: Earth Search by Element 84, https://earth-search.aws.element84.com/v1, collection sentinel-2-l2a
#   (Sentinel-2 Level-2A, surface reflectance, cloud-optimised GeoTIFFs on Amazon, bucket sentinel-cogs).
#   Licence: the Copernicus Sentinel data legal notice. Credit: "Contains modified Copernicus Sentinel data (2024)".
#   The stored numbers are reflectance times 10,000. These items say earthsearch:boa_offset_applied = true: the
#   -1,000 offset of ESA's processing baseline 04.00 is already applied, so reflectance is the number / 10,000.
#   (The band metadata also lists offset -0.1; Element 84 says the flag is the one to follow.)
# Reads: nothing.
# Writes: data_clean/catalog/s2_search_20240810_20240820.csv (id, tile, date, cloud: every image over the box,
#           10 to 20 August 2024; cloud is the tile's share in percent, one decimal),
#         data_clean/catalog/s2_passes_2024_18TUN.csv (id, date, cloud: one row per date of 2024 on tile 18TUN),
#         data/sentinel2/s2_20240815_cayuga_20m.tif (B02, B03, B04, B8A, B11, SCL; UTM zone 18N, 20 m; the 10 m
#           bands averaged 2 x 2),
#         data/sentinel2/s2_tci_20240830_cayuga.tif (true colour, 8-bit, 10 m).

# 1). Preliminary ----
  # Clean up workspace and load or install necessary packages if necessary
  rm(list = ls())
  want <- c("terra", "rstac")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only = TRUE))
  rm(want, need)
  terraOptions(progress = 0, memmax = 2)
  setGDALconfig("GDAL_HTTP_USERAGENT", "aem6850-course-data-script")
  misc <- list()
  misc$stac   <- "https://earth-search.aws.element84.com/v1"
  misc$bbox   <- c(-76.80, 42.43, -76.45, 42.95)       # longitude and latitude; the file snaps out to 20 m cells
  misc$keys   <- c(B02 = "blue", B03 = "green", B04 = "red", B8A = "nir08", B11 = "swir16", SCL = "scl")
  misc$id15   <- "S2B_18TUN_20240815_0_L2A"
  misc$id30   <- "S2A_18TUN_20240830_0_L2A"
  misc$search <- "data_clean/catalog/s2_search_20240810_20240820.csv"
  misc$passes <- "data_clean/catalog/s2_passes_2024_18TUN.csv"
  misc$out15  <- "data/sentinel2/s2_20240815_cayuga_20m.tif"
  misc$out30  <- "data/sentinel2/s2_tci_20240830_cayuga.tif"
  dir.create("data/sentinel2", recursive = TRUE, showWarnings = FALSE)
  dir.create("data_clean/catalog", recursive = TRUE, showWarnings = FALSE)
  box <- vect(ext(misc$bbox[c(1, 3, 2, 4)]), crs = "EPSG:4326")
  search <- function(dt) stac(misc$stac) |>
    stac_search(collections = "sentinel-2-l2a", bbox = misc$bbox, datetime = dt, limit = 100) |>
    get_request() |> items_fetch(progress = FALSE)
  as_table <- function(s) data.frame(
    id    = sapply(s$features, function(f) f$id),
    tile  = sapply(s$features, function(f) paste0(f$properties$`mgrs:utm_zone`, f$properties$`mgrs:latitude_band`,
                                                  f$properties$`mgrs:grid_square`)),
    date  = sapply(s$features, function(f) substr(f$properties$datetime, 1, 10)),
    cloud = sapply(s$features, function(f) f$properties$`eo:cloud_cover`))

# 2). The search for 10 to 20 August 2024 ----
  s <- search("2024-08-10T00:00:00Z/2024-08-20T23:59:59Z")
  tab <- as_table(s)
  tab <- tab[order(tab$date, tab$id), ]
  tab$cloud <- round(tab$cloud, 1)
  write.csv(tab, misc$search, row.names = FALSE)
  print(tab, row.names = FALSE)

# 3). Every date of 2024 on tile 18TUN ----
  if (!file.exists(misc$passes)) {
    ps <- as_table(search("2024-01-01T00:00:00Z/2024-12-31T23:59:59Z"))
    ps <- ps[ps$tile == "18TUN", ]
    ps <- ps[order(ps$date, ps$id), ]
    ps <- ps[!duplicated(ps$date), c("id", "date", "cloud")]  # one image per date (27 August has two processings)
    write.csv(ps, misc$passes, row.names = FALSE)
  }
  cat("dates in 2024:", nrow(read.csv(misc$passes)), "\n")

# 4). Our image: five bands and SCL on 15 August 2024, 20 m ----
  if (!file.exists(misc$out15)) {
    it  <- s$features[[which(tab$id == misc$id15)]]
    b20 <- project(box, "EPSG:32618")
    lay <- lapply(misc$keys, function(k) {
      r <- crop(rast(paste0("/vsicurl/", it$assets[[k]]$href)), b20, snap = "out")
      if (res(r)[1] == 10) r <- aggregate(r, 2, fun = "mean")   # 10 m bands averaged to 20 m
      r
    })
    lay <- lapply(lay, function(r) if (compareGeom(r, lay$B11, stopOnError = FALSE)) r else resample(r, lay$B11, "near"))
    s2 <- rast(lay); names(s2) <- names(misc$keys)
    writeRaster(s2, misc$out15, datatype = "INT2U", gdal = "COMPRESS=DEFLATE", overwrite = TRUE)
  }
  rast(misc$out15)

# 5). The cloudy day: true colour on 30 August 2024 ----
  if (!file.exists(misc$out30)) {
    it  <- (stac(misc$stac) |> stac_search(collections = "sentinel-2-l2a", ids = misc$id30) |> get_request())$features[[1]]
    tci <- rast(paste0("/vsicurl/", it$assets$visual$href))
    tci <- crop(tci, project(box, crs(tci)), snap = "out")
    writeRaster(tci, misc$out30, datatype = "INT1U", gdal = "COMPRESS=DEFLATE", overwrite = TRUE)
  }
  rast(misc$out30)

# the end ----
