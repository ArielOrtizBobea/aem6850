# AEM 6850, session 25. Does the coverage map tell the truth? A test of USGS's LiDAR footprints against the points.
# Run in the 25-lidar-drones folder (open 25-lidar-drones.Rproj first):
#   source("tools/check_coverage.R")
# What it does:
#   Test 1. Draws 300 random points on the land of the lower 48 states. For each point inside a project footprint
#     (data/usgs_index/resources.geojson), walks that project's Entwine Point Tiles (EPT) tree on AWS down to nodes
#     about 300 m across, downloads the deepest nodes near the point and counts laser points within 300 m.
#     For each point outside every footprint, asks The National Map's API whether USGS lists LiDAR tiles nearby.
#   Test 2. Reads USGS's work-unit table (WESM.csv): collection years, quality levels, 3DEP status.
#   Task 3. Draws two check maps: New York's projects, and the Finger Lakes flight over Tompkins County's towns.
# Needs the network and curl. Downloads are cached in misc$cache (set LIDAR_CACHE to keep them between runs).
# Reads: data/usgs_index/resources.geojson; data/usgs_index/WESM.csv (downloaded here if missing);
#        ../23-spatial-vector/data_clean/states/cb_2024_us_state_500k.shp; data_clean/terrain/tompkins_towns.gpkg.
# Writes: data_clean/coverage/coverage_test.csv, data_clean/coverage/ny_projects.gpkg, logs/prep_coverage_test.txt,
#         logs/check_coverage_test.png, logs/check_zoom_ny.png, logs/check_zoom_ithaca.png.

# 1). Preliminary ----
  # Clean up workspace and load or install necessary packages if necessary
  rm(list = ls())
  want <- c("sf", "jsonlite", "rlas", "parallel")
  need <- want[!(want %in% installed.packages()[, "Package"])]
  if (length(need)) install.packages(need)
  invisible(lapply(want, function(i) suppressMessages(require(i, character.only = TRUE))))
  rm(want, need)

  suppressMessages(sf_use_s2(FALSE))
  misc <- list(index   = "data/usgs_index/resources.geojson",
               wesm    = "data/usgs_index/WESM.csv",
               wesm_url = "https://prd-tnm.s3.amazonaws.com/StagedProducts/Elevation/metadata/WESM.csv",
               states  = "../23-spatial-vector/data_clean/states/cb_2024_us_state_500k.shp",
               towns   = "data_clean/terrain/tompkins_towns.gpkg",
               ept     = "https://s3-us-west-2.amazonaws.com/usgs-lidar-public/",
               tnm     = "https://tnmaccess.nationalmap.gov/api/v1/products?datasets=Lidar%20Point%20Cloud%20(LPC)&max=1&bbox=",
               cache   = Sys.getenv("LIDAR_CACHE", file.path(tempdir(), "ept_cache")),
               out     = "data_clean/coverage/coverage_test.csv",
               ny_out  = "data_clean/coverage/ny_projects.gpkg",
               log     = "logs/prep_coverage_test.txt",
               png     = "logs/check_coverage_test.png",
               png_ny  = "logs/check_zoom_ny.png",
               png_ith = "logs/check_zoom_ithaca.png",
               seed    = 6850,
               n       = as.integer(Sys.getenv("N_POINTS", "300")),
               radius  = 300,        # metres on the ground
               max_mb  = 5,          # skip a node file larger than this
               edge_m  = 2000,       # a failure within 2 km of the footprint's outline counts as "at the edge"
               tnm_half = 0.005,     # half-width of the box sent to The National Map, degrees (about 500 m)
               cores   = 6,
               box     = c(xmin = 377600, ymin = 4700350, xmax = 378200, ymax = 4700950),   # campus, EPSG:6347
               ithaca  = c(-76.5019, 42.4440),
               nyc     = c(-73.98566, 40.74844),
               breaks  = c(-Inf, 2011, 2014, 2017, 2020, Inf),
               labels  = c("2011 or earlier", "2012-2014", "2015-2017", "2018-2020", "2021 or later"))
  dir.create(misc$cache, recursive = TRUE, showWarnings = FALSE)
  dir.create(dirname(misc$out), recursive = TRUE, showWarnings = FALSE)
  log_lines <- c(paste("Session 25 LiDAR coverage test, run", format(Sys.time(), "%Y-%m-%d %H:%M %Z")),
                 paste("sf", packageVersion("sf"), "| rlas", packageVersion("rlas"), "|", R.version.string), "")
  say <- function(...) { x <- paste0(...); log_lines <<- c(log_lines, x); cat(x, "\n") }
  rec <- function(label, expr) {
    code <- paste(deparse(substitute(expr), width.cutoff = 500), collapse = " ")
    v <- expr
    if (length(dim(v)) == 2) { say(label, ":    <- ", code); say(paste(capture.output(print(v)), collapse = "\n")); return(invisible(v)) }
    txt <- if (!is.null(names(v))) paste0(names(v), "=", format(v, trim = TRUE)) else format(v)
    say(label, ": ", paste(txt, collapse = " "), "    <- ", code)
    invisible(v)
  }
  # Wilson 95% interval for k successes out of n, in percent
  wilson <- function(k, n, z = 1.96) {
    p <- k / n; c0 <- (p + z^2 / (2 * n)) / (1 + z^2 / n)
    h <- z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2)) / (1 + z^2 / n)
    round(100 * c(p, c0 - h, c0 + h), 1)
  }
  # curl into a temporary name, then rename: parallel workers never read a half-written file.
  # Returns "ok", "too_big" (curl exit 63 under --max-filesize) or "fail".
  fetch <- function(url, file, max_bytes = NULL) {
    if (file.exists(file)) return("ok")
    tmp <- paste0(file, ".part", Sys.getpid())
    args <- c("-sSL", "--fail", "--retry", "3", "--retry-delay", "5", "-m", "180")
    if (!is.null(max_bytes)) args <- c(args, "--max-filesize", format(max_bytes, scientific = FALSE))
    code <- suppressWarnings(system2("curl", c(args, "-o", shQuote(tmp), shQuote(url)), stdout = FALSE, stderr = FALSE))
    if (code == 0 && file.exists(tmp)) { file.rename(tmp, file); return("ok") }
    unlink(tmp)
    if (code == 63) "too_big" else "fail"
  }

