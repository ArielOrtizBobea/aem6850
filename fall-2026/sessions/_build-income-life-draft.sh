#!/usr/bin/env bash
set -euo pipefail

# Rebuilds the session 11 draft project, the zip students download, and
# a copy of the paper, data/income-life-draft.pdf, that the slides link.
#
#   fall-2026/sessions/_build-income-life-draft.sh
#
# The project lives in _income-life-draft/ (the underscore keeps Quarto
# from treating it as part of the site). Its paper, paper/draft.tex, types
# its numbers by hand on purpose, with five planted mismatches against what
# the code and the data give; session 11's agent sweep finds them:
#   0.73 (abstract and results; the code gives 0.69), a gap of 42.8 years
#   (43.0), Table 1 Asia 69.2 (70.7), Table 1 Europe 28,504 (28,054), and
#   "Source: Gapminder, 2002" under Figure 1 (2007).
# Do not "fix" them in draft.tex.

cd "$(dirname "$0")"
SRC=_income-life-draft

(cd "$SRC" && Rscript code/run_everything.R)
(cd "$SRC/paper" \
  && pdflatex -interaction=nonstopmode draft.tex >/dev/null \
  && pdflatex -interaction=nonstopmode draft.tex >/dev/null \
  && rm -f draft.aux draft.log draft.out)

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cp -R "$SRC" "$TMP/income-life-draft"
find "$TMP" -name .DS_Store -delete
(cd "$TMP" && zip -qrX income-life-draft.zip income-life-draft)
mv "$TMP/income-life-draft.zip" data/income-life-draft.zip
cp "$SRC/paper/draft.pdf" data/income-life-draft.pdf
unzip -l data/income-life-draft.zip
