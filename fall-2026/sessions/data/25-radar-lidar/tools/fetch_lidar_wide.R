# AEM 6850, session 25. Downloads the USGS LiDAR points over a wider view of Cornell's campus, for the figures only.
# Run once, in the 25-radar-lidar folder (open 25-radar-lidar.Rproj first):
#   source("tools/fetch_lidar_wide.R")
# Needs the network and curl. The class does not need it: the students read the 600 m square in data_clean/lidar/.
# The box: 1.6 x 1.6 km, from Cascadilla Gorge in the south to Fall Creek gorge and Balch Hall in the north,
#   and from west of Libe Slope to Beebe Lake in the east. It holds McGraw Tower, the Arts Quad, the Ag Quad and
#   Warren Hall. Landmark positions came from OpenStreetMap (see logs/prep_lidar_wide.txt).
# Source used: USGS's public copy of the flight on Amazon Web Services (AWS), project NY_FingerLakes_1_2020,
#   stored as Entwine Point Tiles (EPT): https://s3-us-west-2.amazonaws.com/usgs-lidar-public/NY_FingerLakes_1_2020/ept.json
#   EPT cuts the cloud into a tree of cubes (nodes) in Web Mercator (EPSG:3857). This script walks the tree and
#   downloads every node whose footprint touches the box. tools/make_lidar_wide.R joins them.
# Reads: nothing. Writes: data/lidar_wide/ept/ (ept.json, the hierarchy files used, ept-data/*.laz),
#   data/lidar_wide/fetch_summary.txt (node count, MB, time).

# 1). Preliminary ----
  # Clean up workspace and load or install necessary packages if necessary
  want <- c("jsonlite", "sf")
  need <- want[!(want %in% installed.packages()[, "Package"])]
  if (length(need)) install.packages(need)
  invisible(lapply(want, function(i) suppressMessages(require(i, character.only = TRUE))))
  rm(want, need)

  misc <- list(ept = "https://s3-us-west-2.amazonaws.com/usgs-lidar-public/NY_FingerLakes_1_2020/",
               box = c(xmin = 377400, ymin = 4699800, xmax = 379000, ymax = 4701400),   # EPSG:6347, metres
               pad = 20,                                                                 # metres around the box
               dir = "data/lidar_wide")
  for (d in file.path(misc$dir, c("ept/ept-hierarchy", "ept/ept-data"))) dir.create(d, recursive = TRUE, showWarnings = FALSE)
  t_start <- Sys.time()
  # curl resumes a broken download (-C -) and retries when the server is busy; a file already on disk is skipped
  get <- function(url, file) {
    if (file.exists(file)) return(invisible())
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
  # fetch the nodes, 8 at a time
  urls  <- paste0(misc$ept, "ept-data/", keep, ".laz")
  files <- file.path(misc$dir, "ept/ept-data", paste0(keep, ".laz"))
  miss  <- !file.exists(files)
  if (any(miss)) {
    cfg <- tempfile(); writeLines(paste0('url = "', urls[miss], '"\noutput = "', files[miss], '"'), cfg)
    system2("curl", c("-sSL", "--fail", "--retry", "5", "--parallel", "--parallel-max", "8", "-K", shQuote(cfg)))
  }
  stopifnot(all(file.exists(files)))
  depth <- max(as.integer(sub("-.*", "", keep)))
  out <- c(paste("Fetched", format(Sys.time(), "%Y-%m-%d %H:%M %Z"), "from", misc$ept),
           paste("EPT nodes touching the box:", length(keep), "| hierarchy files used:", length(used),
                 "| deepest depth:", depth, "| MB:", round(sum(file.size(files)) / 1e6, 1),
                 "| seconds:", round(as.numeric(difftime(Sys.time(), t_start, units = "secs")), 1)))
  cat(out, sep = "\n")
  # the summary keeps the first, real download time; a re-run with every node on disk does not overwrite it
  if (any(miss) || !file.exists(file.path(misc$dir, "fetch_summary.txt"))) writeLines(out, file.path(misc$dir, "fetch_summary.txt"))

# the end ----
