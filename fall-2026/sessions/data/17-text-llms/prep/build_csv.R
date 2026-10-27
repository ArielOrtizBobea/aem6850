# The last section of run_all.R on its own: one CSV per folder of replies.
to_csv <- function(folder, out) {
  r <- lapply(list.files(folder, full.names = TRUE), jsonlite::fromJSON)
  d <- data.frame(id = sapply(r, function(x) x$id),
                  stance = sapply(r, function(x) x$answer$stance),
                  input_tokens = sapply(r, function(x) x$reply$usage$input_tokens),
                  output_tokens = sapply(r, function(x) x$reply$usage$output_tokens))
  write.csv(d[order(d$id), ], out, row.names = FALSE)
  cat(out, nrow(d), "rows;", sum(d$input_tokens), "in,", sum(d$output_tokens), "out\n")
}
to_csv("replies/run1", "replies/labels_run1.csv")
to_csv("replies/run2", "replies/labels_run2.csv")
to_csv("replies/statements", "replies/statement_labels.csv")
