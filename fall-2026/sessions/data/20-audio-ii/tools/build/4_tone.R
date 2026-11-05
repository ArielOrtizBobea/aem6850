# =============================================================
# AEM 6850 - Session 20: Audio II
# Script 4 of 5 - how each utterance sounded to the emotion model.
#
# The emotion model scored every consecutive 10-second window of each
# recording for arousal (calm to excited), dominance (submissive to in
# control) and valence (negative to positive), roughly from 0 to 1. Each
# utterance gets the mean of the windows whose midpoints fall inside it,
# and no score (NA) when none does. Pitch and energy are not here: the
# lecture computes them in R from the recordings.
#
# Reads:  data_clean/utterances.csv, replies/emotion_YYYYMMDD.csv
# Writes: data_clean/tone.csv
#
# Open 20-audio-ii.Rproj first. It sits at the project root, so the
# working directory is 20-audio-ii/ and every path below is relative to it.
#
#   source("tools/build/4_tone.R")
# =============================================================


# 1). Preliminary ----

  utt   <- read.csv("data_clean/utterances.csv")
  dates <- unique(utt$date)
  scores <- c("arousal", "dominance", "valence")


# 2). The windows as written ----

  em <- read.csv("replies/emotion_20210127.csv")
  print(head(em, 3))


# 3). The windows inside each utterance, one conference at a time ----

  tone_list <- list()
  windows <- data.frame(date = dates, windows = NA, missing = NA, in_utterance = NA)

  for (k in seq_along(dates)) {
    d <- dates[k]
    u  <- utt[utt$date == d, ]
    em <- read.csv(paste0("replies/emotion_", gsub("-", "", d), ".csv"))

    # the utterance whose span holds each window's midpoint, as in script 3
    mid <- (em$window_start + em$window_end) / 2
    i <- findInterval(mid, u$start)
    i[i == 0] <- NA                          # before the first utterance
    i[!is.na(i) & mid > u$end[i]] <- NA      # between two utterances
    em$turn <- u$turn[i]

    windows$windows[k]      <- nrow(em)
    windows$missing[k]      <- sum(!complete.cases(em[, scores]))
    windows$in_utterance[k] <- sum(!is.na(em$turn))

    # the mean of each score over the windows of each utterance; an
    # utterance with no window inside it gets NA from match()
    em <- em[!is.na(em$turn), ]
    for (v in scores) {
      m <- tapply(em[[v]], em$turn, mean)
      u[[v]] <- round(as.numeric(m[match(u$turn, names(m))]), 4)
    }

    tone_list[[d]] <- u
  }

  tone <- do.call(rbind, tone_list)
  rownames(tone) <- NULL
  tone <- tone[, c("date", "turn", "speaker", "type", "start", "end", "words", scores)]


# 4). How many windows, how many utterances scored ----

  # windows: in the file; missing: with an empty score; in_utterance: with
  # a midpoint inside some utterance
  print(windows, row.names = FALSE)

  # an utterance shorter than 10 seconds often holds no window midpoint
  print(table(type = tone$type, scored = !is.na(tone$arousal)))


# 5). Save ----

  write.csv(tone, "data_clean/tone.csv", row.names = FALSE)
  print(head(tone[tone$type == "answer", ], 5))


# the end ----
