# =============================================================
# AEM 6850 - Session 19: Audio
# Script 5 of 7 - from sound to words in R: the 30-second clip transcribed.
#
# Runs an open speech-to-text model (Whisper) inside R with the whisper
# package from CRAN, on 30 seconds of Powell's answer to Howard Schneider
# (16:09.6 to 16:39.6 in the video), and sets its words beside the Fed's
# text of the same passage.
#
# Reads:  data/clips/schneider30.wav, replies/clip30_fed.txt
# Writes: data_clean/clip30_<model>.txt
#
# The first run downloads, once: torch's own library (a few MB) and the
# model file (tiny 151 MB, base 290 MB) into R's cache. No account is
# needed. Needs R 4.5 or later.
#
# Open 19-audio.Rproj first. It sits at the project root, so the
# working directory is 19-audio/ and every path below is relative to it.
#
#   source("code/5_transcribe.R")
# =============================================================

  # Load or install the packages this script uses
  want <- c("whisper")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)

  # torch, which whisper runs on, needs its own library once. It is checked
  # and installed in a separate R, because a session that has already
  # loaded torch cannot use a library installed after it.
  rscript <- file.path(R.home("bin"), "Rscript")
  if (system2(rscript, c("-e", shQuote("quit(status = !torch::torch_is_installed())"))) != 0)
    system2(rscript, c("-e", shQuote("torch::install_torch()")))

  lapply(want, function(i) require(i, character.only=TRUE))
  rm(want, need, rscript)
  options(whisper.consent = TRUE)   # lets the script download the model file once


# 1). Transcribe the clip ----

  model <- "tiny"                   # or "base": twice the size, fewer errors
  t0 <- Sys.time()
  out <- transcribe("data/clips/schneider30.wav", model = model, language = "en",
                    verbose = FALSE)
  print(Sys.time() - t0)            # a few seconds once the model is downloaded
  cat(strwrap(out$text, 80), sep = "\n")
  writeLines(out$text, paste0("data_clean/clip30_", model, ".txt"))


# 2). The Fed's text of the same 30 seconds ----

  fed <- readLines("replies/clip30_fed.txt", encoding = "UTF-8", warn = FALSE)
  cat(strwrap(fed, 80), sep = "\n")

  # word counts of the two texts
  print(c(model = length(strsplit(trimws(out$text), "\\s+")[[1]]),
    fed   = length(strsplit(trimws(paste(fed, collapse = " ")), "\\s+")[[1]])))
