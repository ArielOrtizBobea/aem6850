# Split the 171 statements into sentences for the closing figure.
# Drops the paragraph that lists how each member voted, the line that says by
# what vote the statement was approved, and footnote markers. Keeps "St. Louis"
# whole. Writes statement_sentences.csv.
fomc <- read.csv("fomc_statements.csv")
drop <- "^(Voting |In taking the action, the Committee voted|The Federal Open Market Committee approved the following statement)"
nbsp <- " "
rows <- list()
for (k in seq_len(nrow(fomc))) {
  par <- strsplit(fomc$text[k], "\n\n", fixed = TRUE)[[1]]
  par <- trimws(par[!grepl(drop, trimws(par))])
  par <- gsub("St. Louis", paste0("St.", nbsp, "Louis"), par, fixed = TRUE)
  s <- unlist(strsplit(par, "(?<=[.!?])\\s+(?=[A-Z“\"])", perl = TRUE))
  s <- trimws(gsub(nbsp, " ", s, fixed = TRUE))
  s <- s[nchar(s) > 0 & !grepl("^([0-9]+\\.|Return to text)$", s)]
  rows[[k]] <- data.frame(date = fomc$date[k], sentence = s)
}
st <- do.call(rbind, rows)
st$id <- seq_len(nrow(st))
st$sid <- match(st$sentence, unique(st$sentence))   # one id per distinct sentence
st <- st[, c("id", "sid", "date", "sentence")]
write.csv(st, "statement_sentences.csv", row.names = FALSE)
cat(nrow(st), "sentences,", max(st$sid), "distinct; per statement:",
    paste(range(table(st$date)), collapse = "-"), "\n")
