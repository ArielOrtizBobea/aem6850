# AEM 6850, session 24. Downloads every raw file in data/, as it was fetched on 2026-11-17.
# Run once, in the 24-spatial-rasters folder (open 24-spatial-rasters.Rproj first):
#   source("tools/fetch_data.R")
# Needs the network; about 400 MB in all. The class does not need it: data_clean/ holds what the slides read.
# The corn yields need a free key from USDA's Quick Stats, saved as NASS_API_KEY in ~/.Renviron.
# Reads: nothing. Writes: data/prism/, data/census/, data/glad/, data/nass/, data/era5/, data/nasa/.
# data/sedac/ is not downloaded here: the population grid needs a free NASA Earthdata login (see README.md).

# 1). Preliminary ----
  options(timeout = 900, HTTPUserAgent = "aem6850-course-data-script")
  misc <- list(days_prism = format(seq(as.Date("2012-07-01"), as.Date("2012-07-31"), by = "day"), "%Y%m%d"),
               days_era5  = c("2012/07/17", "2025/01/08", "2025/01/09"),   # one July day for New York, two days of the Eaton fire
               box_la     = "33.2,-119.6,34.8,-117.2")                      # Worldview's box order: south, west, north, east
  for (d in c("data/prism", "data/census", "data/glad", "data/nass", "data/era5", "data/nasa"))
    dir.create(d, recursive = TRUE, showWarnings = FALSE)
  get <- function(url, file) if (!file.exists(file)) download.file(url, file, mode = "wb", quiet = TRUE)

# 2). PRISM (Oregon State University): daily maximum temperature, 4 km, July 2012, one zip a day ----
  # The service allows each file twice a day, so a file already on disk is never asked for again.
  for (d in misc$days_prism) {
    f <- paste0("data/prism/prism_tmax_us_25m_", d, ".zip")
    if (!file.exists(f)) { get(paste0("https://services.nacse.org/prism/data/get/us/4km/tmax/", d), f); Sys.sleep(2) }
  }

# 3). Census Bureau: county and state outlines ----
  get("https://www2.census.gov/geo/tiger/GENZ2024/shp/cb_2024_us_county_500k.zip", "data/census/cb_2024_us_county_500k.zip")
  get("https://www2.census.gov/geo/tiger/GENZ2024/shp/cb_2024_us_state_500k.zip",  "data/census/cb_2024_us_state_500k.zip")

# 4). University of Maryland (GLAD): share of each 3 km cell under crops, 2008 to 2011 ----
  get("https://glad.geog.umd.edu/Potapov/Global_Crop/Data/Global_cropland_3km_2011.tif", "data/glad/Global_cropland_3km_2011.tif")

# 5). USDA Quick Stats: county corn yields, 2002 to 2012 ----
  key <- Sys.getenv("NASS_API_KEY")
  if (!file.exists("data/nass/corn_yield_county_2002_2012.csv")) {
    stopifnot("NASS_API_KEY is missing from ~/.Renviron" = nzchar(key))
    q <- paste0("https://quickstats.nass.usda.gov/api/api_GET/?format=CSV",
                "&short_desc=", URLencode("CORN, GRAIN - YIELD, MEASURED IN BU / ACRE", reserved = TRUE),
                "&agg_level_desc=COUNTY&source_desc=SURVEY&year__GE=2002&year__LE=2012")
    ok <- tryCatch(download.file(paste0(q, "&key=", key), "data/nass/corn_yield_county_2002_2012.csv",
                                 mode = "wb", quiet = TRUE), error = function(e) 1, warning = function(w) 1)
    if (ok != 0) stop("Quick Stats did not answer; run this section again")   # the message leaves the key out
  }

# 6). ERA5 (ECMWF, from Google's public copy): hourly wind 10 m above the ground, the whole globe, one file a day ----
  for (d in misc$days_era5) for (v in c("u", "v"))
    get(paste0("https://storage.googleapis.com/gcp-public-data-arco-era5/raw/date-variable-single_level/", d,
               "/10m_", v, "_component_of_wind/surface.nc"),
        paste0("data/era5/", v, "10_", gsub("/", "", d), ".nc"))

# 7). NASA Worldview: the Terra satellite's picture of the Los Angeles basin on 9 January 2025, as a GeoTIFF ----
  get(paste0("https://wvs.earthdata.nasa.gov/api/v1/snapshot?REQUEST=GetSnapshot&TIME=2025-01-09&BBOX=", misc$box_la,
             "&CRS=EPSG:4326&LAYERS=MODIS_Terra_CorrectedReflectance_TrueColor&WRAP=day&FORMAT=image/tiff&WIDTH=1200&HEIGHT=966"),
      "data/nasa/worldview_terra_20250109.tif")
