# Collect FOMC policy statements, January 2006 to the latest, from
# federalreserve.gov. Writes fomc_statements.csv and prints counts per year.
# All requests go through fetch() in R/fetch.R (cached, 1 request/second,
# 429 retry).

suppressPackageStartupMessages({
  library(rvest)
  library(dplyr)
  library(stringr)
  library(readr)
})
source("R/fetch.R")

BASE <- "https://www.federalreserve.gov"

# ---- Statement links from the calendar pages --------------------------------

# 2006-2020: one page per year. Each meeting or call is a panel with an <h5>
# heading such as "January 29-30 Meeting - 2008", "January 21 Conference
# Call - 2008", "March 15 (unscheduled) Meeting - 2020" or "March 23 (notation
# vote) - 2020". The policy statement is the link whose text is "Statement".
historical_links <- function(year) {
  page <- read_html(fetch(sprintf("%s/monetarypolicy/fomchistorical%d.htm",
                                  BASE, year))$html)
  panels <- html_elements(page, xpath = "//div[contains(@class,'panel')][.//h5]")
  bind_rows(lapply(panels, function(p) {
    heading <- html_text2(html_element(p, "h5"))
    a <- html_elements(p, "a")
    a <- a[str_trim(html_text2(a)) == "Statement"]
    if (length(a) == 0) return(NULL)
    tibble(heading = heading, href = html_attr(a, "href"))
  })) |>
    distinct(href, .keep_all = TRUE) |>
    mutate(scheduled = str_detect(heading, "Meeting") &
             !str_detect(heading, regex("unscheduled|notation|cancel",
                                        ignore_case = TRUE)))
}

# 2021 onward: the current calendar page. Each meeting is a div.fomc-meeting
# row; the statement is the "HTML" link that follows the "Statement:" label.
# Every row here is a scheduled meeting (the August 2025 notation vote row
# carries only the longer-run goals statement, which has no "Statement:" label).
calendar_links <- function() {
  page <- read_html(fetch(paste0(BASE, "/monetarypolicy/fomccalendars.htm"))$html)
  rows <- html_elements(page, xpath = "//div[contains(concat(' ',@class,' '),' fomc-meeting ')]")
  bind_rows(lapply(rows, function(r) {
    a <- html_elements(r, xpath = ".//strong[contains(.,'Statement:')]/following-sibling::a[normalize-space(.)='HTML']")
    if (length(a) == 0) return(NULL)
    tibble(heading = str_squish(html_text2(r)) |> str_sub(1, 40),
           href = html_attr(a[1], "href"))
  })) |>
    distinct(href, .keep_all = TRUE) |>
    mutate(scheduled = TRUE)
}

links <- bind_rows(lapply(2006:2020, historical_links), calendar_links()) |>
  mutate(url = paste0(BASE, href))

# ---- Statement pages ---------------------------------------------------------

# Body paragraphs of the press release minus page furniture: the media-contact
# line, the pointer to the implementation note, and links to attachments.
BOILERPLATE <- regex(paste(
  "^For media inquiries", "^Implementation Note issued", "^Last Update",
  "^Attachment", "^Related Information",
  "^Information on the actions that will be taken by other central banks",
  sep = "|"), ignore_case = TRUE)

parse_statement <- function(url) {
  res <- fetch(url)
  page <- read_html(res$html)
  article <- html_element(page, "#article")
  date_txt <- html_text2(html_element(article, ".article__time"))
  body <- html_element(article,
    xpath = "./div[contains(@class,'col-sm-8') and not(contains(@class,'heading'))]")
  # Page furniture inside the body: the FAQ widget (2011) and run-in bold
  # headings over link lists ("Statements by Other Central Banks", 2008-2010).
  xml2::xml_remove(html_elements(body, xpath = paste0(
    ".//p[@class='type' or @class='date' or @class='link'] | ",
    ".//p[(b or strong) and not(text()[normalize-space()])] | ",
    ".//p/*[self::b or self::strong][following-sibling::node()[1][self::br] or .//br]")))
  # Block-level text, not just <p>: some releases hold a paragraph as a bare
  # text node (June 2009 vote) or as list items (October 2019).
  paras <- str_split_1(html_text2(body), "\n+") |> str_squish()
  # A line made only of link text points to a related release (FAQs, other
  # central banks' announcements, the New York Fed), not statement text.
  drop_size <- function(x) str_squish(str_remove_all(x, "\\(\\d+ KB PDF\\)"))
  links_txt <- unique(drop_size(html_text2(html_elements(body, "a"))))
  links_txt <- links_txt[links_txt != ""]
  rest <- drop_size(paras)
  for (l in links_txt[order(-nchar(links_txt))]) rest <- str_remove_all(rest, fixed(l))
  link_only <- nchar(str_remove_all(rest, "[^[:alnum:]]")) < 3
  paras <- paras[!link_only & !str_detect(paras, BOILERPLATE)]
  text <- paste(paras, collapse = "\n\n")
  tibble(date = as.Date(date_txt, format = "%B %d, %Y"),
         url = res$url,
         words = str_count(text, "\\S+"),
         text = text)
}

statements <- bind_cols(
  bind_rows(lapply(links$url, parse_statement)),
  select(links, scheduled, heading)
)

stopifnot(!anyNA(statements$date), all(statements$words > 0),
          !anyDuplicated(statements$url))

out <- statements |>
  filter(date >= as.Date("2006-01-01")) |>
  arrange(date) |>
  mutate(date = format(date, "%Y-%m-%d")) |>
  select(date, url, words, text, scheduled)

write_csv(out, "fomc_statements.csv")

cat("Wrote", nrow(out), "statements to fomc_statements.csv\n\n")
cat("Statements per year:\n")
print(as.data.frame(count(out, year = substr(date, 1, 4), name = "statements")),
      row.names = FALSE)
