# AEM 6850, session 26. Draws the candidate points for the hand labels and fetches an aerial photo (NAIP) chip for each.
# Run in the 26-satellite-local folder (open 26-satellite-local.Rproj first):
#   source("tools/make_label_chips.R")
# Needs the network. The class does not need it: data_clean/labels/labels_200.csv holds the labels the slides read.
# Source used: USGS's NAIP image service (The National Map), no account, public domain:
#   https://imagery.nationalmap.gov/arcgis/rest/services/USGSNAIPImagery/ImageServer
#   Over the Sentinel-2 box it serves only the 2019 New York flight at 0.6 m (flown 2 August and 18 September 2019).
#   Credit: "USGS, USDA, The National Map: Orthoimagery."
# How the points are drawn (section 2):
#   Every candidate is the centre of one 20 m cell of the Sentinel-2 image. ESA WorldCover 2021 is put on the same
#   cells (the most common 10 m class in each 20 m cell), and the draw takes the same number of cells from each of
#   four strata: water (80), forest (10), grass or crops (30 and 40 pooled), built (50). Cells under cloud, cloud
#   shadow or with a missing band (scene classification 3, 8, 9, 10) are left out.
#   The labels themselves are read by eye off each chip, so WorldCover only decides where to look.
#   Each candidate gets a random id that says nothing about its stratum, and the strata go in a separate file.
#   Candidates come in batches of 100 per stratum: batch 1 first, batch 2 only if a class ran short.
#   On 2026-11-24 batch 1 (400 points) gave 50+ water, forest and grass or crops but 33 built, so batch 2 was
#   fetched for the three land strata. I labelled 598 candidates in their shuffled order and kept the first
#   50 of each class. The fetch is slow (5 to 30 s per chip on a cold server): about 2 hours run sequentially.
#   Section 4 saves the kept chips as JPEG (quality 85, about 6 KB each) to keep data/naip under 2 MB.
# Reads: data/sentinel2/s2_20240815_cayuga_20m.tif, data/worldcover/worldcover2021_cayuga.tif,
#   and (section 4 only) data_clean/labels/labels_candidates.csv, the hand labels.
# Writes: <cache>/candidates.csv (id, lon, lat, x, y, batch), <cache>/strata.csv (id, stratum),
#   <cache>/png/<id>.png (one 100 m by 100 m chip per candidate) and <cache>/chips_all.csv;
#   section 4 writes data/naip/chips/<id>.jpg for the 200 kept points and data/naip/chips.csv.

# 1). Preliminary ----
  # Clean up workspace and load or install necessary packages if necessary
  want <- c("terra", "httr2", "jsonlite", "png", "jpeg")
  need <- want[!(want %in% installed.packages()[, "Package"])]
  if (length(need)) install.packages(need)
  invisible(lapply(want, function(i) suppressMessages(require(i, character.only = TRUE))))
  rm(want, need)

  # Paths: change s2, wc and cache here to run on copies kept elsewhere
  misc <- list(s2      = "data/sentinel2/s2_20240815_cayuga_20m.tif",
               wc      = "data/worldcover/worldcover2021_cayuga.tif",
               cache   = "data/naip/candidates",          # every candidate's chip; not shipped
               labels  = "data_clean/labels/labels_candidates.csv",
               out     = "data/naip/chips",
               svc     = "https://imagery.nationalmap.gov/arcgis/rest/services/USGSNAIPImagery/ImageServer",
               year    = 2019,
               n       = 100,                             # candidates per stratum per batch
               batches = 3,                               # batches drawn (fetched only as far as misc$fetch)
               fetch   = 2,                               # batches to fetch chips for (batch 2 was needed)
               skip_later = "water",                      # strata left out after batch 1 (water had its 50)
               half    = 50,                              # metres from the point to the chip's edge
               px      = 167)                             # pixels per side: 100 m / 167 = 0.6 m
  if (exists("misc_paths")) misc[names(misc_paths)] <- misc_paths   # set misc_paths <- list(...) before source() to override
  dir.create(file.path(misc$cache, "png"), recursive = TRUE, showWarnings = FALSE)

