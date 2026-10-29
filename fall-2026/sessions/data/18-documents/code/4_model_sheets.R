# =============================================================
# AEM 6850 - Session 18: Documents & scans
# Script 4 of 8 - a vision model reads the five rainfall sheets.
#
# Lecture part 4, a handwritten page. Ten calls: five sheets x two runs,
# each a fresh chat, with the instructions in code/prompt_sheet.txt and a
# fixed reply format (one object per year: twelve months and the total).
#
# Reads:  data/sheets/abbotsbury_<decade>.jpg, code/prompt_sheet.txt
# Writes: replies/abbotsbury_<decade>_run<r>.json, a line per call in
#         logs/model_calls.csv
#
# A call is made only when its reply is missing from replies/, so with the
# folder as shipped this script makes no call. A new call needs ellmer and
# an API key in ANTHROPIC_API_KEY (set it in ~/.Renviron, never in code).
#
# Open 18-documents.Rproj first. It sits at the project root, so the
# working directory is 18-documents/ and every path below is relative to it.
#
#   source("code/4_model_sheets.R")
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
  misc$sheets  <- c("1860s", "1870s", "1880s", "1890s", "1910s")
  misc$runs    <- 1:2
  misc$replies <- "replies"
  misc$log     <- "logs/model_calls.csv"  # one line per model call
  misc$prompt  <- paste(readLines("code/prompt_sheet.txt"), collapse = "\n")

  # The reply format: one object per year column, null where a cell is blank
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


# 2). Call the model, once per missing reply ----

  dir.create(misc$replies, showWarnings = FALSE)
  for (sheet in misc$sheets) {
    for (run in misc$runs) {
      out <- file.path(misc$replies, sprintf("abbotsbury_%s_run%d.json", sheet, run))
      if (file.exists(out)) { message("have ", out); next }
      img <- sprintf("data/sheets/abbotsbury_%s.jpg", sheet)
      message("calling ", misc$model, " for ", img, " run ", run)

      chat <- chat_anthropic(model = misc$model, system_prompt = misc$prompt, cache = "none")
      t0 <- Sys.time()
      # resize = "none": the ellmer default ("low") shrinks the image to fit
      # 512x512, which makes the handwriting unreadable. The sheets are
      # about 670x1080 px, within the API's limits, so send them as they are.
      reply <- chat$chat_structured(content_image_file(img, resize = "none"),
                                    type = sheet_type)
      secs <- as.numeric(Sys.time() - t0, units = "secs")

      write_json(reply, out, pretty = TRUE, digits = NA, auto_unbox = TRUE,
                 null = "null", na = "null")

      tok <- chat$get_tokens()        # one row per assistant turn
      line <- data.frame(size = "medium", model = misc$model, page = sheet, run = run,
                         called_at = format(t0, "%Y-%m-%d %H:%M:%S"),
                         seconds = round(secs, 1),
                         input_tokens = sum(tok$input), output_tokens = sum(tok$output))
      write.table(line, misc$log, sep = ",", append = TRUE, col.names = FALSE,
                  row.names = FALSE)
      message(sprintf("  %.1f s, %d in, %d out, %d years returned",
                      secs, line$input_tokens, line$output_tokens, NROW(reply)))
    }
  }


# the end ----
