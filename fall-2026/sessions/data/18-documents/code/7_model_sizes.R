# =============================================================
# AEM 6850 - Session 18: Documents & scans
# Script 7 of 8 - the same pages read by a smaller and a larger model.
#
# Lecture part 5, reading thousands of pages. Sends the 1899 page (the
# two-request chat of code/3_model_1899.R) and the five rainfall sheets
# (two runs each, the instructions of code/prompt_sheet.txt) to the
# provider's small and large models, to compare seconds, tokens and cells
# right with the medium model the slides use. 22 calls, $0.53 on
# 29 Oct 2026. The sheets' reply format is the one on the slides; the
# medium model's (code/4_model_sheets.R) also described the total field.
#
# Reads:  data_clean/comp1899_p.png, data/sheets/abbotsbury_<decade>.jpg,
#         code/prompt_sheet.txt
# Writes: replies/sizes/*.json (and the markdown of the 1899 page's first
#         request), logs/comp1899_<size>_turns.csv, a line per call in
#         logs/model_calls.csv
#
# A call is made only when its reply is missing from replies/sizes/, so
# with the folder as shipped this script makes no call. A new call needs
# ellmer and an API key in ANTHROPIC_API_KEY (set it in ~/.Renviron, never
# in code). misc$budget stops the run before it spends more than $1.
#
# Open 18-documents.Rproj first. It sits at the project root, so the
# working directory is 18-documents/ and every path below is relative to it.
#
#   source("code/7_model_sizes.R")
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
  misc$models  <- c(small = "claude-haiku-5-5", large = "claude-opus-5-5")
  misc$price   <- rbind(small  = c(0.10, 0.50),   # $ per million tokens (input, output),
                        medium = c(2, 10),        # the provider's list, 29 Oct 2026
                        large  = c(4, 20))
  misc$budget  <- 1                               # stop before spending more than this, in dollars
  misc$sheets  <- c("1860s", "1870s", "1880s", "1890s", "1910s")
  misc$runs    <- 1:2
  misc$replies <- "replies/sizes"
  misc$logs    <- "logs"
  misc$log     <- "logs/model_calls.csv"          # one line per model call
  misc$png     <- "data_clean/comp1899_p.png"
  misc$prompt_sheet <- paste(readLines("code/prompt_sheet.txt"), collapse = "\n")
  misc$prompt_1899  <- "This image is a scanned page of a printed statistical table. Return every row of the table, in order, as one object per row. Copy each number exactly as printed, in millions of dollars with one decimal as on the page. Where a cell is blank or unreadable return null. Do not compute or correct anything."
  misc$ask1 <- "Transcribe every row of the table on this page as a markdown table, one row per printed row, blank cells left empty."
  misc$ask2 <- "Now return the same rows as structured data."

  # The reply formats: one object per year of a sheet; one per row of the 1899 table
  cells <- setNames(rep(list(type_number(required = FALSE)), 13),
                    c(tolower(month.abb), "total"))
  year_type <- do.call(type_object, c(list(year = type_integer()), cells))
  row_type <- type_object(
    row_label  = type_string(),
    national   = type_number(required = FALSE), state   = type_number(required = FALSE),
    loan_trust = type_number(required = FALSE), savings = type_number(required = FALSE),
    private    = type_number(required = FALSE), total   = type_number(required = FALSE))

  dir.create(misc$replies, showWarnings = FALSE, recursive = TRUE)
  if (!file.exists(misc$log))
    writeLines('"size","model","page","run","called_at","seconds","input_tokens","output_tokens"', misc$log)

  # dollars spent so far on the small and large models
  spent <- function() {
    l <- read.csv(misc$log); l <- l[l$size %in% names(misc$models), ]
    sum(l$input_tokens * misc$price[l$size, 1] + l$output_tokens * misc$price[l$size, 2]) / 1e6
  }
  log_call <- function(size, page, run, t0, secs, tok) {
    line <- data.frame(size = size, model = misc$models[[size]], page = page, run = run,
                       called_at = format(t0, "%Y-%m-%d %H:%M:%S"), seconds = round(secs, 1),
                       input_tokens = sum(tok$input), output_tokens = sum(tok$output))
    write.table(line, misc$log, sep = ",", append = TRUE, col.names = FALSE, row.names = FALSE)
    cat(sprintf("%-6s %-6s run %d: %5.1f s, %6d in, %6d out; spent so far $%.3f\n",
                size, page, run, secs, line$input_tokens, line$output_tokens, spent()))
  }
  new_chat <- function(size, prompt)
    chat_anthropic(model = misc$models[[size]], system_prompt = prompt, cache = "none",
                   params = params(max_tokens = 16000))


# 2). Call each model, once per missing reply ----

  for (size in names(misc$models)) {
    # the 1899 page: a plain table first, then the same rows as structured data
    out <- file.path(misc$replies, sprintf("comp1899_%s.json", size))
    if (!file.exists(out)) {
      if (spent() > misc$budget) stop("budget reached")
      chat <- new_chat(size, misc$prompt_1899)
      t0 <- Sys.time()
      md    <- chat$chat(misc$ask1, content_image_file(misc$png, resize = "none"), echo = "none")
      reply <- chat$chat_structured(misc$ask2, type = type_array(row_type))
      secs  <- as.numeric(Sys.time() - t0, units = "secs")
      write_json(reply, out, pretty = TRUE, digits = NA, auto_unbox = TRUE, null = "null", na = "null")
      writeLines(md, file.path(misc$replies, sprintf("comp1899_%s_markdown.md", size)))
      tok <- chat$get_tokens()
      write.csv(tok, file.path(misc$logs, sprintf("comp1899_%s_turns.csv", size)), row.names = FALSE)
      log_call(size, "1899", 1, t0, secs, tok)
    } else message("have ", out)
    # the five rainfall sheets, two fresh chats each
    for (sheet in misc$sheets) for (run in misc$runs) {
      out <- file.path(misc$replies, sprintf("abbotsbury_%s_%s_run%d.json", sheet, size, run))
      if (file.exists(out)) { message("have ", out); next }
      if (spent() > misc$budget) stop("budget reached")
      chat <- new_chat(size, misc$prompt_sheet)
      t0 <- Sys.time()
      reply <- chat$chat_structured(content_image_file(sprintf("data/sheets/abbotsbury_%s.jpg", sheet),
                                                       resize = "none"),
                                    type = type_array(year_type))
      secs <- as.numeric(Sys.time() - t0, units = "secs")
      write_json(reply, out, pretty = TRUE, digits = NA, auto_unbox = TRUE, null = "null", na = "null")
      log_call(size, sheet, run, t0, secs, chat$get_tokens())
    }
  }
  cat(sprintf("done: $%.3f spent on the small and large models\n", spent()))


# the end ----
