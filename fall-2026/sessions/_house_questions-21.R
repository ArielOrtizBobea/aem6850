# AEM 6850 - Session 21: the two house photographs on the slide "Street images of single houses".
# Tool, run before class. Students do not run it. It needs Ollama running with a vision
# model downloaded (the open model of data/21-photos/code/4_local_model.R); no key, no network.
#
# Puts four questions to the model about each photograph in figures/21-photos/houses_src/
# and saves the replies whole (answers_<house>.json) and as one table (answers.csv).
# _figures-21.R, block houses, draws the figure from these files.
#
#   Rscript _house_questions-21.R        from fall-2026/sessions
want <- c("httr2", "jsonlite", "base64enc")
need <- want[!(want %in% installed.packages()[,"Package"])]
if (length(need)) install.packages(need)
invisible(lapply(want, function(i) require(i, character.only = TRUE)))

src    <- "figures/21-photos/houses_src"
model  <- "qwen3.5:4b-q4_K_M"
prompt <- paste("This photograph shows a house from the street. Answer four questions.",
                "Are any of its windows or doors boarded up?",
                "Is a car parked in its driveway?",
                "Are there solar panels on its roof?",
                "Rate its curb appeal, how attractive and well kept it looks from the street,",
                "from 0 (derelict) to 10 (immaculate), and give one short reason for the rating.")
schema <- list(type = "object",
               properties = list(boarded_up = list(type = "boolean"), car_in_driveway = list(type = "boolean"),
                                 solar_panels = list(type = "boolean"),
                                 curb_appeal = list(type = "integer", minimum = 0, maximum = 10),
                                 reason = list(type = "string")),
               required = c("boarded_up", "car_in_driveway", "solar_panels", "curb_appeal", "reason"))
writeLines(c(paste("model:", model), "", "prompt:", prompt), file.path(src, "prompt.txt"))
ask <- function(f) {
  r <- request("http://localhost:11434/api/chat") |>
    req_body_json(list(model = model, format = schema, stream = FALSE, think = FALSE,
                       options = list(temperature = 0),
                       messages = list(list(role = "user", content = prompt, images = list(base64encode(f)))))) |>
    req_timeout(300) |> req_perform()
  writeLines(resp_body_string(r), sub("house_(.*)\\.jpg$", "answers_\\1.json", f))
  a <- fromJSON(resp_body_json(r)$message$content)
  data.frame(house = sub("house_(.*)\\.jpg$", "\\1", basename(f)), a)
}
ans <- do.call(rbind, lapply(file.path(src, c("house_boarded.jpg", "house_solar.jpg")), ask))
write.csv(ans, file.path(src, "answers.csv"), row.names = FALSE)
print(ans)
