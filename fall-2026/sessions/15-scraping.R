# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# AEM 6850 -- Empirical Methods for Applied Economists
# Prof. Ariel Ortiz-Bobea
# Session 15 -- Channels II: scraping
# Tuesday, October 20, 2026
#
# Run it one line at a time: put the cursor on a line and press Cmd-Return
# (Mac) or Ctrl-Enter (Windows).
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# Preliminary ----
# Clean up workspace and load or install necessary packages if necessary
  rm(list=ls())
  want <- c("httr2","jsonlite","rvest")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only=TRUE))
  rm(want, need)


# Statements file ----
ours <- read.csv("fomc_statements.csv")                  # ours: the statements file
dim(ours)
ours[c(1, nrow(ours)), c("date", "words", "scheduled")]  # the first and the last row


# Read html ----
# install.packages(c("rvest", "httr2", "jsonlite"))   # once
library(rvest)
cal    <- read_html("cache/fomccalendars.htm")       # the calendar as saved
panels <- html_elements(cal, ".panel-default")       # one panel per year
length(panels)
titles <- html_text2(html_element(panels, "h4"))     # the first h4 (a heading) inside each panel
titles


# Rows 2024 ----
p2024 <- panels[titles == "2024 FOMC Meetings"]
rows  <- html_elements(p2024, ".fomc-meeting")
length(rows)
data.frame(month = html_text2(html_element(rows, ".fomc-meeting__month")),
           dates = html_text2(html_element(rows, ".fomc-meeting__date")))


# Html attr ----
links <- html_elements(rows[1], "a")                 # the links in the January row
data.frame(text = substr(html_text2(links), 1, 24),  # substr(): the first 24 characters
           file = basename(html_attr(links, "href")))  # basename(): the file name at the end of the address


# Three counts ----
# both selectors start with .fomc-meeting: 6 more a.htm links sit outside the rows
a1 <- html_elements(cal, ".fomc-meeting a[href*='pressreleases/monetary']")  # address contains this
a2 <- html_elements(cal, ".fomc-meeting a[href$='a.htm']")                   # address ends in a.htm
c(contains = length(a1), ends_a = length(a2),
  text_HTML = sum(html_text2(a1) == "HTML"))     # sum() counts the TRUEs


# Html table ----
wiki   <- read_html("cache/wiki_fed_chairs.htm")
tbl    <- html_element(wiki, "table.wikitable")      # the first table of that class
chairs <- as.data.frame(html_table(tbl))             # as.data.frame(): a plain data frame print
dim(chairs)
unlist(chairs[1, 4:5])          # the header spans two rows; its second row arrives as data
chairs <- chairs[-1, ]                               # drop it
names(chairs) <- c("no", "portrait", "name", "start", "end", "duration", "appointer", "experience", "education")
tail(chairs[, c("no", "name", "start", "end")], 3)


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Exercise 1 (5 minutes) ----
# Exercise 1 (5 minutes). R Console, in the 15-scraping folder; needs rvest.
# No network. If you do not have cal, panels and titles yet, run these three:
#   cal    <- read_html("cache/fomccalendars.htm")
#   panels <- html_elements(cal, ".panel-default")
#   titles <- html_text2(html_element(panels, "h4"))
#
# 1. Keep the panel titled "2025 FOMC Meetings".
# 2. Select its .fomc-meeting rows and count them with length().
# 3. Print each row's month (.fomc-meeting__month) and dates
#    (.fomc-meeting__date) in one data frame.
# 4. Find the row that is not a meeting.
#
# Two answers to compare with the room: the number of rows, and
# which row is not a meeting.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




# Feed ----
library(jsonlite)
feed <- fromJSON("cache/ne-press.json")     # warns about a byte-order mark (three invisible bytes); harmless
dim(feed)
fs <- feed[grepl("FOMC statement", feed$t), ]   # titles that contain the phrase; t is the title column
nrow(fs)
table(fs$t)[c("Federal Reserve issues FOMC statement", "FOMC statement")]   # the two common titles


# Fetch page ----
# the same function ships as fetch_page.R: source("fetch_page.R")
library(httr2)
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


