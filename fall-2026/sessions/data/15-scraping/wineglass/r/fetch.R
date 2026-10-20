# Polite cached fetcher: identifying UA, >= 1 s between requests,
# every page saved in cache/, never fetched twice, retry on 429.
library(httr2)

UA <- "AEM 6850 class demo; <your address>"
dir.create("cache", showWarnings = FALSE)
.last_request <- 0

cache_path <- function(url) {
  f <- sub("^https?://", "", url)
  f <- gsub("[^A-Za-z0-9._-]", "_", f)
  file.path("cache", f)
}

# Pages are not always valid UTF-8; fall back to latin1.
read_body <- function(path) {
  raw <- readBin(path, "raw", file.size(path))
  s <- rawToChar(raw)
  if (!validUTF8(s)) s <- iconv(s, "latin1", "UTF-8")
  Encoding(s) <- "UTF-8"
  s
}

fetch <- function(url) {
  path <- cache_path(url)
  if (file.exists(path)) {
    st <- readLines(paste0(path, ".status"), warn = FALSE)
    return(list(status = as.integer(st), body = read_body(path), path = path))
  }
  wait <- 30
  repeat {
    gap <- as.numeric(Sys.time()) - .last_request
    if (gap < 1.1) Sys.sleep(1.1 - gap)
    resp <- request(url) |>
      req_user_agent(UA) |>
      req_error(is_error = function(r) FALSE) |>
      req_perform()
    .last_request <<- as.numeric(Sys.time())
    status <- resp_status(resp)
    if (status != 429) break
    ra <- suppressWarnings(as.numeric(resp_header(resp, "Retry-After")))
    Sys.sleep(if (!is.na(ra)) ra else wait)
    wait <- min(wait * 2, 600)
  }
  writeBin(resp_body_raw(resp), path)  # raw bytes, no decoding
  writeLines(as.character(status), paste0(path, ".status"))
  list(status = status, body = read_body(path), path = path)
}
