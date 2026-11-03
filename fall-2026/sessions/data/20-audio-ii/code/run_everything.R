# =============================================================
# AEM 6850 - Session 20: Audio II
# Master file. Runs every script, in the order the lecture uses them.
#
# Open 20-audio-ii.Rproj first. It sits at the project root, so the
# working directory is 20-audio-ii/ and every path below is relative to it.
#
#   source("code/run_everything.R")     from the R console
#   Rscript code/run_everything.R       from a terminal, run in 20-audio-ii/
#
# 1_words.R          Whisper's words, one row per word, speaker tags removed
# 2_speakers.R       the speaker segments: who spoke when
# 3_utterances.R     a label on every word, turns, Powell's statement and answers
# 4_tone.R           arousal, dominance and valence for each utterance
# 5_meetings.R       one row per conference, with the day's decision
#
# The scripts read only data/meetings.csv, replies/ and data_clean/, so
# they run in about ten seconds and need neither Python nor the audio files.
# =============================================================

  rm(list = ls())

  # each script's output under a header with its name
  cat("\n==== code/1_words.R ====\n\n");      source("code/1_words.R")
  cat("\n==== code/2_speakers.R ====\n\n");   source("code/2_speakers.R")
  cat("\n==== code/3_utterances.R ====\n\n"); source("code/3_utterances.R")
  cat("\n==== code/4_tone.R ====\n\n");       source("code/4_tone.R")
  cat("\n==== code/5_meetings.R ====\n\n");   source("code/5_meetings.R")


# the end ----
