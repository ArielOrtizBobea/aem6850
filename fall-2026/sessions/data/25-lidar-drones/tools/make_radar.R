# AEM 6850, session 25. Builds the radar elevation grid of Tompkins County and compares it with USGS and LiDAR.
# Run in the 25-lidar-drones folder, after tools/fetch_radar.R, tools/make_terrain.R and tools/make_lidar.R:
#   source("tools/make_radar.R")
# What it does: reads the Copernicus DEM GLO-30 tile (TanDEM-X radar), logs its facts, projects it onto the
#   30 m grid of tompkins_dem_utm.tif; A. radar minus USGS over the county, before and after a constant offset;
#   B. the campus box in 30 m cells: radar, USGS, and the 1 m LiDAR ground and surface averaged to 30 m.
# Reads: data/copernicus/, data_clean/terrain/, data_clean/lidar/.
# Writes: data_clean/radar/tompkins_copernicus_utm.tif, data_clean/radar/campus_30m.tif, logs/prep_radar.txt.

# 1). Preliminary ----
  # Clean up workspace and load or install necessary packages if necessary
  rm(list = ls())
  want <- c("terra", "sf")
  need <- want[!(want %in% installed.packages()[, "Package"])]
  if (length(need)) install.packages(need)
  invisible(lapply(want, function(i) suppressMessages(require(i, character.only = TRUE))))
  rm(want, need)

  misc <- list(tile   = "data/copernicus/Copernicus_DSM_COG_10_N42_00_W077_00_DEM.tif",
               wbm    = "data/copernicus/Copernicus_DSM_COG_10_N42_00_W077_00_WBM.tif",
               xml    = "data/copernicus/Copernicus_DSM_10_N42_00_W077_00.xml",
               box    = c(xmin = 377600, xmax = 378200, ymin = 4700350, ymax = 4700950),  # campus, EPSG:6347
               tower  = c(x = 377876.1, y = 4700539.6),                                  # McGraw Tower, EPSG:6347
               lake   = 115.95,                                                          # USGS's flat Cayuga Lake, m
               log    = "logs/prep_radar.txt")
  dir.create("data_clean/radar", recursive = TRUE, showWarnings = FALSE)
  cat("Session 25 radar prep, run", format(Sys.time(), "%Y-%m-%d %H:%M %Z"), "\nterra",
      as.character(packageVersion("terra")), "|", R.version.string, "\n", file = misc$log)
  say <- function(...) { s <- paste0(...); cat(s, "\n"); cat(s, "\n", file = misc$log, append = TRUE) }
  # log a value with the code line that made it
  lg  <- function(label, expr) {
    code <- paste(deparse(substitute(expr), width.cutoff = 500), collapse = " ")
    v <- expr; say(label, ": ", paste(format(v), collapse = " "), "    <- ", code); invisible(v)
  }
  q <- function(x, p) round(as.numeric(quantile(x, p, na.rm = TRUE)), 2)

# 2). The tile and its facts ----
  say("\n== 1. The tile ==")
  cop <- rast(misc$tile)
  lg("CRS", crs(cop, describe = TRUE)$name)
  lg("EPSG", crs(cop, describe = TRUE)$code)
  lg("Size, rows x cols", dim(cop)[1:2])
  lg("Cell size, degrees (x, y)", signif(res(cop), 7))
  lg("Cell size, arc-seconds", round(res(cop) * 3600, 3))
  lg("Cell size at 42.44 N, metres east-west", round(res(cop)[1] * 111320 * cos(42.44 * pi / 180), 1))
  lg("Cell size at 42.44 N, metres north-south", round(res(cop)[2] * 111132, 1))
  xml <- readLines(misc$xml, warn = FALSE)
  grab <- function(tag) trimws(gsub("<[^>]+>", "", grep(tag, xml, value = TRUE)))
  lg("Vertical reference in the tile's metadata (xml)", grab("vertical:"))
  lg("Radar data collected, first acquisition", grab("tsxx_startTime"))
  lg("Radar data collected, last acquisition", grab("tsxx_stopTime"))
  lg("Radar acquisitions used for this tile", grab("numberOfUsedAcquisitions"))
  lg("Satellites", grab("<tsxx:satellite "))
  lg("Sensor", grab("<tsxx:sensor>"))
  lg("Tile generated", grab("<tsxx:generationTime>"))
  say("Surface or ground: 'The Copernicus DEM is a Digital Surface Model (DSM) which represents the surface of the",
      " Earth including buildings, infrastructure and vegetation.' (data/copernicus/readme.html,",
      " https://copernicus-dem-30m.s3.amazonaws.com/readme.html)")
  say("Licence: data/copernicus/eula_F.pdf, 'Licence for the use of the Copernicus WorldDEM-30', free of charge;",
      " reproduction, distribution and adaptation allowed with the notice: 'produced using Copernicus WorldDEM-30",
      " (c) DLR e.V. 2010-2014 and (c) Airbus Defence and Space GmbH 2014-2018 provided under COPERNICUS by the",
      " European Union and ESA; all rights reserved'. AWS registry points to",
      " https://dataspace.copernicus.eu/explore-data/data-collections/copernicus-contributing-missions/collections-description/COP-DEM")

