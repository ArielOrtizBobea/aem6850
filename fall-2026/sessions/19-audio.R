# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# AEM 6850 -- Empirical Methods for Applied Economists
# Prof. Ariel Ortiz-Bobea
# Session 19 -- Audio I: speech to text
# Tuesday, November 3, 2026
#
# Run it one line at a time: put the cursor on a line and press Cmd-Return
# (Mac) or Ctrl-Enter (Windows).
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# Preliminary ----
# Clean up workspace and load or install necessary packages if necessary
  rm(list=ls())
  want <- c("jsonlite","tuneR")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only=TRUE))
  rm(want, need)


# A recording as a vector of numbers ----
library(tuneR)
wav <- readWave("data/clips/open2min.wav")
wav@samp.rate          # samples a second
length(wav@left)       # samples in 2 minutes
i <- 112800 + 1:800    # 50 ms from 7.05 s
wav@left[i[1:6]]       # the first six
plot((i - 1) / 16000, wav@left[i], type = "l",
     main = "\"Good\", 7.05 to 7.10 s",
     xlab = "seconds", ylab = "amplitude")


# Reading the reply in R ----
library(jsonlite)
stt <- fromJSON("replies/words.json")
names(stt)
# stt$segments: one row per segment; its words column holds a small table per row
words <- do.call(rbind, stt$segments$words)    # stack the 1,711 per-segment word tables
words <- words[, c("word", "start", "end", "probability")]
words$word <- trimws(words$word)               # the model puts a space before each word
dim(words)


head(words, 4)


fed <- readLines("replies/fed_transcript.txt", encoding = "UTF-8", warn = FALSE)
fed <- sub("^\f", "", fed)                                   # a form feed starts each page
header <- "^(February 1, 2023|FINAL|Page [0-9]+ of 23|.*Press Conference)$"
fed <- fed[fed != "" & !grepl(header, fed)]                  # blank lines, page headers
fed <- sub("^[A-Z][A-Z-]+( [A-Z][A-Z-]+)+\\. ", "", fed)     # speaker tags: "CHAIR POWELL. "
fed_text <- paste(fed, collapse = " ")
length(strsplit(trimws(fed_text), "\\s+")[[1]])              # the Fed's spoken words


small <- fromJSON("replies/words_base.json")                       # the small model, same settings
small_words <- do.call(rbind, small$segments$words)
per_min <- rbind(large = table(floor(words$start / 60)),          # words per minute of the conference
                 small = table(floor(small_words$start / 60)))
per_min[, 34:45]                                                   # minutes 33 to 44
c(large = max(stt$segments$compression_ratio), small = max(small$segments$compression_ratio))


readLines("replies/speakers.rttm", n = 2)
seg <- read.table("replies/speakers.rttm")[, c(4, 5, 8)]   # start, duration, label
names(seg) <- c("start", "dur", "speaker")
seg$end <- seg$start + seg$dur
seg <- seg[order(seg$start), ]
head(seg, 3)
c(stretches = nrow(seg), labels = length(unique(seg$speaker)))


findInterval(c(0.5, 2.1, 4.9, 7.0), c(0, 2, 5))   # the last start at or before each time


mid <- (words$start + words$end) / 2     # a word goes with the stretch holding most of it
i <- findInterval(mid, seg$start)        # the last stretch that starts before the midpoint
i[i == 0] <- NA                          # before the first stretch
i[!is.na(i) & mid > seg$end[i]] <- NA    # past that stretch's end, in a gap
words$speaker <- seg$speaker[i]
c(no_label = sum(is.na(words$speaker)), share = round(mean(is.na(words$speaker)), 3))
words[words$start > 923 & words$start < 926.5, ]


w <- words[!is.na(words$speaker), ]                          # the 7,184 labelled words
new_turn <- c(TRUE, w$speaker[-1] != w$speaker[-nrow(w)])    # TRUE where the label changes
w$turn <- cumsum(new_turn)
max(w$turn)
turn_label <- tapply(w$speaker, w$turn, unique)              # one label per turn
sort(table(turn_label), decreasing = TRUE)[1:4]
powell <- names(sort(table(w$speaker), decreasing = TRUE))[1] # the label with the most words
powell


