# =============================================================
# AEM 6850 - Session 21: Photographs I
# Tool, run before class. Students do not run it: it needs an API key.
#
# Asks a general vision model four things about the one street photo
# (data/street/porlamar.jpg): a label for the kind of place, a score for how
# busy it is, a count of cars and people, and a one-sentence caption. Saves
# each reply as it came back in replies/street/.
#
#   Rscript tools/describe_street.R         from the project folder
# =============================================================

  want <- c("httr2", "jsonlite", "base64enc")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only=TRUE))
  rm(want, need)

  model <- "claude-opus-5-5"
  img   <- base64encode("data/street/porlamar.jpg")

  asks <- list(
    label   = list(text = "What kind of place is this photograph of? Pick one label.",
                   schema = list(type = "object", properties = list(label = list(type = "string",
                     enum = list("residential street", "shopping street", "highway", "park",
                                 "parking lot", "market", "indoor"))),
                     required = list("label"), additionalProperties = FALSE)),
    busy    = list(text = "How busy is this street, from 0 (empty) to 10 (packed with people and vehicles)? Give the number and one short reason.",
                   schema = list(type = "object", properties = list(busy = list(type = "integer", enum = as.list(0:10)),
                     reason = list(type = "string")), required = list("busy", "reason"), additionalProperties = FALSE)),
    count   = list(text = "Count the cars (fully or partly visible, motorcycles excluded) and the people in this photograph.",
                   schema = list(type = "object", properties = list(cars = list(type = "integer"), people = list(type = "integer")),
                     required = list("cars", "people"), additionalProperties = FALSE)),
    caption = list(text = "Describe this photograph in one sentence.",
                   schema = list(type = "object", properties = list(caption = list(type = "string")),
                     required = list("caption"), additionalProperties = FALSE)))

  dir.create("replies/street", showWarnings = FALSE, recursive = TRUE)
  for (nm in names(asks)) {
    resp <- request("https://api.anthropic.com/v1/messages") |>
      req_headers("x-api-key" = Sys.getenv("ANTHROPIC_API_KEY"),
                  "anthropic-version" = "2026-10-21", "content-type" = "application/json") |>
      req_body_json(list(model = model, max_tokens = 400,
        output_config = list(effort = "low", format = list(type = "json_schema", schema = asks[[nm]]$schema)),
        messages = list(list(role = "user", content = list(
          list(type = "image", source = list(type = "base64", media_type = "image/jpeg", data = img)),
          list(type = "text", text = asks[[nm]]$text)))))) |>
      req_retry(max_tries = 3) |> req_timeout(180) |> req_perform()
    writeLines(resp_body_string(resp), sprintf("replies/street/%s.json", nm))
    r <- resp_body_json(resp)
    cat(nm, ": ", r$content[[which(sapply(r$content, `[[`, "type") == "text")]]$text, "\n", sep = "")
  }
  writeLines(c(sprintf("model: %s", model), "effort: low", "",
               unlist(lapply(names(asks), function(n) c(n, asks[[n]]$text, "")))), "replies/street_prompts.txt")
