# reference_scrape.R  (AEM 6850, session 15)
# Builds cache/ for the deck: the Fed's meeting calendar, the year pages
# 2006-2020, the press-release feed, every linked policy-statement page,
# two Wayback Machine listings and one snapshot, the revision history of
# one Wikipedia page, and one Wikipedia table page.
# Run from the 15-scraping folder. Polite: a contact user agent, one
# request per second, every page saved once as the bytes the server sent,
# and a fetch log (url, final_url, file, time, status, bytes).
suppressPackageStartupMessages({ library(httr2); library(rvest); library(jsonlite) })

UA   <- "AEM 6850 course prep (Cornell University); <your address>"
BASE <- "https://www.federalreserve.gov"
LOG  <- "cache/fetch_log.csv"
dir.create("cache", showWarnings = FALSE)
dir.create("prep",  showWarnings = FALSE)

fetch <- function(url, file, pause = 1) {
  if (file.exists(file)) return(invisible(FALSE))
  resp <- request(url) |> req_user_agent(UA) |> req_retry(max_tries = 4) |>
    req_error(is_error = function(r) FALSE) |> req_perform()
  body <- resp_body_raw(resp)
  if (resp_status(resp) == 200) writeBin(body, file)
  row <- data.frame(url = url, final_url = resp$url, file = file,
                    time = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
                    status = resp_status(resp), bytes = length(body))
  write.table(row, LOG, sep = ",", row.names = FALSE, qmethod = "double",
              col.names = !file.exists(LOG), append = TRUE)
  cat(resp_status(resp), url, "\n")
  Sys.sleep(pause)
  invisible(TRUE)
}

# 1. The lists: calendar (2021-2027), year pages (2006-2020), the feed ----
fetch(paste0(BASE, "/monetarypolicy/fomccalendars.htm"), "cache/fomccalendars.htm")
for (y in 2006:2020)
  fetch(sprintf("%s/monetarypolicy/fomchistorical%d.htm", BASE, y),
        sprintf("cache/fomchistorical%d.htm", y))
fetch(paste0(BASE, "/json/ne-press.json"), "cache/ne-press.json")

# 2. Every monetary press-release page the lists link to ----
cal <- read_html("cache/fomccalendars.htm")
a   <- html_elements(cal, ".fomc-meeting a")
links <- data.frame(source = "fomccalendars.htm", text = html_text2(a), href = html_attr(a, "href"))
for (y in 2006:2020) {
  p <- read_html(sprintf("cache/fomchistorical%d.htm", y))
  a <- html_elements(p, "a")
  links <- rbind(links, data.frame(source = sprintf("fomchistorical%d.htm", y),
                                   text = html_text2(a), href = html_attr(a, "href")))
}
links <- links[!is.na(links$href), ]
links$href_abs <- ifelse(grepl("^http", links$href), links$href, paste0(BASE, links$href))
pat <- "/newsevents/(press/monetary/|pressreleases/monetary)[0-9]{8}[a-z]?[0-9]?\\.htm$"
links$is_monetary <- grepl(pat, links$href_abs)
write.csv(links, "cache/links.csv", row.names = FALSE)

file_for <- function(u) paste0("cache/monetary", sub(".*?([0-9]{8}[a-z]?[0-9]?)\\.htm$", "\\1", u), ".htm")
for (u in unique(links$href_abs[links$is_monetary])) fetch(u, file_for(u))

# ... and every release the feed titles as an FOMC statement
feed <- fromJSON("cache/ne-press.json")
st   <- feed[grepl("FOMC statement", feed$t) & grepl("monetary[0-9]{8}", feed$l), ]
for (u in paste0(BASE, st$l)) fetch(u, file_for(u))

# 3. Past versions: the Wayback Machine (two listings, one snapshot) ----
fetch(paste0("https://web.archive.org/cdx/search/cdx?url=federalreserve.gov/monetarypolicy/fomccalendars.htm",
             "&output=json&fl=timestamp,original,statuscode&filter=statuscode:200&collapse=timestamp:4"),
      "cache/wayback_calendar_cdx.json", pause = 2)
fetch("https://web.archive.org/web/20150102155451id_/https://www.federalreserve.gov/monetarypolicy/fomccalendars.htm",
      "cache/fomccalendars_20150102.htm", pause = 2)
fetch(paste0("https://web.archive.org/cdx/search/cdx?url=federalreserve.gov/newsevents/pressreleases/monetary*",
             "&output=json&fl=timestamp,original,mimetype,statuscode&collapse=urlkey"),
      "cache/wayback_statements_cdx.json", pause = 2)

# 4. Changes to one page: Wikipedia's revision history (no editor field) ----
cont <- ""; i <- 1
repeat {
  f <- sprintf("cache/wiki_powell_revisions_%d.json", i)
  fetch(paste0("https://en.wikipedia.org/w/api.php?action=query&prop=revisions&titles=Jerome_Powell",
               "&rvlimit=500&rvprop=ids%7Ctimestamp%7Csize%7Ccomment&format=json&formatversion=2", cont), f)
  j <- fromJSON(f, simplifyVector = FALSE)
  if (is.null(j$continue)) break
  cont <- paste0("&rvcontinue=", j$continue$rvcontinue); i <- i + 1
}
fetch("https://en.wikipedia.org/wiki/Chair_of_the_Federal_Reserve", "cache/wiki_fed_chairs.htm")

# 5. The user-agent test on bls.gov (two requests; slide-only material) ----
bls <- function(ua) {
  r <- request("https://www.bls.gov/cpi/") |> req_error(is_error = function(r) FALSE)
  if (!is.null(ua)) r <- req_user_agent(r, ua)
  resp <- req_perform(r); Sys.sleep(1)
  data.frame(user_agent = if (is.null(ua)) "httr2 default" else ua,
             status = resp_status(resp), time = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"))
}
write.csv(rbind(bls(NULL), bls("AEM 6850 class exercise; <your address>")),
          "prep/bls_user_agent_test.csv", row.names = FALSE)

# Summary ----
lg <- read.csv(LOG)
cat("\nfiles in cache:", length(list.files("cache")), "\n")
print(table(lg$status))
cat("monetary pages:", length(list.files("cache", pattern = "^monetary")), "\n")
