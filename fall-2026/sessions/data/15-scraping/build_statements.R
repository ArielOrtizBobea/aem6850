# build_statements.R  (AEM 6850, session 15)
# Builds fomc_statements.csv from the pages in cache/: one row per FOMC
# policy statement since January 2006, with date, url, words, text and
# scheduled. A page counts as a policy statement when its own title
# contains "FOMC statement" and the release is the committee's decision on
# its policy stance: the titles that announce dollar swap lines, liquidity
# measures, the longer-run goals statement, the policy normalization
# principles or a change of release times are left out, as is everything
# else the lists link to (implementation notes, the August 2025 notation
# vote, balance-sheet plans). Every excluded page is listed in
# prep/excluded.csv with its title.
# Run from the 15-scraping folder after reference_scrape.R.
suppressPackageStartupMessages({ library(rvest); library(jsonlite) })

lg    <- read.csv("cache/fetch_log.csv")
files <- list.files("cache", pattern = "^monetary[0-9]{8}[a-z]?[0-9]?\\.htm$", full.names = TRUE)

# Which statements followed a scheduled meeting: from the year pages' headings
sched <- data.frame()
for (y in 2006:2020) {
  p <- read_html(sprintf("cache/fomchistorical%d.htm", y))
  for (panel in html_elements(p, ".panel-default")) {
    head <- html_text2(html_element(panel, "h5"))
    a <- html_elements(panel, "a")
    href <- html_attr(a, "href")[html_text2(a) == "Statement"]
    if (length(href)) sched <- rbind(sched, data.frame(key = sub(".*?([0-9]{8}[a-z]?)\\.htm$", "\\1", href),
                                                       heading = head, scheduled = !grepl("conference call|unscheduled|notation", head, ignore.case = TRUE)))
  }
}
cal <- read_html("cache/fomccalendars.htm")
cal_keys <- sub(".*?([0-9]{8}[a-z]?)\\.htm$", "\\1",
                html_attr(html_elements(cal, ".fomc-meeting a[href*='pressreleases/monetary']"), "href"))

clean <- function(ps) {
  ps <- gsub(" ", " ", ps)
  drop <- grepl("^(For release at|For immediate release|For media inquiries|Implementation Note issued|Last Update|Release Date)", ps) |
          grepl("^[A-Z][a-z]+ [0-9]{1,2}, [0-9]{4}$", ps)   # the date line
  ps[!drop & nzchar(trimws(ps))]
}

rows <- list(); excluded <- list()
for (f in files) {
  raw   <- readLines(f, warn = FALSE, encoding = "UTF-8")
  if (grepl("20090624a", f)) raw <- gsub("<P></P>", "<P>", raw, fixed = TRUE)   # this page opens its voting paragraph with an empty <P></P>
  p     <- read_html(paste(raw, collapse = "\n"))
  title <- html_text2(html_element(p, "h3.title"))
  if (is.na(title)) title <- html_text2(html_element(p, "title"))
  key   <- sub("^cache/monetary(.*)\\.htm$", "\\1", f)
  date  <- as.Date(html_text2(html_element(p, "p.article__time")), "%B %d, %Y")   # the page's own date line
  if (is.na(date)) date <- as.Date(substr(key, 1, 8), "%Y%m%d")                       # else the address
  url   <- lg$final_url[match(f, lg$file)]
  not_policy <- grepl("swap|liquidity|longer-run goals|normalization principles|time changes", title, ignore.case = TRUE)
  if (!grepl("FOMC statement", title) || not_policy) {
    excluded[[f]] <- data.frame(key = key, date = date, title = title, url = url); next
  }
  pars <- html_elements(p, "#article p")
  link_only <- vapply(pars, function(x) {                      # cross-references and headings, not statement text:
    lt <- paste(html_text2(html_elements(x, "a")), collapse = ""); t <- html_text2(x)
    share <- if (nchar(t)) nchar(gsub("[[:space:]]", "", lt)) / nchar(gsub("[[:space:]]", "", t)) else 0
    no_sentence <- !grepl("[.!?]", t)
    (nzchar(lt) && share >= 0.8) ||                              #  a paragraph that is mostly links
      (nzchar(lt) && no_sentence) ||                             #  a link with a label and no sentence
      (no_sentence && nchar(t) < 80) }, logical(1))              #  a short heading or label (a lead-in ending in a colon stays)
  ps   <- trimws(clean(html_text2(pars[!link_only])))
  while (length(ps) && grepl(":$", ps[length(ps)])) ps <- ps[-length(ps)]   # a trailing lead-in to links that were dropped
  text <- paste(ps, collapse = "\n\n")
  s    <- if (key %in% sched$key) sched$scheduled[match(key, sched$key)] else if (key %in% cal_keys) TRUE else NA
  rows[[f]] <- data.frame(date = format(date), url = url, words = length(strsplit(text, "\\s+")[[1]]),
                          text = text, scheduled = s, title = title, paragraphs = length(ps))
}
d  <- do.call(rbind, rows); d <- d[order(d$date), ]
ex <- do.call(rbind, excluded); ex <- ex[order(ex$date), ]

cat("statements:", nrow(d), " excluded pages:", nrow(ex), "\n")
cat("scheduled NA (not on any list; set to FALSE):", sum(is.na(d$scheduled)), "\n")
if (any(is.na(d$scheduled))) print(d[is.na(d$scheduled), c("date", "title", "url")])
d$scheduled[is.na(d$scheduled)] <- FALSE
cat("\ntitles kept:\n"); print(table(d$title))
cat("\nexcluded titles (first 60 chars):\n"); print(table(substr(ex$title, 1, 60)))
cat("\nper year: statements, scheduled, feed-titled\n")
feed <- fromJSON("cache/ne-press.json"); fs <- feed[grepl("FOMC statement", feed$t), ]   # 179 titles; the next line drops the non-policy ones
yr <- data.frame(year = 2006:2026)
yr$statements <- as.integer(table(factor(substr(d$date, 1, 4), levels = yr$year)))
yr$scheduled  <- as.integer(table(factor(substr(d$date[d$scheduled], 1, 4), levels = yr$year)))
fs$year <- format(as.Date(sub(" .*", "", fs$d), "%m/%d/%Y"), "%Y")
fs <- fs[!grepl("swap|liquidity|longer-run goals|normalization principles|time changes", fs$t, ignore.case = TRUE), ]
yr$feed       <- as.integer(table(factor(fs$year, levels = yr$year)))
print(yr, row.names = FALSE)
cat("\nparagraph counts:\n"); print(table(d$paragraphs))
cat("words: "); print(summary(d$words))

write.csv(d[, c("date", "url", "words", "text", "scheduled")], "fomc_statements.csv", row.names = FALSE)
write.csv(ex, "prep/excluded.csv", row.names = FALSE)
write.csv(yr, "prep/per_year.csv", row.names = FALSE)
write.csv(d[, c("date", "url", "title", "paragraphs", "words", "scheduled")], "prep/statements_index.csv", row.names = FALSE)
