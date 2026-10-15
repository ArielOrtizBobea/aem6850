# model_send.R: sends the request that model_call.R builds and saves the reply.
# Run it in the 14-apis folder. Needs internet, httr2, jsonlite and
# ANTHROPIC_API_KEY in ~/.Renviron. Each call costs money.
# Writes raw/model_prompt.txt and raw/model_live.json.
source("model_call.R")
if (Sys.getenv("ANTHROPIC_API_KEY") == "") {
  stop("ANTHROPIC_API_KEY is empty: add it to ~/.Renviron and restart R")
}

resp <- req_perform(req)              # about 11 seconds
writeLines(resp_body_string(resp), "raw/model_live.json")
reply <- fromJSON("raw/model_live.json")
print(reply$stop_reason)              # "end_turn": the model finished
labels <- read.csv(text = reply$content$text[reply$content$type == "text"])
print(table(labels$label))            # each saved run: economy 217, group 49
