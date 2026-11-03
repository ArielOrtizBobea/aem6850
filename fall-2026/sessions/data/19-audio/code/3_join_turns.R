# =============================================================
# AEM 6850 - Session 19: Audio
# Script 3 of 6 - put a speaker label on every word, then cut turns.
#
# Joins Whisper's words (script 1) to the speaker segments (script 2) by
# time: each word takes the label of the segment its midpoint falls in. A
# turn is a run of words with the same label. The turns are then counted
# against the speaker tags in the Fed's transcript.
#
# Reads:  data_clean/words.rds, data_clean/seg.rds, replies/fed_transcript.txt
# Writes: data_clean/w.rds
#
# Open 19-audio.Rproj first. It sits at the project root, so the
# working directory is 19-audio/ and every path below is relative to it.
#
#   source("code/3_join_turns.R")
# =============================================================


# 1). Read the words and the segments ----

  words <- readRDS("data_clean/words.rds")
  seg   <- readRDS("data_clean/seg.rds")


# 2). A label for each word ----

  # findInterval() gives, for each midpoint, the last segment that starts
  # before it; the word belongs to that segment only if it has not ended yet
  mid <- (words$start + words$end) / 2
  i <- findInterval(mid, seg$start)
  i[i == 0] <- NA                          # before the first segment
  i[!is.na(i) & mid > seg$end[i]] <- NA    # in a gap between segments
  words$speaker <- seg$speaker[i]


# 3). Words with no label ----

  cat("words with no label:", sum(is.na(words$speaker)),
      " share:", round(mean(is.na(words$speaker)), 3), "\n")


# 4). Turns ----

  # keep the labelled words; a new turn starts wherever the label changes
  w <- words[!is.na(words$speaker), ]
  new_turn <- c(TRUE, w$speaker[-1] != w$speaker[-nrow(w)])
  w$turn <- cumsum(new_turn)
  cat("turns:", max(w$turn), "\n")


# 5). Turns and words per label ----

  turn_label <- tapply(w$speaker, w$turn, unique)
  print(table(turn_label))
  print(sort(table(w$speaker), decreasing = TRUE))


# 6). Against the Fed's transcript ----

  # the transcript opens every turn with a tag: CHAIR POWELL, MICHELLE SMITH
  # (the moderator, who calls on each reporter) or the reporter's name
  fed <- readLines("replies/fed_transcript.txt", encoding = "UTF-8", warn = FALSE)
  fed <- sub("^\f", "", fed)
  tag <- regmatches(fed, regexpr("^[A-Z][A-Z-]+( [A-Z][A-Z-]+)+(?=\\. )", fed, perl = TRUE))

  # Powell is the label with the most words; no label is the moderator's:
  # each of her calls ("Rachel.", "Neil.") lasts under a second and falls
  # in a gap between segments
  powell <- names(sort(table(w$speaker), decreasing = TRUE))[1]
  print(rbind(model = c(powell = sum(turn_label == powell), moderator = 0),
              fed   = c(powell = sum(tag == "CHAIR POWELL"),
                        moderator = sum(tag == "MICHELLE SMITH"))))


# 7). Save for the next scripts ----

  saveRDS(w, "data_clean/w.rds")


# the end ----
