# AEM 6850, session 25. Downloads two NOAA MRMS radar grids for the radar day 12 June 2022 and crops them to the
#   seven Plains states of the instructor's hail pilot, so the slides can show the radar data itself.
# Run once, in the 25-radar-lidar folder:
#   source("tools/fetch_mrms.R")
# Needs the network; about 3 MB kept, plus about 20 MB of reflectivity snapshots read once to pick the hour.
# A file already on disk is never fetched again.
# Source: NOAA's Multi-Radar Multi-Sensor (MRMS) grids, public bucket on Amazon (no account):
#   https://noaa-mrms-pds.s3.amazonaws.com/ (registry: https://registry.opendata.aws/noaa-mrms-pds/)
#   1. MESH_Max_1440min: the largest hail size estimated in each 0.01 degree cell over the previous 24 hours, mm.
#      The file stamped 12:00 UTC on 13 June covers the radar day, 12:00 UTC 12 June to 12:00 UTC 13 June,
#      the same file the pilot (tools/hail_pilot/mesh_pipeline.R) used.
#   2. MergedReflectivityQCComposite: the strongest radar echo above each cell at one moment, dBZ.
#      The hour is picked from the data: the snapshot nearest each full hour from 21:00 UTC 12 June to 06:00 UTC
#      13 June is read, and the one with the most km2 of 50 dBZ or more inside the seven-state box is kept.
# Reads: data_clean/hail/counties_7states.gpkg and data_clean/hail/hail_county_day.csv (for the check).
# Writes: data/mrms/ (the two raw files), data_clean/hail/mesh_20220612.tif, data_clean/hail/reflectivity_20220612.tif,
#   logs/prep_mrms.txt.

# 1). Preliminary ----
  # Clean up workspace and load or install necessary packages if necessary
  rm(list = ls())
  want <- c("terra")
  need <- want[!(want %in% installed.packages()[, "Package"])]
  if (length(need)) install.packages(need)
  invisible(lapply(want, function(i) suppressMessages(require(i, character.only = TRUE))))
  rm(want, need)

  options(timeout = 900, HTTPUserAgent = "aem6850-course-data-script")
  misc <- list(bucket = "https://noaa-mrms-pds.s3.amazonaws.com",
               raw    = "data/mrms",
               out    = "data_clean/hail",
               log    = "logs/prep_mrms.txt",
               bb     = ext(-109.1, -89.4, 36.9, 49.1))       # CO IA KS MN NE ND SD, as in the pilot
  dir.create(misc$raw, recursive = TRUE, showWarnings = FALSE)
  cat("Session 25 MRMS prep, run", format(Sys.time(), "%Y-%m-%d %H:%M %Z"), "\n", R.version.string, "\n", file = misc$log)
  say <- function(...) { s <- paste0(...); cat(s, "\n"); cat(s, "\n", file = misc$log, append = TRUE) }
  # log a value with the code line that made it
  lg  <- function(label, expr) {
    code <- paste(deparse(substitute(expr), width.cutoff = 500), collapse = " ")
    v <- expr; say(label, ": ", paste(format(v), collapse = " "), "    <- ", code); invisible(v)
  }
  # download once; TRUE if the file is on disk afterwards
  get <- function(url, file) {
    if (!file.exists(file)) try(download.file(url, file, method = "curl", extra = "-sSfL", quiet = TRUE), silent = TRUE)
    file.exists(file) && file.size(file) > 0
  }
  # read a .grib2.gz, crop to the box, set the CRS as the pilot does
  readgz <- function(gz) {
    g <- file.path(tempdir(), sub("\\.gz$", "", basename(gz)))
    system2("gunzip", c("-c", shQuote(gz)), stdout = g)
    r <- crop(rast(g), misc$bb); crs(r) <- "EPSG:4326"; r <- r * 1   # * 1 reads the values into memory
    unlink(g); r
  }
  # the keys of one product and day in the bucket (S3 list, 1,000 keys a page)
  keys <- function(prefix) {
    out <- character(); tok <- NULL
    repeat {
      u <- sprintf("%s/?list-type=2&prefix=%s%s", misc$bucket, prefix,
                   if (is.null(tok)) "" else paste0("&continuation-token=", URLencode(tok, reserved = TRUE)))
      x <- paste(readLines(u, warn = FALSE), collapse = "")
      out <- c(out, regmatches(x, gregexpr("(?<=<Key>)[^<]+", x, perl = TRUE))[[1]])
      tok <- regmatches(x, regexpr("(?<=<NextContinuationToken>)[^<]+", x, perl = TRUE))
      if (!length(tok)) break
    }
    out
  }

# 2). Hail size: MESH, largest in 24 hours, stamped 12:00 UTC 13 June 2022 ----
  for (hhmmss in c("120000", "123000", "113000", "130000")) {     # the pilot's fallback times
    f <- sprintf("MRMS_MESH_Max_1440min_00.50_20220613-%s.grib2.gz", hhmmss)
    if (get(sprintf("%s/CONUS/MESH_Max_1440min_00.50/20220613/%s", misc$bucket, f), file.path(misc$raw, f))) break
  }
  say("\n== MESH, 24-hour maximum ==")
  lg("File", f)
  lg("Size, MB", round(file.size(file.path(misc$raw, f)) / 1e6, 2))
  mesh <- readgz(file.path(misc$raw, f))
  mesh <- classify(mesh, cbind(-Inf, 0, 0), right = FALSE)        # negative values to 0, as the pilot did
  mesh[is.na(mesh)] <- 0                                           # missing to 0, as the pilot did
  names(mesh) <- "mesh_mm"
  lg("Grid, rows and columns", dim(mesh)[1:2])
  lg("Cell size, degrees", res(mesh))
  lg("Largest hail in the box, mm", round(global(mesh, "max")[[1]], 1))
  lg("Cells with hail >= 25.4 mm", global(mesh >= 25.4, "sum")[[1]])
  writeRaster(mesh, file.path(misc$out, "mesh_20220612.tif"), datatype = "FLT4S",
              gdal = c("COMPRESS=DEFLATE", "PREDICTOR=3"), overwrite = TRUE)
  lg("mesh_20220612.tif, MB", round(file.size(file.path(misc$out, "mesh_20220612.tif")) / 1e6, 2))

