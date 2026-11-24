# Daily MRMS MESH (24 h max, 12Z-12Z) for seven Plains states, Apr-Sep 2021-2025.
# Output: county-day hail area by size threshold, county max size; daily cropped rasters for hail days.
suppressMessages(library(terra))
bb <- ext(-109.1, -89.4, 36.9, 49.1)
st <- c("08", "19", "20", "27", "31", "38", "46")          # CO IA KS MN NE ND SD
tmpl <- crop(rast("mesh_test.grib2"), bb); crs(tmpl) <- "EPSG:4326"
cty <- vect("cb/cb_2023_us_county_5m.shp"); cty <- cty[cty$STATEFP %in% st, ]
cty <- project(cty, "EPSG:4326"); cty$idx <- seq_len(nrow(cty))
writeVector(cty, "counties_7states.gpkg", overwrite = TRUE)
cidv  <- values(rasterize(cty, tmpl, field = "idx"), mat = FALSE)
areav <- values(cellSize(tmpl, unit = "km"), mat = FALSE)
ok <- !is.na(cidv)
geoid <- cty$GEOID
days <- do.call(c, lapply(2021:2025, function(y) seq(as.Date(sprintf("%d-04-01", y)), as.Date(sprintf("%d-09-30", y)), by = "day")))
out <- "mesh_county_day.csv"
done <- if (file.exists(out)) unique(read.csv(out)$date) else character(0)
if (!file.exists(out)) cat("date,geoid,area_19mm,area_25mm,area_38mm,area_51mm,max_mm\n", file = out)
log <- file("mesh_pipeline.log", open = "a")
for (k in seq_along(days)) {
  d <- days[k]; ds <- format(d)
  if (ds %in% done) next
  f1 <- format(d + 1, "%Y%m%d"); got <- FALSE
  for (hhmmss in c("120000", "123000", "113000", "130000")) {
    url <- sprintf("https://noaa-mrms-pds.s3.amazonaws.com/CONUS/MESH_Max_1440min_00.50/%s/MRMS_MESH_Max_1440min_00.50_%s-%s.grib2.gz", f1, f1, hhmmss)
    gz <- tempfile(fileext = ".grib2.gz")
    if (tryCatch(download.file(url, gz, mode = "wb", quiet = TRUE) == 0, error = function(e) FALSE, warning = function(w) FALSE)) { got <- TRUE; break }
  }
  if (!got) { writeLines(paste(ds, "MISSING"), log); flush(log); next }
  system2("gunzip", c("-f", gz)); g <- sub("\\.gz$", "", gz)
  r <- crop(rast(g), bb); crs(r) <- "EPSG:4326"
  v <- values(r, mat = FALSE); v[is.na(v) | v < 0] <- 0
  if (any(v[ok] > 0)) {
    a <- function(th) { s <- ok & v >= th; x <- tapply(areav[s], cidv[s], sum); y <- numeric(length(geoid)); y[as.integer(names(x))] <- x; y }
    pos <- ok & v > 0; mx <- tapply(v[pos], cidv[pos], max); m <- numeric(length(geoid)); m[as.integer(names(mx))] <- mx
    df <- data.frame(date = ds, geoid = geoid, area_19mm = a(19.05), area_25mm = a(25.4), area_38mm = a(38.1), area_51mm = a(50.8), max_mm = m)
    df <- df[df$max_mm > 0, ]
    write.table(round_df <- within(df, { area_19mm <- round(area_19mm, 2); area_25mm <- round(area_25mm, 2); area_38mm <- round(area_38mm, 2); area_51mm <- round(area_51mm, 2); max_mm <- round(max_mm, 1) }),
                out, sep = ",", append = TRUE, row.names = FALSE, col.names = FALSE, quote = FALSE)
    if (any(v[ok] >= 19.05)) { values(r) <- round(v); writeRaster(r, sprintf("days/%s.tif", gsub("-", "", ds)), datatype = "INT2S", gdal = c("COMPRESS=DEFLATE"), overwrite = TRUE) }
  }
  unlink(c(gz, g)); writeLines(paste(ds, "ok", sum(v[ok] >= 25.4)), log); flush(log)
}
writeLines("done", log); close(log)
