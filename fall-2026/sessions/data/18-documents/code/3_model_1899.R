# =============================================================
# AEM 6850 - Session 18: Documents & scans
# Script 3 of 8 - a vision model reads the 1899 bank table.
#
# Lecture part 3, a scan of a printed page. Asks a vision model to
# transcribe Table XVII of the 1899 report (data_clean/comp1899_p.png,
# FRASER page 693 = printed page 646), then scores its reading against
# the reference copy, the archive's OCR layer and tesseract (the last two
# from code/2_ocr_runs.R; run that first).
#
# One chat, two requests. A single chat_structured() call with the image
# alone returned one or two rows, the second labelled "placeholder", in
# three tries (replies/comp1899_direct_run*.json; set misc$direct_runs to
# 1:3 to reproduce). A plain chat() with the same image reads the whole
# table, so the run asks for the transcription as text first and then for
# the same rows as structured data.
#
# Reads:  data_clean/comp1899_p.png, data_clean/comp1899_truth.csv,
#         data_clean/ocr/comp1899_archive.csv, data_clean/ocr/comp1899_tess300.csv
# Writes: replies/comp1899_run1.json (and the markdown of the first request),
#         logs/comp1899_run1_meta.json, a line in logs/model_calls.csv,
#         data_clean/comp1899_model.csv
#
# A call is made only when its reply is missing from replies/, so with the
# folder as shipped this script makes no call. A new call needs ellmer and
# an API key in ANTHROPIC_API_KEY (set it in ~/.Renviron, never in code).
#
# Open 18-documents.Rproj first. It sits at the project root, so the
# working directory is 18-documents/ and every path below is relative to it.
#
#   source("code/3_model_1899.R")
# =============================================================


# 1). Preliminary ----

  # Load or install the packages this script uses
  want <- c("ellmer", "jsonlite")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only=TRUE))
  rm(want, need)

  # Parameters
  misc <- list()
  misc$model   <- "claude-sonnet-5-5"     # the medium model, the one the slides use
  misc$img     <- "data_clean/comp1899_p.png"
  misc$truth   <- "data_clean/comp1899_truth.csv"
  misc$archive <- "data_clean/ocr/comp1899_archive.csv"
  misc$tess    <- "data_clean/ocr/comp1899_tess300.csv"
  misc$out     <- "data_clean/comp1899_model.csv"
  misc$replies <- "replies"
  misc$logs    <- "logs"
  misc$log     <- "logs/model_calls.csv"  # one line per model call
  misc$runs        <- 1
  misc$direct_runs <- integer(0)
  misc$cols    <- c("national", "state", "loan_trust", "savings", "private", "total")
  misc$prompt  <- "This image is a scanned page of a printed statistical table. Return every row of the table, in order, as one object per row. Copy each number exactly as printed, in millions of dollars with one decimal as on the page. Where a cell is blank or unreadable return null. Do not compute or correct anything."
  misc$ask1    <- "Transcribe every row of the table on this page as a markdown table, one row per printed row, blank cells left empty."
  misc$ask2    <- "Now return the same rows as structured data."

  # The reply format: one object per printed row
  row_type <- type_object(
    row_label  = type_string(),
    national   = type_number(required = FALSE),
    state      = type_number(required = FALSE),
    loan_trust = type_number(required = FALSE),
    savings    = type_number(required = FALSE),
    private    = type_number(required = FALSE),
    total      = type_number(required = FALSE))

  # resize = "none": ellmer's default ("low") shrinks the image to fit
  # 512 x 512 px, which makes the digits unreadable. The 300-dpi render is
  # 1650 x 2550 px; the API accepts it as is.
  img <- function() content_image_file(misc$img, resize = "none")


# 2). Call the model, once per missing reply ----

  for (run in misc$runs) {
    out  <- file.path(misc$replies, sprintf("comp1899_run%d.json", run))
    meta <- file.path(misc$logs, sprintf("comp1899_run%d_meta.json", run))
    if (file.exists(out)) { message("have ", out); next }
    message("calling ", misc$model, " with ", misc$img, ", run ", run)
    chat <- chat_anthropic(model = misc$model, system_prompt = misc$prompt, cache = "none")
    t0 <- Sys.time()
    md    <- chat$chat(misc$ask1, img(), echo = "none")
    reply <- chat$chat_structured(misc$ask2, type = type_array(row_type))
    secs  <- as.numeric(Sys.time() - t0, units = "secs")
    write_json(reply, out, pretty = TRUE, digits = NA, auto_unbox = TRUE,
               null = "null", na = "null")
    writeLines(md, file.path(misc$replies, sprintf("comp1899_run%d_markdown.md", run)))
    tok <- chat$get_tokens()      # one row per assistant turn
    write_json(list(model = misc$model, image = misc$img, run = run, form = "two-step",
                    called_at = format(t0, "%Y-%m-%d %H:%M:%S"), seconds = round(secs, 1),
                    input_tokens = sum(tok$input), output_tokens = sum(tok$output),
                    cached_input_tokens = sum(tok$cached_input),
                    turns = nrow(tok), rows_returned = nrow(reply),
                    system_prompt = misc$prompt, ask1 = misc$ask1, ask2 = misc$ask2),
               meta, pretty = TRUE, auto_unbox = TRUE, digits = NA)
    write.table(data.frame(size = "medium", model = misc$model, page = "1899", run = run,
                           called_at = format(t0, "%Y-%m-%d %H:%M:%S"), seconds = round(secs, 1),
                           input_tokens = sum(tok$input), output_tokens = sum(tok$output)),
                misc$log, sep = ",", append = TRUE, col.names = FALSE, row.names = FALSE)
    cat(sprintf("run %d: %.1f s, %d input tokens, %d output tokens over %d turns, %d rows\n",
                run, secs, sum(tok$input), sum(tok$output), nrow(tok), nrow(reply)))
  }

  # the one-call form, kept for the record
  for (run in misc$direct_runs) {
    out <- file.path(misc$replies, sprintf("comp1899_direct_run%d.json", run))
    if (file.exists(out)) { message("have ", out); next }
    chat <- chat_anthropic(model = misc$model, system_prompt = misc$prompt, cache = "none")
    t0 <- Sys.time()
    reply <- chat$chat_structured(img(), type = type_array(row_type))
    secs <- as.numeric(Sys.time() - t0, units = "secs")
    write_json(reply, out, pretty = TRUE, digits = NA, auto_unbox = TRUE, null = "null", na = "null")
    tok <- chat$get_tokens()
    cat(sprintf("direct run %d: %.1f s, %d in, %d out, %d rows\n",
                run, secs, sum(tok$input), sum(tok$output), nrow(reply)))
  }


