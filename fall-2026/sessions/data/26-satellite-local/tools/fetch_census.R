# AEM 6850, session 26. Downloads New York's county boundaries and county population from the Census Bureau.
# Run in the 26-satellite-local folder (open 26-satellite-local.Rproj first):
#   source("tools/fetch_census.R")
# Needs the network, no account and no key. About 17 MB is downloaded; 2 MB is kept.
# Sources (Census Bureau, public domain):
#   Counties: cartographic boundary file 2023, 1:500,000, all US counties (11.6 MB zip)
#     https://www2.census.gov/geo/tiger/GENZ2023/shp/cb_2023_us_county_500k.zip
#   Population 2023: county population estimates, Vintage 2023 (1.4 MB, kept whole)
#     https://www2.census.gov/programs-surveys/popest/datasets/2020-2023/counties/totals/co-est2023-alldata.csv
#   Population 2013: county population estimates, Vintage 2019 (3.6 MB; only New York's rows are kept)
#     https://www2.census.gov/programs-surveys/popest/datasets/2010-2019/counties/totals/co-est2019-alldata.csv
# The boundary zip covers every county in the US, so only New York's 62 rows are kept, as they came (NAD83, every
#   column), in data/census/cb_2023_ny_county_500k.gpkg. The 2019 vintage file is kept for New York only, every column.
# Reads: nothing. Writes: data/census/.

# 1). Preliminary ----
  # Clean up workspace and load or install necessary packages if necessary
  rm(list = ls())
  want <- c("sf")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only = TRUE))
  rm(want, need)
  options(timeout = 600, HTTPUserAgent = "aem6850-course-data-script")
  misc <- list()
  misc$dir    <- "data/census"
  misc$cb     <- "https://www2.census.gov/geo/tiger/GENZ2023/shp/cb_2023_us_county_500k.zip"
  misc$pop23  <- "https://www2.census.gov/programs-surveys/popest/datasets/2020-2023/counties/totals/co-est2023-alldata.csv"
  misc$pop13  <- "https://www2.census.gov/programs-surveys/popest/datasets/2010-2019/counties/totals/co-est2019-alldata.csv"
  misc$out_cb    <- file.path(misc$dir, "cb_2023_ny_county_500k.gpkg")
  misc$out_pop23 <- file.path(misc$dir, "co-est2023-alldata.csv")
  misc$out_pop13 <- file.path(misc$dir, "co-est2019-alldata_ny.csv")
  dir.create(misc$dir, recursive = TRUE, showWarnings = FALSE)
  get <- function(url, file) if (!file.exists(file)) download.file(url, file, mode = "wb", quiet = TRUE)

# 2). County boundaries, New York's rows ----
  if (!file.exists(misc$out_cb)) {
    z <- file.path(tempdir(), basename(misc$cb))
    get(misc$cb, z)
    cty <- st_read(paste0("/vsizip/", z), quiet = TRUE)
    ny  <- cty[cty$STATEFP == "36", ]
    st_write(ny, misc$out_cb, quiet = TRUE)
  }
  ny <- st_read(misc$out_cb, quiet = TRUE)
  cat("New York counties:", nrow(ny), "\n")

# 3). Population ----
  get(misc$pop23, misc$out_pop23)
  if (!file.exists(misc$out_pop13)) {
    z <- file.path(tempdir(), basename(misc$pop13))
    get(misc$pop13, z)
    p <- readLines(z, encoding = "latin1")
    st <- sapply(strsplit(p[-1], ","), `[`, 4)               # column 4 is STATE
    writeLines(c(p[1], p[-1][st == "36"]), misc$out_pop13)
  }
  p23 <- read.csv(misc$out_pop23, fileEncoding = "latin1")
  cat("2023 rows for New York counties:", sum(p23$STATE == 36 & p23$COUNTY > 0), "\n")
  print(file.info(list.files(misc$dir, full.names = TRUE))["size"])

# the end ----
