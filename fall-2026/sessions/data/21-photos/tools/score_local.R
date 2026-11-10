# =============================================================
# AEM 6850 - Session 21: Photographs I
# Tool, run before class. Students do not run it.
#
# The same photographs put to an open vision model running on this computer
# (Ollama; see code/4_local_model.R), in two ways:
#   1. the haze question of replies/haze_prompt.txt, for all 365 days
#      -> replies/local/haze/<date>.json and replies/local/haze_local.csv
#   2. a direct question, "how many micrograms of PM2.5?", for the 110 held-out
#      days of code/3_judge.R -> replies/local/direct/<date>.json and
#      replies/local/direct_local.csv
# Every reply is saved whole; days already saved are skipped. The model's name
# and both questions are written to replies/local/prompts.txt.
#
#   Rscript tools/score_local.R        from the project folder
# =============================================================
want <- c("httr2", "jsonlite", "base64enc")
need <- want[!(want %in% installed.packages()[,"Package"])]
if (length(need)) install.packages(need)
invisible(lapply(want, function(i) require(i, character.only = TRUE)))

model <- "qwen3.5:4b-q4_K_M"
haze_prompt   <- readLines("replies/haze_prompt.txt")[5]
direct_prompt <- paste("This photograph of the Beijing skyline was taken from the same window one morning in 2014.",
                       "Estimate the concentration of fine particles (PM2.5) in the air that day, in micrograms per cubic metre.",
                       "Give one number and one short reason.")
haze_schema <- list(type = "object",
  properties = list(haze = list(type = "integer", minimum = 0, maximum = 10),
                    sky = list(type = "string", enum = c("clear", "light haze", "heavy haze", "overcast", "fog or mist",
                                                         "rain", "snow", "night or dark")),
                    reason = list(type = "string")),
  required = c("haze", "sky", "reason"))
direct_schema <- list(type = "object",
  properties = list(pm25 = list(type = "number", minimum = 0, maximum = 1000), reason = list(type = "string")),
  required = c("pm25", "reason"))
writeLines(c(paste("model:", model), "", "haze prompt:", haze_prompt, "", "direct prompt:", direct_prompt),
           "replies/local/prompts.txt")

ask <- function(day, prompt, schema, dir) {
  out <- sprintf("replies/local/%s/%s.json", dir, day)
  if (!file.exists(out)) {
    r <- request("http://localhost:11434/api/chat") |>
      req_body_json(list(model = model, format = schema, stream = FALSE, think = FALSE,
                         options = list(temperature = 0),
                         messages = list(list(role = "user", content = prompt,
                           images = list(base64encode(sprintf("data_clean/tiles/%s.jpg", day))))))) |>
      req_timeout(300) |> req_perform()
    writeLines(resp_body_string(r), out)
  }
  fromJSON(fromJSON(out)$message$content)
}

d <- read.csv("data_clean/haze_pm25.csv")
# 1. the haze score, all days
h <- lapply(d$date, ask, prompt = haze_prompt, schema = haze_schema, dir = "haze")
write.csv(data.frame(date = d$date, haze_local = sapply(h, `[[`, "haze"), sky_local = sapply(h, `[[`, "sky")),
          "replies/local/haze_local.csv", row.names = FALSE)
# 2. micrograms asked directly, the held-out days of code/3_judge.R
set.seed(6850); fit <- sample(nrow(d), round(0.7 * nrow(d)))
p <- lapply(d$date[-fit], ask, prompt = direct_prompt, schema = direct_schema, dir = "direct")
write.csv(data.frame(date = d$date[-fit], pm25_direct = sapply(p, `[[`, "pm25")),
          "replies/local/direct_local.csv", row.names = FALSE)
cat(length(h), "haze replies;", length(p), "direct replies\n")
