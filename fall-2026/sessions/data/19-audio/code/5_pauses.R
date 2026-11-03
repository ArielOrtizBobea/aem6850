# =============================================================
# AEM 6850 - Session 19: Audio
# Script 5 of 6 - pauses, speaking rate and "you know", from the turns.
#
# Uses the utterance table (script 4): the pause before each of Powell's
# answers, how fast each speaker talks, and how often Powell says
# "you know" in each answer. Then reads the word table (script 1) for the
# silence between words before each answer, since words with no speaker
# label can sit inside a pause in the table.
#
# Reads:  data_clean/utterances.csv, data_clean/words.rds
# Writes: nothing
#
# Open 19-audio.Rproj first. It sits at the project root, so the
# working directory is 19-audio/ and every path below is relative to it.
#
#   source("code/5_pauses.R")
# =============================================================


# 1). Read the utterance table ----

  utt <- read.csv("data_clean/utterances.csv")
  utt$words <- lengths(strsplit(utt$text, " "))

  # Powell is the label with the most words
  powell <- names(which.max(tapply(utt$words, utt$speaker, sum)))

  # start times as minutes:seconds, to find a moment in the video
  clock <- function(s) sprintf("%02d:%02d", floor(s / 60), floor(s %% 60))


# 2). The pause before each answer ----

  # the gap between the end of one turn and the start of the next
  utt$pause <- utt$start - c(NA, utt$end[-nrow(utt)])

  # Powell's turns after the first, which is his opening statement
  answers <- utt[utt$speaker == powell & !is.na(utt$pause), ]
  cat("answers:", nrow(answers), " median pause (s):", median(answers$pause), "\n")


# 3). The five longest pauses ----

  longest <- answers[order(answers$pause, decreasing = TRUE)[1:5], ]
  print(data.frame(at    = clock(longest$start),
                   pause = longest$pause,
                   text  = substr(longest$text, 1, 45)), right = FALSE)


# 4). The silence between words before each answer ----

  # the word table holds every word, labelled or not; the gap before each
  # word is its start minus the end of the word before it
  words <- readRDS("data_clean/words.rds")
  words$gap <- words$start - c(NA, words$end[-nrow(words)])

  # for each answer, the largest gap between consecutive words from the end
  # of the turn before to the answer's first word; the times are written to
  # the hundredth, and the CSV and the JSON can differ in the last binary
  # digit (1425.61 read back as 1425.6099999999999), hence the 0.005 margin
  rows <- which(utt$speaker == powell & !is.na(utt$pause))   # the same answers
  answers$silence <- NA
  for (k in seq_along(rows)) {
    r <- rows[k]
    between <- words$start >= utt$end[r - 1] - 0.005 & words$start <= utt$start[r] + 0.005
    answers$silence[k] <- max(words$gap[between])
  }
  print(data.frame(at      = clock(answers$start),
                   pause   = round(answers$pause, 2),
                   silence = round(answers$silence, 2)), row.names = FALSE)
  cat("median silence before an answer (s):", median(answers$silence),
      " longest:", max(answers$silence), "at", clock(answers$start[which.max(answers$silence)]), "\n")


# 5). Speaking rate ----

  # words per second within each turn, then the median turn of each side
  utt$rate <- utt$words / (utt$end - utt$start)
  utt$who  <- ifelse(utt$speaker == powell, "Powell", "others")
  med <- tapply(utt$rate, utt$who, median)
  print(round(cbind(turns = table(utt$who), per_second = med, per_minute = 60 * med), 1))


# 6). "You know" in each of Powell's turns ----

  mine <- utt[utt$speaker == powell, ]
  mine$you_know <- lengths(regmatches(mine$text,
                     gregexpr("\\byou know\\b", mine$text, ignore.case = TRUE)))
  mine$per_100_words <- round(100 * mine$you_know / mine$words, 1)
  print(data.frame(at = clock(mine$start), mine[, c("words", "you_know", "per_100_words")]),
        row.names = FALSE)

  # the opening statement is read from a text; the answers are not
  cat("opening statement:", mine$you_know[1], " answers:", sum(mine$you_know[-1]),
      " per 100 words in the answers:",
      round(100 * sum(mine$you_know[-1]) / sum(mine$words[-1]), 2), "\n")


# the end ----
