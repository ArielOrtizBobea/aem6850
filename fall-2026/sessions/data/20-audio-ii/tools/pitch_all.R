# =============================================================
# AEM 6850 - Session 20: Audio II
# Tool, run before class. Students do not run it: it reads the 24 full
# recordings in data/media/ (7 GB), which are not in the zip.
#
# Adds to data_clean/tone.csv, one row per turn:
#   pitch, pitch_iqr, voiced, energy     measured over the whole turn
#   pitch15, iqr15, energy15, voiced15   first 15 s of each answer of 15 s or more
#   arousal15, dominance15, valence15    the model's direct 15-s scores, replies/emotion_openings.csv
# Writes data_clean/quiet.csv: the quiet levels of each recording.
#
# Run after tools/build/run_everything.R, from the project folder:
#   Rscript tools/pitch_all.R
# The first pass over the 24 recordings takes about a minute on an Apple M2 Max.
# =============================================================

  # Load or install the packages this script uses
  want <- c("wrassp")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only=TRUE))
  rm(want, need)

# 1). Whole turns, and the openings of answers ----

  base <- c("date","turn","speaker","type","start","end","words","arousal","dominance","valence")
  tone <- read.csv("data_clean/tone.csv")[, base]
  long <- tone$type == "answer" & tone$end - tone$start >= 15
  add  <- c("pitch","pitch_iqr","voiced","energy","pitch15","iqr15","energy15","voiced15")
  tone[add] <- NA_real_
  quiet <- list()
  for (d in unique(tone$date)) {
    f <- file.path("data/media", paste0("fomc", gsub("-", "", d), ".wav"))
    p <- ksvF0(f, gender = "m", toFile = FALSE)
    e <- rmsana(f, toFile = FALSE)
    tp <- attr(p, "startTime") + (seq_along(p$F0) - 1) / attr(p, "sampleRate")
    te <- attr(e, "startTime") + (seq_along(e$rms) - 1) / attr(e, "sampleRate")
    for (i in which(tone$date == d)) {
      kp <- tp >= tone$start[i] & tp <= tone$end[i]
      v  <- p$F0[kp]; v <- v[v > 0]
      if (length(v) >= 40) { tone$pitch[i] <- median(v); tone$pitch_iqr[i] <- IQR(v) }
      tone$voiced[i] <- length(v) / max(1, sum(kp))
      ke <- te >= tone$start[i] & te <= tone$end[i]
      if (any(ke)) tone$energy[i] <- mean(e$rms[ke])
      if (long[i]) {
        o <- ksvF0(f, beginTime = tone$start[i], endTime = tone$start[i] + 15, gender = "m", toFile = FALSE)
        r <- rmsana(f, beginTime = tone$start[i], endTime = tone$start[i] + 15, toFile = FALSE)
        tone$pitch15[i]  <- median(o$F0[o$F0 > 0])
        tone$iqr15[i]    <- IQR(o$F0[o$F0 > 0])
        tone$energy15[i] <- mean(r$rms)
        tone$voiced15[i] <- mean(o$F0 > 0)
      }
    }
    r <- as.vector(e$rms)
    quiet[[d]] <- data.frame(date = d, q01 = unname(quantile(r, 0.01)),
                             q10 = unname(quantile(r, 0.10)), med = median(r))
    cat(d, "\n")
  }

# 2). The model's direct 15-s scores ----

  o <- read.csv("replies/emotion_openings.csv")
  names(o)[names(o) %in% c("arousal","dominance","valence")] <- c("arousal15","dominance15","valence15")
  tone <- merge(tone, o, by = c("date","start"), all.x = TRUE, sort = FALSE)
  tone <- tone[order(tone$date, tone$turn), c(base, add, "arousal15","dominance15","valence15")]
  write.csv(tone, "data_clean/tone.csv", row.names = FALSE)
  write.csv(do.call(rbind, quiet), "data_clean/quiet.csv", row.names = FALSE)

# the end ----
