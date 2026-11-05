# =============================================================
# AEM 6850 - Session 20: Audio II
# Script 3 of 3 - Powell through the hikes.
#
# Variance between conferences, Powell against the reporters, hikes against
# holds, and arousal through the Q&A within a conference.
#
# Reads:  data_clean/tone.csv, data_clean/meetings.csv
# Writes: nothing
#
# Open 20-audio-ii.Rproj first. It sits at the project root, so the
# working directory is 20-audio-ii/ and every path below is relative to it.
#
#   source("code/3_conferences.R")
# =============================================================

# 1). Preliminary ----

  tone <- read.csv("data_clean/tone.csv")
  ans  <- tone[tone$type == "answer" & tone$end - tone$start >= 15, ]   # 571 answers
  z <- function(x, base = x) (x - mean(base)) / sd(base)

# 2). Energy and pitch by conference ----

  share <- function(x, g) 1 - sum((x - ave(x, g))^2) / sum((x - mean(x))^2)
  print(round(sapply(ans[, c("energy", "pitch", "arousal", "valence")], share, g = ans$date), 2))
  conf <- aggregate(cbind(pitch, energy, arousal) ~ date, ans, median)
  meet <- read.csv("data_clean/meetings.csv")
  conf <- merge(conf, meet[, c("date", "decision")])
  others <- tone[tone$type == "other" & tone$end - tone$start >= 10 & !is.na(tone$energy), ]
  conf <- merge(conf, setNames(aggregate(energy ~ date, others, median), c("date", "reporters")))
  print(round(cor(conf$energy, conf$reporters), 2))
  plot(as.Date(conf$date), conf$pitch, pch = ifelse(conf$decision == "hike", 19, 1),
       ylim = c(85, 105), xlab = "Press conference", ylab = "Powell's median pitch, Hz")
  abline(v = as.Date("2022-05-04"), lty = 2)
  legend("topright", c("Rate hike", "Hold"), pch = c(19, 1))

# 3). Hikes against holds ----

  later <- conf$decision == "hold" & conf$date >= "2022-03-01"
  print(round(rbind(hike  = colMeans(conf[conf$decision == "hike", c("pitch", "arousal", "energy")]),
                    hold  = colMeans(conf[conf$decision == "hold", c("pitch", "arousal", "energy")]),
                    later = colMeans(conf[later, c("pitch", "arousal", "energy")])), 3))

# 4). Arousal through the Q&A ----

  ans$quarter <- ave(ans$start, ans$date, FUN = function(s) ceiling(4 * rank(s) / length(s)))  # 1 to 4
  by_quarter <- function(v) tapply(ave(ans[[v]], ans$date, FUN = z), ans$quarter, mean)        # z within date
  print(round(sapply(c("arousal", "energy", "pitch"), by_quarter), 2))

# the end ----
