# Before class: the demo's five sentences labelled twice (the fallback for the
# live call), and the range request sent without a schema (for the page).
.libPaths(c(Sys.getenv("ELLMER_LIB"), .libPaths()))
source("model_setup.R")
tdw <- read.csv("tdw_sentences.csv")
set.seed(6850)
pick <- sample(nrow(tdw), 5)
chat <- chat_anthropic(system_prompt = CODEBOOK, model = MODEL, cache = "none")
five <- as.list(tdw$sentence[pick])
for (k in 1:2) {
  live <- parallel_chat_structured(chat, five, type = stance_type, on_error = "stop")
  d <- data.frame(id = tdw$id[pick], sentence = tdw$sentence[pick],
                  annotators = c("dovish", "hawkish", "neutral")[tdw$label[pick] + 1],
                  stance = as.character(live$stance))
  write.csv(d, sprintf("demo/demo_run%d.csv", k), row.names = FALSE)
  print(d[, c("id", "annotators", "stance")])
}
fomc <- read.csv("fomc_statements.csv")
i <- which(fomc$date == "2023-03-22")
rchat <- chat_anthropic(system_prompt = RANGE_PROMPT, model = MODEL, cache = "none")
reply <- rchat$chat(fomc$text[i], echo = "none")
writeLines(as.character(reply), "replies/no_schema_reply.txt")
cat(as.character(reply), "\n")
