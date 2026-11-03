# =============================================================
# AEM 6850 - Session 19: Audio
# Script 7 of 7 - word-error rate on a 30-second clip.
#
# Scores four Whisper runs on the same 30 seconds of Powell's answer to
# Howard Schneider (16:09 to 16:39 in the video) against the Fed's text of
# that passage: insertions, deletions and substitutions, word by word.
#
# Reads:  replies/clip30_fed.txt, replies/clip30_<model>.json, code/align.R
# Writes: data_clean/wer_table.csv
#
# Open 19-audio.Rproj first. It sits at the project root, so the
# working directory is 19-audio/ and every path below is relative to it.
#
#   source("code/7_wer.R")
# =============================================================

  # Load or install the packages this script uses
  want <- c("jsonlite")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only=TRUE))
  rm(want, need)


# 1). Two helpers ----

  # to_words(): lower case, dashes and slashes to spaces, other punctuation
  # dropped, then split into words
  to_words <- function(x) {
    x <- tolower(paste(x, collapse = " "))
    x <- gsub("[-/—–]", " ", x)
    x <- gsub("[^a-z0-9' ]", "", x)
    strsplit(trimws(x), " +")[[1]]
  }

  # word_edits(): code each distinct word as one character, so that adist()
  # counts edits between words rather than between letters
  word_edits <- function(ref, hyp) {
    vocab <- unique(c(ref, hyp))
    r <- intToUtf8(match(ref, vocab) + 1000)
    h <- intToUtf8(match(hyp, vocab) + 1000)
    adist(r, h, counts = TRUE)
  }


# 2). The reference: the Fed's text of the 30 seconds ----

  ref <- to_words(readLines("replies/clip30_fed.txt", encoding = "UTF-8", warn = FALSE))
  cat("reference words:", length(ref), "\n")
  print(head(ref, 12))


# 3). The four runs on the clip ----

  # two model sizes, each run plain and with a prompt written full of
  # fillers ("Um, uh, so, you know, ..."), which invites the model to keep them
  runs <- c(base         = "replies/clip30_base.json",
            base_prompt  = "replies/clip30_base_prompt.json",
            turbo        = "replies/clip30_turbo.json",
            turbo_prompt = "replies/clip30_turbo_prompt.json")
  hyps <- lapply(runs, function(f) to_words(fromJSON(f)$text))


# 4). Insertions, deletions, substitutions and the rate ----

  # rate = all edits divided by the number of reference words
  wer <- t(sapply(hyps, function(h) {
    d <- word_edits(ref, h)
    k <- attr(d, "counts")[1, 1, ]
    c(ref_words = length(ref), model_words = length(h), k,
      rate = round(sum(k) / length(ref), 3))
  }))
  print(wer)
  write.csv(data.frame(run = rownames(wer), wer), "data_clean/wer_table.csv",
            row.names = FALSE)


# 5). Where the turbo run differs from the reference ----

  # adist() also returns the path it took, one letter per step:
  # M match, S substitution, D deletion, I insertion; align() walks it
  source("code/align.R")
  print(align(ref, hyps$turbo), row.names = FALSE)


# the end ----
