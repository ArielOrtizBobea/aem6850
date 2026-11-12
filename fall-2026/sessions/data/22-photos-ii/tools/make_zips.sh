#!/bin/zsh
# AEM 6850 - Session 22. Builds the two project zips, run from fall-2026/sessions/data:
#   zsh 22-photos-ii/tools/make_zips.sh
# 22-photos-ii.zip                 the public one: code and every table, no photographs
# _planning/22-photos-ii-full.zip  for Box behind a Cornell NetID (never committed): adds the camera
#                                  frames, the 200 labelled street views and the Fed face crops.
# Neither carries the raw panoramas (665 MB) or the Fed video frames.
set -e
cd "$(dirname "$0")/../.."
rm -f 22-photos-ii.zip ../../../_planning/22-photos-ii-full.zip
# the live script (every code slide in order) rides in both zips; the copy is removed afterwards
cp ../22-photos-ii.R 22-photos-ii/22-photos-ii.R
trap "rm -f 22-photos-ii/22-photos-ii.R" EXIT
common=("22-photos-ii/logs/*" "*/.DS_Store" "*/Rplots.pdf" "22-photos-ii/tools/weights/*" "22-photos-ii/.venv/*" "22-photos-ii/data/ithaca/panoramas/*" "22-photos-ii/data/fed/frames/*")
zip -rq 22-photos-ii.zip 22-photos-ii -x $common "22-photos-ii/data/cameras/frames/*" \
    "22-photos-ii/data_clean/views/*" "22-photos-ii/data_clean/fed_faces/*"
zip -rq ../../../_planning/22-photos-ii-full.zip 22-photos-ii -x $common "22-photos-ii/data_clean/views/*"
# the 200 labelled views only
tail -n +2 22-photos-ii/data_clean/label_sample.csv | awk -F, '{gsub(/"/, "", $3); print "22-photos-ii/" $3}' | zip -q ../../../_planning/22-photos-ii-full.zip -@
ls -la 22-photos-ii.zip ../../../_planning/22-photos-ii-full.zip
