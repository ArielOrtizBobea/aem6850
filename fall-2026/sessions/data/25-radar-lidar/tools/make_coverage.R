# AEM 6850, session 25. Where public LiDAR exists in the United States: USGS's LiDAR projects on AWS.
# Run in the 25-radar-lidar folder (open 25-radar-lidar.Rproj first):
#   source("tools/make_coverage.R")
# What it does: downloads the index of every project in USGS's public AWS bucket (usgs-lidar-public), kept by
#   Hobu Inc. on GitHub (hobuinc/usgs-lidar, boundaries/resources.geojson); counts the projects, their points and
#   years; measures the share of land covered in the lower 48, New York and Alaska; lists New York's projects;
#   draws a check map and saves the footprints dissolved by flight-year class.
# Reads: data/usgs_index/resources.geojson (downloaded here if missing);
#        ../23-spatial-vector/data_clean/states/cb_2024_us_state_500k.shp (Census cartographic state outlines).
# Writes: data_clean/coverage/usgs_lidar_by_year.gpkg, logs/prep_coverage.txt, logs/check_coverage.png.

# 1). Preliminary ----
  # Clean up workspace and load or install necessary packages if necessary
  rm(list = ls())
  want <- c("sf", "jsonlite")
  need <- want[!(want %in% installed.packages()[, "Package"])]
  if (length(need)) install.packages(need)
  invisible(lapply(want, function(i) suppressMessages(require(i, character.only = TRUE))))
  rm(want, need)

  suppressMessages(sf_use_s2(FALSE))
  misc <- list(url    = "https://raw.githubusercontent.com/hobuinc/usgs-lidar/master/boundaries/resources.geojson",
               index  = "data/usgs_index/resources.geojson",
               states = "../23-spatial-vector/data_clean/states/cb_2024_us_state_500k.shp",
               out    = "data_clean/coverage/usgs_lidar_by_year.gpkg",
               log    = "logs/prep_coverage.txt",
               png    = "logs/check_coverage.png",
               ithaca = c(-76.5019, 42.4440),
               nyc    = c(-73.98566, 40.74844),    # Empire State Building
               breaks = c(-Inf, 2011, 2014, 2017, 2020, Inf),
               labels = c("2011 or earlier", "2012-2014", "2015-2017", "2018-2020", "2021 or later"))
  dir.create(dirname(misc$out), recursive = TRUE, showWarnings = FALSE)
  dir.create(dirname(misc$index), recursive = TRUE, showWarnings = FALSE)
  log_lines <- c(paste("Session 25 LiDAR coverage, run", format(Sys.time(), "%Y-%m-%d %H:%M %Z")),
                 paste("sf", packageVersion("sf"), "|", R.version.string), "")
  say <- function(...) { x <- paste0(...); log_lines <<- c(log_lines, x); cat(x, "\n") }
  rec <- function(label, expr) {
    code <- paste(deparse(substitute(expr), width.cutoff = 500), collapse = " ")
    v <- expr
    say(label, ": ", paste(format(v), collapse = " "), "    <- ", code)
    invisible(v)
  }

# 2). The index ----
  if (!file.exists(misc$index)) download.file(misc$url, misc$index, mode = "wb")
  # the date of the latest commit that changed the file, from GitHub's public API (no token needed)
  api <- tryCatch(fromJSON("https://api.github.com/repos/hobuinc/usgs-lidar/commits?path=boundaries/resources.geojson&per_page=1"),
                  error = function(e) NULL)
  if (!is.null(api)) say("Latest commit changing resources.geojson: ", api$commit$committer$date, " (\"", api$commit$message, "\")")
  say("Index downloaded: ", format(file.mtime(misc$index), "%Y-%m-%d %H:%M %Z"), ", ", round(file.size(misc$index) / 1e6, 2), " MB")
  idx <- st_read(misc$index, quiet = TRUE)
  rec("Projects in the index", nrow(idx))
  rec("Property names", setdiff(names(idx), attr(idx, "sf_column")))
  rec("Total points, billions", round(sum(as.numeric(idx$count)) / 1e9, 1))
  rec("Points per project: min, median, max (millions)", round(as.numeric(quantile(as.numeric(idx$count), c(0, 0.5, 1))) / 1e6, 1))
  # a year in the name: the FIRST 4-digit group from 1990-2029. Names such as
  # USGS_LPC_NY_Sandy_Ul_Du_Or_2013_LAS_2016 carry the flight year first and the delivery year after "LAS_".
  yr <- regmatches(idx$name, regexpr("(199[0-9]|20[0-2][0-9])", idx$name))
  idx$year <- NA_integer_; idx$year[grepl("(199[0-9]|20[0-2][0-9])", idx$name)] <- as.integer(yr)
  rec("Names carrying a 4-digit year", sum(!is.na(idx$year)))
  rec("Range of 4-digit years (first one in the name)", range(idx$year, na.rm = TRUE))
  rec("Projects per 4-digit year", table(idx$year))
  # newer names end in a letter and two digits (NY_Hudson_1_D22); read 22 as 2022, an inference from the pattern
  code <- !is.na(idx$name) & is.na(idx$year) & grepl("_[A-Z][0-9]{2}$", idx$name)
  idx$year_code <- NA_integer_; idx$year_code[code] <- 2000L + as.integer(sub(".*_[A-Z]([0-9]{2})$", "\\1", idx$name[code]))
  rec("Names with no 4-digit year but a letter+2-digit suffix (e.g. _D22)", sum(code))
  rec("Their suffix years", table(idx$year_code))
  rec("Names with neither", idx$name[is.na(idx$year) & is.na(idx$year_code)])
  idx$year_map <- ifelse(is.na(idx$year), idx$year_code, idx$year)
  rec("Projects with a year for the map (4-digit or suffix)", sum(!is.na(idx$year_map)))
  idx$period <- cut(idx$year_map, misc$breaks, labels = misc$labels)
  # a check on the count field: the largest projects
  big <- head(idx[order(-as.numeric(idx$count)), c("name", "count")], 5); st_geometry(big) <- NULL
  say("Five largest projects by count (billions of points): ", paste(big$name, round(as.numeric(big$count) / 1e9, 1), sep = "=", collapse = ", "))

