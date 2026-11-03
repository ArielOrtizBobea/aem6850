# =============================================================
# AEM 6850 - Session 19: Audio
# Script 1 of 7 - the words Whisper heard, one row per word.
#
# Reads the full press conference of 1 February 2023 as transcribed by
# Whisper (large-v3-turbo, with a start and end time on every word), stacks
# its segments into one table of words, and sets the counts beside the
# Fed's own transcript.
#
# Reads:  replies/words.json, replies/fed_transcript.txt
# Writes: data_clean/words.rds
#
# Open 19-audio.Rproj first. It sits at the project root, so the
# working directory is 19-audio/ and every path below is relative to it.
#
#   source("code/1_words.R")
# =============================================================

  # Load or install the packages this script uses
  want <- c("jsonlite")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only=TRUE))
  rm(want, need)


# 1). Read Whisper's reply ----

  # one list: the whole text, the language, and a table of segments
  # (a sentence or a phrase each)
  stt <- fromJSON("replies/words.json")
  print(names(stt))
  cat("segments:", nrow(stt$segments), "\n")


# 2). One row per word ----

  # each segment holds its own small table of words; stack them
  words <- do.call(rbind, stt$segments$words)
  words <- words[, c("word", "start", "end", "probability")]
  words$word <- trimws(words$word)     # Whisper puts a space before each word

  print(dim(words))
  print(head(words))


# 3). The Fed's transcript of the same hour ----

  # pdftotext's copy of the PDF; a form feed starts each new page
  fed <- readLines("replies/fed_transcript.txt", encoding = "UTF-8", warn = FALSE)
  fed <- sub("^\f", "", fed)

  # drop what is not speech: blank lines, the header on every page, page numbers
  header <- "^(February 1, 2023|FINAL|Page [0-9]+ of 23|.*Press Conference)$"
  fed <- fed[fed != "" & !grepl(header, fed)]

  # drop the speaker tags that open each turn, such as "CHAIR POWELL. "
  fed <- sub("^[A-Z][A-Z-]+( [A-Z][A-Z-]+)+\\. ", "", fed)
  fed_text <- paste(fed, collapse = " ")


# 4). Words and "you know", Whisper beside the Fed ----

  count_you_know <- function(x) {
    lengths(regmatches(x, gregexpr("\\byou know\\b", x, ignore.case = TRUE)))
  }

  whisper_text <- paste(words$word, collapse = " ")
  fed_words <- strsplit(trimws(fed_text), "\\s+")[[1]]

  # Whisper's word list splits some numbers ("2%" comes as "2" and "%")
  # and the Fed writes "2 percent", so the counts differ a little even
  # where the two agree on what was said
  print(rbind(words    = c(whisper = nrow(words), fed = length(fed_words)),
              you_know = c(whisper = count_you_know(whisper_text),
                           fed     = count_you_know(fed_text))))


# 5). Save for the next scripts ----

  saveRDS(words, "data_clean/words.rds")


# the end ----
