# One of n R sessions running save_replies() on its share of the ids.
# Usage: Rscript prep/run_shard.R <labels|statements> <folder> <k> <n>
a <- commandArgs(trailingOnly = TRUE)
.libPaths(c(Sys.getenv("ELLMER_LIB"), .libPaths()))
source("model_setup.R"); source("save_replies.R")
k <- as.integer(a[3]); n <- as.integer(a[4])
if (a[1] == "labels") {
  d <- read.csv("tdw_sentences.csv"); texts <- d$sentence; ids <- d$id
} else {
  st <- read.csv("statement_sentences.csv"); u <- st[!duplicated(st$sid), ]
  texts <- u$sentence; ids <- u$sid
}
mine <- which((seq_along(ids) - 1) %% n == k - 1)
t0 <- Sys.time()
for (tries in 1:3) {   # a failed call stops the loop; rerun picks up where it stopped
  ok <- tryCatch({ save_replies(texts[mine], ids[mine], a[2], CODEBOOK, stance_type); TRUE },
                 error = function(e) { message("shard ", k, ": ", conditionMessage(e)); Sys.sleep(20); FALSE })
  if (ok) break
}
cat("shard", k, "done in", round(as.numeric(Sys.time() - t0, units = "mins"), 1), "min\n")
