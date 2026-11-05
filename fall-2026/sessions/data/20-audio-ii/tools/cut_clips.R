# =============================================================
# AEM 6850 - Session 20: Audio II
# Tool, run before class. Students do not run it: it reads the full recordings.
#
# Cuts the clips in data/clips/ from data/media/ with ffmpeg, as 16 kHz mono WAV
# and 64 kb/s MP3, and writes data_clean/clips.csv and data_clean/turns_excerpt.csv.
# clip1 to clip8 are the seeded draw, each brought to one level by one gain so they
# play on the same footing; pitch, range and energy in clips.csv are measured on the
# cuts as recorded. Clips 4 and 7 start just after the drawn time, past the end of the
# reporter's words and a fragment of a phrase. Scores come from replies/emotion_clips.csv.
#
#   Rscript tools/cut_clips.R        from the project folder
# =============================================================

  want <- c("wrassp", "tuneR")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only=TRUE))
  rm(want, need)

# 1). Preliminary ----

  misc <- list(level = 58, out = "data/clips")          # dB, the level clip1 to clip8 play at
  dir.create(misc$out, showWarnings = FALSE, recursive = TRUE)
  rec <- function(d) sprintf("data/media/fomc%s.wav", gsub("-", "", d))
  cut <- function(d, s, len, to, gain = 0)
    system2("ffmpeg", c("-nostdin -loglevel error -y -ss", s, "-i", rec(d), "-t", len,
                        if (gain != 0) c("-af", sprintf("volume=%.2fdB", gain)),
                        "-ac 1 -ar 16000 -c:a pcm_s16le", to))
  mp3 <- function(w) system2("ffmpeg", c("-nostdin -loglevel error -y -i", w, "-b:a 64k",
                                         sub("wav$", "mp3", w)))
  voice <- function(f, from = 0, to = 0) {
    p <- ksvF0(f, beginTime = from, endTime = to, gender = "m", toFile = FALSE)
    e <- rmsana(f, beginTime = from, endTime = to, toFile = FALSE)
    v <- p$F0[p$F0 > 0]
    c(pitch = median(v), range = IQR(v), energy = mean(e$rms), voiced = mean(p$F0 > 0))
  }

# 2). The named clips, as recorded ----

  named <- rbind(c("calm", "2021-11-03", 2388.72), c("activated", "2021-11-03", 1514.68),
                 c("jun2022", "2022-06-15", 583.88), c("sep2023", "2023-09-20", 551.12),
                 c("answer_20211103", "2021-11-03", 504.62), c("answer_20230201", "2023-02-01", 452.63))
  for (i in 1:nrow(named)) {
    w <- file.path(misc$out, paste0(named[i, 1], ".wav"))
    cut(named[i, 2], named[i, 3], 15, w)
    mp3(w)
  }
  cut("2021-11-03", 480, 160, file.path(misc$out, "excerpt_20211103.wav"))

# 3). The eight drawn clips, at one level ----

  tone <- read.csv("data_clean/tone.csv")
  ans  <- tone[tone$type == "answer" & tone$end - tone$start >= 15, ]
  ans  <- ans[order(ans$date, ans$start), ]
  set.seed(6850)
  pick <- ans[sample(nrow(ans), 8), c("date", "start")]
  later <- c(0, 0, 0, 0.35, 0, 0, 0.42, 0)              # clips 4 and 7, see the banner
  scores <- read.csv("replies/emotion_clips.csv")
  clips <- data.frame()
  for (k in 1:8) {
    s <- pick$start[k] + later[k]
    tmp <- tempfile(fileext = ".wav")
    cut(pick$date[k], s, 15, tmp)
    v <- voice(tmp)
    w <- file.path(misc$out, sprintf("clip%d.wav", k))
    cut(pick$date[k], s, 15, w, gain = misc$level - v[["energy"]])
    mp3(w)
    sc <- scores[scores$clip == sprintf("clip%d", k), ]
    clips <- rbind(clips, data.frame(clip = k, date = pick$date[k], start = pick$start[k], cut = s,
                                     pitch = v[["pitch"]], range = v[["range"]], energy = v[["energy"]],
                                     gain = misc$level - v[["energy"]], peak = max(abs(readWave(w)@left)),
                                     arousal = sc$arousal, valence = sc$valence))
  }
  write.csv(clips[, setdiff(names(clips), "peak")], "data_clean/clips.csv", row.names = FALSE)
  print(clips[, c("clip", "date", "cut", "pitch", "range", "energy", "gain", "peak", "arousal")], digits = 4)

# 4). The turns inside the excerpt ----

  turns <- tone[tone$date == "2021-11-03" & tone$start >= 480 & tone$end <= 640, c("turn", "speaker", "type", "start", "end")]
  write.csv(turns, "data_clean/turns_excerpt.csv", row.names = FALSE)
  print(turns)

# the end ----
