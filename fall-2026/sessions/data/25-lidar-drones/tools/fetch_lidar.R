# AEM 6850, session 25. Downloads the USGS LiDAR points over Cornell's central campus, as fetched on 2026-11-23.
# Run once, in the 25-lidar-drones folder (open 25-lidar-drones.Rproj first):
#   source("tools/fetch_lidar.R")
# Needs the network and curl. The class does not need it: data_clean/lidar/ holds what the slides read.
# Source used: USGS's public copy of the flight on Amazon Web Services (AWS), project NY_FingerLakes_1_2020,
#   stored as Entwine Point Tiles (EPT): https://s3-us-west-2.amazonaws.com/usgs-lidar-public/NY_FingerLakes_1_2020/ept.json
#   EPT cuts the cloud into a tree of cubes (nodes) in Web Mercator (EPSG:3857). This script walks the tree and
#   downloads every node whose footprint touches the campus box, about 32 MB (89 nodes). tools/make_lidar.R joins them.
# Original tiles (same flight, NY_FingerLakes_2020_A20, listed by the National Map's API):
#   https://tnmaccess.nationalmap.gov/api/v1/products?datasets=Lidar%20Point%20Cloud%20(LPC)&bbox=-76.487,42.446,-76.483,42.449
#   Section 3 fetches them only when misc$tiles_too is TRUE: rockyweb.usgs.gov was rate-limited and stalled on 2026-11-23.
# Reads: nothing. Writes: data/lidar/ept/ (ept.json, the hierarchy files used, ept-data/*.laz),
#   data/lidar/*.xml (tile metadata), and data/lidar/*.laz (original tiles, optional).

# 1). Preliminary ----
  # Clean up workspace and load or install necessary packages if necessary
  want <- c("jsonlite", "sf")
  need <- want[!(want %in% installed.packages()[, "Package"])]
  if (length(need)) install.packages(need)
  invisible(lapply(want, function(i) suppressMessages(require(i, character.only = TRUE))))
  rm(want, need)

  misc <- list(ept       = "https://s3-us-west-2.amazonaws.com/usgs-lidar-public/NY_FingerLakes_1_2020/",
               box       = c(xmin = 377600, ymin = 4700350, xmax = 378200, ymax = 4700950),   # EPSG:6347, metres
               pad       = 20,                                                                 # metres around the box
               dir       = "data/lidar",
               tiles     = c("u_3765069950", "u_3780069950"),
               laz       = "https://rockyweb.usgs.gov/vdelivery/Datasets/Staged/Elevation/LPC/Projects/NY_FingerLakes_2020_A20/NY_FingerLakes_1_2020/LAZ/",
               meta      = "https://prd-tnm.s3.amazonaws.com/StagedProducts/Elevation/LPC/Projects/NY_FingerLakes_2020_A20/NY_FingerLakes_1_2020/metadata/",
               tiles_too = FALSE)
  for (d in file.path(misc$dir, c("ept/ept-hierarchy", "ept/ept-data"))) dir.create(d, recursive = TRUE, showWarnings = FALSE)
  # curl resumes a broken download (-C -) and retries when the server is busy; a file already on disk is skipped
  get <- function(url, file, size = NA) {
    if (file.exists(file) && (is.na(size) || file.size(file) == size)) return(invisible())
    system2("curl", c("-sSL", "--fail", "--retry", "10", "--retry-delay", "20", "--retry-all-errors",
                      "-C", "-", "-o", shQuote(file), shQuote(url)))
  }

# 2). AWS copy: walk the EPT tree, keep the nodes that touch the box ----
  get(paste0(misc$ept, "ept.json"), file.path(misc$dir, "ept/ept.json"))
  info <- fromJSON(file.path(misc$dir, "ept/ept.json"))
  b    <- st_bbox(st_transform(st_as_sfc(st_bbox(misc$box, crs = 6347)), 3857))
  b    <- b + c(-1, -1, 1, 1) * misc$pad
  side <- info$bounds[4] - info$bounds[1]
  touches <- function(key) {
    k <- as.numeric(strsplit(key, "-")[[1]]); s <- side / 2^k[1]
    x0 <- info$bounds[1] + k[2] * s; y0 <- info$bounds[2] + k[3] * s
    x0 < b[["xmax"]] && x0 + s > b[["xmin"]] && y0 < b[["ymax"]] && y0 + s > b[["ymin"]]
  }
  # a hierarchy file lists nodes and point counts; -1 means "the rest of this subtree is in its own file"
  keep <- character(0); todo <- "0-0-0-0"; used <- character(0)
  while (length(todo)) {
    h_key <- todo[1]; todo <- todo[-1]
    f <- file.path(misc$dir, "ept/ept-hierarchy", paste0(h_key, ".json"))
    get(paste0(misc$ept, "ept-hierarchy/", h_key, ".json"), f); used <- c(used, h_key)
    h <- unlist(fromJSON(f))
    h <- h[vapply(names(h), touches, logical(1))]
    keep <- c(keep, names(h)[h > 0])
    todo <- c(todo, setdiff(names(h)[h == -1], h_key))
  }
  keep <- unique(keep)
  # delete hierarchy files that were downloaded but not needed (none, by construction) and fetch the nodes, 8 at a time
  urls  <- paste0(misc$ept, "ept-data/", keep, ".laz")
  files <- file.path(misc$dir, "ept/ept-data", paste0(keep, ".laz"))
  miss  <- !file.exists(files)
  if (any(miss)) {
    cfg <- tempfile(); writeLines(paste0('url = "', urls[miss], '"\noutput = "', files[miss], '"'), cfg)
    system2("curl", c("-sSL", "--fail", "--retry", "5", "--parallel", "--parallel-max", "8", "-K", shQuote(cfg)))
  }
  stopifnot(all(file.exists(files)))
  depth <- max(as.integer(sub("-.*", "", keep)))
  cat("EPT nodes touching the box:", length(keep), "| hierarchy files used:", length(used),
      "| deepest depth:", depth, "| MB:", round(sum(file.size(files)) / 1e6, 1), "\n")

# 3). Original tiles (optional) and their metadata ----
  sizes <- c(u_3765069950 = 86046801, u_3780069950 = 81058728)   # bytes, as the TNM API listed them
  for (t in misc$tiles) {
    f <- paste0("USGS_LPC_NY_FingerLakes_2020_A20_", t)
    get(paste0(misc$meta, f, ".xml"), file.path(misc$dir, paste0(f, ".xml")))
    if (misc$tiles_too) get(paste0(misc$laz, f, ".laz"), file.path(misc$dir, paste0(f, ".laz")), sizes[[t]])
  }

# the end ----
