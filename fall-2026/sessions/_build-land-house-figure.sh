#!/usr/bin/env bash
# Session 12: reruns the figure project, draws the page's images, and
# writes the student zip. The licensed files must be in the project's data/
# first (see _land-house-figure/code/1_get_data.R); they never go in the zip.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
proj="$here/_land-house-figure"
img="$here/figures/12-publication-graphics"
mkdir -p "$img" "$here/data"

cd "$proj"
Rscript code/2_clean_data.R
Rscript code/3_figure1.R
sed 's/^journal <- "nature"/journal <- "aer"/' code/3_figure1.R > code/.figure1_aer.R
Rscript code/.figure1_aer.R
rm code/.figure1_aer.R
Rscript code/figure1_default.R
# match/: the first agent demo's folder, a copy of the default script and
# a 300-dpi picture of the Nature figure (2_clean_data.R writes its data)
cp code/figure1_default.R match/code/figure1_default.R
pdftoppm -r 300 -png -singlefile figures/nature/figure1.pdf match/target/figure1
for f in figures/nature/figure1.pdf; do Rscript tools/check_fig.R "$f" nature; done
for f in figures/aer/Figure1?.pdf; do Rscript tools/check_fig.R "$f" aer; done
Rscript tools/check_fig.R figures/default/figure1.pdf nature

cd "$here"
Rscript _figures-12.R "$proj" "$img"

# The zip: code, specs, tools, agents, the public data and the NHGIS
# request. No ICPSR or NHGIS data, nothing computed from them.
stage="$(mktemp -d)"
mkdir -p "$stage/land-house-figure"
(cd "$proj" && tar -cf - \
   --exclude='./data/icpsr/*' --exclude='./data/nhgis/nhgis*' \
   --exclude='./data_clean/*' --exclude='./check' --exclude='./figures/*' \
   --exclude='./match/data_clean' --exclude='./match/figures' --exclude='./match/check' \
   --exclude='.DS_Store' .) | tar -xf - -C "$stage/land-house-figure"
rm -f "$here/data/land-house-figure.zip"
(cd "$stage" && zip -qr "$here/data/land-house-figure.zip" land-house-figure)
rm -rf "${stage:?}"
unzip -l "$here/data/land-house-figure.zip"
