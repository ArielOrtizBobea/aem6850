# build_csv.R: long-format tables from the volunteers' transcriptions and
# from the vision model's replies.
# Run from the session data folder:  Rscript code/build_csv.R
# Writes rain_volunteers.csv and rain_model.csv.

SHEETS <- c("1860s" = "volunteers/TYRain_1860-1869_02_pt3-page-038.csv",
            "1870s" = "volunteers/TYRain_1870-1879_04_pt1-page-064.csv",
            "1880s" = "volunteers/ERROR_TYRain_1880-1889_05_pt3-page-032.csv",
            "1890s" = "volunteers/TYRain_1890-1899_09_pt1-page-113.csv",
            "1910s" = "volunteers/TYRain_1910-1919_11_pt1-page-034.csv")
MONTHS <- c("jan", "feb", "mar", "apr", "may", "jun",
            "jul", "aug", "sep", "oct", "nov", "dec")

# ---- volunteers -------------------------------------------------------------
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
    month  = rep(c(MONTHS, "total"), times = length(years)),
    stringsAsFactors = FALSE)
  out$unread <- vals == "-999" | vals == "-999.00"
  num <- suppressWarnings(as.numeric(vals))
  num[out$unread | !nzchar(vals)] <- NA
  out$inches <- num
  out[, c("sheet", "year", "month", "inches", "unread")]
}

volunteers <- do.call(rbind, Map(read_volunteers, names(SHEETS), SHEETS))
rownames(volunteers) <- NULL
write.csv(volunteers, "rain_volunteers.csv", row.names = FALSE, na = "")
cat("rain_volunteers.csv:", nrow(volunteers), "rows,",
    sum(!is.na(volunteers$inches)), "with a number,",
    sum(volunteers$unread), "marked unread\n")

# ---- model -----------------------------------------------------------------
# One JSON file per sheet and run (cache/abbotsbury_<sheet>_run<r>.json):
# an array of objects {year, jan, ..., dec, total}; null = blank or unread.
# Rows are matched to the volunteers' year range for the same sheet; a year
# the model did not return gets NA throughout, extra years are dropped.
read_model <- function(sheet, run) {
  path <- sprintf("cache/abbotsbury_%s_run%d.json", sheet, run)
  if (!file.exists(path)) return(NULL)
  m <- jsonlite::fromJSON(path)
  if (length(m) == 0 || !is.data.frame(m)) m <- data.frame(year = integer(0))
  for (col in c(MONTHS, "total")) if (is.null(m[[col]])) m[[col]] <- NA_real_
  m$year <- as.integer(m$year)
  m <- m[!duplicated(m$year), ]                 # keep the first object per year
  years <- sort(unique(volunteers$year[volunteers$sheet == sheet]))
  m <- m[match(years, m$year), c(MONTHS, "total")]
  data.frame(
    sheet  = sheet,
    year   = rep(years, each = 13),
    month  = rep(c(MONTHS, "total"), times = length(years)),
    inches = as.numeric(as.vector(t(as.matrix(m)))),
    run    = run,
    stringsAsFactors = FALSE)
}

model <- do.call(rbind, unlist(lapply(names(SHEETS), function(s)
  lapply(1:2, function(r) read_model(s, r))), recursive = FALSE))
if (!is.null(model)) {
  rownames(model) <- NULL
  write.csv(model, "rain_model.csv", row.names = FALSE, na = "")
  cat("rain_model.csv:", nrow(model), "rows from",
      length(unique(paste(model$sheet, model$run))), "sheet-runs\n")
} else {
  cat("no cache files yet; rain_model.csv not written\n")
}
