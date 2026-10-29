# make_cache.R: ask a vision model to transcribe each Rainfall Rescue sheet.
# Run from the session data folder:  Rscript code/make_cache.R
# Ten calls: five sheets x two runs, each a fresh chat. A call whose cache
# file already exists is skipped, so the script is safe to rerun.
# The API key is read by ellmer from ANTHROPIC_API_KEY (set in ~/.Renviron).

library(ellmer)
library(jsonlite)

MODEL  <- "claude-sonnet-5-5"
SHEETS <- c("1860s", "1870s", "1880s", "1890s", "1910s")
RUNS   <- 1:2
LOG    <- "cache/log.csv"

PROMPT <- "This image is a ten-year sheet of handwritten monthly rainfall in inches. Rows are the months January to December, then a row with the written annual total. Columns are years. Return one object per year column. Copy every number exactly as written on the sheet. Where a cell is blank or you cannot read it, return null. Do not compute or correct anything."

year_type <- type_object(
  year = type_integer(),
  jan = type_number(required = FALSE), feb = type_number(required = FALSE),
  mar = type_number(required = FALSE), apr = type_number(required = FALSE),
  may = type_number(required = FALSE), jun = type_number(required = FALSE),
  jul = type_number(required = FALSE), aug = type_number(required = FALSE),
  sep = type_number(required = FALSE), oct = type_number(required = FALSE),
  nov = type_number(required = FALSE), dec = type_number(required = FALSE),
  total = type_number(required = FALSE,
                      description = "the annual total as written on the sheet"))
sheet_type <- type_array(year_type)

dir.create("cache", showWarnings = FALSE)
if (!file.exists(LOG)) {
  writeLines("sheet,run,model,called_at,seconds,input_tokens,output_tokens,cached_input_tokens,cost_usd",
             LOG)
}

for (sheet in SHEETS) {
  for (run in RUNS) {
    out <- sprintf("cache/abbotsbury_%s_run%d.json", sheet, run)
    if (file.exists(out)) { message("have ", out); next }
    img <- sprintf("sheets/abbotsbury_%s.jpg", sheet)
    message("calling ", MODEL, " for ", img, " run ", run)

    chat <- chat_anthropic(model = MODEL, system_prompt = PROMPT, cache = "none")
    t0 <- Sys.time()
    # resize = "none": the ellmer default ("low") shrinks the image to fit
    # 512x512, which makes the handwriting unreadable. The sheets are
    # about 670x1080 px, within the API's limits, so send them as they are.
    reply <- chat$chat_structured(content_image_file(img, resize = "none"),
                                  type = sheet_type)
    secs <- as.numeric(Sys.time() - t0, units = "secs")

    write_json(reply, out, pretty = TRUE, digits = NA, auto_unbox = TRUE,
               null = "null", na = "null")

    tok <- chat$get_tokens()        # one row per assistant turn: input, output, cached_input, cost
    line <- data.frame(
      sheet = sheet, run = run, model = MODEL,
      called_at = format(t0, "%Y-%m-%d %H:%M:%S"),
      seconds = round(secs, 1),
      input_tokens = sum(tok$input), output_tokens = sum(tok$output),
      cached_input_tokens = sum(tok$cached_input),
      cost_usd = round(sum(tok$cost), 5))
    write.table(line, LOG, sep = ",", append = TRUE, col.names = FALSE,
                row.names = FALSE, quote = FALSE)
    message(sprintf("  %.1f s, %d in, %d out, %d years returned",
                    secs, line$input_tokens, line$output_tokens, NROW(reply)))
  }
}
