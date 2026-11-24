# AEM 6850, session 25. Downloads the USGS LiDAR points around a New York City skyscraper, as fetched on 2026-11-23.
# Run once, in the 25-lidar-drones folder (open 25-lidar-drones.Rproj first):
#   source("tools/fetch_nyc.R")                       # the Empire State Building, 400 x 400 m
#   Rscript tools/fetch_nyc.R owtc                     # One World Trade Center (the size check only)
# Needs the network and curl. The class does not need it: data_clean/lidar_nyc/ holds what the slides read.
# Source used: USGS's public copy on Amazon Web Services (AWS), project NY_NewYorkCity, stored as Entwine Point
#   Tiles (EPT): https://s3-us-west-2.amazonaws.com/usgs-lidar-public/NY_NewYorkCity/ept.json
#   EPT cuts the cloud into a tree of cubes (nodes) in Web Mercator (EPSG:3857). This script walks the tree and
#   downloads every node whose footprint touches the box (the routine of tools/fetch_lidar.R).
# Reads: nothing. Writes: data/lidar_nyc/ept.json, data/lidar_nyc/<target>/ept-hierarchy/*.json,
#   data/lidar_nyc/<target>/ept-data/*.laz, data/lidar_nyc/<target>/fetch.txt (nodes, MB, seconds).

# 1). Preliminary ----
  # Clean up workspace and load or install necessary packages if necessary
  want <- c("jsonlite", "sf")
  need <- want[!(want %in% installed.packages()[, "Package"])]
  if (length(need)) install.packages(need)
  invisible(lapply(want, function(i) suppressMessages(require(i, character.only = TRUE))))
  rm(want, need)

  targets <- list(esb  = c(lon = -73.98566, lat = 40.74844),    # Empire State Building
                  owtc = c(lon = -74.01338, lat = 40.71274))    # One World Trade Center
  args <- commandArgs(trailingOnly = TRUE)
  misc <- list(ept    = "https://s3-us-west-2.amazonaws.com/usgs-lidar-public/NY_NewYorkCity/",
               target = if (length(args)) args[1] else "esb",
               half   = if (length(args) > 1) as.numeric(args[2]) / 2 else 200,   # metres from the centre to the box edge
               pad    = 20,                                                        # metres around the box
               dir    = "data/lidar_nyc")
  misc$sub <- file.path(misc$dir, misc$target)
  for (d in file.path(misc$sub, c("ept-hierarchy", "ept-data"))) dir.create(d, recursive = TRUE, showWarnings = FALSE)
  get <- function(url, file) {
    if (file.exists(file)) return(invisible())
    system2("curl", c("-sSL", "--fail", "--retry", "10", "--retry-delay", "20", "--retry-all-errors",
                      "-C", "-", "-o", shQuote(file), shQuote(url)))
  }

# 2). The box, in NAD83(2011) / UTM zone 18N (EPSG:6347), metres ----
  ctr <- st_coordinates(st_transform(st_sfc(st_point(targets[[misc$target]]), crs = 4326), 6347))[1, ]
  box <- c(xmin = ctr[[1]] - misc$half, ymin = ctr[[2]] - misc$half, xmax = ctr[[1]] + misc$half, ymax = ctr[[2]] + misc$half)

# 3). Walk the EPT tree, keep the nodes that touch the box ----
  t0 <- Sys.time()
  get(paste0(misc$ept, "ept.json"), file.path(misc$dir, "ept.json"))
  info <- fromJSON(file.path(misc$dir, "ept.json"))
  b    <- st_bbox(st_transform(st_as_sfc(st_bbox(box, crs = 6347)), 3857))
  b    <- b + c(-1, -1, 1, 1) * misc$pad
  side <- info$bounds[4] - info$bounds[1]
  touches <- function(key) {
    k <- as.numeric(strsplit(key, "-")[[1]]); s <- side / 2^k[1]
    x0 <- info$bounds[1] + k[2] * s; y0 <- info$bounds[2] + k[3] * s
    x0 < b[["xmax"]] && x0 + s > b[["xmin"]] && y0 < b[["ymax"]] && y0 + s > b[["ymin"]]
  }
  # a hierarchy file lists nodes and point counts; -1 means "the rest of this subtree is in its own file"
  keep <- character(0); counts <- numeric(0); todo <- "0-0-0-0"; used <- character(0)
  while (length(todo)) {
    h_key <- todo[1]; todo <- todo[-1]
    f <- file.path(misc$sub, "ept-hierarchy", paste0(h_key, ".json"))
    get(paste0(misc$ept, "ept-hierarchy/", h_key, ".json"), f); used <- c(used, h_key)
    h <- unlist(fromJSON(f))
    h <- h[vapply(names(h), touches, logical(1))]
    keep <- c(keep, names(h)[h > 0]); counts <- c(counts, h[h > 0])
    todo <- c(todo, setdiff(names(h)[h == -1], h_key))
  }
  counts <- counts[!duplicated(keep)]; keep <- unique(keep)
  t_walk <- as.numeric(difftime(Sys.time(), t0, units = "secs"))

# 4). Download the nodes, 8 at a time ----
  urls  <- paste0(misc$ept, "ept-data/", keep, ".laz")
  files <- file.path(misc$sub, "ept-data", paste0(keep, ".laz"))
  miss  <- !file.exists(files)
  t1 <- Sys.time()
  if (any(miss)) {
    cfg <- tempfile(); writeLines(paste0('url = "', urls[miss], '"\noutput = "', files[miss], '"'), cfg)
    system2("curl", c("-sSL", "--fail", "--retry", "5", "--parallel", "--parallel-max", "8", "-K", shQuote(cfg)))
  }
  t_get <- as.numeric(difftime(Sys.time(), t1, units = "secs"))
  stopifnot(all(file.exists(files)))
  msg <- c(paste0("Target ", misc$target, ", box ", 2 * misc$half, " x ", 2 * misc$half, " m centred on EPSG:6347 x ",
                  round(ctr[[1]], 1), ", y ", round(ctr[[2]], 1)),
           paste0("EPT nodes touching the box: ", length(keep), " | hierarchy files used: ", length(used),
                  " | deepest depth: ", max(as.integer(sub("-.*", "", keep))),
                  " | points in those nodes (hierarchy counts): ", sum(counts),
                  " | MB: ", round(sum(file.size(files)) / 1e6, 1)),
           paste0("Seconds: walking the hierarchy ", round(t_walk, 1), ", downloading ", sum(miss), " nodes ", round(t_get, 1),
                  if (!any(miss)) " (all on disk already)" else ""))
  cat(msg, sep = "\n"); writeLines(msg, file.path(misc$sub, "fetch.txt"))

# the end ----
