# =============================================================
# AEM 6850 - Session 20: Audio II
# Script 1 of 5 - the words Whisper heard, one row per word, 24 conferences.
#
# Reads Whisper's transcription of each of the 24 press conferences of
# 2021-2023 (large-v3-turbo, a start and end time on every word), stacks
# each one's segments into a table of words, and removes the speaker tags
# Whisper wrote as if they were speech ("CHAIR POWELL.", "MICHELLE SMITH.").
#
# Reads:  data/meetings.csv, replies/words_YYYYMMDD.json
# Writes: data_clean/words.csv
#
# Open 20-audio-ii.Rproj first. It sits at the project root, so the
# working directory is 20-audio-ii/ and every path below is relative to it.
#
#   source("code/1_words.R")
# =============================================================


# 1). Preliminary ----

  # Clean up workspace and load or install necessary packages if necessary
  want <- c("jsonlite")
  need <- want[!(want %in% installed.packages()[, "Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only = TRUE))
  rm(want, need)

  # the 24 conference dates, written 20210127 in the file names
  meet  <- read.csv("data/meetings.csv")
  dates <- as.character(meet$date)


# 2). Read one of Whisper's replies ----

  # Python wrote a missing number as NaN, which is not valid JSON; the
  # reader wants null, so swap it before parsing (5 of the files have one)
  read_whisper <- function(file) {
    txt <- paste(readLines(file, warn = FALSE), collapse = "\n")
    txt <- gsub(":\\s*NaN", ": null", txt)
    fromJSON(txt)
  }

  stt <- read_whisper("replies/words_20210127.json")
  print(names(stt))
  cat("segments:", nrow(stt$segments), "\n")


# 3). Find the speaker tags ----

  # On many recordings Whisper writes the Fed transcript's speaker tags as
  # if they were spoken: "CHAIR POWELL.", "MICHELLE SMITH.", sometimes a
  # wrong name ("CHAIR YELLEN.", "CHAIRMAN BERNANKE."). A tag is two or
  # three words in capitals, the last ending in a period, standing between
  # two sentences: the word before it ends a sentence or breaks off with a
  # dash ("runoff -"), or the tag opens the file.
  # That rule keeps the speech Whisper wrote in capitals, such as
  # "we bought MBS II." and three whole sentences on 15 June 2022.
  find_tags <- function(word) {
    caps     <- grepl("^[A-Z][A-Z'’-]+$", word)      # capitals, no period
    caps_end <- grepl("^[A-Z][A-Z'’-]+\\.$", word)   # capitals, then a period
    sentence_end <- grepl("[.?!\u2014-]$", word)          # . ? ! or a dash

    tag <- rep(FALSE, length(word))
    n_tags <- 0
    for (e in which(caps_end)) {
      b <- e                                  # walk back over capital words
      while (b > 1 && caps[b - 1]) b <- b - 1
      run <- e - b + 1
      if (run >= 2 && run <= 3 && (b == 1 || sentence_end[b - 1])) {
        tag[b:e] <- TRUE
        n_tags <- n_tags + 1
      }
    }
    list(tag = tag, n_tags = n_tags)
  }


# 4). One row per word, every conference ----

  words_list <- list()
  counts <- data.frame(date = dates, whisper = NA, tags = NA, tag_words = NA, words = NA)

  for (k in seq_along(dates)) {
    stt <- read_whisper(paste0("replies/words_", dates[k], ".json"))

    # each segment holds its own small table of words; stack them
    w <- do.call(rbind, stt$segments$words)
    w <- w[, c("word", "start", "end", "probability")]
    w$word <- trimws(w$word)           # Whisper puts a space before each word

    tags <- find_tags(w$word)
    counts$whisper[k]   <- nrow(w)
    counts$tags[k]      <- tags$n_tags
    counts$tag_words[k] <- sum(tags$tag)

    w <- w[!tags$tag, ]
    counts$words[k] <- nrow(w)

    # the date as 2021-01-27, so as.Date() reads it
    w$date <- format(as.Date(dates[k], "%Y%m%d"))
    words_list[[k]] <- w[, c("date", "word", "start", "end", "probability")]
  }

  words <- do.call(rbind, words_list)
  rownames(words) <- NULL


# 5). Tags removed, per conference ----

  # whisper: words as returned; tags and the words they held; words: kept
  print(counts, row.names = FALSE)
  cat("words kept:", nrow(words), " tags removed:", sum(counts$tags), "\n")


# 6). Save for the next scripts ----

  write.csv(words, "data_clean/words.csv", row.names = FALSE)


# the end ----
