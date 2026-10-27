# Two test calls on the hosted model (billed, a few cents), plus one call with
# temperature = 0 to see whether the model rejects it (a rejected call is not billed).
.libPaths(c(Sys.getenv("ELLMER_LIB"), .libPaths()))
source("model_setup.R"); source("save_replies.R")
fomc <- read.csv("fomc_statements.csv"); tdw <- read.csv("tdw_sentences.csv")
i <- which(fomc$date == "2023-03-22")

chat <- chat_anthropic(system_prompt = RANGE_PROMPT, model = MODEL)
r1 <- chat$clone()
ans1 <- r1$chat_structured(fomc$text[i], type = range_type)
str(ans1)
j1 <- r1$last_turn()@json
writeLines(jsonlite::toJSON(j1, auto_unbox = TRUE, pretty = TRUE, null = "null"), "prep/test_range_reply.json")
print(j1$usage); print(j1$model); print(j1$stop_reason)

set.seed(6850); pick <- sample(nrow(tdw), 5)
unlink("prep/test_label", recursive = TRUE)
save_replies(tdw$sentence[pick[1]], tdw$id[pick[1]], "prep/test_label", CODEBOOK, stance_type)
rec <- jsonlite::fromJSON(list.files("prep/test_label", full.names = TRUE)[1])
str(rec$answer); print(rec$reply$usage); print(sapply(rec$reply$content, function(x) x)[1])

res <- tryCatch({
  ct <- chat_anthropic(system_prompt = CODEBOOK, model = MODEL, params = params(temperature = 0))
  ct$chat_structured(tdw$sentence[pick[2]], type = stance_type)
}, error = function(e) conditionMessage(e))
cat("temperature = 0:\n"); print(res)
