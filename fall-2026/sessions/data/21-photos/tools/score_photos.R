# =============================================================
# AEM 6850 - Session 21: Photographs I
# Tool, run before class. Students do not run it: it needs an API key and makes
# 365 model calls. The replies it saves ship in replies/haze/.
#
# Sends each daily photograph in data_clean/tiles/ to a general vision model
# with one question, a haze score from 0 to 10, and saves the reply exactly as
# it came back, one JSON file per day. The key lives in ~/.Renviron as
# ANTHROPIC_API_KEY; nothing is pasted into the script.
#
#   Rscript tools/score_photos.R            from the project folder
#   Rscript tools/score_photos.R test       the first three days only
# =============================================================

  want <- c("httr2", "jsonlite", "base64enc")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only=TRUE))
  rm(want, need)

# 1). What we ask ----

  prompt <- paste(
    "This photograph of the Beijing skyline was taken from the same window one morning in 2014.",
    "Rate the haze in the air from 0 to 10. 0 is a perfectly clear day: sharp distant buildings, a blue sky.",
    "10 is the densest smog: the nearest tower barely visible, no horizon.",
    "Also name the sky condition you see and give one short reason for the score.")

  schema <- list(
    type = "object",
    properties = list(
      haze   = list(type = "integer", enum = as.list(0:10)),
      sky    = list(type = "string",
                    enum = list("clear", "light haze", "heavy haze", "overcast",
                                "fog or mist", "rain", "snow", "night or dark")),
      reason = list(type = "string")),
    required = list("haze", "sky", "reason"),
    additionalProperties = FALSE)

  model <- "claude-opus-5-5"

  one_request <- function(file) {
    request("https://api.anthropic.com/v1/messages") |>
      req_headers("x-api-key" = Sys.getenv("ANTHROPIC_API_KEY"),
                  "anthropic-version" = "2026-10-21",
                  "content-type" = "application/json") |>
      req_body_json(list(
        model = model, max_tokens = 400,
        output_config = list(effort = "low",
                             format = list(type = "json_schema", schema = schema)),
        messages = list(list(role = "user", content = list(
          list(type = "image",
               source = list(type = "base64", media_type = "image/jpeg",
                             data = base64encode(file))),
          list(type = "text", text = prompt)))))) |>
      req_retry(max_tries = 4) |>
      req_timeout(180)
  }

# 2). Send, save every reply as it came ----

  tiles <- read.csv("data_clean/tiles.csv")
  if (length(commandArgs(TRUE)) && commandArgs(TRUE)[1] == "test") tiles <- tiles[1:3, ]
  dir.create("replies/haze", showWarnings = FALSE, recursive = TRUE)
  dir.create("logs", showWarnings = FALSE)
  out  <- sprintf("replies/haze/%s.json", tiles$date)
  todo <- !file.exists(out)                              # rerun only what is missing
  cat(sum(todo), "photos to score,", sum(!todo), "already saved\n")

  if (any(todo)) {
    t0 <- Sys.time()
    reqs  <- lapply(tiles$file[todo], one_request)
    resps <- req_perform_parallel(reqs, max_active = 4, on_error = "continue", progress = FALSE)
    ok <- 0
    for (i in seq_along(resps)) {
      r <- resps[[i]]
      if (inherits(r, "httr2_response") && resp_status(r) == 200) {
        writeLines(resp_body_string(r), out[todo][i]); ok <- ok + 1
      } else {
        msg <- if (inherits(r, "httr2_response")) resp_body_string(r) else conditionMessage(r)
        cat(sprintf("%s  FAILED  %s\n", tiles$date[todo][i], substr(msg, 1, 200)),
            file = "logs/score_photos_failures.log", append = TRUE)
      }
    }
    cat(sprintf("%d saved, %d failed, %.1f min\n", ok, sum(todo) - ok,
                as.numeric(difftime(Sys.time(), t0, units = "mins"))))
  }

# 3). Record what was asked ----

  writeLines(c(sprintf("model: %s", model), "effort: low", "",
               "prompt:", prompt, "", "schema:", toJSON(schema, auto_unbox = TRUE, pretty = TRUE)),
             "replies/haze_prompt.txt")
  cat(sprintf("%s  %s  %d replies on disk\n", Sys.time(), model, length(list.files("replies/haze"))),
      file = "logs/score_photos.log", append = TRUE)