# 3). Project onto the USGS grid of Tompkins County ----
  say("\n== 2. Onto the county grid ==")
  dem   <- rast("data_clean/terrain/tompkins_dem_utm.tif")              # USGS 3DEP, 30 m, NAVD88, EPSG:26918
  towns <- st_read("data_clean/terrain/tompkins_towns.gpkg", quiet = TRUE)
  box_ll <- ext(project(ext(dem), crs(dem), "EPSG:4326")) + 0.01
  cop_c <- crop(cop, box_ll)
  rad   <- project(cop_c, dem, method = "bilinear"); names(rad) <- "elev_radar"
  writeRaster(rad, "data_clean/radar/tompkins_copernicus_utm.tif", overwrite = TRUE, gdal = "COMPRESS=DEFLATE")
  lg("Radar grid, rows x cols, same as USGS", c(dim(rad)[1:2], compareGeom(rad, dem)))
  lg("Radar range in the frame, m", round(as.numeric(global(rad, range, na.rm = TRUE)), 2))

# 4). A. Radar minus USGS, county ----
  say("\n== A. County: radar minus USGS ==")
  cty  <- rasterize(vect(towns), dem, field = 1)                       # 1 inside the county
  lake <- dem <= misc$lake + 0.5                                       # USGS's flat lake surface
  d    <- rad - dem
  v    <- data.frame(d = values(d, mat = FALSE), cty = values(cty, mat = FALSE), lake = values(lake, mat = FALSE),
                     slope = values(terrain(dem, "slope", unit = "degrees"), mat = FALSE))
  vc   <- v[!is.na(v$cty) & !v$lake & !is.na(v$d), ]                   # county land cells
  lg("County land cells compared (lake left out)", nrow(vc))
  lg("Radar minus USGS, median, m", round(median(vc$d), 2))
  lg("Radar minus USGS, 5th and 95th percentiles, m", q(vc$d, c(0.05, 0.95)))
  lg("Share of land cells with radar > 5 m above USGS, %", round(100 * mean(vc$d > 5), 1))
  # the offset between the two vertical references (EGM2008 against NAVD88)
  vl <- v[!is.na(v$cty) & v$lake & !is.na(v$d), ]
  lg("Lake cells (USGS within 0.5 m of 115.95 m)", nrow(vl))
  lg("Radar minus USGS on the lake, median and IQR, m", c(round(median(vl$d), 2), q(vl$d, c(0.25, 0.75))))
  wbm  <- project(crop(rast(misc$wbm), box_ll), dem, method = "near")
  lg("Radar's own water mask: lake cells (WBM = 2) on USGS's lake, %", round(100 * mean(values(wbm, mat = FALSE)[values(lake, mat = FALSE) %in% TRUE] == 2, na.rm = TRUE), 1))
  lg("Radar elevation on the lake, median, m (EGM2008)", round(median(values(rad, mat = FALSE)[values(lake, mat = FALSE) %in% TRUE], na.rm = TRUE), 2))
  vf <- vc[vc$slope < 1, ]                                             # flat land: slope under 1 degree
  dens <- density(vf$d, from = -10, to = 30, n = 4001, bw = 0.1)
  lg("Flat land cells (slope < 1 degree)", nrow(vf))
  lg("Radar minus USGS on flat land, mode (density peak), m", round(dens$x[which.max(dens$y)], 2))
  lg("Radar minus USGS on flat land, median, m", round(median(vf$d), 2))
  off <- round(dens$x[which.max(dens$y)], 2)
  say("Offset removed below: the flat-land mode, ", off, " m. Flat open fields dominate it; trees and roofs only",
      " push cells up. The lake gives a second estimate, but the lake's level was not the same on the radar",
      " dates (2011-2013) and the USGS flight. Two cross-checks below disagree by about 1 m: the campus lawn",
      " (+0.58 m against LiDAR ground) and the two geoid models (+0.65 m). Either way the share above 5 m moves 2 to 4 points.")
  vc$d0 <- vc$d - off
  lg("After the offset: median, m", round(median(vc$d0), 2))
  lg("After the offset: 5th and 95th percentiles, m", q(vc$d0, c(0.05, 0.95)))
  lg("After the offset: share of land cells > 5 m above USGS, %", round(100 * mean(vc$d0 > 5), 1))
  lg("After the offset: share of land cells > 10 m above USGS, %", round(100 * mean(vc$d0 > 10), 1))
  lg("With +0.58 m instead (the campus lawn estimate, section B): share > 5 m above USGS, %", round(100 * mean(vc$d - 0.58 > 5), 1))
  # what the two geoid models alone predict at the tower, for a point at ellipsoidal height 0 (PROJ grids from cdn.proj.org;
  # the small difference between the WGS 84 and NAD83(2011) ellipsoid frames is ignored)
  gh <- tryCatch({
    sf::sf_proj_network(TRUE)
    c(egm2008 = sf::sf_project("EPSG:4979", "EPSG:4326+3855", cbind(-76.48505, 42.44757, 0), keep = TRUE)[3],
      navd88  = sf::sf_project("EPSG:6319", "EPSG:6318+5703", cbind(-76.48505, 42.44757, 0), keep = TRUE)[3])
  }, error = function(e) c(egm2008 = NA, navd88 = NA))
  lg("Geoid models at the tower: EGM2008 height minus NAVD88 height (GEOID12B) of one point, m", round(gh[["egm2008"]] - gh[["navd88"]], 2))
  # by town (the map shows where)
  towns$id <- seq_len(nrow(towns))
  tw_id <- rasterize(vect(towns), dem, field = "id")
  vt <- data.frame(town = towns$NAMELSAD[values(tw_id, mat = FALSE)], d0 = values(d, mat = FALSE) - off, lake = values(lake, mat = FALSE))
  vt <- vt[!is.na(vt$town) & !vt$lake & !is.na(vt$d0), ]
  bt <- aggregate(d0 ~ town, vt, function(x) c(median = round(median(x), 1), above5 = round(100 * mean(x > 5), 1)))
  bt <- do.call(data.frame, bt); names(bt) <- c("town", "median_m", "share_above_5m_pct"); bt <- bt[order(-bt$share_above_5m_pct), ]
  say("By town, after the offset    <- aggregate(d0 ~ town, ..., median and mean(x > 5))")
  for (l in capture.output(print(bt, row.names = FALSE))) say("  ", l)

