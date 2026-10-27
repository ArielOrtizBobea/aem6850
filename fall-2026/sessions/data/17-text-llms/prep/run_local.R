# Label the 2,480 sentences with an open model on this computer (no charge).
# Usage: Rscript prep/run_local.R <model file> <out.csv>
# Resumable: ids already in out.csv are skipped.
a <- commandArgs(trailingOnly = TRUE)
.libPaths(c(Sys.getenv("ELLMER_LIB"), .libPaths()))
source("model_setup.R")
LOCAL_MODEL <- a[1]; out <- a[2]
tdw <- read.csv("tdw_sentences.csv")
done <- if (file.exists(out)) read.csv(out)$id else integer(0)
chat_local <- chat_ollama(model = LOCAL_MODEL, system_prompt = CODEBOOK,
                          params = params(temperature = 0, seed = 6850, reasoning_effort = "none"))
if (!file.exists(out)) writeLines("id,stance,seconds", out)
t0 <- Sys.time()
for (j in setdiff(tdw$id, done)) {
  t1 <- Sys.time()
  r <- tryCatch(chat_local$clone()$chat_structured(tdw$sentence[j], type = stance_type)$stance,
                error = function(e) NA)
  cat(sprintf("%d,%s,%.2f\n", j, r, as.numeric(Sys.time() - t1, units = "secs")),
      file = out, append = TRUE)
}
cat(LOCAL_MODEL, "done in", round(as.numeric(Sys.time() - t0, units = "mins"), 1), "min\n")
