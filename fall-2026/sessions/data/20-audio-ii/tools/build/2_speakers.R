# =============================================================
# AEM 6850 - Session 20: Audio II
# Script 2 of 5 - who spoke when, as the speaker model saw it.
#
# Reads the speaker labels of each conference: one line per stretch of one
# voice, with the label the clustering gave that voice (SPK00, SPK01, ...).
# The labels carry no names, and SPK00 in one conference has nothing to do
# with SPK00 in another.
#
# Reads:  data/meetings.csv, replies/speakers_YYYYMMDD.rttm
# Writes: data_clean/segments.csv
#
# Open 20-audio-ii.Rproj first. It sits at the project root, so the
# working directory is 20-audio-ii/ and every path below is relative to it.
#
#   source("tools/build/2_speakers.R")
# =============================================================


# 1). Preliminary ----

  meet  <- read.csv("data/meetings.csv")
  dates <- as.character(meet$date)


# 2). The file as written ----

  # RTTM, a plain-text format with ten columns separated by spaces
  cat(readLines("replies/speakers_20210127.rttm", n = 3), sep = "\n")


# 3). Start, end and label, every conference ----

  seg_list <- list()
  for (k in seq_along(dates)) {
    # column 4 is the start in seconds, 5 the duration, 8 the label
    s <- read.table(paste0("replies/speakers_", dates[k], ".rttm"))[, c(4, 5, 8)]
    names(s) <- c("start", "dur", "speaker")
    s$end  <- s$start + s$dur
    s$date <- format(as.Date(dates[k], "%Y%m%d"))
    s <- s[order(s$start), ]
    seg_list[[k]] <- s[, c("date", "start", "end", "speaker")]
  }

  seg <- do.call(rbind, seg_list)
  rownames(seg) <- NULL


# 4). How many stretches, how many voices ----

  print(data.frame(segments = tapply(seg$speaker, seg$date, length),
                   labels   = tapply(seg$speaker, seg$date, function(x) length(unique(x)))))
  cat("segments:", nrow(seg), "\n")


# 5). Save for the next scripts ----

  write.csv(seg, "data_clean/segments.csv", row.names = FALSE)


# the end ----
