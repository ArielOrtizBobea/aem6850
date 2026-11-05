# =============================================================
# AEM 6850 - Session 20: Audio II
# Script 3 of 5 - one row per turn: who, when, what was said, and whether
# it is Powell's opening statement, one of his answers, or someone else.
#
# Joins the words (script 1) to the speaker segments (script 2) by time:
# each word takes the label of the segment its midpoint falls in. A turn is
# a run of words with the same label. Powell is the label with the most
# words in each conference; his first long turn is the prepared statement
# he reads, and his later turns are his answers to reporters.
#
# Reads:  data_clean/words.csv, data_clean/segments.csv
# Writes: data_clean/utterances.csv
#
# Open 20-audio-ii.Rproj first. It sits at the project root, so the
# working directory is 20-audio-ii/ and every path below is relative to it.
#
#   source("tools/build/3_utterances.R")
# =============================================================


# 1). Preliminary ----

  words <- read.csv("data_clean/words.csv")
  seg   <- read.csv("data_clean/segments.csv")
  dates <- unique(words$date)

  # the opening statement lasts 6 to 9 minutes; no answer before it is
  # this long, so "long" means at least two minutes
  misc <- list(statement_min_s = 120)


# 2). A label for each word, then turns, one conference at a time ----

  utt_list <- list()
  unlabelled <- c()

  for (d in dates) {
    w <- words[words$date == d, ]
    s <- seg[seg$date == d, ]

    # findInterval() gives, for each midpoint, the last segment that starts
    # before it; the word belongs to that segment only if it has not ended yet
    mid <- (w$start + w$end) / 2
    i <- findInterval(mid, s$start)
    i[i == 0] <- NA                          # before the first segment
    i[!is.na(i) & mid > s$end[i]] <- NA      # in a gap between segments
    w$speaker <- s$speaker[i]
    unlabelled[d] <- mean(is.na(w$speaker))

    # keep the labelled words; a new turn starts wherever the label changes
    w <- w[!is.na(w$speaker), ]
    new_turn <- c(TRUE, w$speaker[-1] != w$speaker[-nrow(w)])
    w$turn <- cumsum(new_turn)

    # one row per turn; tapply() splits a column by turn and applies a
    # function to each piece
    u <- data.frame(
      date    = d,
      turn    = as.integer(names(tapply(w$start, w$turn, min))),
      speaker = tapply(w$speaker, w$turn, unique),
      start   = tapply(w$start, w$turn, min),
      end     = tapply(w$end, w$turn, max),
      words   = tapply(w$word, w$turn, length),
      text    = tapply(w$word, w$turn, paste, collapse = " "))

    # Powell is the label with the most words
    powell <- names(which.max(tapply(u$words, u$speaker, sum)))

    # his first turn of two minutes or more is the statement; his turns
    # after it are answers; everything else, including any short Powell
    # turn before the statement, is "other"
    is_powell <- u$speaker == powell
    first_long <- which(is_powell & u$end - u$start >= misc$statement_min_s)[1]
    u$type <- "other"
    u$type[first_long] <- "statement"
    u$type[is_powell & u$turn > u$turn[first_long]] <- "answer"

    utt_list[[d]] <- u
  }

  utt <- do.call(rbind, utt_list)
  rownames(utt) <- NULL
  utt <- utt[, c("date", "turn", "speaker", "type", "start", "end", "words", "text")]


# 3). Words with no label ----

  # a word whose midpoint falls in a gap between segments gets no label;
  # it stays in words.csv but in no turn
  print(round(unlabelled, 3))


# 4). Turns per conference, and how many are Powell's ----

  print(table(utt$date, utt$type))
  cat("utterances:", nrow(utt), "\n")


# 5). Save and look ----

  write.csv(utt, "data_clean/utterances.csv", row.names = FALSE)

  # the first five, text cut to 45 characters for the screen
  first <- head(utt, 5)
  first$text <- substr(first$text, 1, 45)
  print(first, right = FALSE)


# the end ----
