# Builds one table with a row per county: farmland value per acre and the
# median value of an owner-occupied home in 1940 and 2022, and the real
# value in 2022 as a multiple of the value in 1940. Writes data_clean/counties.rds.

# 1). Parameters ----
# NHGIS names its files after the extract number, so they are found by
# the dataset part of the name: ds78 is the 1940 census, ds262 the
# 2018-2022 ACS.
nhgis <- function(pattern) {
  list.files("data/nhgis", pattern, recursive = TRUE, full.names = TRUE)[1]
}
misc <- list(
  icpsr = "data/icpsr/35206-0001-Data.rda",
  nass  = "data/nass_land_value_county.csv",
  h1940 = nhgis("ds78_1940_county\\.csv$"),
  h2022 = nhgis("ds262_20225_county\\.csv$")
)

# 2). Farmland value per acre, 1940: Census of Agriculture, ICPSR 35206 ----
e <- new.env()
load(misc$icpsr, envir = e)
ag <- e$da35206.0001
ag <- ag[ag$LEVEL == 1, ]                               # counties, not states
# Three counties carry a neighbour's FIPS code in this file. Comparing
# every name with the name NASS gives the code finds only these.
fix <- c("NEOSHO/DORN" = 20133, "NESS" = 20135)          # Kansas
k <- trimws(ag$NAME) %in% names(fix) & ag$FIPS %in% c(20135, 20137)
ag$FIPS[k] <- fix[trimws(ag$NAME[k])]
ag$FIPS[trimws(ag$NAME) == "JACKSON" & ag$FIPS == 13151] <- 13157  # Georgia
land40 <- data.frame(fips = sprintf("%05d", ag$FIPS), land_1940 = ag$FAVAL940)

# 3). Farmland value per acre, 2022: Census of Agriculture, NASS ----
nass <- read.csv(misc$nass)
nass <- nass[nass$year == 2022, ]
land22 <- data.frame(
  fips = sprintf("%02d%03d", nass$state_fips_code, nass$county_code),
  land_2022 = suppressWarnings(as.numeric(gsub(",", "", nass$Value)))  # "(D)" -> NA
)

# 4). Median value of an owner-occupied home, NHGIS ----
# Row 2 of an NHGIS file repeats the column names in words; drop it.
read_nhgis <- function(file) read.csv(file, colClasses = "character")[-1, ]

# 1940 codes are the FIPS code with a 0 added; codes ending in 5 are areas
# that are not counties, such as Yellowstone National Park.
h40 <- read_nhgis(misc$h1940)
h40 <- h40[substr(h40$COUNTYA, 4, 4) == "0", ]
house40 <- data.frame(fips = paste0(substr(h40$STATEA, 1, 2),
                                    substr(h40$COUNTYA, 1, 3)),
                      house_1940 = suppressWarnings(as.numeric(h40$BYP001)))

h22 <- read_nhgis(misc$h2022)                           # in 2022 dollars
house22 <- data.frame(fips = paste0(h22$STATEA, h22$COUNTYA),
                      house_2022 = as.numeric(h22$AQU4E001))

# 5). Consumer price index, BLS via FRED (annual mean of the months) ----
cpi <- read.csv("data/CPIAUCNS.csv")
cpi <- tapply(cpi$CPIAUCNS, substr(cpi$observation_date, 1, 4), mean)
inflation <- cpi[["2022"]] / cpi[["1940"]]

# 6). Join and compute the real 2022 value as a multiple of 1940 ----
d <- Reduce(function(a, b) merge(a, b, by = "fips", all = TRUE),
            list(land40, land22, house40, house22))
d <- d[as.numeric(substr(d$fips, 1, 2)) <= 56 &
       !substr(d$fips, 1, 2) %in% c("02", "15"), ]      # lower 48 and DC
d$land_ratio  <- d$land_2022  / d$land_1940  / inflation
d$house_ratio <- d$house_2022 / d$house_1940 / inflation

# 7). Checks ----
stopifnot(!anyDuplicated(d$fips), inflation > 20, inflation < 22)
c(counties = nrow(d),
  farmland = sum(!is.na(d$land_ratio)),
  houses   = sum(!is.na(d$house_ratio)),
  both     = sum(!is.na(d$land_ratio) & !is.na(d$house_ratio)))

# 8). Save ----
# A copy goes to match/, the folder for the session's first agent demo,
# which holds only the default script, a picture of the target and the data.
for (f in c("data_clean", "match/data_clean")) {
  dir.create(f, showWarnings = FALSE, recursive = TRUE)
  saveRDS(d, file.path(f, "counties.rds"))
}
