#!/bin/zsh
# AEM 6850 - Session 23. Builds the class zip, run from fall-2026/sessions/data:
#   zsh 23-spatial-vector/tools/make_zips.sh
# 23-spatial-vector.zip leaves out data/sahie/ (88 MB), the primary-roads file (38 MB), data/epa/ (10 MB)
# and data/meta/ (245 MB); tools/fetch_data.R downloads them, and data_clean/ holds what the slides need.
set -e
cd "$(dirname "$0")/../.."
rm -f 23-spatial-vector.zip
# the live script (every code slide in order) rides in the zip; the copy is removed afterwards
cp ../23-spatial-vector.R 23-spatial-vector/23-spatial-vector.R
trap "rm -f 23-spatial-vector/23-spatial-vector.R" EXIT
zip -rq 23-spatial-vector.zip 23-spatial-vector -x "*/.DS_Store" "*/Rplots.pdf" "23-spatial-vector/.Rproj.user/*" \
    "23-spatial-vector/data/sahie/*" "23-spatial-vector/data/census/tl_2024_us_primaryroads.zip" \
    "23-spatial-vector/data/epa/*" "23-spatial-vector/data/meta/*" "23-spatial-vector/smoke_june2023.gif" \
    "23-spatial-vector/data_clean/counties/*" "23-spatial-vector/data_clean/states/*"
ls -la 23-spatial-vector.zip
