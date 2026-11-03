# =============================================================
# AEM 6850 - Session 19: Audio
# Script 0 of 7 - a recording is a vector of numbers.
#
# Reads the first two minutes of the press conference of 1 February 2023
# as a WAV file: 16,000 samples a second, each a whole number. Prints the
# sampling rate, the number of samples, the first six values, and plots
# 50 milliseconds of Chair Powell's "Good" (the word starts near 7.05 s).
#
# Reads:  data/clips/open2min.wav
# Writes: data_clean/good_50ms.png
#
# Open 19-audio.Rproj first. It sits at the project root, so the
# working directory is 19-audio/ and every path below is relative to it.
#
#   source("code/0_sound.R")
# =============================================================

  # Load or install the packages this script uses
  want <- c("tuneR")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only=TRUE))
  rm(want, need)


# 1). Read the clip ----

  # a Wave object: the samples in wav@left (one channel: mono), the
  # sampling rate in wav@samp.rate, 16 bits per sample in wav@bit
  wav <- readWave("data/clips/open2min.wav")

  print(wav@samp.rate)              # samples a second (hertz)
  print(wav@bit)                    # bits per sample: whole numbers from -32,768 to 32,767
  print(length(wav@left))           # samples in the clip
  print(length(wav@left) / wav@samp.rate)   # seconds: 120

  # the first six samples: silence before anyone speaks
  print(wav@left[1:6])


# 2). Fifty milliseconds of "Good" ----

  # 50 ms from 7.05 s: 800 samples, starting at sample 7.05 * 16000 + 1
  i <- 112800 + 1:800
  print(wav@left[i[1:6]])

  png("data_clean/good_50ms.png", width = 1400, height = 700, res = 200)
  plot((i - 1) / wav@samp.rate, wav@left[i], type = "l",
       main = "\"Good\", 7.05 to 7.10 s", xlab = "seconds", ylab = "amplitude")
  dev.off()


# 3). The whole recording, by arithmetic ----

  # the full conference (44 min 37 s = 2,677 s) is not in the zip; at the
  # same rate it holds 2677 * 16000 samples, about 42.8 million numbers
  print(2677 * 16000)
