# After every run: write README.txt (model, runs, calls, tokens) from the saved
# replies. Run from the 17-text-llms folder.
csv <- function(f) if (file.exists(f)) read.csv(f) else NULL
rng <- csv("replies/range_model.csv"); r1 <- csv("replies/labels_run1.csv")
r2 <- csv("replies/labels_run2.csv"); st <- csv("replies/statement_labels.csv")
tok <- function(d) if (is.null(d)) c(NA, NA) else c(sum(d$input_tokens), sum(d$output_tokens))
row <- function(name, d, calls) sprintf("%-38s %6s calls  %10s input  %8s output", name,
  format(calls, big.mark = ","), format(tok(d)[1], big.mark = ","), format(tok(d)[2], big.mark = ","))
loc <- sapply(c("4b", "9b", "27b"), function(s) {
  d <- csv(paste0("replies/local_", s, ".csv")); if (is.null(d)) NA else nrow(d) })
txt <- c(
"17-text-llms: how the saved model replies were made",
"====================================================",
"",
"Closed model: claude-sonnet-5-5 (the provider's mid-size model), written once",
"as MODEL in model_setup.R. Prompts: range_prompt.txt and codebook.txt, written",
"before any reply was seen. Schemas: range_type and stance_type in",
"model_setup.R. Every call used the model's default settings (the model",
"rejects a temperature setting) with ellmer's prompt cache off",
"(cache = \"none\"), one fresh conversation per item.",
paste0("Runs made on ", format(Sys.Date(), "%d %B %Y"), " on the instructor's key, ellmer ",
       as.character(packageVersion("ellmer", lib.loc = c(Sys.getenv("ELLMER_LIB"), .libPaths()))),
       ", ", R.version.string, "."),
"",
row("Target range, 171 statements", rng, 171),
row("Stance labels, run 1", r1, nrow(r1)),
row("Stance labels, run 2", r2, nrow(r2)),
row("Statement sentences (distinct)", st, nrow(st)),
"",
"The label runs used save_replies() (save_replies.R), split across 8 R",
"sessions (prep/run_shard.R) that call it on parts of the ids. The range run",
"used parallel_chat_structured() (prep/run_range.R). replies/*.csv are built",
"from the JSON files by prep/build_csv.R. demo/ holds the sentences of",
"the five-sentence task labelled twice before class, as demo.R does live.",
"",
"Open models, run on the instructor's laptop (Apple M2 Max, 64 GB) through a",
"local Ollama server, the same codebook and schema, temperature 0, seed 6850,",
"thinking off, by run_local.R (a copy is in prep/):",
sprintf("  qwen3.5:4b-q4_K_M (3.3 GB): %s sentences, replies/local_4b.csv", loc[1]),
sprintf("  qwen3.5:9b-q4_K_M (6.6 GB): %s sentences, replies/local_9b.csv", loc[2]),
sprintf("  qwen3.5:27b-q4_K_M (17 GB): %s sentences, replies/local_27b.csv", loc[3]),
"Each row holds the id, the label and the seconds the call took.")
writeLines(txt, "README.txt")
cat(txt, sep = "\n")
