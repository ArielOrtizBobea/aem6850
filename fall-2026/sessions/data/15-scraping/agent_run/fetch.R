# Polite, cached fetcher for federalreserve.gov.
# Every page is stored in cache/ (body as .html, final URL after redirects as
# .url). A page already in cache is never requested again. Requests are spaced
# at least one second apart, and a 429 answer is retried after a wait.

library(httr2)

UA <- "AEM 6850 class demo; <address>"
CACHE_DIR <- "cache"
dir.create(CACHE_DIR, showWarnings = FALSE)

.last_request <- new.env()
.last_request$t <- 0

cache_key <- function(url) {
  key <- sub("^https?://", "", url)
  key <- gsub("[^A-Za-z0-9._-]", "_", key)
  file.path(CACHE_DIR, key)
}

# Returns list(html = <character>, url = <final url>)
fetch <- function(url, max_tries = 6) {
  key <- cache_key(url)
  html_file <- paste0(key, ".html")
  url_file <- paste0(key, ".url")
  if (file.exists(html_file) && file.exists(url_file)) {
    return(list(html = readr::read_file(html_file),
                url = readLines(url_file, warn = FALSE)[1]))
  }

  for (try in seq_len(max_tries)) {
    wait <- 1 - (as.numeric(Sys.time()) - .last_request$t)
    if (wait > 0) Sys.sleep(wait)
    .last_request$t <- as.numeric(Sys.time())

    resp <- request(url) |>
      req_user_agent(UA) |>
      req_error(is_error = function(resp) FALSE) |>
      req_perform()

    status <- resp_status(resp)
    if (status == 429) {
      ra <- suppressWarnings(as.numeric(resp_header(resp, "Retry-After")))
      pause <- if (!is.na(ra)) ra else 30 * try
      message("429 on ", url, "; waiting ", pause, "s")
      Sys.sleep(pause)
      next
    }
    if (status >= 400) stop("HTTP ", status, " for ", url)

    html <- resp_body_string(resp)
    final_url <- resp$url
    readr::write_file(html, html_file)
    writeLines(final_url, url_file)
    message("fetched ", url)
    return(list(html = html, url = final_url))
  }
  stop("gave up on ", url, " after repeated 429s")
}
