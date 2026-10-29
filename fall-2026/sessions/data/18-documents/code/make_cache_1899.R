# make_cache_1899.R: ask a vision model to transcribe the 1899 Comptroller
# table (comp1899_p.png, FRASER page 693 = printed page 646), then compare
# its reading with the truth file, the archive's OCR layer and tesseract
# (the parsed OCR tables ocr/comp1899_*.csv are written by code/ocr_runs.R;
# run that first).
# Run from the session data folder:  Rscript code/make_cache_1899.R
# A run whose cache file exists is skipped, so the script is safe to rerun.
# The API key is read by ellmer from ANTHROPIC_API_KEY (set in ~/.Renviron).
#
# What changed from the one-call form. A single chat_structured() call with
# the image alone (PROMPT as system prompt) returned one or two rows, the
# second labelled "placeholder", in three tries (cache/comp1899_direct_run*.json;
# set DIRECT_RUNS <- 1:3 to reproduce). A plain chat() with the same image
# reads the whole table, so the run below asks for the transcription as
# text first and then calls chat_structured() in the same chat.

suppressPackageStartupMessages({ library(ellmer); library(jsonlite) })

MODEL <- "claude-sonnet-5-5"
IMG   <- "comp1899_p.png"
PROMPT <- "This image is a scanned page of a printed statistical table. Return every row of the table, in order, as one object per row. Copy each number exactly as printed, in millions of dollars with one decimal as on the page. Where a cell is blank or unreadable return null. Do not compute or correct anything."
ASK1 <- "Transcribe every row of the table on this page as a markdown table, one row per printed row, blank cells left empty."
ASK2 <- "Now return the same rows as structured data."
RUNS <- 1
DIRECT_RUNS <- integer(0)
COLS <- c("national", "state", "loan_trust", "savings", "private", "total")

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
img <- function() content_image_file(IMG, resize = "none")

dir.create("cache", showWarnings = FALSE)
for (run in RUNS) {
  OUT  <- sprintf("cache/comp1899_run%d.json", run)
  META <- sprintf("cache/comp1899_run%d_meta.json", run)
  if (file.exists(OUT)) { message("have ", OUT); next }
  message("calling ", MODEL, " with ", IMG, ", run ", run)
  chat <- chat_anthropic(model = MODEL, system_prompt = PROMPT, cache = "none")
  t0 <- Sys.time()
  md    <- chat$chat(ASK1, img(), echo = "none")
  reply <- chat$chat_structured(ASK2, type = type_array(row_type))
  secs  <- as.numeric(Sys.time() - t0, units = "secs")
  write_json(reply, OUT, pretty = TRUE, digits = NA, auto_unbox = TRUE,
             null = "null", na = "null")
  writeLines(md, sprintf("cache/comp1899_run%d_markdown.md", run))
  tok <- chat$get_tokens()      # one row per assistant turn
  meta <- list(model = MODEL, image = IMG, run = run, form = "two-step",
               called_at = format(t0, "%Y-%m-%d %H:%M:%S"), seconds = round(secs, 1),
               input_tokens = sum(tok$input), output_tokens = sum(tok$output),
               cached_input_tokens = sum(tok$cached_input),
               turns = nrow(tok), rows_returned = nrow(reply),
               system_prompt = PROMPT, ask1 = ASK1, ask2 = ASK2)
  write_json(meta, META, pretty = TRUE, auto_unbox = TRUE, digits = NA)
  cat(sprintf("run %d: %.1f s, %d input tokens, %d output tokens over %d turns, %d rows\n",
              run, secs, sum(tok$input), sum(tok$output), nrow(tok), nrow(reply)))
}
for (run in DIRECT_RUNS) {     # the one-call form, kept for the record
  OUT <- sprintf("cache/comp1899_direct_run%d.json", run)
  if (file.exists(OUT)) { message("have ", OUT); next }
  chat <- chat_anthropic(model = MODEL, system_prompt = PROMPT, cache = "none")
  t0 <- Sys.time()
  reply <- chat$chat_structured(img(), type = type_array(row_type))
  secs <- as.numeric(Sys.time() - t0, units = "secs")
  write_json(reply, OUT, pretty = TRUE, digits = NA, auto_unbox = TRUE, null = "null", na = "null")
  tok <- chat$get_tokens()
  cat(sprintf("direct run %d: %.1f s, %d in, %d out, %d rows\n",
              run, secs, sum(tok$input), sum(tok$output), nrow(reply)))
}

# ===========================================================================
# compare the model's reading with the truth and the two OCR readings
# ===========================================================================
truth <- read.csv("ocr/comp1899_truth.csv", stringsAsFactors = FALSE)
meta  <- fromJSON("cache/comp1899_run1_meta.json")
cat(sprintf("\nmodel %s, called %s: %.1f s, %d input + %d output tokens, %d rows\n",
            meta$model, meta$called_at, meta$seconds, meta$input_tokens,
            meta$output_tokens, meta$rows_returned))
model <- fromJSON("cache/comp1899_run1.json")
for (cc in COLS) if (!cc %in% names(model)) model[[cc]] <- NA_real_
model[COLS] <- lapply(model[COLS], as.numeric)

# components vs Total
has_total <- !is.na(model$total)
comp <- rowSums(model[, COLS[1:5]], na.rm = TRUE)
pass <- has_total & abs(comp - model$total) <= 0.15
cat(sprintf("components vs Total (|diff| <= 0.15): %d of %d rows with a Total pass\n",
            sum(pass), sum(has_total)))
if (any(!pass)) print(model[!pass, c("row_label", COLS)], row.names = FALSE)

# align with the truth by label (same rule as ocr_runs.R)
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
write.csv(read, "ocr/comp1899_model.csv", row.names = FALSE)

# three readings cell by cell (archive layer, tesseract 300 dpi, model)
arch <- read.csv("ocr/comp1899_archive.csv"); tess <- read.csv("ocr/comp1899_tess300.csv")
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
