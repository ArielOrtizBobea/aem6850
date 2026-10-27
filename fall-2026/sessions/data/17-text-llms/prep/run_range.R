# Section 1 of run_all.R on its own: the target range of every statement.
.libPaths(c(Sys.getenv("ELLMER_LIB"), .libPaths()))
source("model_setup.R")
fomc <- read.csv("fomc_statements.csv")
chat <- chat_anthropic(system_prompt = RANGE_PROMPT, model = MODEL, cache = "none")
t0 <- Sys.time()
ranges <- parallel_chat_structured(chat, as.list(fomc$text), type = range_type,
                                   include_tokens = TRUE, on_error = "continue")
ranges$date <- fomc$date
if (".error" %in% names(ranges)) print(which(!sapply(ranges$.error, is.null)))
write.csv(ranges[, c("date", "lower", "upper", "input_tokens", "output_tokens")],
          "replies/range_model.csv", row.names = FALSE)
cat("range: 171 calls in", round(as.numeric(Sys.time() - t0, units = "secs")), "s;",
    sum(ranges$input_tokens), "in,", sum(ranges$output_tokens), "out\n")
