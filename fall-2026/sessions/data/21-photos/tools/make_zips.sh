#!/bin/zsh
# AEM 6850 - Session 21. Builds the two project zips, run from fall-2026/sessions/data:
#   zsh 21-photos/tools/make_zips.sh
# 21-photos.zip         the public one: everything except the photographs (data/composite,
#                       data_clean/tiles), which are not redistributed on the public site
# _planning/21-photos-full.zip   the whole project, for Box behind a Cornell NetID (never committed)
set -e
cd "$(dirname "$0")/../.."
rm -f 21-photos.zip ../../../_planning/21-photos-full.zip
zip -rq ../../../_planning/21-photos-full.zip 21-photos -x "21-photos/logs/*" "*/.DS_Store" "*/Rplots.pdf"
zip -rq 21-photos.zip 21-photos -x "21-photos/logs/*" "*/.DS_Store" "*/Rplots.pdf" \
    "21-photos/data/composite/*" "21-photos/data_clean/tiles/*"
ls -la 21-photos.zip ../../../_planning/21-photos-full.zip
