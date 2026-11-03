# =============================================================
# AEM 6850 - Session 19: Audio
# Master file. Runs every script, in the order the lecture uses them.
#
# Open 19-audio.Rproj first. It sits at the project root, so the
# working directory is 19-audio/ and every path below is relative to it.
#
#   source("code/run_everything.R")     from the R console
#   Rscript code/run_everything.R       from a terminal, run in 19-audio/
#
# 1_words.R          Whisper's words, one row per word, beside the Fed's count
# 2_speakers.R       the speaker segments: who spoke when
# 3_join_turns.R     a speaker label on every word, then turns
# 4_utterances.R     one row per turn: speaker, start, end, text
# 5_pauses.R         pauses before answers, the silence between words, speaking rate, "you know"
# 6_wer.R            word-error rate of four runs on a 30-second clip (sources align.R)
#
# The scripts read only what is in replies/ and data_clean/, so they run
# in a few seconds and need neither Python nor the audio files.
# =============================================================

  rm(list = ls())

  # each script's output under a header with its name
  cat("\n==== code/1_words.R ====\n\n");      source("code/1_words.R")
  cat("\n==== code/2_speakers.R ====\n\n");   source("code/2_speakers.R")
  cat("\n==== code/3_join_turns.R ====\n\n"); source("code/3_join_turns.R")
  cat("\n==== code/4_utterances.R ====\n\n"); source("code/4_utterances.R")
  cat("\n==== code/5_pauses.R ====\n\n");     source("code/5_pauses.R")
  cat("\n==== code/6_wer.R ====\n\n");        source("code/6_wer.R")
