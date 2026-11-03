# =============================================================
# AEM 6850 - Session 19: Audio
# Script 2 of 6 - who spoke when, as the speaker model saw it.
#
# Reads the speaker labels for the full press conference: one line per
# stretch of one voice, with a label the clustering gave that voice
# (SPK00, SPK01, ...). The labels carry no names.
#
# Reads:  replies/speakers.rttm
# Writes: data_clean/seg.rds
#
# Open 19-audio.Rproj first. It sits at the project root, so the
# working directory is 19-audio/ and every path below is relative to it.
#
#   source("code/2_speakers.R")
# =============================================================


# 1). The file as written ----

  # RTTM, a plain-text format with ten columns separated by spaces
  cat(readLines("replies/speakers.rttm", n = 3), sep = "\n")


# 2). Keep start, duration and label ----

  # column 4 is the start in seconds, 5 the duration, 8 the label
  seg <- read.table("replies/speakers.rttm")[, c(4, 5, 8)]
  names(seg) <- c("start", "dur", "speaker")
  seg$end <- seg$start + seg$dur
  seg <- seg[order(seg$start), ]
  print(head(seg))


# 3). How many stretches, how many voices ----

  cat("segments:", nrow(seg), " labels:", length(unique(seg$speaker)), "\n")


# 4). Save for the next scripts ----

  saveRDS(seg, "data_clean/seg.rds")


# the end ----
