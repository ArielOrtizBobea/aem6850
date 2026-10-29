# =============================================================
# AEM 6850 - Session 18: Documents & scans
# Script 5 of 8 - the rainfall sheets as long tables.
#
# Lecture part 4, a handwritten page. Puts the volunteers' typing and the
# vision model's replies in one shape, one row per sheet, year and month
# (the written total is the 13th "month"), so the two can be compared cell
# by cell.
#
# Reads:  data/volunteers/TYRain_*.csv, replies/abbotsbury_<decade>_run<r>.json
# Writes: data_clean/rain_volunteers.csv, data_clean/rain_model.csv
#
# Open 18-documents.Rproj first. It sits at the project root, so the
# working directory is 18-documents/ and every path below is relative to it.
#
#   source("code/5_sheets_to_csv.R")
# =============================================================


# 1). Preliminary ----

  # Load or install the packages this script uses
  want <- c("jsonlite")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only=TRUE))
  rm(want, need)

  # Parameters
  misc <- list()
  misc$sheets <- c("1860s" = "data/volunteers/TYRain_1860-1869_02_pt3-page-038.csv",
                   "1870s" = "data/volunteers/TYRain_1870-1879_04_pt1-page-064.csv",
                   "1880s" = "data/volunteers/ERROR_TYRain_1880-1889_05_pt3-page-032.csv",
                   "1890s" = "data/volunteers/TYRain_1890-1899_09_pt1-page-113.csv",
                   "1910s" = "data/volunteers/TYRain_1910-1919_11_pt1-page-034.csv")
  misc$replies <- "replies"
  misc$out_vol <- "data_clean/rain_volunteers.csv"
  misc$out_mod <- "data_clean/rain_model.csv"
  misc$months  <- c("jan", "feb", "mar", "apr", "may", "jun",
                    "jul", "aug", "sep", "oct", "nov", "dec")


# 2). The volunteers' typing ----

  # A TYRain file: rows 1-3 metadata, row 5 = year headings from column B,
  # rows 6-17 = January..December, row 18 = Total as transcribed.
  # Blank = no value; -999 = the volunteers could not read the cell.
  read_volunteers <- function(sheet, path) {
    raw <- read.csv(path, header = FALSE, colClasses = "character",
                    strip.white = TRUE, na.strings = character(0))
    years <- raw[5, -1]
    keep  <- which(nzchar(years))                 # columns with a year heading
    years <- as.integer(years[keep])
    body  <- raw[6:18, keep + 1, drop = FALSE]     # 12 months + Total
    vals  <- as.vector(as.matrix(body))           # column-major = year-major: the 13 rows of year 1, then year 2, ...
    out <- data.frame(
      sheet  = sheet,
      year   = rep(years, each = 13),
      month  = rep(c(misc$months, "total"), times = length(years)),
      stringsAsFactors = FALSE)
    out$unread <- vals == "-999" | vals == "-999.00"
    num <- suppressWarnings(as.numeric(vals))
    num[out$unread | !nzchar(vals)] <- NA
    out$inches <- num
    out[, c("sheet", "year", "month", "inches", "unread")]
  }

  volunteers <- do.call(rbind, Map(read_volunteers, names(misc$sheets), misc$sheets))
  rownames(volunteers) <- NULL
  write.csv(volunteers, misc$out_vol, row.names = FALSE, na = "")
  cat(basename(misc$out_vol), ":", nrow(volunteers), "rows,",
      sum(!is.na(volunteers$inches)), "with a number,",
      sum(volunteers$unread), "marked unread\n")


# 3). The model's replies ----

  # One JSON file per sheet and run (replies/abbotsbury_<sheet>_run<r>.json):
  # an array of objects {year, jan, ..., dec, total}; null = blank or unread.
  # Rows are matched to the volunteers' year range for the same sheet; a year
  # the model did not return gets NA throughout, extra years are dropped.
  read_model <- function(sheet, run) {
    path <- file.path(misc$replies, sprintf("abbotsbury_%s_run%d.json", sheet, run))
    if (!file.exists(path)) return(NULL)
    m <- fromJSON(path)
    if (length(m) == 0 || !is.data.frame(m)) m <- data.frame(year = integer(0))
    for (col in c(misc$months, "total")) if (is.null(m[[col]])) m[[col]] <- NA_real_
    m$year <- as.integer(m$year)
    m <- m[!duplicated(m$year), ]                 # keep the first object per year
    years <- sort(unique(volunteers$year[volunteers$sheet == sheet]))
    m <- m[match(years, m$year), c(misc$months, "total")]
    data.frame(
      sheet  = sheet,
      year   = rep(years, each = 13),
      month  = rep(c(misc$months, "total"), times = length(years)),
      inches = as.numeric(as.vector(t(as.matrix(m)))),
      run    = run,
      stringsAsFactors = FALSE)
  }

  model <- do.call(rbind, unlist(lapply(names(misc$sheets), function(s)
    lapply(1:2, function(r) read_model(s, r))), recursive = FALSE))
  if (!is.null(model)) {
    rownames(model) <- NULL
    write.csv(model, misc$out_mod, row.names = FALSE, na = "")
    cat(basename(misc$out_mod), ":", nrow(model), "rows from",
        length(unique(paste(model$sheet, model$run))), "sheet-runs\n")
  } else {
    cat("no replies yet;", misc$out_mod, "not written\n")
  }


# the end ----
