# =============================================================
# AEM 6850 - Session 20: Audio II
# Script 1 of 3 - pitch level, pitch range and energy of a recording.
#
# A tone of known pitch first, then one clip of Powell, the same clip at half
# the volume, the turns of a 160-s excerpt, and a clip against his baseline.
#
# Reads:  data/clips/, data_clean/turns_excerpt.csv, data_clean/tone.csv
# Writes: data_clean/tone120.wav, data_clean/half.wav
#
# Open 20-audio-ii.Rproj first. It sits at the project root, so the
# working directory is 20-audio-ii/ and every path below is relative to it.
#
#   source("code/1_pitch_energy.R")
# =============================================================

# 1). Preliminary ----

  # Load or install the packages this script uses
  want <- c("wrassp", "tuneR")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only=TRUE))
  rm(want, need)

# 2). A known tone ----

  x <- round(8000 * sin(2 * pi * 120 * (1:48000) / 16000))     # 3 s at 120 Hz
  writeWave(Wave(x, samp.rate = 16000, bit = 16), "data_clean/tone120.wav")
  p <- ksvF0("data_clean/tone120.wav", gender = "m", toFile = FALSE)
  print(length(p$F0))             # 600: one value every 5 ms
  print(median(p$F0[p$F0 > 0]))   # 120.03

# 3). One clip: 3 Nov 2021, 25:15, 15 s ----

  f <- "data/clips/activated.wav"
  voice <- function(f, from = 0, to = 0) {
    p <- ksvF0(f, beginTime = from, endTime = to, gender = "m", toFile = FALSE)
    e <- rmsana(f, beginTime = from, endTime = to, toFile = FALSE)
    v <- p$F0[p$F0 > 0]       # the voiced frames
    c(pitch = median(v), range = IQR(v), energy = mean(e$rms), voiced = mean(p$F0 > 0))
  }
  print(round(voice(f), 2))

  # The two tracks: voiced frames, then energy
  p <- ksvF0(f, gender = "m", toFile = FALSE); e <- rmsana(f, toFile = FALSE)
  pitch_track <- p$F0; pitch_track[pitch_track == 0] <- NA
  op <- par(mfrow = c(2, 1), mar = c(4, 4, 1, 1))
  plot((seq_along(pitch_track) - 1) * 0.005, pitch_track, pch = 16, cex = 0.4,
       xlab = "Seconds into the answer", ylab = "Pitch, Hz")
  plot((seq_along(e$rms) - 1) * 0.005, e$rms, type = "l", xlab = "Seconds into the answer", ylab = "Energy, dB")
  par(op)

# 4). Halving the volume ----

  w <- readWave(f)
  w@left <- as.integer(round(w@left / 2))    # every sample cut in half
  writeWave(w, "data_clean/half.wav")
  print(round(rbind(as_recorded = voice(f), half = voice("data_clean/half.wav")), 2))

# 5). Per turn: 160 s of 3 Nov 2021, starting at 480 s ----

  turns <- read.csv("data_clean/turns_excerpt.csv")
  g <- "data/clips/excerpt_20211103.wav"
  m <- t(sapply(1:nrow(turns), function(i) voice(g, turns$start[i] - 480, turns$end[i] - 480)))
  print(cbind(turns[, c("speaker", "start", "end")], round(m, 2)))

# 6). A clip against Powell's baseline, first 15 s against first 15 s ----

  tone <- read.csv("data_clean/tone.csv")
  ans  <- tone[tone$type == "answer" & tone$end - tone$start >= 15, ]   # 571 answers
  z <- function(x, base = x) (x - mean(base)) / sd(base)
  read_clip <- function(v, d) round(c(pitch = z(v[["pitch"]], d$pitch15), range = z(v[["range"]], d$iqr15),
                                      energy = z(v[["energy"]], d$energy15)), 2)
  nov <- ans[ans$date == "2021-11-03", ]
  print(read_clip(voice(f), nov))

# 7). Exercise 1 ----

  a <- voice("data/clips/answer_20211103.wav")
  b <- voice("data/clips/answer_20230201.wav")
  feb <- ans[ans$date == "2023-02-01", ]
  print(round(rbind(a, b), 2))
  print(rbind(a = read_clip(a, nov), b = read_clip(b, feb)))

# the end ----
