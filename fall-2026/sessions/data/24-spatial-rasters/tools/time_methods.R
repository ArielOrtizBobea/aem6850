# AEM 6850, session 24. Times four ways of averaging July 2012's daily temperature over every county
# of the lower 48 states, and saves the seconds in data_clean/timings.csv for the slide that shows them.
# Run once, in the 24-spatial-rasters folder (open 24-spatial-rasters.Rproj first); about 25 minutes:
#   source("tools/time_methods.R")
# Reads:  data_clean/tmax_july2012.tif, data/census/cb_2024_us_county_500k.zip.
# Writes: data_clean/timings.csv (method, days, calls, seconds), logs/time_methods.log.

# 1). Preliminary ----
  want <- c("terra", "sf", "exactextractr", "Matrix")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only = TRUE))
  rm(want, need)
  secs <- function(expr) unname(system.time(expr)[3])
  out  <- list()
  add  <- function(method, days, calls, s) {
    out[[length(out) + 1]] <<- data.frame(method = method, days = days, calls = calls, seconds = round(s, 3))
    cat(format(Sys.time(), "%H:%M:%S"), method, "| days", days, "| calls", calls, "|", round(s, 2), "s\n")
  }

# 2). The grids and the counties ----
  tmax <- rast("data_clean/tmax_july2012.tif")
  unzip("data/census/cb_2024_us_county_500k.zip", exdir = "data_clean/counties")
  co <- st_read("data_clean/counties/cb_2024_us_county_500k.shp", quiet = TRUE)
  co <- co[!(co$STATEFP %in% c("02", "15", "60", "66", "69", "72", "78")), ]   # the lower 48 states and DC
  co <- st_transform(co, crs(tmax))
  v  <- vect(co)
  stopifnot(nrow(co) == 3109, nlyr(tmax) == 31)

# 3). terra's extract(), counting each cell by the fraction inside the county ----
  add("terra extract(exact = TRUE)", 1, 1,  secs(e1 <- extract(tmax[[1]], v, fun = mean, exact = TRUE, na.rm = TRUE)))
  add("terra extract(exact = TRUE)", 3, 3,  secs(for (i in 1:3) extract(tmax[[i]], v, fun = mean, exact = TRUE, na.rm = TRUE)))
  add("terra extract(exact = TRUE)", 31, 1, secs(e31 <- extract(tmax, v, fun = mean, exact = TRUE, na.rm = TRUE)))

# 4). terra's extract(), counting only the cells whose centre is inside the county ----
  add("terra extract()", 1, 1,  secs(extract(tmax[[1]], v, fun = mean, na.rm = TRUE)))
  add("terra extract()", 31, 1, secs(extract(tmax, v, fun = mean, na.rm = TRUE)))

# 5). exactextractr ----
  add("exact_extract()", 1, 1,  secs(x1 <- exact_extract(tmax[[1]], co, "mean", progress = FALSE)))
  add("exact_extract()", 3, 3,  secs(for (i in 1:3) exact_extract(tmax[[i]], co, "mean", progress = FALSE)))
  add("exact_extract()", 31, 1, secs(x31 <- exact_extract(tmax, co, "mean", progress = FALSE)))

# 6). The weight matrix: the table of cells and fractions once, then one multiplication ----
  s_tab <- secs({
    info <- exact_extract(tmax[[1]], co, include_cell = TRUE, progress = FALSE)
    n    <- vapply(info, nrow, 1L)
    tab  <- data.frame(county = rep(seq_along(info), n), cell = unlist(lapply(info, `[[`, "cell")),
                       frac = unlist(lapply(info, `[[`, "coverage_fraction")), value = unlist(lapply(info, `[[`, "value")))
    tab  <- tab[!is.na(tab$value), ]                                  # cells over the sea hold no temperature
    tab$w <- tab$frac / ave(tab$frac, tab$county, FUN = sum)
    P    <- sparseMatrix(i = tab$county, j = tab$cell, x = tab$w, dims = c(nrow(co), ncell(tmax)))
  })
  add("weight matrix P, built once", 1, 1, s_tab)
  s_val <- secs({ M <- values(tmax); M[is.na(M)] <- 0 })
  add("values() into a matrix", 31, 1, s_val)
  add("P %*% M", 31, 1, secs(C <- P %*% M))

# 7). The three results agree ----
  stopifnot(max(abs(as.matrix(C) - as.matrix(x31)), na.rm = TRUE) < 1e-4,
            max(abs(as.matrix(e31[, -1]) - as.matrix(x31)), na.rm = TRUE) < 1e-4,
            abs(rowSums(P) - 1) < 1e-8)
  write.csv(do.call(rbind, out), "data_clean/timings.csv", row.names = FALSE)
