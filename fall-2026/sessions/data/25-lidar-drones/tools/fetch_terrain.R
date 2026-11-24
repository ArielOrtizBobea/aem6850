# AEM 6850, session 25. Downloads the raw terrain and drone files in data/, as fetched on 2026-11-23.
# Run once, in the 25-lidar-drones folder:
#   source("tools/fetch_terrain.R")
# Needs the network; about 72 MB in all. A file already on disk is never fetched again.
# The LiDAR point cloud is fetched by its own script, not this one.
# Reads: nothing. Writes: data/usgs_dem/, data/census/, data/drone/, data/usgs_gauge/.

# 1). Preliminary ----
  options(timeout = 900, HTTPUserAgent = "aem6850-course-data-script")
  for (d in c("data/usgs_dem", "data/census", "data/drone", "data/usgs_gauge"))
    dir.create(d, recursive = TRUE, showWarnings = FALSE)
  get <- function(url, file) if (!file.exists(file)) download.file(url, file, method = "curl", extra = "-sSfL", quiet = TRUE)

# 2). USGS 3DEP: 1 arc-second elevation (about 30 m), the tile from 42 to 43 N and 76 to 77 W ----
  get("https://prd-tnm.s3.amazonaws.com/StagedProducts/Elevation/1/TIFF/current/n43w077/USGS_1_n43w077.tif",
      "data/usgs_dem/USGS_1_n43w077.tif")

# 3). Census Bureau TIGER 2024: town borders in New York, roads in Caldwell County NC ----
  get("https://www2.census.gov/geo/tiger/TIGER2024/COUSUB/tl_2024_36_cousub.zip", "data/census/tl_2024_36_cousub.zip")
  get("https://www2.census.gov/geo/tiger/TIGER2024/ROADS/tl_2024_37027_roads.zip", "data/census/tl_2024_37027_roads.zip")

# 4). OpenAerialMap: "Willis Corn Trial" drone mosaic, NC State Extension, CC BY 4.0, and its record ----
  get("https://oin-hotosm-temp.s3.us-east-1.amazonaws.com/673502355604c600010b4336/0/673502355604c600010b4337.tif",
      "data/drone/willis_corn_trial.tif")
  get("https://api.openaerialmap.org/meta?title=Willis%20Corn%20Trial", "data/drone/willis_corn_trial_meta.json")

# 5). USGS Water Services: the site record of gauge 04234000, Fall Creek near Ithaca NY ----
  get("https://waterservices.usgs.gov/nwis/site/?format=rdb&sites=04234000&siteOutput=expanded",
      "data/usgs_gauge/site_04234000.rdb")

# the end ----
