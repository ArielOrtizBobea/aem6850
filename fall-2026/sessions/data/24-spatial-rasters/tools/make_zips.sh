#!/bin/zsh
# AEM 6850 - Session 24. Builds the class zip, run from fall-2026/sessions/data:
#   zsh 24-spatial-rasters/tools/make_zips.sh
# 24-spatial-rasters.zip leaves out the raw downloads data/era5/ (285 MB), data/glad/, data/sedac/, data/nass/
# and 30 of PRISM's 31 daily zips; tools/fetch_data.R downloads them, and data_clean/ holds what the slides need.
# It also leaves out what R writes at run time: data_clean/prism/, counties/ and states/, and logs/.
set -e
cd "$(dirname "$0")/../.."
rm -f 24-spatial-rasters.zip
# the live script (every code slide in order) rides in the zip; the copy is removed afterwards
cp ../24-spatial-rasters.R 24-spatial-rasters/24-spatial-rasters.R
trap "rm -f 24-spatial-rasters/24-spatial-rasters.R" EXIT
zip -rq 24-spatial-rasters.zip 24-spatial-rasters -x "*/.DS_Store" "*/Rplots.pdf" "24-spatial-rasters/.Rproj.user/*" \
    "24-spatial-rasters/data/era5/*" "24-spatial-rasters/data/glad/*" "24-spatial-rasters/data/sedac/*" \
    "24-spatial-rasters/data/nass/*" "24-spatial-rasters/data/prism/*" \
    "24-spatial-rasters/data_clean/prism/*" "24-spatial-rasters/data_clean/counties/*" \
    "24-spatial-rasters/data_clean/states/*" "24-spatial-rasters/logs/*"
# of PRISM's 31 daily zips only 17 July goes in: the slides read it, and tmax_july2012.tif holds the rest
zip -q 24-spatial-rasters.zip 24-spatial-rasters/data/prism/prism_tmax_us_25m_20120717.zip
ls -la 24-spatial-rasters.zip