# 2). The footprints, the states and 300 random points on land ----
  idx <- st_read(misc$index, quiet = TRUE)
  # flight year from the name, as tools/make_coverage.R reads it
  yr <- regmatches(idx$name, regexpr("(199[0-9]|20[0-2][0-9])", idx$name))
  idx$year <- NA_integer_; idx$year[grepl("(199[0-9]|20[0-2][0-9])", idx$name)] <- as.integer(yr)
  code <- is.na(idx$year) & grepl("_[A-Z][0-9]{2}$", idx$name)
  idx$year[code] <- 2000L + as.integer(sub(".*_[A-Z]([0-9]{2})$", "\\1", idx$name[code]))
  idx_5070 <- st_make_valid(st_transform(st_make_valid(idx), 5070))
  st  <- st_read(misc$states, quiet = TRUE)
  l48 <- st_transform(st[!st$STUSPS %in% c("AK", "HI", "PR", "VI", "GU", "MP", "AS"), ], 5070)
  land <- st_union(l48)
  set.seed(misc$seed)
  pts <- st_sf(id = seq_len(misc$n), geometry = st_sample(land, misc$n, exact = TRUE))
  rec("Random points drawn on land (seed 6850, EPSG:5070, uniform by area)", nrow(pts))
  pts$state <- l48$STUSPS[st_nearest_feature(pts, l48)]
  ll <- st_coordinates(st_transform(pts, 4326)); pts$lon <- ll[, 1]; pts$lat <- ll[, 2]
  hit <- st_intersects(pts, idx_5070)
  pts$n_footprints <- lengths(hit)
  pts$inside <- pts$n_footprints > 0
  # projects newest first: the first one tested is the newest flight
  pts$projects <- vapply(hit, function(i) paste(idx$name[i][order(-idx$year[i], idx$name[i])], collapse = ";"), "")
  rec("Points inside at least one footprint", sum(pts$inside))
  rec("Points outside every footprint", sum(!pts$inside))
  # distance from each inside point to the outline of the union of the footprints that hold it, metres
  pts$edge_dist_m <- NA_real_
  for (i in which(pts$inside)) {
    u <- st_union(idx_5070[hit[[i]], ])
    pts$edge_dist_m[i] <- round(as.numeric(st_distance(pts[i, ], st_cast(st_boundary(u), "MULTILINESTRING"))))
  }

