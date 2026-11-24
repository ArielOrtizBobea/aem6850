#!/bin/zsh
# AEM 6850 - Session 25. Builds the class zip, run from anywhere:
#   zsh fall-2026/sessions/data/25-lidar-drones/tools/make_zips.sh
# 25-lidar-drones.zip holds the .Rproj, README.md, run_everything.R, code/, the files the six scripts read, and two that Practice 9 and 10 need
# (fallcreek_dem_utm.tif, the gauge record).
# It leaves out every raw download in data/ (the LiDAR tiles and EPT nodes, the 54 MB elevation tile, the USGS index,
# the Census zips, the mosaic's record), the drone mosaic and its road files (kept on disk for session 26, with tools/drone_for_session26.R), the files in data_clean/ that only the figures
# and the prep read, tools/ and logs/. tools/fetch_*.R download the raw files again.
set -e
cd "$(dirname "$0")/../.."
rm -f 25-lidar-drones.zip
files=(
  25-lidar-drones/25-lidar-drones.Rproj
  25-lidar-drones/README.md
  25-lidar-drones/run_everything.R
  25-lidar-drones/code/1_radar.R
  25-lidar-drones/code/2_lidar.R
  25-lidar-drones/code/3_heights.R
  25-lidar-drones/code/4_slope.R
  25-lidar-drones/code/5_views.R
  25-lidar-drones/code/6_watershed.R
  25-lidar-drones/data_clean/lidar/campus.laz
  25-lidar-drones/data_clean/lidar/campus_dtm.tif
  25-lidar-drones/data_clean/lidar/campus_dsm.tif
  25-lidar-drones/data_clean/lidar/campus_height.tif
  25-lidar-drones/data_clean/lidar_nyc/esb_height.tif
  25-lidar-drones/data_clean/radar/tompkins_copernicus_utm.tif
  25-lidar-drones/data_clean/hail/hail_county_day.csv
  25-lidar-drones/data_clean/hail/hail_county_month.csv
  25-lidar-drones/data_clean/hail/counties_7states.gpkg
  25-lidar-drones/data_clean/hail/mesh_20220612.tif
  25-lidar-drones/data_clean/hail/reflectivity_20220612.tif
  25-lidar-drones/data_clean/terrain/tompkins_dem_utm.tif
  25-lidar-drones/data_clean/terrain/tompkins_towns.gpkg
  25-lidar-drones/data_clean/terrain/fallcreek_dem_filled.tif
  25-lidar-drones/data_clean/terrain/fallcreek_dem_utm.tif
  25-lidar-drones/data/usgs_gauge/site_04234000.rdb
)
for f in $files; do [[ -f $f ]] || { echo "missing: $f"; exit 1 }; done
zip -q 25-lidar-drones.zip $files
ls -la 25-lidar-drones.zip
