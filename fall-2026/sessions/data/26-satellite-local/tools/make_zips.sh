#!/bin/zsh
# AEM 6850 - Session 26. Builds the class zip, run from anywhere:
#   zsh fall-2026/sessions/data/26-satellite-local/tools/make_zips.sh
# 26-satellite-local.zip holds the .Rproj, README.md, run_everything.R, code/, every file in data/ the scripts read
# or the README describes (the downloads are small, so all of them ship, with the aerial-photo chips of the labelled
# points), and the files in data_clean/ the scripts read, with the county lights table and the season's NDVI.
# It leaves out tools/ (they need the network), logs/, the labelling's candidate cache (data/naip/candidates/) and
# the labelling's working files in data_clean/labels/ other than labels_200.csv. No .Rhistory, Rplots.pdf, .DS_Store.
set -e
cd "$(dirname "$0")/../.."
rm -f 26-satellite-local.zip
p=26-satellite-local
files=(
  $p/26-satellite-local.Rproj
  $p/README.md
  $p/run_everything.R
  $p/code/1_sensors.R
  $p/code/2_drone.R
  $p/code/3_sentinel2.R
  $p/code/4_uses.R
  $p/code/5_resolution.R
  $p/code/6_error.R
  $p/code/7_lake.R
  $p/data/drone/willis_corn_trial.tif
  $p/data/drone/willis_corn_trial_meta.json
  $p/data/sentinel2/s2_20240815_cayuga_20m.tif
  $p/data/sentinel2/s2_tci_20240830_cayuga.tif
  $p/data/sentinel1/s1_vv_db_20240901_cayuga_20m.tif
  $p/data/worldcover/worldcover2021_cayuga.tif
  $p/data/lights/ntl_viirs_2023_ny.tif
  $p/data/lights/ntl_li2020_2013_ny.tif
  $p/data/census/cb_2023_ny_county_500k.gpkg
  $p/data/census/co-est2023-alldata.csv
  $p/data/census/co-est2019-alldata_ny.csv
  $p/data_clean/drone/caldwell_roads_near_mosaic.gpkg
  $p/data_clean/drone/tiger_offset.csv
  $p/data_clean/drone/corn_trial_10m.tif
  $p/data_clean/drone/corn_trial_30m.tif
  $p/data_clean/census/ny_counties.gpkg
  $p/data_clean/lights/ny_county_lights.csv
  $p/data_clean/catalog/s2_search_20240810_20240820.csv
  $p/data_clean/catalog/s2_passes_2024_18TUN.csv
  $p/data_clean/catalog/s2_box_clear_2024.csv
  $p/data_clean/ndvi/ndvi_season_2024.csv
  $p/data_clean/labels/labels_200.csv
)
for f in $files; do [[ -f $f ]] || { echo "missing: $f"; exit 1 }; done
# the aerial-photo chips of the 200 labelled points, if the labelling has written them
chips=($p/data/naip/chips.csv(N) $p/data/naip/chips/*(N.))
zip -q 26-satellite-local.zip $files $chips -x '*.DS_Store' '*.Rhistory' '*Rplots.pdf'
ls -la 26-satellite-local.zip