# 3). Test 1: walk each project's EPT tree and count laser points within 300 m ----
  # ept.json gives the cube (EPSG:3857). Node D-X-Y-Z covers min + (X,Y,Z) * side / 2^D. A hierarchy file maps keys to
  # point counts; -1 means the subtree's keys sit in their own hierarchy file. Nodes are additive across depths.
  ept_info <- function(p) {
    f <- file.path(misc$cache, p, "ept.json"); dir.create(dirname(f), showWarnings = FALSE)
    if (fetch(paste0(misc$ept, p, "/ept.json"), f) != "ok") return(NULL)
    fromJSON(f)
  }
  hier <- function(p, key) {
    f <- file.path(misc$cache, p, paste0("h-", key, ".json"))
    if (fetch(paste0(misc$ept, p, "/ept-hierarchy/", key, ".json"), f) != "ok") return(NULL)
    unlist(fromJSON(f))
  }
  test_one <- function(p, x, y, r) {
    info <- ept_info(p)
    if (is.null(info)) return(list(status = "no ept.json"))
    b <- info$bounds; side <- b[4] - b[1]
    d_target <- max(0, round(log2(side / r)))            # nodes about r map units (300 m on the ground) across
    meets <- function(keys) {
      k <- do.call(rbind, lapply(strsplit(keys, "-"), as.numeric)); s <- side / 2^k[, 1]
      x0 <- b[1] + k[, 2] * s; y0 <- b[2] + k[, 3] * s
      k[, 1] <= d_target & x0 < x + r & x0 + s > x - r & y0 < y + r & y0 + s > y - r
    }
    keys <- c(); todo <- "0-0-0-0"; nh <- 0
    while (length(todo)) {
      h <- hier(p, todo[1]); todo <- todo[-1]; nh <- nh + 1
      if (is.null(h)) return(list(status = "hierarchy failed"))
      h <- h[meets(names(h))]
      keys <- c(keys, names(h)[h > 0])
      todo <- c(todo, setdiff(names(h)[h == -1], c(keys, todo)))
    }
    keys <- unique(keys)
    depth <- as.integer(sub("-.*", "", keys))
    out <- list(status = "walked", d_target = d_target, node_m = round(side / 2^d_target * cos(atan(sinh(y / 6378137)))),
                deepest = max(depth), n_keys = length(keys), n_hier = nh, files = 0, mb = 0, skipped = 0, n_pts = 0,
                levels = 0)
    # the deepest level first, then up the tree until a level gives a laser point within r (a failure checks every level)
    for (d in sort(unique(depth), decreasing = TRUE)) {
      out$levels <- out$levels + 1
      for (k in keys[depth == d]) {
        f <- file.path(misc$cache, p, paste0(k, ".laz"))
        s <- fetch(paste0(misc$ept, p, "/ept-data/", k, ".laz"), f, misc$max_mb * 1e6)
        if (s == "too_big") { out$skipped <- out$skipped + 1; next }
        if (s != "ok") { out$skipped <- out$skipped + 1; next }
        xyz <- tryCatch(read.las(f, select = "xyz"), error = function(e) NULL)
        if (is.null(xyz)) { out$skipped <- out$skipped + 1; next }
        out$files <- out$files + 1; out$mb <- out$mb + file.size(f) / 1e6
        out$n_pts <- out$n_pts + sum((xyz$X - x)^2 + (xyz$Y - y)^2 <= r^2)
      }
      if (out$n_pts > 0) break
    }
    out
  }
  xy <- st_coordinates(st_transform(pts, 3857))
  pts$x3857 <- xy[, 1]; pts$y3857 <- xy[, 2]
  pts$r_map <- misc$radius / cos(pts$lat * pi / 180)       # Web Mercator stretches distance by 1/cos(latitude)
  test_point <- function(i) {
    pr <- strsplit(pts$projects[i], ";")[[1]]; res <- list()
    for (p in pr) {
      o <- tryCatch(test_one(p, pts$x3857[i], pts$y3857[i], pts$r_map[i]), error = function(e) list(status = conditionMessage(e)))
      o$project <- p; res[[p]] <- o
      if (!is.null(o$n_pts) && o$n_pts > 0) break
    }
    res
  }
  inside <- which(pts$inside)
  t0 <- Sys.time()
  results <- mclapply(inside, test_point, mc.cores = misc$cores, mc.preschedule = FALSE)
  say("TIME EPT test of ", length(inside), " points: ", round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1), " min")
  get_field <- function(r, f) vapply(r, function(o) if (is.null(o[[f]])) NA_character_ else as.character(o[[f]]), "")
  pts$tested <- NA_character_; pts$n_laser_300m <- NA_integer_; pts$pass <- NA; pts$pass_project <- NA_character_
  pts$node_m <- NA_real_; pts$deepest_depth <- NA_integer_; pts$files_read <- NA_integer_; pts$mb_read <- NA_real_
  pts$files_skipped <- NA_integer_; pts$status <- NA_character_
  for (j in seq_along(inside)) {
    i <- inside[j]; r <- results[[j]]
    if (inherits(r, "try-error")) { pts$status[i] <- "worker error"; next }
    n <- as.integer(get_field(r, "n_pts")); n[is.na(n)] <- 0L
    pts$tested[i]        <- paste(names(r), collapse = ";")
    pts$n_laser_300m[i]  <- max(n)
    pts$pass[i]          <- any(n > 0)
    pts$pass_project[i]  <- if (any(n > 0)) names(r)[which(n > 0)[1]] else NA
    last <- r[[if (any(n > 0)) which(n > 0)[1] else 1]]
    pts$node_m[i]        <- if (is.null(last$node_m)) NA else last$node_m
    pts$deepest_depth[i] <- if (is.null(last$deepest)) NA else last$deepest
    pts$files_read[i]    <- sum(as.integer(get_field(r, "files")), na.rm = TRUE)
    pts$mb_read[i]       <- round(sum(as.numeric(get_field(r, "mb")), na.rm = TRUE), 2)
    pts$files_skipped[i] <- sum(as.integer(get_field(r, "skipped")), na.rm = TRUE)
    pts$status[i]        <- paste(unique(get_field(r, "status")), collapse = ";")
  }
  ok <- pts$inside & !is.na(pts$pass)
  rec("Inside points tested", sum(ok))
  rec("Statuses of the walks", table(pts$status[pts$inside], useNA = "ifany"))
  rec("Node files read, total", sum(pts$files_read, na.rm = TRUE))
  rec("Node files skipped (over 5 MB or failed), total", sum(pts$files_skipped, na.rm = TRUE))
  rec("Target node width on the ground, m: min, median, max", as.numeric(quantile(pts$node_m, c(0, .5, 1), na.rm = TRUE)))
  rec("Inside points with laser points within 300 m", sum(pts$pass[ok]))
  rec("Share of inside points that pass, % and Wilson 95% interval", wilson(sum(pts$pass[ok]), sum(ok)))
  rec("Inside points that pass with a project other than the newest footprint", sum(pts$pass[ok] & pts$pass_project[ok] != sub(";.*", "", pts$projects[ok])))
  rec("Laser points within 300 m among passes: min, median, max", as.numeric(quantile(pts$n_laser_300m[ok & pts$pass], c(0, .5, 1))))
  sh <- wilson(sum(pts$pass[ok]), sum(ok)) / 100
  rec("Corrected land share with real points, % (88.0 x pass share; x interval ends)", round(88.0 * sh, 1))
  rec("Direct share: passes over all random points, % and Wilson 95% interval", wilson(sum(pts$pass, na.rm = TRUE), misc$n))
  fails <- pts[ok & !pts$pass, ]
  say("", "Failures (inside a footprint, no laser point within 300 m):")
  if (nrow(fails)) say(paste(sprintf("  id %3d %s %.4f,%.4f edge %6.0f m, nodes to depth %s, projects %s",
                                     fails$id, fails$state, fails$lon, fails$lat, fails$edge_dist_m, fails$deepest_depth,
                                     fails$tested), collapse = "\n"))