# 3). Reflectivity: the hour with the most strong echoes ----
  k <- c(keys("CONUS/MergedReflectivityQCComposite_00.50/20220612/"),
         keys("CONUS/MergedReflectivityQCComposite_00.50/20220613/"))
  say("\n== Composite reflectivity ==")
  lg("Snapshots in the bucket, 12 and 13 June 2022", length(k))
  tk <- as.POSIXct(sub(".*_(\\d{8}-\\d{6})\\.grib2\\.gz$", "\\1", k), format = "%Y%m%d-%H%M%S", tz = "UTC")
  hrs <- seq(as.POSIXct("2022-06-12 21:00", tz = "UTC"), as.POSIXct("2022-06-13 06:00", tz = "UTC"), by = "hour")
  pick <- sapply(hrs, function(h) which.min(abs(as.numeric(tk - h))))  # the snapshot nearest each full hour
  cand <- file.path(tempdir(), basename(k[pick]))
  a50 <- sapply(seq_along(pick), function(i) {
    if (!get(sprintf("%s/%s", misc$bucket, k[pick[i]]), cand[i])) return(NA)
    r <- readgz(cand[i]); s <- r >= 50
    global(cellSize(r, unit = "km") * s, "sum", na.rm = TRUE)[[1]]
  })
  tab <- data.frame(utc = format(tk[pick], "%d Jun %H:%M:%S"), km2_50dBZ = round(a50))
  for (i in seq_len(nrow(tab))) say("  ", tab$utc[i], " UTC: ", format(tab$km2_50dBZ[i], big.mark = ","), " km2 of 50 dBZ or more")
  lg("Chosen snapshot (most km2 of 50 dBZ or more)", basename(k[pick[which.max(a50)]]))
  best <- k[pick[which.max(a50)]]; fr <- file.path(misc$raw, basename(best))
  file.copy(cand[which.max(a50)], fr, overwrite = TRUE); unlink(cand)
  lg("Its time, UTC", format(tk[pick[which.max(a50)]], "%Y-%m-%d %H:%M:%S %Z"))
  lg("Its time, Central (CDT)", format(tk[pick[which.max(a50)]], "%Y-%m-%d %H:%M:%S %Z", tz = "America/Chicago"))
  lg("Size, MB", round(file.size(fr) / 1e6, 2))
  refl <- readgz(fr)
  refl[refl < -30] <- NA                                           # -99 and -999 mark no echo and no coverage
  names(refl) <- "dbz"
  lg("Grid, rows and columns", dim(refl)[1:2])
  lg("Strongest echo in the box, dBZ", round(global(refl, "max", na.rm = TRUE)[[1]], 1))
  lg("Share of cells with an echo that reach 10 dBZ or more, percent", round(100 * global(refl >= 10, "mean", na.rm = TRUE)[[1]], 1))
  writeRaster(round(refl * 2) / 2, file.path(misc$out, "reflectivity_20220612.tif"), datatype = "FLT4S",
              gdal = c("COMPRESS=DEFLATE", "PREDICTOR=3"), overwrite = TRUE)
  lg("reflectivity_20220612.tif, MB", round(file.size(file.path(misc$out, "reflectivity_20220612.tif")) / 1e6, 2))

# 4). Check against the pilot's county table ----
  # as tools/hail_pilot/mesh_pipeline.R: counties rasterized to the grid, cell areas in km2, summed where >= 25.4 mm
  m   <- rast(file.path(misc$out, "mesh_20220612.tif"))
  cty <- vect(file.path(misc$out, "counties_7states.gpkg")); cty$idx <- seq_len(nrow(cty))
  cid <- values(rasterize(cty, m, field = "idx"), mat = FALSE)
  are <- values(cellSize(m, unit = "km"), mat = FALSE)
  v   <- values(m, mat = FALSE)
  s   <- !is.na(cid) & v >= 25.4
  x   <- tapply(are[s], cid[s], sum); km2 <- numeric(nrow(cty)); km2[as.integer(names(x))] <- x
  hd  <- read.csv(file.path(misc$out, "hail_county_day.csv"), colClasses = c(geoid = "character"))
  d   <- hd[hd$date == "2022-06-12", ]
  pil <- d$km2_1in[match(cty$GEOID, d$geoid)]; pil[is.na(pil)] <- 0
  say("\n== Check against the pilot, radar day 12 June 2022 ==")
  lg("Counties with hail >= 1 inch, from mesh_20220612.tif", sum(km2 > 0))
  lg("Counties with hail >= 1 inch, in hail_county_day.csv", sum(pil > 0))
  lg("Counties where the two disagree on any hail", sum((km2 > 0) != (pil > 0)))
  lg("Correlation of km2 across the 567 counties", round(cor(km2, pil), 5))
  lg("Largest absolute difference, km2", round(max(abs(km2 - pil)), 2))
  lg("Largest county area here and in the pilot, km2", round(c(max(km2), max(pil)), 2))

# the end ----