# Fetch page files ----
dir.create("mine", showWarnings = FALSE)                  # your own fetches go here; cache/ stays as shipped
if (!file.exists("mine/fetch_log.csv")) writeLines("url,file,time,status", "mine/fetch_log.csv")


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Exercise 2 (5 minutes) ----
# Exercise 2 (5 minutes). R Console, in the 15-scraping folder; needs
# fetch_page(): run source("fetch_page.R") if it is not defined yet. One
# live request. Step 2's two lines are long: copy them from fetch_page.R.
#
# 1. Put your own address in the user agent:
#    ua <- "AEM 6850 student; <your netid>@cornell.edu"
# 2. Fetch the 15 June 2022 statement into mine/:
#    fetch_page("https://www.federalreserve.gov/newsevents/pressreleases/monetary20220615a.htm",
#               "mine/monetary20220615a.htm", ua)
#    No network? file.copy("cache/monetary20220615a.htm", "mine/"), then the same line.
# 3. Read the saved file with read_html() and select "#article p".
# 4. Count the paragraphs with length(); print them with html_text2().
#
# Two answers to compare with the room: the number of paragraphs, and
# which paragraph names the member who voted against the decision.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




# Year loop ----
ua  <- "AEM 6850 student; <your netid>@cornell.edu"       # any name with your address works
out <- data.frame()
for (y in 2006:2020) {
  url  <- sprintf("https://www.federalreserve.gov/monetarypolicy/fomchistorical%d.htm", y)
  file <- sprintf("cache/fomchistorical%d.htm", y)
  fetch_page(url, file, ua)                               # returns "already saved": the file is in cache/
  page <- read_html(file)
  h5   <- html_text2(html_elements(page, ".panel-default h5"))   # one heading per meeting or call
  a    <- html_elements(page, "a")                        # every link; here every Statement link sits inside a panel
  out  <- rbind(out, data.frame(year = y, listed = length(h5),
                                statements = sum(html_text2(a) == "Statement")))
}


# Year counts ----
colSums(out[, c("listed", "statements")])
print(out[out$listed != out$statements, ], row.names = FALSE)   # the eight years that differ


# Address forms ----
p08  <- read_html("cache/fomchistorical2008.htm")
a08  <- html_elements(p08, "a")
href <- html_attr(a08[html_text2(a08) == "Statement"], "href")   # the 11 Statement links of 2008
unique(dirname(href))        # the folder part of the address: an older form
basename(href)               # the file part: two end in b


# Agent vs site ----
agent <- read.csv("agent_run/fomc_statements.csv")
ours  <- read.csv("fomc_statements.csv")
c(agent = nrow(agent), ours = nrow(ours))
yr <- data.frame(year = 2006:2026)
yr$agent <- as.vector(table(substr(agent$date, 1, 4)))   # rows per year; substr(): characters 1 to 4
yr$ours  <- as.vector(table(substr(ours$date,  1, 4)))
print(yr[yr$agent != yr$ours, ], row.names = FALSE)      # the years that differ


# Seeded draw ----
set.seed(6850)
pick <- sample(nrow(agent), 3)
agent[pick, c("date", "words", "scheduled")]
# match(): the row of ours with the same date
agent$text[pick] == ours$text[match(agent$date[pick], ours$date)]
# the last row, so the scrape ran to the end
agent[nrow(agent), c("date", "words")]


# Agent log ----
fetch_log <- readLines("agent_run/fetch_log.txt")
c(lines = length(fetch_log), fetched = sum(startsWith(fetch_log, "fetched")))
sub("fetched https://www.federalreserve.gov", "", grep("429", fetch_log, value = TRUE))   # the lines that contain 429


# Demo compare ----
r  <- read.csv("wineglass/r/wineglass.csv", na.strings = c("", "NA"))       # blank sex reads as NA
py <- read.csv("wineglass/python/wineglass.csv", na.strings = c("", "NA"))
cols <- c("year", "place", "sex", "age_group", "net_time")
c(r = nrow(r), python = nrow(py))
identical(r[cols], py[cols])                                              # same rows, same values
rbind(rows = table(r$year), last_place = tapply(r$place, r$year, max))   # one column per year


