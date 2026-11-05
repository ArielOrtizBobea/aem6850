# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# AEM 6850 -- Empirical Methods for Applied Economists
# Prof. Ariel Ortiz-Bobea
# Session 20 -- Audio II: tone & emotion
# Thursday, November 5, 2026
#
# Run it one line at a time: put the cursor on a line and press Cmd-Return
# (Mac) or Ctrl-Enter (Windows).
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# Pitch of a known tone ----
want <- c("wrassp", "tuneR")
need <- want[!(want %in% installed.packages()[,"Package"])]
if (length(need)) install.packages(need)
lapply(want, function(i) require(i, character.only = TRUE))
rm(want, need)
x <- round(8000 * sin(2 * pi * 120 * (1:48000) / 16000))     # 3 s at 120 Hz
writeWave(Wave(x, samp.rate = 16000, bit = 16), "data_clean/tone120.wav")
p <- ksvF0("data_clean/tone120.wav", gender = "m", toFile = FALSE)
length(p$F0)             # 600: one value every 5 ms
median(p$F0[p$F0 > 0])   # 120.03


# Pitch and energy of one clip ----
f <- "data/clips/activated.wav"
p <- ksvF0(f, gender = "m", toFile = FALSE)
round(p$F0[786:793], 1)     # 3.93 to 3.96 s: zeros, then voice starts
voice <- function(f, from = 0, to = 0) {
  p <- ksvF0(f, beginTime = from, endTime = to, gender = "m", toFile = FALSE)
  e <- rmsana(f, beginTime = from, endTime = to, toFile = FALSE)
  v <- p$F0[p$F0 > 0]       # the voiced frames
  c(pitch = median(v), range = IQR(v), energy = mean(e$rms), voiced = mean(p$F0 > 0))
}
round(voice(f), 2)


# Halving the volume ----
w <- readWave(f)
w@left <- as.integer(round(w@left / 2))    # every sample cut in half
writeWave(w, "data_clean/half.wav")
round(rbind(as_recorded = voice(f), half = voice("data_clean/half.wav")), 2)


# Pitch and energy per turn ----
turns <- read.csv("data_clean/turns_excerpt.csv")
g <- "data/clips/excerpt_20211103.wav"          # 160 s of 3 Nov 2021, starting at 480 s
m <- t(sapply(1:nrow(turns), function(i) voice(g, turns$start[i] - 480, turns$end[i] - 480)))
cbind(turns[, c("speaker", "start", "end")], round(m, 2))


# A clip against Powell's baseline ----
tone <- read.csv("data_clean/tone.csv")
ans  <- tone[tone$type == "answer" & tone$end - tone$start >= 15, ]   # 571 answers
z <- function(x, base = x) (x - mean(base)) / sd(base)
nov <- ans[ans$date == "2021-11-03", ]             # his 21 answers that day
v <- voice(f)
round(c(pitch  = z(v[["pitch"]], nov$pitch15),
        range  = z(v[["range"]], nov$iqr15),
        energy = z(v[["energy"]], nov$energy15)), 2)


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Exercise 1 (5 minutes) ----
# Exercise 1 (5 minutes). Two clips, each against Powell's answers that day.
# In the 20-audio-ii folder, with voice(), z() and ans as on the slides before.
# Clips, first 15 s of each answer:
#   data/clips/answer_20211103.wav   3 Nov 2021, 8:25
#   data/clips/answer_20230201.wav   1 Feb 2023, 7:33
# 1. Run voice() on each clip.
# 2. Keep his answers on each date from ans.
# 3. z-score each clip's pitch, range and energy against its own date,
#    with pitch15, iqr15 and energy15.
# Two answers to compare with the room: which clip is higher in hertz,
# and which is higher against its own day.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