# 4). Test 1, outside points: does The National Map list LiDAR tiles there? ----
  pts$tnm_total <- NA_integer_; pts$tnm_title <- NA_character_
  out_i <- which(!pts$inside)
  for (i in out_i) {
    bb <- paste(round(c(pts$lon[i] - misc$tnm_half, pts$lat[i] - misc$tnm_half,
                        pts$lon[i] + misc$tnm_half, pts$lat[i] + misc$tnm_half), 4), collapse = ",")
    f <- file.path(misc$cache, sprintf("tnm_%03d.json", pts$id[i]))
    if (!file.exists(f)) { fetch(paste0(misc$tnm, bb), f); Sys.sleep(1) }
    j <- tryCatch(fromJSON(f), error = function(e) NULL)
    if (is.null(j$total)) next
    pts$tnm_total[i] <- j$total
    if (j$total > 0) pts$tnm_title[i] <- j$items$title[1]
  }
  rec("Outside points with an answer from The National Map", sum(!is.na(pts$tnm_total[out_i])))
  rec("Outside points where USGS lists LiDAR tiles within ~500 m", sum(pts$tnm_total[out_i] > 0, na.rm = TRUE))
  say("Outside points, state | lon,lat | tiles listed | first tile:")
  say(paste(sprintf("  id %3d %s %.4f,%.4f %5s %s", pts$id[out_i], pts$state[out_i], pts$lon[out_i], pts$lat[out_i],
                    pts$tnm_total[out_i], ifelse(is.na(pts$tnm_title[out_i]), "", pts$tnm_title[out_i])), collapse = "\n"))
  pts$class <- ifelse(pts$inside, ifelse(is.na(pts$pass), "inside, not tested", ifelse(pts$pass, "passed", "failed")),
                      ifelse(is.na(pts$tnm_total), "outside, no answer",
                             ifelse(pts$tnm_total > 0, "outside, USGS lists LiDAR", "outside, none listed")))
  rec("Classes of the 300 points", table(pts$class))
  out <- st_drop_geometry(pts); out$r_map <- round(out$r_map, 1)
  write.csv(out, misc$out, row.names = FALSE)
  rec("coverage_test.csv rows", nrow(out))

