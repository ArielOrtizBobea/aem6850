# AEM 6850, session 25. Downloads the radar-made elevation tile over Ithaca in data/copernicus/, as fetched on 2026-11-23.
# Run once, in the 25-radar-lidar folder:
#   source("tools/fetch_radar.R")
# Needs the network; about 44 MB in all. A file already on disk is never fetched again.
# The tile is the Copernicus DEM GLO-30 (made from the TanDEM-X radar satellites), 42 to 43 N and 77 to 76 W,
#   from the public copy on Amazon (no account): https://registry.opendata.aws/copernicus-dem/
# Reads: nothing. Writes: data/copernicus/.

# 1). Preliminary ----
  options(timeout = 900, HTTPUserAgent = "aem6850-course-data-script")
  dir.create("data/copernicus", recursive = TRUE, showWarnings = FALSE)
  get <- function(url, file) if (!file.exists(file)) download.file(url, file, method = "curl", extra = "-sSfL", quiet = TRUE)
  misc <- list(bucket = "https://copernicus-dem-30m.s3.amazonaws.com",
               tile   = "Copernicus_DSM_COG_10_N42_00_W077_00_DEM",
               stem   = "Copernicus_DSM_10_N42_00_W077_00")

# 2). The elevation tile itself (42.8 MB) ----
  get(sprintf("%s/%s/%s.tif", misc$bucket, misc$tile, misc$tile), file.path("data/copernicus", paste0(misc$tile, ".tif")))

# 3). The tile's small companions listed in the bucket ----
  # the tile's metadata (ISO 19115 XML), the licence (EULA), the bucket's readme,
  # and the water body mask (WBM: 1 ocean, 2 lake, 3 river), used to find Cayuga Lake.
  # The height error map (HEM, 50 MB) is left out.
  get(sprintf("%s/%s/%s.xml", misc$bucket, misc$tile, misc$stem), file.path("data/copernicus", paste0(misc$stem, ".xml")))
  get(sprintf("%s/%s/INFO/eula_F.pdf", misc$bucket, misc$tile), "data/copernicus/eula_F.pdf")
  get(sprintf("%s/readme.html", misc$bucket), "data/copernicus/readme.html")
  get(sprintf("%s/%s/AUXFILES/%s.tif", misc$bucket, misc$tile, sub("_DEM$", "_WBM", misc$tile)),
      file.path("data/copernicus", paste0(sub("_DEM$", "_WBM", misc$tile), ".tif")))

# the end ----
