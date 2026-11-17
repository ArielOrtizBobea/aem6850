# AEM 6850, session 23. Builds the uninsured share of low-income adults by county and year, 2008-2018.
# Run in the 23-spatial-vector folder, after tools/fetch_data.R:  source("tools/sahie_panel.R")
# Reads: data/sahie/sahie-2008-csv.zip ... sahie-2018-csv.zip (88 MB, not in the class zip).
# Writes: data_clean/sahie_uninsured.csv (GEOID, year, pctui; 34,567 rows), which the slides read.
# Reading the eleven files takes about 40 seconds and 600 MB of memory.

# 1). Preliminary ----
  misc <- list(years = 2008:2018, out = "data_clean/sahie_uninsured.csv")

# 2). One year: adults 18-64 at or below 138% of the poverty line, all races and sexes ----
  read_year <- function(y) {
    z <- paste0("data/sahie/sahie-", y, "-csv.zip"); f <- unzip(z, list = TRUE)$Name[1]
    h <- grep("^year,", readLines(unz(z, f), 200))[1]               # the table starts below a long header
    x <- read.csv(unz(z, f), skip = h - 1, colClasses = "character", strip.white = TRUE)
    # geocat 50: county; agecat 1: 18 to 64; racecat 0, sexcat 0: all; iprcat 3: at or below 138% of poverty
    x <- x[x$geocat == "50" & x$agecat == "1" & x$racecat == "0" & x$sexcat == "0" & x$iprcat == "3", ]
    if ("version" %in% names(x) && any(x$version == "Updated")) x <- x[x$version == "Updated", ]   # 2013 only
    data.frame(GEOID = paste0(x$statefips, x$countyfips), year = y, pctui = as.numeric(x$PCTUI))
  }

# 3). Every year, saved ----
  sahie <- do.call(rbind, lapply(misc$years, read_year))
  table(sahie$year)                                                 # 3,142 to 3,143 counties a year
  write.csv(sahie, misc$out, row.names = FALSE)

# the end ----