# 3). Coverage of land ----
  st <- st_read(misc$states, quiet = TRUE)
  l48 <- st_transform(st[!st$STUSPS %in% c("AK", "HI", "PR", "VI", "GU", "MP", "AS"), ], 5070)
  idx <- st_make_valid(idx)
  idx_5070 <- st_make_valid(st_transform(idx, 5070))
  t0 <- Sys.time()
  cover <- st_make_valid(st_union(idx_5070))
  say("TIME st_union() of all footprints in EPSG:5070: ", round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1), " s")
  share <- function(poly) {
    poly <- st_union(poly)
    as.numeric(st_area(st_intersection(cover, poly)) / st_area(poly))
  }
  rec("Share of the lower 48's land covered by at least one project, %", round(100 * share(l48), 1))
  rec("Share of New York State covered, %", round(100 * share(l48[l48$STUSPS == "NY", ]), 1))
  ak <- st_transform(st[st$STUSPS == "AK", ], 3338)   # Alaska Albers, equal area
  cover_ak <- st_make_valid(st_union(st_make_valid(st_transform(idx[st_intersects(idx, st_transform(ak, 4326), sparse = FALSE)[, 1], ], 3338))))
  rec("Share of Alaska covered, %", round(100 * as.numeric(st_area(st_intersection(cover_ak, st_union(ak))) / st_area(st_union(ak))), 1))
  by_state <- sapply(sort(l48$STUSPS), function(s) round(100 * share(l48[l48$STUSPS == s, ]), 1))
  say("Share covered by state, %: ", paste(names(by_state), by_state, sep = "=", collapse = ", "))

# 4). New York's projects ----
  ny <- st_transform(st[st$STUSPS == "NY", ], 4326)
  in_ny <- idx[st_intersects(idx, ny, sparse = FALSE)[, 1], ]
  in_ny <- in_ny[order(in_ny$year, in_ny$name), ]
  say("", "Projects touching New York State (", nrow(in_ny), "), name | year | points (millions):")
  say(paste(sprintf("  %-40s %5s %9.1f", in_ny$name, in_ny$year, as.numeric(in_ny$count) / 1e6), collapse = "\n"))
  pt <- function(p) st_sfc(st_point(p), crs = 4326)
  rec("Projects holding Ithaca (Tompkins County)", idx$name[st_intersects(idx, pt(misc$ithaca), sparse = FALSE)[, 1]])
  rec("Projects holding the Empire State Building (Manhattan)", idx$name[st_intersects(idx, pt(misc$nyc), sparse = FALSE)[, 1]])

# 5). Footprints dissolved by flight-year class, saved for redrawing ----
  by_year <- do.call(rbind, lapply(levels(idx$period), function(p) {
    g <- st_make_valid(st_union(idx_5070[!is.na(idx$period) & idx$period == p, ]))
    st_sf(period = p, projects = sum(idx$period == p, na.rm = TRUE), geometry = g)
  }))
  # newer flights drawn on top: clip each class by the union of the later ones, so the file holds what the map shows
  drawn <- by_year
  for (i in seq_len(nrow(drawn) - 1)) {
    later <- st_union(by_year[(i + 1):nrow(by_year), ])
    drawn$geometry[i] <- st_make_valid(st_difference(by_year$geometry[i], later))
  }
  drawn <- st_make_valid(st_intersection(drawn, st_union(l48)))
  drawn <- st_simplify(drawn, dTolerance = 500)   # 500 m tolerance keeps the file small; the map is national
  st_write(drawn, misc$out, delete_dsn = TRUE, quiet = TRUE)
  rec("usgs_lidar_by_year.gpkg size, MB (lower 48, simplified 500 m, newest on top)", round(file.size(misc$out) / 1e6, 2))
  rec("Land area of each class as drawn, % of the lower 48", setNames(round(100 * as.numeric(st_area(drawn)) / as.numeric(st_area(st_union(l48))), 1), drawn$period))

# 6). Check map ----
  cols <- hcl.colors(5, "viridis")
  pts <- st_transform(st_sfc(st_point(misc$ithaca), st_point(misc$nyc), crs = 4326), 5070)
  png(misc$png, width = 2400, height = 1500, res = 200)
  par(mar = c(0.5, 0.5, 2.5, 0.5))
  plot(st_geometry(l48), col = "grey95", border = NA, main = "USGS LiDAR projects on AWS, by flight year (lower 48)")
  plot(st_geometry(drawn), col = cols[match(drawn$period, misc$labels)], border = NA, add = TRUE)
  plot(st_geometry(l48), col = NA, border = "grey30", lwd = 0.6, add = TRUE)
  xy <- st_coordinates(pts)
  points(xy, pch = 21, bg = "red", col = "white", cex = 1.6, lwd = 1.5)
  text(xy[1, 1], xy[1, 2], "Ithaca", pos = 3, font = 2, cex = 0.9)
  text(xy[2, 1], xy[2, 2], "New York City", pos = 4, font = 2, cex = 0.9)
  legend("bottomleft", legend = c(misc$labels, "no project"), fill = c(cols, "grey95"), border = "grey40",
         title = "Flight year", bg = "white", box.col = "grey40", cex = 0.9, inset = 0.01)
  dev.off()

  writeLines(log_lines, misc$log)

# the end ----