# 5). B. The campus box in 30 m cells ----
  say("\n== B. Campus box, 30 m cells ==")
  dtm1 <- rast("data_clean/lidar/campus_dtm.tif"); dsm1 <- rast("data_clean/lidar/campus_dsm.tif")
  g30  <- rast(ext(misc$box[c("xmin", "xmax", "ymin", "ymax")]), res = 30, crs = "EPSG:6347")
  usgs_ll <- rast("data_clean/terrain/tompkins_dem_lonlat.tif")        # USGS 1 arc-second, before projection
  rad30  <- project(cop_c, g30, method = "bilinear")
  usgs30 <- project(usgs_ll, g30, method = "bilinear")
  dtm30  <- aggregate(dtm1, 30, mean); dsm30 <- aggregate(dsm1, 30, mean)
  camp <- c(rad30, usgs30, dtm30, dsm30); names(camp) <- c("radar", "usgs", "lidar_ground", "lidar_surface")
  writeRaster(camp, "data_clean/radar/campus_30m.tif", overwrite = TRUE, gdal = "COMPRESS=DEFLATE")
  say("Grid: the campus box cut in 30 m cells, EPSG:6347; radar and USGS projected from lon/lat (bilinear), LiDAR averaged")
  lg("Cells, rows x cols", dim(camp)[1:2])
  lg("Campus cells: radar minus LiDAR surface, median, m", round(median(values(camp$radar - camp$lidar_surface), na.rm = TRUE), 2))
  lg("Campus cells: radar minus LiDAR ground, median, m", round(median(values(camp$radar - camp$lidar_ground), na.rm = TRUE), 2))
  lg("Campus cells: USGS minus LiDAR ground, median, m", round(median(values(camp$usgs - camp$lidar_ground), na.rm = TRUE), 2))
  lg("Campus cells: correlation of (radar - USGS) with (LiDAR surface - ground)",
     round(cor(values(camp$radar - camp$usgs), values(camp$lidar_surface - camp$lidar_ground), use = "complete"), 2))
  open <- values(camp$lidar_surface - camp$lidar_ground, mat = FALSE) < 0.5   # open cells: lawns, no roof or tree
  lg("Campus cells with LiDAR surface less than 0.5 m above ground (open lawn)", sum(open, na.rm = TRUE))
  lg("Open campus cells: radar minus LiDAR ground, median, m (a third estimate of the offset)",
     round(median(values(camp$radar - camp$lidar_ground, mat = FALSE)[open %in% TRUE]), 2))
  tp <- cbind(misc$tower[["x"]], misc$tower[["y"]])
  lg("Tower's 30 m cell centre, EPSG:6347", xyFromCell(g30, cellFromXY(g30, tp)))
  lg("Tower's cell: radar, m (EGM2008)", round(extract(camp$radar, tp)[[1]], 2))
  lg("Tower's cell: radar after the offset, m", round(extract(camp$radar, tp)[[1]] - off, 2))
  lg("Tower's cell: USGS 30 m, m (NAVD88)", round(extract(camp$usgs, tp)[[1]], 2))
  lg("Tower's cell: LiDAR ground, mean of 900 1 m cells, m", round(extract(camp$lidar_ground, tp)[[1]], 2))
  lg("Tower's cell: LiDAR surface, mean of 900 1 m cells, m", round(extract(camp$lidar_surface, tp)[[1]], 2))
  lg("Tower's cell: LiDAR surface, highest 1 m cell, m", round(max(values(crop(dsm1, ext(rep(xyFromCell(g30, cellFromXY(g30, tp)), each = 2) + c(-15, 15, -15, 15))))), 2))
  lg("1 m LiDAR surface at the tower's top (logs/prep_lidar.txt), m", round(extract(dsm1, cbind(377875.5, 4700540.5))[[1]], 2))

# the end ----