table(turn_label)
head(sort(table(w$speaker), decreasing = TRUE), 3)


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Exercise 1 (5 minutes) ----
# Exercise 1 (5 minutes). The two files joined, the turns counted.
# 1. words and seg as built in Part 3 (run this script to that point,
#    or source code/1_words.R and code/2_speakers.R).
# 2. Give each word the label at its midpoint (findInterval() at the midpoint,
#    the two NA cases); count the words with no label.
# 3. Number the turns with cumsum(); turn_label; powell = the label with the most words.
# 4. The moderator calls each reporter by name. Print the words between 417.5 and
#    421.5 s, her first name call, and read their labels:
#    words[words$start > 417.5 & words$start < 421.5, c("word", "start", "speaker")]
# 5. Compare: rbind(model = c(powell = ..., moderator = ...), fed = c(30, 17))
# Two answers to compare with the room (say them aloud): your two counts against
# 30 and 17, and the label on "Chris Rugeber." at 07:00, the moderator's first
# name call.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




utt <- data.frame(
  speaker = tapply(w$speaker, w$turn, unique),
  start   = tapply(w$start,   w$turn, min),
  end     = tapply(w$end,     w$turn, max),
  text    = tapply(w$word,    w$turn, paste, collapse = " "))   # a turn's words as one string
nrow(utt)
write.csv(utt, "data_clean/utterances.csv", row.names = FALSE)
first <- head(utt, 5); first$text <- substr(first$text, 1, 45)  # substr(): characters 1 to 45
print(first, right = FALSE)


who <- c(SPK00 = "Powell", SPK02 = "Rugaber (AP)")
utt$name <- who[utt$speaker]       # NA for the labels not yet named
head(utt[, c("speaker", "name", "start")], 3)


utt <- read.csv("data_clean/utterances.csv")
utt$words <- lengths(strsplit(utt$text, " "))                       # words per turn
powell <- names(which.max(tapply(utt$words, utt$speaker, sum)))     # the label with the most words
clock  <- function(s) sprintf("%02d:%02d", floor(s / 60), floor(s %% 60))   # seconds to mm:ss
# x <- c(10, 20, 30); c(NA, x[-3]) gives NA 10 20: the previous row's value
utt$pause <- utt$start - c(NA, utt$end[-nrow(utt)])                 # this start minus the previous end
head(utt[, c("speaker", "start", "end", "pause")], 6)


utt$rate <- utt$words / (utt$end - utt$start)          # words per second
utt$who  <- ifelse(utt$speaker == powell, "Powell", "others")
med <- tapply(utt$rate, utt$who, median)
round(cbind(turns = table(utt$who), per_second = med, per_minute = 60 * med), 1)
round(utt$rate[1], 2)                                  # the opening statement


# Counting "you know" in each answer ----
mine <- utt[utt$speaker == powell, ]
hits <- gregexpr("\\byou know\\b", mine$text, ignore.case = TRUE)   # every match in each turn
mine$you_know <- lengths(regmatches(mine$text, hits))               # how many per turn
c(opening = mine$you_know[1], answers = sum(mine$you_know[-1]),
  per_100_words = round(100 * sum(mine$you_know[-1]) / sum(mine$words[-1]), 2))
barplot(100 * mine$you_know / mine$words, names.arg = clock(mine$start), las = 2,
        ylab = "\"you know\" per 100 words", main = "Each of Powell's 27 turns, by its start time")


data.frame(at = clock(mine$start), mine[, c("words", "you_know")])


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Exercise 2 (4 minutes) ----
# Exercise 2 (4 minutes). The pause before each Powell answer.
# 1. utt with its pause column, powell and clock(), as built on the slides before.
# 2. answers <- Powell's rows that have a pause (the opening statement has none).
# 3. How many answers; median(answers$pause).
# 4. The longest: its pause, clock(start), and the first words of its text
#    (substr(text, 1, 45)).
# Two answers to compare with the room: the median pause in seconds, and the
# clock time of the longest pause with what the answer begins with.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




utt$prev_end <- c(NA, utt$end[-nrow(utt)])                # where the turn before ends
answers <- utt[utt$speaker == powell & !is.na(utt$pause), ]
silence <- function(from, to) {                           # the longest gap from one time to another
  g <- words[words$start > from - 0.005 & words$start < to - 0.005, ]   # the words in between
  max(c(g$start, to) - c(from, g$end))
}
answers$silence <- mapply(silence, answers$prev_end, answers$start)
c(table = median(answers$pause), words = median(answers$silence))
words[words$start > 1371.7 & words$start < 1378.3, c("word", "start", "end", "speaker")]


