# =============================================================
# AEM 6850 - Session 21: Photographs I
# Script 4, optional - the haze question put to an open vision model
# running on this computer.
#
# Not part of run_everything.R. It needs Ollama (a free program that runs
# open models and answers requests on this machine) running, with one
# vision model downloaded. Nothing leaves the computer: no key, no network.
#
# Reads:  replies/haze_prompt.txt, data_clean/tiles/*.jpg, replies/haze/*.json
# Writes: nothing
#
# Open 21-photos.Rproj first.
#   source("code/4_local_model.R")
# =============================================================

# 1). Preliminary ----

  want <- c("httr2", "jsonlite", "base64enc")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only = TRUE))

  model  <- "qwen3.5:4b-q4_K_M"       # the vision model downloaded on this machine; `ollama list` prints yours
  prompt <- readLines("replies/haze_prompt.txt")[5]      # line 5 is the question sent to the API model
  # the three fields the reply must have, the same as for the API model
  schema <- list(type = "object",
                 properties = list(haze   = list(type = "integer", minimum = 0, maximum = 10),
                                   sky    = list(type = "string",
                                                 enum = c("clear", "light haze", "heavy haze", "overcast",
                                                          "fog or mist", "rain", "snow", "night or dark")),
                                   reason = list(type = "string")),
                 required = c("haze", "sky", "reason"))

# 2). One photograph to the model on this computer ----

  ask_local <- function(file) {
    request("http://localhost:11434/api/chat") |>                     # the model server on this computer
      req_body_json(list(model = model, format = schema,                 # which model; the reply's form
        stream = FALSE, think = FALSE,                                 # one reply, in one piece
        options = list(temperature = 0),                               # the same answer every time
        messages = list(list(role = "user", content = prompt,          # the same question
                             images = list(base64encode(file)))))) |>  # the photograph, written out as text
      req_timeout(300) |> req_perform() |> resp_body_json()
  }
  r <- ask_local("data_clean/tiles/2014-01-06.jpg")                    # the hazy morning
  cat(r$message$content, "\n")
  round(r$total_duration / 1e9, 1)                                     # seconds it took

# 3). Two mornings beside the API model's saved replies ----

  days  <- c("2014-01-03", "2014-01-06")
  local <- sapply(days, function(d) fromJSON(ask_local(sprintf("data_clean/tiles/%s.jpg", d))$message$content)$haze)
  api   <- sapply(days, function(d) { a <- fromJSON(sprintf("replies/haze/%s.json", d))
                                      fromJSON(a$content$text[a$content$type == "text"])$haze })
  rbind(local, api)
