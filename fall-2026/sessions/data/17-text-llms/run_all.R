# The billed runs, made once before class on the instructor's key. Every later
# number in the session reads the files these lines write; rerunning this
# script with the replies in place makes no call to the label runs.
# Needs ellmer, jsonlite, model_setup.R, save_replies.R and an API key in
# ~/.Renviron. (Before class the label runs were split across 8 R sessions,
# prep/run_shard.R, which call the same save_replies() on parts of the ids.)
source("model_setup.R")
source("save_replies.R")
fomc <- read.csv("fomc_statements.csv")
tdw <- read.csv("tdw_sentences.csv")
st <- read.csv("statement_sentences.csv")

# 1. The target range of every statement: 171 calls
chat <- chat_anthropic(system_prompt = RANGE_PROMPT, model = MODEL, cache = "none")
ranges <- parallel_chat_structured(chat, as.list(fomc$text), type = range_type,
                                   include_tokens = TRUE, on_error = "continue")
ranges$date <- fomc$date
write.csv(ranges[, c("date", "lower", "upper", "input_tokens", "output_tokens")],
          "replies/range_model.csv", row.names = FALSE)

# 2-3. Stance labels on the 2,480 sentences, twice, every raw reply saved
save_replies(tdw$sentence, tdw$id, "replies/run1", CODEBOOK, stance_type)
save_replies(tdw$sentence, tdw$id, "replies/run2", CODEBOOK, stance_type)

# 4. Stance labels on the statement sentences, each distinct sentence once
u <- st[!duplicated(st$sid), ]
save_replies(u$sentence, u$sid, "replies/statements", CODEBOOK, stance_type)

# One CSV per folder of replies: id, stance, input_tokens, output_tokens
to_csv <- function(folder, out) {
  r <- lapply(list.files(folder, full.names = TRUE), jsonlite::fromJSON)
  d <- data.frame(id = sapply(r, function(x) x$id),
                  stance = sapply(r, function(x) x$answer$stance),
                  input_tokens = sapply(r, function(x) x$reply$usage$input_tokens),
                  output_tokens = sapply(r, function(x) x$reply$usage$output_tokens))
  write.csv(d[order(d$id), ], out, row.names = FALSE)
}
to_csv("replies/run1", "replies/labels_run1.csv")
to_csv("replies/run2", "replies/labels_run2.csv")
to_csv("replies/statements", "replies/statement_labels.csv")   # id here is the sentence's sid
