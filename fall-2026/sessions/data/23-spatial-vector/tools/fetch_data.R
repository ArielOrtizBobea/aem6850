# AEM 6850, session 23. Downloads every raw file in data/, as it was fetched on 2026-11-13.
# Run once, in the 23-spatial-vector folder (open 23-spatial-vector.Rproj first):
#   source("tools/fetch_data.R")
# Needs the network; about 430 MB in all. The class does not need it: data/ already holds the files,
# except data/sahie/, data/epa/, data/meta/ and the primary-roads file, which stay out of the class zip.
# Reads: nothing. Writes: data/census/, data/sahie/, data/inpe/, data/osm/, data/noaa/hms/, data/epa/, data/meta/.

# 1). Preliminary ----
  options(timeout = 600, HTTPUserAgent = "aem6850-course-data-script")
  misc <- list(census = "https://www2.census.gov",
               wfs    = "https://terrabrasilis.dpi.inpe.br/geoserver/ows?service=WFS&version=2.0.0",
               box    = "BBOX(geom,-9.53,-63.099,-8.729,-62.291)",   # Cujubim's box: lat, lon order
               bbox   = "(-9.53,-63.099,-8.729,-62.291)")             # the same box for Overpass: south, west, north, east
  for (d in c("data/census", "data/sahie", "data/inpe", "data/osm", "data/noaa/hms", "data/epa", "data/meta"))
    dir.create(d, recursive = TRUE, showWarnings = FALSE)
  get <- function(url, file) if (!file.exists(file)) download.file(url, file, mode = "wb", quiet = TRUE)

# 2). Census Bureau: county and state outlines, primary roads, county population ----
  get(paste0(misc$census, "/geo/tiger/GENZ2024/shp/cb_2024_us_county_500k.zip"), "data/census/cb_2024_us_county_500k.zip")
  get(paste0(misc$census, "/geo/tiger/GENZ2024/shp/cb_2024_us_state_500k.zip"),  "data/census/cb_2024_us_state_500k.zip")
  get(paste0(misc$census, "/geo/tiger/TIGER2024/PRIMARYROADS/tl_2024_us_primaryroads.zip"),
      "data/census/tl_2024_us_primaryroads.zip")
  get(paste0(misc$census, "/programs-surveys/popest/datasets/2020-2024/counties/totals/co-est2024-alldata.csv"),
      "data/census/co-est2024-alldata.csv")

# 3). Census Bureau: Small Area Health Insurance Estimates (SAHIE), 2008 to 2018 ----
  for (y in 2008:2018)
    get(paste0(misc$census, "/programs-surveys/sahie/datasets/time-series/estimates-acs/sahie-", y, "-csv.zip"),
        paste0("data/sahie/sahie-", y, "-csv.zip"))

# 4). INPE's PRODES: Rondonia's municipalities and the clearings in Cujubim's box ----
  wfs <- function(layer, extra) paste0(misc$wfs, "&request=GetFeature&outputFormat=application/json",
                                       "&typeNames=prodes-legal-amz:", layer, extra)
  get(wfs("municipalities_legal_amazon", "&srsName=EPSG:4674&cql_filter=geocodigo%20LIKE%20%2711%25%27"),
      "data/inpe/municipalities_RO.json")                           # geocodigo starting 11: Rondonia
  for (s in c(0, 2000, 4000, 6000)) {                               # the server returns 2,000 features a page
    get(wfs("yearly_deforestation", paste0("&sortBy=fid&count=2000&startIndex=", s, "&cql_filter=", misc$box)),
        paste0("data/inpe/yearly_cujubim_bbox_", s, ".json"))
    Sys.sleep(1)
  }
  get(wfs("accumulated_deforestation_2007", paste0("&sortBy=fid&cql_filter=", misc$box)),
      "data/inpe/accumulated_2007_cujubim_bbox.json")

# 5). OpenStreetMap: roads and places in Cujubim's box, through the Overpass API ----
  q <- paste0('[out:json][timeout:120];(way["highway"]', misc$bbox,
              ';node["place"~"city|town|village"]', misc$bbox, ';);out geom;')
  get(paste0("https://overpass-api.de/api/interpreter?data=", URLencode(q, reserved = TRUE)),
      "data/osm/roads_cujubim_bbox.json")

# 6). NOAA's Hazard Mapping System: smoke outlines, one zip a day, June 2023 ----
  for (d in sprintf("202306%02d", 1:30))
    get(paste0("https://satepsanone.nesdis.noaa.gov/pub/FIRE/web/HMS/Smoke_Polygons/Shapefile/2023/06/hms_smoke", d, ".zip"),
        paste0("data/noaa/hms/hms_smoke", d, ".zip"))

# 7). EPA: daily PM2.5 at every monitor, 2023 (cut by tools/cut_pm25.R) ----
  get("https://aqs.epa.gov/aqsweb/airdata/daily_88101_2023.zip", "data/epa/daily_88101_2023.zip")

# 8). Meta: Social Connectedness Index between US counties (cut by tools/cut_sci.R) ----
  get(paste0("https://data.humdata.org/dataset/e9988552-74e4-4ff4-943f-c782ac8bca87/resource/",
             "97dc352f-c9c5-47d6-a6ef-88709e14006c/download/us_counties.csv"), "data/meta/us_counties.csv")

# the end ----