word_edits <- function(ref, hyp) {
  vocab <- unique(c(ref, hyp))                  # every distinct word
  r <- intToUtf8(match(ref, vocab) + 1000)      # one character per word, past the ordinary letters
  h <- intToUtf8(match(hyp, vocab) + 1000)
  adist(r, h, counts = TRUE)
}
ref <- strsplit("so we can now say that the process has really started", " ")[[1]]
hyp <- strsplit("so we can say that the processes has really really started", " ")[[1]]
d <- word_edits(ref, hyp)
attr(d, "counts")[1, 1, ]
sum(attr(d, "counts")) / length(ref)
attr(d, "trafos")


to_words <- function(x) {
  x <- tolower(paste(x, collapse = " "))
  x <- gsub("[-/—–]", " ", x)          # dashes and slashes split words: "We—this" -> "we this"
  x <- gsub("[^a-z0-9' ]", "", x)      # other punctuation dropped; the straight apostrophe stays
  strsplit(trimws(x), " +")[[1]]
}
to_words("We—this is what we thought. We—you know, it's P.C.E.")
ref <- to_words(readLines("replies/clip30_fed.txt", encoding = "UTF-8", warn = FALSE))
length(ref)


runs <- c(small = "replies/clip30_base.json",   small_prompt = "replies/clip30_base_prompt.json",
          large = "replies/clip30_turbo.json",  large_prompt = "replies/clip30_turbo_prompt.json")
hyps  <- lapply(runs, function(f) to_words(fromJSON(f)$text))   # one word vector per file
score <- function(h) { k <- attr(word_edits(ref, h), "counts")[1, 1, ]
                       c(model_words = length(h), k, rate = round(sum(k) / length(ref), 3)) }
t(sapply(hyps, score))                                          # one row per run


fromJSON("replies/clip30_base_prompt.json")$segments[, c("start", "end")]   # small model, prompted: one segment
substr(fromJSON("replies/clip30_turbo_prompt.json")$text, 1, 51)             # large model, prompted: first words


source("code/align.R")     # align(): walks attr(d, "trafos") and prints one row per edit


align(ref, hyps$large)


align(ref, hyps$small)


cat(readLines("code/align.R"), sep = "\n")


align(ref, hyps$large_prompt)
clip <- do.call(rbind, fromJSON("replies/clip30_turbo.json")$segments$words)
tail(clip, 2)                      # the last two words, both placed at 29.98 s


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Practice ----
# Practice. Run in the 19-audio folder after the slides' code has built
# words (with its speaker column), seg, w, utt (with pause, words and rate),
# powell, clock(), to_words(), word_edits(), ref, hyps and align().
# None needs Python, an account or the network; task 8 needs earphones.

# Reading model output
#  1. replies/words_base_nocond.json is the small model run again with each
#     30-second chunk decoded without the text before it. Read its words as
#     on the slides and count them per minute with table(floor(start / 60)).
#     Does it still loop after 34:57? Set minutes 35 to 44 beside the large
#     model's.
#  2. The ten words in words with the lowest probability, with their clock
#     times. Where in the conference do they fall?
# Speaker labels
#  3. Label each word by its start time instead of its midpoint. How many
#     words change label?
#  4. rle(is.na(words$speaker)) gives the runs of unlabelled words. How many
#     runs are there, and how many are the moderator calling a reporter by
#     name?
# Measures from the times
#  5. Powell's longest answer by words, his opening statement left out: its
#     start, end and length in seconds. Read its text. Is it one answer?
#  6. Every silence over 2.5 s between consecutive words in words, with the
#     words on either side and the clock time it ends. What happens in the
#     two longest?
#  7. For each Powell answer, the longest silence between words from the end
#     of the previous turn to the start of the answer. The median and the
#     longest, with its clock time, against the table's 1.76 s.
# Word-error rate
#  8. With earphones, write your own transcript of 0:06 to 0:36 of
#     data/clips/open2min.mp3 by the rules on the session page, before you
#     open any model file; save it as data_clean/my_opening.txt. Score the
#     large and small models' words that start before 36.6 s against it, and
#     against the Fed's text of the same passage.
#  9. Put the PDF's curly apostrophes back into the reference with
#     gsub("'", "\u2019", ...) and score the large model again. Which words
#     change, and what is the rate?
# Alignment
# 10. align(ref, hyps$small) lists the small model's nine errors on the
#     clip. Find each in data/clips/schneider30.mp3 with the times of the
#     model's segments, and listen. Which are wrong words, and which are
#     restarts?
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =


# The end
