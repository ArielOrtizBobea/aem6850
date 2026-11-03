# =============================================================
# AEM 6850 - Session 19: Audio
# Script 4 of 7 - one row per turn: who, when, and what was said.
#
# Collapses the labelled words (script 3) into an utterance table, the
# shape most research uses: speaker, start, end and text of each turn.
#
# Reads:  data_clean/w.rds
# Writes: data_clean/utterances.csv
#
# Open 19-audio.Rproj first. It sits at the project root, so the
# working directory is 19-audio/ and every path below is relative to it.
#
#   source("code/4_utterances.R")
# =============================================================


# 1). Read the labelled words ----

  w <- readRDS("data_clean/w.rds")


# 2). One row per turn ----

  # tapply() splits a column by turn and applies a function to each piece
  utt <- data.frame(
    speaker = tapply(w$speaker, w$turn, unique),
    start   = tapply(w$start, w$turn, min),
    end     = tapply(w$end, w$turn, max),
    text    = tapply(w$word, w$turn, paste, collapse = " "))
  cat("utterances:", nrow(utt), "\n")


# 3). Save and look ----

  write.csv(utt, "data_clean/utterances.csv", row.names = FALSE)

  # the first five, text cut to 45 characters for the screen
  first <- head(utt, 5)
  first$text <- substr(first$text, 1, 45)
  print(first, right = FALSE)


# the end ----