# 2). Candidates: centres of 20 m cells, stratified by WorldCover ----
  s2 <- rast(misc$s2)
  wc <- project(rast(misc$wc), s2[[1]], method = "mode")    # WorldCover on the Sentinel-2 cells, most common class
  ok <- !is.na(values(sum(s2[[1:5]]))) & !(values(s2$SCL) %in% c(3, 8, 9, 10))
  wcv <- values(wc)[, 1]
  strata <- list("water" = 80, "forest" = 10, "grass or crops" = c(30, 40), "built" = 50)

  set.seed(6850)
  cand <- do.call(rbind, lapply(names(strata), function(s) {
    cells <- which(ok & wcv %in% strata[[s]])
    pick <- sample(cells, misc$n * misc$batches)
    data.frame(cell = pick, stratum = s, batch = rep(seq_len(misc$batches), each = misc$n))
  }))
  cand <- cand[!duplicated(cand$cell), ]
  cand$id <- sprintf("p%04d", sample(1000:9999, nrow(cand)))      # random ids, unrelated to the stratum
  cand <- cand[order(cand$batch, runif(nrow(cand))), ]             # shuffled within each batch
  xy <- xyFromCell(s2, cand$cell)
  ll <- crds(project(vect(xy, crs = crs(s2)), "EPSG:4326"))
  cand <- cbind(cand, x = xy[, 1], y = xy[, 2], lon = round(ll[, 1], 6), lat = round(ll[, 2], 6))
  write.csv(cand[, c("id", "lon", "lat", "x", "y", "batch")], file.path(misc$cache, "candidates.csv"), row.names = FALSE)
  write.csv(cand[, c("id", "stratum")], file.path(misc$cache, "strata.csv"), row.names = FALSE)

# 3). Chips: 100 m by 100 m of the 2019 photo around each candidate ----
  rule <- toJSON(list(mosaicMethod = "esriMosaicAttribute", sortField = "Year", sortValue = as.character(misc$year),
                      where = sprintf("Category = 1 AND Year = %d", misc$year)), auto_unbox = TRUE)
  ask <- function(path) request(paste0(misc$svc, path)) |> req_user_agent("course-script (R httr2)") |>
    req_retry(max_tries = 6, backoff = function(i) 10 * i, is_transient = function(r) resp_status(r) >= 500) |>
    req_timeout(120)
  todo <- cand[cand$batch <= misc$fetch & !(cand$batch > 1 & cand$stratum %in% misc$skip_later), ]
  log_file <- file.path(misc$cache, "chips_all.csv")
  done <- if (file.exists(log_file)) read.csv(log_file) else NULL
  for (i in seq_len(nrow(todo))) {
    p <- todo[i, ]
    f <- file.path(misc$cache, "png", paste0(p$id, ".png"))
    if (file.exists(f) && !is.null(done) && p$id %in% done$id) next
    b <- c(xmin = p$x - misc$half, ymin = p$y - misc$half, xmax = p$x + misc$half, ymax = p$y + misc$half)
    ask("/exportImage") |>
      req_url_query(bbox = paste(b, collapse = ","), bboxSR = 32618, imageSR = 32618,
                    size = paste(misc$px, misc$px, sep = ","), format = "png24", f = "image",
                    interpolation = "RSP_BilinearInterpolation", mosaicRule = rule) |>
      req_perform(path = f)
    # which photo tile lies under the point, and the day it was flown
    q <- ask("/query") |>
      req_url_query(where = sprintf("Category = 1 AND Year = %d", misc$year),
                    geometry = sprintf("%f,%f", p$x, p$y), geometryType = "esriGeometryPoint", inSR = 32618,
                    spatialRel = "esriSpatialRelIntersects", outFields = "Name,Year,acquisition_date",
                    returnGeometry = "false", f = "json") |>
      req_perform() |> resp_body_json()
    a <- if (length(q$features)) q$features[[1]]$attributes else list(Name = NA, Year = NA, acquisition_date = NA)
    row <- data.frame(id = p$id, xmin = b[["xmin"]], xmax = b[["xmax"]], ymin = b[["ymin"]], ymax = b[["ymax"]],
                      crs = "EPSG:32618", naip_year = a$Year, naip_tile = a$Name,
                      acquired = if (is.null(a$acquisition_date) || is.na(a$acquisition_date)) NA else
                        format(as.POSIXct(a$acquisition_date / 1000, origin = "1970-01-01", tz = "UTC"), "%Y-%m-%d"))
    done <- rbind(done, row)
    write.csv(done, log_file, row.names = FALSE)
    Sys.sleep(0.5)                                                  # a short pause between requests
  }

# 4). The 200 kept points: their chips as JPEG (quality 85) and their extents ----
  if (file.exists(misc$labels)) {
    lab <- read.csv(misc$labels)
    keep <- lab$id[lab$kept]
    dir.create(misc$out, recursive = TRUE, showWarnings = FALSE)
    for (k in keep) {
      im <- readPNG(file.path(misc$cache, "png", paste0(k, ".png")))[, , 1:3]
      writeJPEG(im, file.path(misc$out, paste0(k, ".jpg")), quality = 0.85)
    }
    chips <- read.csv(log_file)
    write.csv(chips[match(keep, chips$id), ], "data/naip/chips.csv", row.names = FALSE)
  }