# 5). Check map: the 300 points on the coverage map ----
  cols  <- hcl.colors(5, "viridis")
  drawn <- st_read("data_clean/coverage/usgs_lidar_by_year.gpkg", quiet = TRUE)
  key   <- c("passed" = "white", "failed" = "red", "outside, USGS lists LiDAR" = "orange", "outside, none listed" = "black",
             "outside, no answer" = "grey50", "inside, not tested" = "grey50")
  shp   <- c("passed" = 21, "failed" = 24, "outside, USGS lists LiDAR" = 22, "outside, none listed" = 4,
             "outside, no answer" = 1, "inside, not tested" = 1)
  png(misc$png, width = 2400, height = 1500, res = 200)
  par(mar = c(0.5, 0.5, 2.5, 0.5))
  plot(st_geometry(l48), col = "grey95", border = NA, main = "300 random points on land: laser points within 300 m?")
  plot(st_geometry(drawn), col = adjustcolor(cols[match(drawn$period, misc$labels)], 0.55), border = NA, add = TRUE)
  plot(st_geometry(l48), col = NA, border = "grey30", lwd = 0.6, add = TRUE)
  xy <- st_coordinates(pts)
  points(xy, pch = shp[pts$class], bg = key[pts$class], col = ifelse(pts$class == "passed", "black", key[pts$class]),
         cex = 1.1, lwd = ifelse(pts$class == "outside, none listed", 2, 1))
  used <- names(key)[names(key) %in% pts$class]
  tab <- table(pts$class)[used]
  legend("bottomleft", legend = paste0(used, " (", tab, ")"), pch = shp[used], pt.bg = key[used],
         col = ifelse(used == "passed", "black", key[used]), title = "Random point", bg = "white", cex = 0.85, inset = 0.01)
  legend("bottomright", legend = misc$labels, fill = adjustcolor(cols, 0.55), border = "grey40", title = "Flight year",
         bg = "white", cex = 0.8, inset = 0.01)
  dev.off()