# Wayback snap ----
snap <- read_html("cache/fomccalendars_20150102.htm")   # the page as captured on 2 January 2015
length(html_elements(snap, ".panel-default"))            # today's selector finds nothing
html_text2(html_elements(snap, "th#year"))               # th#year: a th element whose id is year
sum(html_text2(html_elements(snap, "a")) == "Statement")   # links named Statement on the 2015 page


# Wayback cdx ----
cdx <- fromJSON("cache/wayback_calendar_cdx.json")      # a header row, then one capture per year
cdx[c(2, 9, 20), 1]                                      # the first, a middle and the last capture; YYYYMMDDhhmmss


# Wiki history ----
# https://en.wikipedia.org/w/api.php?action=query&prop=revisions&titles=Jerome_Powell
#   &rvlimit=500&rvprop=ids|timestamp|size|comment&format=json&formatversion=2
# rvlimit: revisions per reply (at most 500); rvprop: the fields wanted
j <- fromJSON("cache/wiki_powell_revisions_1.json")          # the first reply
j$continue$rvcontinue                                        # where the next request starts
one <- function(i) {
  j  <- fromJSON(sprintf("cache/wiki_powell_revisions_%d.json", i))
  pg <- j$query$pages
  pg$revisions[[1]]                                          # the revisions of the one page
}
revs <- do.call(rbind, lapply(1:4, one))                     # the four replies, stacked
nrow(revs)


# Edits per year slide ----
year <- substr(revs$timestamp, 1, 4)
barplot(table(year), las = 2, ylab = "Edits",
        main = "Edits per year, Wikipedia article 'Jerome Powell'")


year <- substr(revs$timestamp, 1, 4)
barplot(table(year), las = 2, ylab = "Edits",
        main = "Edits per year, Wikipedia article 'Jerome Powell'")


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Practice ----
# Practice. Run in the 15-scraping folder with rvest, httr2 and jsonlite
# loaded, after the saved calendar is read (cal, panels, titles) and
# fetch_page() is defined. Your fetches go to mine/. Tasks 1-5 and 10 need
# no network. Task 6 sends two requests to bls.gov: after class, not in the room.

# Selectors on the saved calendar (cache/fomccalendars.htm)
#  1. Count the links named "Press Conference" inside .fomc-meeting rows,
#     per panel. Which years have one for every meeting?
#  2. The minutes' release dates sit in text like "(Released February 21,
#     2024)" inside .fomc-meeting__minutes. Pull them out with regmatches()
#     and regexpr(). How many rows have one?
#  3. Count the dates ending in an asterisk (the meetings that also publish
#     the members' projections). How many per year?
# The year pages (cache/fomchistorical2008.htm, 2020.htm)
#  4. Read the h5 headings and sort them into meetings, conference calls,
#     unscheduled meetings, notation votes and a cancelled meeting.
#  5. For each call or notation vote, count the links named "Statement"
#     inside its panel. Which issued a statement?
# Identifying yourself (after class, one request per line)
#  6. Run the two BLS requests from the user-agent slide with req_error()
#     so the reply comes back. Record both status codes and the first 200
#     characters of each body with resp_body_string().
# Whether you may scrape (no code needed)
#  7. For one site you would use in your own research: find its terms of
#     use and its robots.txt. Write three lines: what the terms say about
#     automated access, which paths robots.txt disallows, and whether a
#     feed, API or sitemap exists. Follow one Sitemap: line: is it a
#     sitemap or an index of sitemaps, and is the page you need in it?
# Past versions
#  8. Query the CDX index for a page you use, with collapse=timestamp:4 and
#     filter=statuscode:200. How many captures per year? Fetch the oldest
#     with the id_ flag through fetch_page() into mine/ and read one element
#     with the selector that works on today's page. Does it?
#  9. Request the revision history of a Wikipedia page you choose, with
#     your contact user agent and rvprop=ids|timestamp|size|comment, paging
#     with rvcontinue until it is absent. Plot edits per year. Do not
#     request the user field.
# The statements file (fomc_statements.csv)
# 10. plot(as.Date(d$date), d$words). Compute the median words per year
#     with tapply(). Which year's statements were longest, which shortest?
#     Open the longest (which.max) and the shortest (which.min) in the
#     browser and say what each announced.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =


# The end
