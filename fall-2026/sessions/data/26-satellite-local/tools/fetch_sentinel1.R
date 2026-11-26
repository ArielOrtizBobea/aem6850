# AEM 6850, session 26. Downloads the Sentinel-1 radar image of 1 September 2024 over our image's box.
# Run in the 26-satellite-local folder (open 26-satellite-local.Rproj first):
#   source("tools/fetch_sentinel1.R")
# Needs the network. About 1 minute. A file already on disk is never fetched again.
# Source: Microsoft Planetary Computer, collection sentinel-1-rtc (radiometrically terrain-corrected Sentinel-1,
#   VV polarisation, 10 m, linear power), orbit 106, two frames of 1 September 2024 (S1A).
#   https://planetarycomputer.microsoft.com/dataset/sentinel-1-rtc . Licence CC BY 4.0 (Catalyst, Microsoft).
#   Caveat: the collection's catalog record says "msft:requires_account": true. The search and the anonymous
#   signing below (https://planetarycomputer.microsoft.com/api/sas/v1/sign) worked without an account on 2026-11-23
#   and 2026-11-24. The fallback with no account flag is the collection sentinel-1-grd (20 August 2024).
#   Contains modified Copernicus Sentinel data (2024).
# Reads: data/sentinel2/s2_20240815_cayuga_20m.tif (the box and its 20 m cells).
# Writes: data/sentinel1/s1_vv_db_20240901_cayuga_20m.tif: VV backscatter in decibels times 10, as whole numbers
#   (divide by 10 for dB), on the 20 m cells of the Sentinel-2 image. The 10 m frames are averaged to 20 m in linear
#   power before the conversion to decibels.

# 1). Preliminary ----
  # Clean up workspace and load or install necessary packages if necessary
  rm(list = ls())
  want <- c("terra", "rstac", "httr2")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only = TRUE))
  rm(want, need)
  terraOptions(progress = 0, memmax = 2)
  setGDALconfig("GDAL_HTTP_USERAGENT", "aem6850-course-data-script")
  misc <- list()
  misc$stac  <- "https://planetarycomputer.microsoft.com/api/stac/v1"
  misc$sign  <- "https://planetarycomputer.microsoft.com/api/sas/v1/sign"
  misc$day   <- "2024-09-01T00:00:00Z/2024-09-01T23:59:59Z"
  misc$s2    <- "data/sentinel2/s2_20240815_cayuga_20m.tif"
  misc$out   <- "data/sentinel1/s1_vv_db_20240901_cayuga_20m.tif"
  dir.create(dirname(misc$out), recursive = TRUE, showWarnings = FALSE)

# 2). Search, sign and read the two frames ----
  if (!file.exists(misc$out)) {
    s2  <- rast(misc$s2)[[1]]
    box <- project(as.polygons(ext(s2), crs = crs(s2)), "EPSG:4326")
    it <- stac(misc$stac) |>
      stac_search(collections = "sentinel-1-rtc", bbox = as.vector(ext(box))[c(1, 3, 2, 4)],
                  datetime = misc$day) |>
      post_request()
    sign <- function(h) (request(misc$sign) |> req_url_query(href = h) |>
                           req_user_agent("aem6850-course-data-script") |> req_perform() |> resp_body_json())$href
    pieces <- lapply(it$features, function(f) {
      cat(f$id, "\n")
      r <- rast(paste0("/vsicurl/", sign(f$assets$vv$href)))
      crop(r, ext(s2) + 40, snap = "out")                    # both frames are on UTM zone 18N, 10 m
    })
    vv <- if (length(pieces) > 1) do.call(mosaic, c(pieces, fun = "mean")) else pieces[[1]]
    vv <- classify(vv, cbind(0, NA))                         # 0 is no data

# 3). 20 m cells, decibels times 10 ----
    vv20 <- resample(vv, s2, method = "average")              # mean linear power of the 10 m cells in each 20 m cell
    db10 <- round(100 * log10(vv20))                          # 10 * log10 is decibels; times 10 again keeps one decimal
    names(db10) <- "VV_dB_x10"
    writeRaster(db10, misc$out, datatype = "INT2S", gdal = "COMPRESS=DEFLATE", overwrite = TRUE)
  }
  db10 <- rast(misc$out)
  db10
  cat("file MB:", round(file.size(misc$out) / 1e6, 1), "\n")
  print(global(db10 / 10, quantile, probs = c(0.02, 0.5, 0.98), na.rm = TRUE))

# the end ----