# 3). The model's reading against the reference copy ----

  COLS  <- misc$cols
  truth <- read.csv(misc$truth, stringsAsFactors = FALSE)
  meta  <- fromJSON(file.path(misc$logs, "comp1899_run1_meta.json"))
  cat(sprintf("\nmodel %s, called %s: %.1f s, %d input + %d output tokens, %d rows\n",
              meta$model, meta$called_at, meta$seconds, meta$input_tokens,
              meta$output_tokens, meta$rows_returned))
  model <- fromJSON(file.path(misc$replies, "comp1899_run1.json"))
  for (cc in COLS) if (!cc %in% names(model)) model[[cc]] <- NA_real_
  model[COLS] <- lapply(model[COLS], as.numeric)

  # components vs Total
  has_total <- !is.na(model$total)
  comp <- rowSums(model[, COLS[1:5]], na.rm = TRUE)
  pass <- has_total & abs(comp - model$total) <= 0.15
  cat(sprintf("components vs Total (|diff| <= 0.15): %d of %d rows with a Total pass\n",
              sum(pass), sum(has_total)))
  if (any(!pass)) print(model[!pass, c("row_label", COLS)], row.names = FALSE)

  # align with the reference by label (same rule as code/2_ocr_runs.R)
  norm <- function(s) tolower(gsub("[^A-Za-z]", "", s))
  tn <- norm(truth$row_label); mn <- norm(model$row_label)
  read <- truth; read[, COLS] <- NA_real_
  p <- 1L; aligned <- 0L
  for (i in seq_len(nrow(model))) {
    if (p > nrow(truth)) break
    cand <- p:min(p + 3L, nrow(truth))
    d <- sapply(cand, function(j) adist(substr(mn[i], 1, nchar(tn[j])), tn[j]))
    lim <- ifelse(nchar(tn[cand]) >= 7, 3, 2)
    ok <- which(d <= lim)
    if (length(ok)) { j <- cand[ok[which.min(d[ok])]]; read[j, COLS] <- model[i, COLS]; p <- j + 1L; aligned <- aligned + 1L }
  }
  same <- (is.na(read[, COLS]) & is.na(truth[, COLS])) |
          (!is.na(read[, COLS]) & !is.na(truth[, COLS]) & abs(read[, COLS] - truth[, COLS]) < 0.05)
  cat(sprintf("rows aligned to the truth: %d of %d; cells right %d, wrong %d (of %d)\n",
              aligned, nrow(truth), sum(same), sum(!same), length(same)))
  w <- which(!same, arr.ind = TRUE)
  if (nrow(w)) print(data.frame(row_label = truth$row_label[w[, 1]], col = COLS[w[, 2]],
                                truth = truth[, COLS][w], model = read[, COLS][w]), row.names = FALSE)
  write.csv(read, misc$out, row.names = FALSE)


# 4). Three readings cell by cell: archive layer, tesseract 300 dpi, model ----

  arch <- read.csv(misc$archive); tess <- read.csv(misc$tess)
  eq <- function(a, b) (is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & abs(a - b) < 0.05)
  T <- as.matrix(truth[, COLS]); A <- as.matrix(arch[, COLS]); B <- as.matrix(tess[, COLS]); M <- as.matrix(read[, COLS])
  a_ok <- eq(A, T); b_ok <- eq(B, T); m_ok <- eq(M, T)
  cat(sprintf("\ncells (%d): archive right %d, tesseract right %d, model right %d\n",
              length(T), sum(a_ok), sum(b_ok), sum(m_ok)))
  cat("all three agree with each other:", sum(eq(A, B) & eq(B, M)),
      " (and with the truth:", sum(eq(A, B) & eq(B, M) & m_ok), ")\n")
  cat("model right where the archive layer is wrong:", sum(m_ok & !a_ok), "of", sum(!a_ok), "\n")
  cat("model right where tesseract is wrong:", sum(m_ok & !b_ok), "of", sum(!b_ok), "\n")
  cat("model right where either OCR is wrong:", sum(m_ok & (!a_ok | !b_ok)), "of", sum(!a_ok | !b_ok), "\n")
  cat("model wrong:", sum(!m_ok), "cells\n")
  w <- which(!m_ok, arr.ind = TRUE)
  if (nrow(w)) print(data.frame(row_label = truth$row_label[w[, 1]], col = COLS[w[, 2]],
                                truth = T[w], model = M[w], archive = A[w], tesseract = B[w]),
                     row.names = FALSE)


# the end ----
