# =============================================================
# AEM 6850 - Session 19: Audio
# align(): where a model's words differ from the reference, one row per edit.
#
# adist() returns, with counts = TRUE, the path it took from one string to
# the other, one letter per step: M match, S substitution, D deletion,
# I insertion. align() walks that path and prints each edit with its
# position in the reference, the reference word and the model's word.
#
# Needs word_edits(), defined in code/7_wer.R (step 1) and on the slides.
# Sourced by code/7_wer.R.
#
#   source("code/align.R")
#   align(ref, hyp)        # ref and hyp: two vectors of words
# =============================================================

  align <- function(ref, hyp) {
    d <- word_edits(ref, hyp)
    ops <- strsplit(attr(d, "trafos")[1, 1], "")[[1]]
    i <- 0; j <- 0; out <- NULL
    for (op in ops) {
      if (op %in% c("M", "S", "D")) i <- i + 1    # a step that uses a reference word
      if (op %in% c("M", "S", "I")) j <- j + 1    # a step that uses a model word
      if (op != "M") out <- rbind(out, data.frame(
        op = op, ref_pos = i,
        ref   = if (op == "I") "" else ref[i],
        model = if (op == "D") "" else hyp[j]))
    }
    out
  }


# the end ----
