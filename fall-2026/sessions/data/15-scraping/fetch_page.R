# fetch_page.R  (AEM 6850, session 15)
# One polite fetch: a user agent that says who you are and how to reach you,
# a retry on 429 or 503, the reply saved once as the bytes the server sent,
# one log row per request, and a one-second pause. Run from the 15-scraping
# folder: source("fetch_page.R"). Needs httr2.
library(httr2)
dir.create("mine", showWarnings = FALSE)                  # your own fetches go here; cache/ stays as shipped
if (!file.exists("mine/fetch_log.csv")) writeLines("url,file,time,status", "mine/fetch_log.csv")
fetch_page <- function(url, file, ua) {
  if (file.exists(file)) return("already saved")          # never fetch a page twice
  req  <- request(url)
  req  <- req_user_agent(req, ua)                         # who you are and how to reach you
  req  <- req_retry(req, max_tries = 4)                   # a 429 or 503: wait (Retry-After if given), try again
  req  <- req_error(req, is_error = function(resp) FALSE) # a 403 or 404 comes back as a reply, not an R error
  resp <- req_perform(req)
  if (resp_status(resp) == 200) writeBin(resp_body_raw(resp), file)   # the bytes exactly as sent
  write(paste(url, file, format(Sys.time()), resp_status(resp), sep = ","),
        "mine/fetch_log.csv", append = TRUE)              # one log row per request, failures included
  Sys.sleep(1)                                            # one request a second
  resp_status(resp)
}

# Exercise 2, the two long lines, ready to copy:
# fetch_page("https://www.federalreserve.gov/newsevents/pressreleases/monetary20220615a.htm",
#            "mine/monetary20220615a.htm", "AEM 6850 student; <your NetID>@cornell.edu")
# If the fetch fails, use the shipped copy instead:
# file.copy("cache/monetary20220615a.htm", "mine/monetary20220615a.htm")
