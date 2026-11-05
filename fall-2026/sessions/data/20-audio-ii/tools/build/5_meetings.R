# =============================================================
# AEM 6850 - Session 20: Audio II
# Script 5 of 5 - one row per conference: length, turns, Powell's share,
# how his answers sounded, and what the Committee decided that day.
#
# Sums the utterance and tone tables (scripts 3 and 4) by conference and
# adds the decision announced that day: a rise in the federal funds target
# range ("hike") or no change ("hold"). The eleven hikes of 2022-2023 are
# typed below from the Fed's table of target-range changes, which dates
# each change the day after the meeting that announced it.
#
# Reads:  data/meetings.csv, data_clean/utterances.csv, data_clean/tone.csv
# Writes: data_clean/meetings.csv
#
# Open 20-audio-ii.Rproj first. It sits at the project root, so the
# working directory is 20-audio-ii/ and every path below is relative to it.
#
#   source("tools/build/5_meetings.R")
# =============================================================


# 1). Preliminary ----

  meet <- read.csv("data/meetings.csv")
  utt  <- read.csv("data_clean/utterances.csv")
  tone <- read.csv("data_clean/tone.csv")

  # https://www.federalreserve.gov/monetarypolicy/openmarket.htm (read
  # 2026-11-02): eleven increases, none in 2021, none after July 2023;
  # the size in basis points (100 bp = 1 percentage point)
  hikes <- data.frame(
    date    = c("2022-03-16", "2022-05-04", "2022-06-15", "2022-07-27",
                "2022-09-21", "2022-11-02", "2022-12-14", "2023-02-01",
                "2023-03-22", "2023-05-03", "2023-07-26"),
    size_bp = c(25, 50, 75, 75, 75, 75, 50, 25, 25, 25, 25))


# 2). One row per conference ----

  m <- data.frame(date = format(as.Date(as.character(meet$date), "%Y%m%d")),
                  duration_s = meet$duration_s)

  # turns, and Powell's label as script 3 chose it (the label of his answers)
  m$n_turns      <- as.numeric(table(utt$date)[m$date])
  powell_rows    <- utt[utt$type %in% c("statement", "answer"), ]
  m$powell_label <- tapply(powell_rows$speaker, powell_rows$date, unique)[m$date]
  is_powell      <- utt$speaker == m$powell_label[match(utt$date, m$date)]
  m$powell_turns <- as.numeric(tapply(is_powell, utt$date, sum)[m$date])
  m$powell_words <- as.numeric(tapply(utt$words * is_powell, utt$date, sum)[m$date])


# 3). How Powell's answers sounded ----

  # the plain mean over his scored answers, each answer counting once
  ans <- tone[tone$type == "answer", ]
  m$powell_answers  <- as.numeric(table(ans$date)[m$date])
  m$arousal_answers <- round(as.numeric(tapply(ans$arousal, ans$date, mean, na.rm = TRUE)[m$date]), 4)
  m$valence_answers <- round(as.numeric(tapply(ans$valence, ans$date, mean, na.rm = TRUE)[m$date]), 4)


# 4). The decision ----

  m$decision <- ifelse(m$date %in% hikes$date, "hike", "hold")
  m$size_bp  <- 0
  m$size_bp[match(hikes$date, m$date)] <- hikes$size_bp

  # the top of the target range after the decision, in percent: 0.25 from
  # March 2020 until the first hike, then up by each hike in turn
  m$upper <- 0.25 + cumsum(m$size_bp) / 100

  print(table(m$decision))
  print(m, row.names = FALSE, digits = 3)


# 5). Save ----

  write.csv(m, "data_clean/meetings.csv", row.names = FALSE)


# the end ----
