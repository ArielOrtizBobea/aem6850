# =============================================================
# AEM 6850 - Session 20: Audio II
# Master file. Runs every script, in the order the lecture uses them.
#
# Open 20-audio-ii.Rproj first. It sits at the project root, so the
# working directory is 20-audio-ii/ and every path below is relative to it.
#
#   source("code/run_everything.R")     from the R console
#   Rscript code/run_everything.R       from a terminal, run in 20-audio-ii/
#
# 1_pitch_energy.R   a known tone, one clip, half the volume, per turn, the baseline, Exercise 1
# 2_ear.R            the seeded draw of eight clips, Exercise 2
# 3_conferences.R    across conferences, hikes against holds, through the Q&A
#
# The scripts read only what is in data/clips/ and data_clean/, so they run in a
# few seconds and need neither Python nor the full recordings.
# =============================================================

rm(list = ls())
source("code/1_pitch_energy.R")
source("code/2_ear.R")
source("code/3_conferences.R")
