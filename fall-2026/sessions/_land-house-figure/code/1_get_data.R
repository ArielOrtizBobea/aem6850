# Downloads the public raw files into data/, exactly as the sources serve
# them, and records how the two licensed files were obtained.
#
# Public, downloaded below:
# - Farmland 2022: USDA NASS Quick Stats, Census of Agriculture, "AG LAND,
#   INCL BUILDINGS - ASSET VALUE, MEASURED IN $ / ACRE", by county. The API
#   needs a free key (https://quickstats.nass.usda.gov/api), read from the
#   NASS_API_KEY environment variable, for example a line in ~/.Renviron.
# - Prices: BLS consumer price index for all urban consumers, not seasonally
#   adjusted, monthly, from FRED (https://fred.stlouisfed.org/series/CPIAUCNS).
#
# Licensed, not redistributed (each needs its own free account):
# - Homes 1940 and 2018-2022: IPUMS NHGIS (https://www.nhgis.org), 1940
#   census table NT74 and 2018-2022 ACS table B25077, county level.
#   Downloaded below: the request in data/nhgis/extract_definition.json
#   goes to the IPUMS API with a free key read from IPUMS_API_KEY
#   (https://account.ipums.org/api_keys), for example a line in ~/.Renviron.
# - Farmland 1940: Haines, Fishback and Rhode, United States Agriculture
#   Data, 1840-2012, ICPSR 35206 v4, part 1 (farm land values, 1850-1959),
#   R format (https://doi.org/10.3886/ICPSR35206.v4). No API: download it
#   with an ICPSR account (Cornell is a member) and save
#   35206-0001-Data.rda in data/icpsr/. Checked at the end.

# 1). Parameters ----
misc <- list(
  nass_url  = "https://quickstats.nass.usda.gov/api/api_GET/",
  nass_item = "AG LAND, INCL BUILDINGS - ASSET VALUE, MEASURED IN $ / ACRE",
  cpi_url   = "https://fred.stlouisfed.org/graph/fredgraph.csv?id=CPIAUCNS"
)

# Downloads to a temporary file first. If a download fails, the copy of
# the file that came with the project stays in place.
fetch <- function(url, file) {
  tmp <- tempfile()
  ok <- tryCatch(download.file(url, tmp, quiet = TRUE) == 0,
                 error = function(e) FALSE, warning = function(w) FALSE)
  if (ok && file.size(tmp) > 0) {
    file.copy(tmp, file, overwrite = TRUE)
  } else if (file.exists(file)) {
    message("Download failed; keeping the copy of ", file, " in the project.")
  } else {
    stop("Download failed and there is no copy of ", file, call. = FALSE)
  }
}

# 2). Farmland values, NASS ----
key <- Sys.getenv("NASS_API_KEY")
if (nchar(key) > 0) {
  query <- paste0(
    "key=", key,
    "&source_desc=CENSUS",
    "&short_desc=", URLencode(misc$nass_item, reserved = TRUE),
    "&agg_level_desc=COUNTY",
    "&format=CSV"
  )
  fetch(paste0(misc$nass_url, "?", query), "data/nass_land_value_county.csv")
} else {
  message("No NASS_API_KEY; using the NASS file that came with the project.")
}

# 3). Consumer prices, FRED ----
fetch(misc$cpi_url, "data/CPIAUCNS.csv")

# 4). Home values, IPUMS NHGIS ----
# Skipped when the two tables are already in data/nhgis/.
have <- list.files("data/nhgis", "ds78_1940_county\\.csv$|ds262_20225_county\\.csv$",
                   recursive = TRUE)
if (length(have) < 2) {
  library(httr2)
  ipums <- Sys.getenv("IPUMS_API_KEY")
  stopifnot(nchar(ipums) > 0)
  api <- function(path = "") {
    request(paste0("https://api.ipums.org/extracts", path)) |>
      req_url_query(collection = "nhgis", version = 2) |>
      req_headers(Authorization = ipums)
  }
  definition <- jsonlite::read_json("data/nhgis/extract_definition.json")
  job <- tryCatch(
    api() |> req_body_json(definition) |> req_perform() |> resp_body_json(),
    error = function(e) stop("The IPUMS API did not accept the request (",
      conditionMessage(e), "). Download the two tables at nhgis.org, or ",
      "copy them into data/nhgis/ from another copy of the project.",
      call. = FALSE))
  repeat {                                   # usually a minute or two
    Sys.sleep(15)
    job <- api(paste0("/", job$number)) |> req_perform() |> resp_body_json()
    if (job$status == "completed") break
    if (job$status %in% c("failed", "canceled")) stop("NHGIS extract ", job$status)
  }
  url <- job$downloadLinks$tableData$url
  zip <- file.path("data/nhgis", basename(url))
  request(url) |> req_headers(Authorization = ipums) |> req_perform(path = zip)
  unzip(zip, exdir = "data/nhgis")
}

# 5). Farmland 1940, ICPSR: check the file is in place ----
if (!file.exists("data/icpsr/35206-0001-Data.rda")) {
  stop("data/icpsr/35206-0001-Data.rda is missing: download part 1 of ",
       "ICPSR 35206 in R format (see the README).", call. = FALSE)
}