# 6). Test 2: USGS's work-unit table (WESM) ----
  if (!file.exists(misc$wesm)) fetch(misc$wesm_url, misc$wesm)
  w <- read.csv(misc$wesm, stringsAsFactors = FALSE)
  say("")
  rec("WESM.csv size, MB", round(file.size(misc$wesm) / 1e6, 2))
  rec("WESM columns", names(w))
  rec("Work units (rows)", nrow(w))
  rec("Distinct work units / projects", c(length(unique(w$workunit)), length(unique(w$project))))
  w$start <- as.integer(substr(w$collect_start, 1, 4))
  rec("Collection start years: min, median, max", as.numeric(quantile(w$start, c(0, .5, 1), na.rm = TRUE)))
  rec("Work units by collection start year", table(w$start, useNA = "ifany"))
  w$period <- cut(w$start, c(-Inf, 2004, 2009, 2014, 2019, Inf), labels = c("before 2005", "2005-2009", "2010-2014", "2015-2019", "2020 or later"))
  rec("Work units by five-year period of collection start", table(w$period, useNA = "ifany"))
  rec("Quality level (ql)", table(w$ql, useNA = "ifany"))
  rec("Quality level by five-year period", table(w$period, w$ql))
  rec("spec (Lidar Base Specification version)", table(w$spec, useNA = "ifany"))
  rec("lpc_category (point cloud meets 3DEP?)", table(w$lpc_category, useNA = "ifany"))
  rec("Share of work units whose point cloud 'Meets', %", round(100 * mean(w$lpc_category == "Meets"), 1))
  rec("Area columns in WESM", grep("area|sqkm|sq_|acre", names(w), value = TRUE, ignore.case = TRUE))
  # AWS project names against WESM work units: an exact match gives WESM's collection year
  rec("AWS projects whose name is a WESM work unit", sum(idx$name %in% w$workunit))
  pass <- pts[!is.na(pts$pass) & pts$pass, ]
  pass$year_name <- idx$year[match(pass$pass_project, idx$name)]
  pass$year_wesm <- w$start[match(pass$pass_project, w$workunit)]
  pass$year_flight <- ifelse(is.na(pass$year_wesm), pass$year_name, pass$year_wesm)
  rec("Passed points whose project matches a WESM work unit", sum(!is.na(pass$year_wesm)))
  rec("Passed points: flight year of the newest project with points (WESM start, else the name)", table(pass$year_flight, useNA = "ifany"))
  rec("Passed points by period", table(cut(pass$year_flight, misc$breaks, labels = misc$labels), useNA = "ifany"))
  rec("Passed points whose newest flight with points is older than 2015", sum(pass$year_flight < 2015, na.rm = TRUE))
  # the newest footprint over each passed point, whether or not it gave points
  newest_fp <- vapply(strsplit(pass$projects, ";"), function(p) max(idx$year[match(p, idx$name)], na.rm = TRUE), 0)
  rec("Passed points whose newest footprint (any) is older than 2015", sum(newest_fp < 2015))

