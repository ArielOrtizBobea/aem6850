# AEM 6850, session 25. Writes a copy of the drone mosaic with its black corners set to missing (NA).
# Run in the 25-radar-lidar folder (open 25-radar-lidar.Rproj first), after tools/fetch_terrain.R:
#   source("tools/make_drone_masked.R")
# Why: the mosaic as downloaded marks no missing value, so the corners outside the flight read as black pixels
#   (0 in all three layers). mask() on all 47 million pixels needs several GB of memory, too much for a student
#   laptop with Zoom open. Students read this copy instead, where the corners are already NA.
# How: a pixel that is 0 in all three layers is a corner and becomes NA. A pixel inside the flight with a 0 in one
#   or two layers (142,410 of them) gets 1 in that layer, so 0 can serve as the file's NA value. The NA pattern is
#   exactly the one mask(mo, sum(mo) == 0, maskvalues = TRUE) gives. Stored as bytes, lossless DEFLATE.
# Reads: data/drone/willis_corn_trial.tif (11.4 MB, JPEG-compressed as OpenAerialMap serves it).
# Writes: data_clean/drone/corn_trial_masked.tif (about 60 MB), logs/prep_drone_masked.txt.

# 1). Preliminary ----
  # Clean up workspace and load or install necessary packages if necessary
  rm(list = ls())
  want <- c("terra")
  need <- want[!(want %in% installed.packages()[, "Package"])]
  if (length(need)) install.packages(need)
  invisible(lapply(want, function(i) suppressMessages(require(i, character.only = TRUE))))
  rm(want, need)

  terraOptions(progress = 0)
  setGDALconfig("GDAL_PAM_ENABLED", "NO")   # layer names and statistics inside the .tif, no .aux.xml beside it
  misc <- list(raw = "data/drone/willis_corn_trial.tif",
               out = "data_clean/drone/corn_trial_masked.tif",
               log = "logs/prep_drone_masked.txt")
  dir.create("logs", showWarnings = FALSE)
  say <- function(...) { s <- paste0(...); cat(s, "\n"); cat(s, "\n", file = misc$log, append = TRUE) }
  cat("AEM 6850 session 25, the masked drone mosaic. Run on", format(Sys.time(), "%Y-%m-%d %H:%M %Z"),
      "with terra", as.character(packageVersion("terra")), "\n", file = misc$log)

# 2). The corners to NA ----
  mo     <- rast(misc$raw)
  corner <- sum(mo) == 0                                            # TRUE outside the flight
  mo1    <- ifel(mo == 0, 1, mo)                                    # a 0 inside the flight becomes 1
  mo1    <- mask(mo1, corner, maskvalues = TRUE, updatevalue = 0)   # the corners become 0, the NA value
  names(mo1) <- names(mo)
  unlink(paste0(misc$out, ".aux.xml"))
  writeRaster(mo1, misc$out, datatype = "INT1U", NAflag = 0, overwrite = TRUE,
              gdal = c("COMPRESS=DEFLATE", "PREDICTOR=2", "ZLEVEL=9", "TILED=YES"))
  rm(mo1); invisible(gc())
  m <- rast(misc$out); names(m) <- names(mo); update(m, names = TRUE)   # writeRaster() left the names out

# 3). Check the copy against mask() on the original ----
  m  <- rast(misc$out)
  say("Layer names: ", paste(names(m), collapse = ", "), "; .aux.xml beside it: ", file.exists(paste0(misc$out, ".aux.xml")))
  na <- global(is.na(m), "sum")[[1]]
  ref <- global(corner, "sum")[[1]]
  say("Wrote ", misc$out, ": ", format(file.size(misc$out), big.mark = ","), " bytes")
  say("NA pixels in each layer: ", paste(format(na, big.mark = ","), collapse = ", "),
      "; corner pixels (0 in all three layers of the original): ", format(ref, big.mark = ","),
      sprintf(" (%.1f%% of %s)", 100 * ref / ncell(mo), format(ncell(mo), big.mark = ",")))
  say("Same NA pattern in all three layers: ", all(na == ref))
  d <- global(abs(m - mo), "max", na.rm = TRUE)[[1]]
  say("Largest change inside the flight, in levels of 0 to 255: ", paste(d, collapse = ", "))

# the end ----
