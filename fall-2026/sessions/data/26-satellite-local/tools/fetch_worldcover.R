# AEM 6850, session 26. Downloads ESA WorldCover 2021 around Cayuga Lake.
# Run in the 26-satellite-local folder (open 26-satellite-local.Rproj first):
#   source("tools/fetch_worldcover.R")
# Needs the network, no account. A few seconds. A file already on disk is never fetched again.
# Source: ESA WorldCover 10 m 2021 v200, tile N42W078, the public copy on Amazon:
#   https://esa-worldcover.s3.eu-central-1.amazonaws.com/v200/2021/map/ESA_WorldCover_10m_2021_v200_N42W078_Map.tif
#   Licence CC BY 4.0. Credit: "© ESA WorldCover project 2021 / Contains modified Copernicus Sentinel data (2021)
#   processed by ESA WorldCover consortium". Citation: Zanaga et al. (2022), https://doi.org/10.5281/zenodo.7254221
# Classes: 10 tree cover, 20 shrubland, 30 grassland, 40 cropland, 50 built-up, 60 bare or sparse vegetation,
#   70 snow and ice, 80 permanent water, 90 herbaceous wetland, 95 mangroves, 100 moss and lichen.
# Reads: nothing.
# Writes: data/worldcover/worldcover2021_cayuga.tif: longitude -76.80 to -76.44, latitude 42.40 to 42.97, in the
#   tile's own cells (1/12,000 degree, about 10 m). It reaches a little past our image on every side but the east,
#   so the Ithaca box of the sprawl task fits.
#   With misc$wide = TRUE it also writes data/worldcover/worldcover2021_cayuga_wide.tif (latitude 42.40 to 43.05),
#   which holds the whole of Cayuga Lake; not shipped (see _planning/session26_prep_results.md, item 1).

# 1). Preliminary ----
  # Clean up workspace and load or install necessary packages if necessary
  rm(list = ls())
  want <- c("terra")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only = TRUE))
  rm(want, need)
  terraOptions(progress = 0, memmax = 2)
  setGDALconfig("GDAL_HTTP_USERAGENT", "aem6850-course-data-script")
  misc <- list()
  misc$url  <- "/vsicurl/https://esa-worldcover.s3.eu-central-1.amazonaws.com/v200/2021/map/ESA_WorldCover_10m_2021_v200_N42W078_Map.tif"
  misc$ext  <- c(-76.80, -76.44, 42.40, 42.97)
  misc$out  <- "data/worldcover/worldcover2021_cayuga.tif"
  misc$wide <- FALSE
  misc$ext_wide <- c(-76.80, -76.44, 42.40, 43.05)
  misc$out_wide <- "data/worldcover/worldcover2021_cayuga_wide.tif"
  dir.create("data/worldcover", recursive = TRUE, showWarnings = FALSE)

# 2). The crop ----
  if (!file.exists(misc$out)) {
    wc <- crop(rast(misc$url), ext(misc$ext))
    writeRaster(wc, misc$out, datatype = "INT1U", gdal = "COMPRESS=DEFLATE", overwrite = TRUE)
  }
  if (misc$wide && !file.exists(misc$out_wide)) {
    wc <- crop(rast(misc$url), ext(misc$ext_wide))
    writeRaster(wc, misc$out_wide, datatype = "INT1U", gdal = "COMPRESS=DEFLATE", overwrite = TRUE)
  }
  wc <- rast(misc$out)
  wc
  freq(wc)

# the end ----