# Eight clips drawn at random ----
ans <- ans[order(ans$date, ans$start), ]            # the 571 answers in a fixed order
set.seed(6850)
pick <- ans[sample(nrow(ans), 8), c("date", "start")]
s <- round(pick$start)
pick$clock <- sprintf("%d:%02d", s %/% 60, s %% 60)  # seconds to m:ss
rownames(pick) <- 1:8
pick[, c("date", "clock")]
clips <- read.csv("data_clean/clips.csv")           # holds the scores too: print none before rating
round(cor(clips$pitch, clips$energy), 2)            # cor() on pitch and energy, so no score shows yet


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Exercise 2 (7 minutes) ----
# Exercise 2 (7 minutes). The model's arousal score against your ear.
# In the 20-audio-ii folder, with clips and z() as on the slides before.
# 1. Listen to clips 1 to 8 in order. Rate each: 1 calm and flat, 3 ordinary,
#    5 animated and urgent. Rate before anything else.
# 2. mine      <- c( , , , , , , , )     # your eight ratings
#    neighbour <- c( , , , , , , , )     # a neighbour's eight
# 3. cor(mine, clips$arousal)  and  cor(mine, neighbour)
# 4. round(z(mine) - z(clips$arousal), 2)   # your gap from the model, clip by clip
# Two answers to compare with the room: your cor() with the model beside your
# cor() with your neighbour, and the clip with your largest gap.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




# Energy and pitch by conference ----
share <- function(x, g) 1 - sum((x - ave(x, g))^2) / sum((x - mean(x))^2)
round(sapply(ans[, c("energy", "pitch", "arousal", "valence")], share, g = ans$date), 2)
conf <- aggregate(cbind(pitch, energy, arousal) ~ date, ans, median)
meet <- read.csv("data_clean/meetings.csv")
conf <- merge(conf, meet[, c("date", "decision")])
others <- tone[tone$type == "other" & tone$end - tone$start >= 10 & !is.na(tone$energy), ]
conf <- merge(conf, setNames(aggregate(energy ~ date, others, median), c("date", "reporters")))
round(cor(conf$energy, conf$reporters), 2)
plot(as.Date(conf$date), conf$pitch, pch = ifelse(conf$decision == "hike", 19, 1),
     ylim = c(85, 105), xlab = "Press conference", ylab = "Powell's median pitch, Hz")
abline(v = as.Date("2022-05-04"), lty = 2)
legend("topright", c("Rate hike", "Hold"), pch = c(19, 1))


# Hikes against holds ----
later <- conf$decision == "hold" & conf$date >= "2022-03-01"
round(rbind(hike  = colMeans(conf[conf$decision == "hike", c("pitch", "arousal", "energy")]),
            hold  = colMeans(conf[conf$decision == "hold", c("pitch", "arousal", "energy")]),
            later = colMeans(conf[later, c("pitch", "arousal", "energy")])), 3)


# Arousal through the Q&A ----
ans$quarter <- ave(ans$start, ans$date, FUN = function(s) ceiling(4 * rank(s) / length(s)))  # 1 to 4: position in that day's Q&A
by_quarter <- function(v) tapply(ave(ans[[v]], ans$date, FUN = z), ans$quarter, mean)        # z within date, then mean by quarter
round(sapply(c("arousal", "energy", "pitch"), by_quarter), 2)


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Practice ----
# Practice. Run in the 20-audio-ii folder after the slides' code has built
# voice(), z(), ans (with quarter), clips, conf and others.
# None needs Python, an account or the network.

# By ear and by tracker
#  1. Rate the eight clips for valence, 1 to 5, then cor() with clips$valence.
#  2. Run the second tracker mhsF0() (it returns $pitch) on the two clips of
#     Exercise 1. How far does the gap between them move?
# The clips
#  3. Halve the clips of Exercise 1, as on the slide. What moves?
#  4. In data/clips/activated.wav, what share of voiced frames lies outside 2/3 to
#     1.5 times the median? Draw the track with plot(p$F0).
#  5. Read the clips of Exercise 1 against all 571 answers instead of their own day.
#     What happens to the signs?
# Across conferences
#  6. First against last quarter per conference. In how many does arousal fall?
#     Energy? Pitch?
#  7. Reporters against Powell by conference, in levels and with diff(), for energy,
#     pitch and arousal.
#  8. Means of conference medians before and after 4 May 2022, for Powell and for the
#     reporters. What else changed in May 2022?
# Your own voice
#  9. Record yourself on a phone, convert the file with
#     av::av_audio_convert(file, "me.wav", channels = 1, sample_rate = 16000)
#     and run voice("me.wav"). Levels from a phone cannot be compared with the Fed's.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =


# The end