# 7). Task 3: New York's projects, and the Finger Lakes flight over Tompkins County ----
  ny  <- st_transform(st[st$STUSPS == "NY", ], 5070)
  nyp <- idx_5070[st_intersects(idx_5070, ny, sparse = FALSE)[, 1], c("name", "count", "year")]
  nyp$period <- cut(nyp$year, misc$breaks, labels = misc$labels)
  st_write(nyp, misc$ny_out, delete_dsn = TRUE, quiet = TRUE)
  rec("ny_projects.gpkg: projects touching New York", nrow(nyp))
  fl <- nyp[nyp$name == "NY_FingerLakes_1_2020", ]
  cities <- st_transform(st_sfc(st_point(misc$ithaca), st_point(misc$nyc), crs = 4326), 5070)
  nyp <- nyp[order(nyp$year, na.last = FALSE), ]    # newest drawn on top
  bb  <- st_bbox(ny)
  png(misc$png_ny, width = 2000, height = 1600, res = 200)
  par(mar = c(0.5, 0.5, 2.5, 0.5))
  plot(st_geometry(ny), col = "grey95", border = NA, main = "New York State: USGS LiDAR projects on AWS",
       xlim = bb[c(1, 3)], ylim = bb[c(2, 4)])
  plot(st_geometry(nyp), col = adjustcolor(cols[as.integer(nyp$period)], 0.6), border = "grey40", lwd = 0.3, add = TRUE)
  plot(st_geometry(l48), col = NA, border = "grey20", lwd = 0.8, add = TRUE)
  plot(st_geometry(fl), col = NA, border = "red", lwd = 2.5, add = TRUE)
  cxy <- st_coordinates(cities)
  points(cxy, pch = 21, bg = "red", col = "white", cex = 1.6, lwd = 1.5)
  text(cxy[, 1], cxy[, 2], c("Ithaca", "New York City"), pos = c(3, 4), font = 2, cex = 0.9)
  legend("topleft", legend = c(misc$labels, "NY_FingerLakes_1_2020"), fill = c(adjustcolor(cols, 0.6), NA),
         border = c(rep("grey40", 5), "red"), title = "Flight year", bg = "white", cex = 0.8, inset = 0.01)
  dev.off()

  towns <- st_read(misc$towns, quiet = TRUE)
  fl_t  <- st_transform(fl, st_crs(towns))
  campus <- st_transform(st_as_sfc(st_bbox(misc$box, crs = 6347)), st_crs(towns))
  rec("Campus box inside the Finger Lakes footprint", as.vector(st_within(campus, fl_t, sparse = FALSE)))
  cb <- st_bbox(campus); cc <- c(mean(cb[c(1, 3)]), mean(cb[c(2, 4)])); half <- 1500   # draw the square 3 km wide
  png(misc$png_ith, width = 2000, height = 1800, res = 200)
  par(mar = c(0.5, 0.5, 2.5, 0.5))
  plot(st_geometry(towns), col = "grey92", border = "grey30", main = "Tompkins County towns and the Finger Lakes LiDAR flight")
  plot(st_geometry(st_intersection(fl_t, st_union(towns))), col = adjustcolor(cols[4], 0.35), border = NA, add = TRUE)
  plot(st_geometry(towns), col = NA, border = "grey30", add = TRUE)
  plot(st_geometry(fl_t), col = NA, border = "red", lwd = 1.5, lty = 2, add = TRUE)
  rect(cc[1] - half, cc[2] - half, cc[1] + half, cc[2] + half, border = "red", lwd = 3)
  text(cc[1] + half, cc[2] + half, "Campus box, 600 x 600 m\n(square drawn 3 km wide)", pos = 4, col = "red", font = 2, cex = 0.8)
  tc <- st_coordinates(st_point_on_surface(towns)); text(tc, towns$NAME, cex = 0.75, col = "grey20")
  legend("bottomleft", legend = c("NY_FingerLakes_1_2020 (2020)", "campus box"), fill = c(adjustcolor(cols[4], 0.35), NA),
         border = c("red", "red"), bg = "white", cex = 0.8, inset = 0.01)
  dev.off()

  writeLines(log_lines, misc$log)

# the end ----
