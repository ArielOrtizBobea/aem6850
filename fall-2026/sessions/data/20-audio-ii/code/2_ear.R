# =============================================================
# AEM 6850 - Session 20: Audio II
# Script 2 of 3 - the emotion score against your ear.
#
# The seeded draw of eight clips, then the model's arousal for the 15 s played.
# Type your ratings into mine and neighbour in section 3 and run that section.
#
# Reads:  data_clean/tone.csv, data_clean/clips.csv
# Writes: nothing
#
# Open 20-audio-ii.Rproj first. It sits at the project root, so the
# working directory is 20-audio-ii/ and every path below is relative to it.
#
#   source("code/2_ear.R")
# =============================================================

# 1). The draw ----

  tone <- read.csv("data_clean/tone.csv")
  ans  <- tone[tone$type == "answer" & tone$end - tone$start >= 15, ]
  ans  <- ans[order(ans$date, ans$start), ]          # the 571 answers in a fixed order
  set.seed(6850)
  pick <- ans[sample(nrow(ans), 8), c("date", "start")]
  s <- round(pick$start)
  pick$clock <- sprintf("%d:%02d", s %/% 60, s %% 60)  # seconds to m:ss
  rownames(pick) <- 1:8
  print(pick[, c("date", "clock")])

# 2). The clips ----

  clips <- read.csv("data_clean/clips.csv")          # holds the scores too: print none before rating
  print(round(cor(clips$pitch, clips$energy), 2))

# 3). Exercise 2, after rating ----

  z <- function(x, base = x) (x - mean(base)) / sd(base)
  # mine      <- c( , , , , , , , )                  # your eight ratings
  # neighbour <- c( , , , , , , , )                  # a neighbour's eight
  # cor(mine, clips$arousal); cor(mine, neighbour)
  # round(z(mine) - z(clips$arousal), 2)             # your gap from the model, clip by clip

# 4). How far eight clips go: 20,000 sets of random ratings ----

  set.seed(6850)
  sims <- suppressWarnings(replicate(20000, cor(sample(1:5, 8, TRUE), clips$arousal)))
  print(round(mean(abs(sims) > 0.5, na.rm = TRUE), 3))

# the end ----
