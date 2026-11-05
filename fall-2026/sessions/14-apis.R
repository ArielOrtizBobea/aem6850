# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# AEM 6850 -- Empirical Methods for Applied Economists
# Prof. Ariel Ortiz-Bobea
# Session 14 -- Channels I: APIs
# Thursday, October 15, 2026
#
# Run it one line at a time: put the cursor on a line and press Cmd-Return
# (Mac) or Ctrl-Enter (Windows).
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# Preliminary ----
# Clean up workspace and load or install necessary packages if necessary
  rm(list=ls())
  want <- c("httr2","jsonlite")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only=TRUE))
  rm(want, need)


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Exercise 1 (2 minutes) ----
# Exercise 1 (2 minutes). In your browser; no R needed.
# Start from the request on the slide:
# https://api.worldbank.org/v2/country/IND/indicator/EG.ELC.ACCS.ZS?date=2023&format=json
#
# 1. Replace IND with another country's three-letter code:
#    CHN China, BGD Bangladesh, KEN Kenya, NGA Nigeria,
#    ETH Ethiopia, BRA Brazil, or your own country's.
# 2. Change date=2023 to date=2000.
# A first request can take up to a minute. Wait, or reload the page.
#
# Two answers to compare with the room: your country's access to
# electricity (% of population) in 2023 and in 2000.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




# Sending the request from R with httr2 ----
# install.packages(c("httr2", "jsonlite"))   # once; jsonlite does not come with httr2
library(httr2)
req <- request("https://api.worldbank.org/v2/country/all/indicator/EG.ELC.ACCS.ZS")
req <- req_url_query(req, date = 2023, format = "json", per_page = 100, page = 1)
req
#> <httr2_request>
#> GET https://api.worldbank.org/v2/country/all/indicator/EG.ELC.ACCS.ZS?date=2023&format=json&per_page=100&page=1
#> Body: empty
resp <- req_perform(req)
resp_status(resp)
#> [1] 200


# A status 200 whose body holds an error ----
bad <- request("https://api.worldbank.org/v2/country/all/indicator/EG.ELC.ACCS.ZZ")
bad <- req_url_query(bad, date = 2023, format = "json")
resp_bad <- req_perform(bad)
resp_status(resp_bad)
#> [1] 200
writeLines(resp_body_string(resp_bad))
#> [{"message":[{"id":"120","key":"Invalid value","value":"The provided parameter value is not valid"}]}]
# no network? writeLines(readLines("saved/wb_bad_code.json")) shows the same body


# Reading the JSON reply into R with fromJSON() ----
library(jsonlite)
first <- fromJSON(resp_body_string(resp))
# no network? first <- fromJSON("saved/wb_2023_p1.json") gives the same
str(first[[1]])
d <- first[[2]]
dim(d)
names(d)


# Flattening the records into a data frame ----
class(d$country)             # a data frame inside the data frame
wb1 <- data.frame(country = d$country$value, iso3 = d$countryiso3code,
                  year = d$date, access = d$value)
head(wb1, 3)
wb1[wb1$iso3 == "IND", ]


# fetch() to request and save one page, flat() to flatten it ----
dir.create("raw", showWarnings = FALSE)
fetch <- function(p, year, per) {
  req <- request("https://api.worldbank.org/v2/country/all/indicator/EG.ELC.ACCS.ZS")
  req <- req_url_query(req, date = year, format = "json", per_page = per, page = p)
  txt <- resp_body_string(req_perform(req))
  writeLines(txt, paste0("raw/wb_", year, "_p", p, ".json"))  # the reply as sent
  Sys.sleep(1)                                                # one request a second
  fromJSON(txt)
}
flat <- function(reply) {
  d <- reply[[2]]
  data.frame(country = d$country$value, iso3 = d$countryiso3code,
             year = d$date, access = d$value)
}


# Requesting all pages and comparing rows with the total ----
first <- fetch(1, 2023, 100)
replies <- lapply(1:first[[1]]$pages, fetch, year = 2023, per = 100)
wb <- do.call(rbind, lapply(replies, flat))
c(rows = nrow(wb), total = first[[1]]$total)
#>  rows total
#>   266   266
wb[wb$iso3 == "IND", ]
#>     country iso3 year access
#> 139   India  IND 2023   99.5


# Rebuilding the table from the saved replies ----
replies <- lapply(paste0("saved/wb_2023_p", 1:3, ".json"), fromJSON)
wb <- do.call(rbind, lapply(replies, flat))
nrow(wb)
replies[[1]][[1]]$lastupdated


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Exercise 2 (5 minutes) ----
# Exercise 2 (5 minutes). R Console, in the 14-apis folder.
# First run source("wb_functions.R"), which defines fetch() and flat().
# No network? Skip the requests and run
#   replies0 <- lapply(paste0("saved/wb_2000_p", 1:6, ".json"), fromJSON)
#   first0 <- replies0[[1]]
#
# 1. Request page 1 of the year 2000 with 50 rows a page:
#    first0 <- fetch(1, 2000, 50). How many pages? What total?
# 2. Request every page into replies0 with lapply(), then stack them:
#    wb0 <- do.call(rbind, lapply(replies0, flat))
# 3. Compare nrow(wb0) with the total.
# 4. Find India's row (iso3 is "IND").
#
# Two answers to compare with the room: the rows against the
# reported total, and India's access to electricity in 2000.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




# One row of the EIA reply ----
p1 <- fromJSON("saved/eia_nyis_0.json")
p1$response$data[1, c("period", "respondent", "type",
                      "type-name", "value", "value-units")]


# Requesting every hour of 2025 from the EIA in R ----
base <- request("https://api.eia.gov/v2/electricity/rto/region-data/data/")
base <- req_url_query(base,                   # backticks let R use names with brackets
  api_key = Sys.getenv("EIA_KEY"),
  frequency = "local-hourly",                 # hours in New York time
  `data[0]` = "value",                        # the demand number
  `facets[respondent][]` = "NYIS",            # New York's grid
  `facets[type][]` = "D",                     # D = demand
  start = "2025-01-01T00-05", end = "2026-01-01T00-05",  # -05: 5 hours behind UTC (4 in summer)
  `sort[0][column]` = "period",               # sort by hour, so that the
  `sort[0][direction]` = "asc")               # pages follow in order
eia_page <- function(offset) {
  req <- req_url_query(base, offset = offset, length = 5000)  # skip, then up to 5,000
  txt <- resp_body_string(req_perform(req))
  writeLines(txt, paste0("raw/eia_nyis_", offset, ".json"))
  Sys.sleep(1)
  fromJSON(txt)
}


# Stacking the two EIA pages into the 8,760 hours of 2025 ----
p1 <- fromJSON("saved/eia_nyis_0.json")
p2 <- fromJSON("saved/eia_nyis_5000.json")
p1$warnings$warning
eia <- rbind(p1$response$data, p2$response$data)
eia$demand <- as.numeric(eia$value)  # text to numbers
c(rows = nrow(eia), total = as.numeric(p1$response$total),
  hours = 365 * 24)
tail(eia$period, 1)                  # the last row: the end bound
eia <- eia[substr(eia$period, 1, 4) == "2025", ]           # keep the rows of 2025
c(rows = nrow(eia), repeated = anyDuplicated(eia$period))  # repeated 0: no hour appears twice


# Drawing a year of hourly demand with plot() ----
eia$date <- as.Date(substr(eia$period, 1, 10))       # "2025-06-24T19-04" -> 2025-06-24
eia$hour <- as.numeric(substr(eia$period, 12, 13))   # -> 19
par(mar = c(4, 6, 3, 1))                             # room for the y-axis numbers
plot(eia$date + eia$hour / 24, eia$demand, type = "l", lwd = 0.5, yaxt = "n",
     xlab = "2025, New York time", ylab = "",
     main = "Hourly electricity demand, New York's grid (NYISO), 2025. Data: EIA")
at <- seq(0, 30000, 5000)
axis(2, at = at, labels = format(at, big.mark = ","), las = 1)   # commas in the numbers
title(ylab = "Demand (megawatt-hours)", line = 4.5)


# Two hours recorded as zero ----
eia[eia$demand == 0, c("period", "demand")]
eia$demand[eia$demand == 0] <- NA


# The peak hour of the June 2025 heat wave ----
eia[which.max(eia$demand), c("period", "demand")]   # the row with the largest demand


# Labelling the 266 names as economies or groups ----
# needs wb: source("model_call.R")
# builds it and sends nothing
s <- sort(wb$country, method = "radix")
writeLines(s[180:190])   # 11 of the 266


# Building the prompt from the 266 names ----
replies <- lapply(paste0("saved/wb_2023_p", 1:3, ".json"), fromJSON)
wb <- do.call(rbind, lapply(replies, flat))
# sort by name, the same way on every computer
wb <- wb[order(tolower(wb$country), method = "radix"), ]
wb$id <- 1:nrow(wb)

prompt <- paste0(
  "Below are ", nrow(wb), " names from a World Bank table. Some are single ",
  "economies (a country or a territory). Others are groups of economies ",
  "(a region, an income group, a lending group, or the world). Label each ",
  "name. Reply with CSV only: a header line id,label, then one line per ",
  "name with its number and either economy or group.\n\n",
  paste0(wb$id, ". ", wb$country, collapse = "\n"))
writeLines(prompt, "raw/model_prompt.txt")


# The first lines of the prompt sent to the model ----
p <- strsplit(prompt, "\n")[[1]]   # the prompt, split into its lines
length(p)                          # the instructions, a blank line, 266 names
# the instructions, the blank line and names 1 to 7, wrapped at 75 characters
cat(strwrap(head(p, 9), 75), sep = "\n")


# The model's id, as on the first line of model_call.R ----
MODEL <- "claude-opus-5-5"   # the model's id, from the provider's list of models


# Putting the key in a header and the prompt in the body ----
req <- request("https://api.anthropic.com/v1/messages")
req <- req_headers(req, "x-api-key" = Sys.getenv("ANTHROPIC_API_KEY"),
                   "anthropic-version" = "2023-06-01", .redact = "x-api-key")
req <- req_body_json(req, list(model = MODEL, max_tokens = 4000,
  messages = list(list(role = "user", content = prompt))))
req


# Reading the text and the stop reason in the model's reply ----
reply <- fromJSON("saved/model_reply_1.json")
reply$content$type
reply$stop_reason
txt <- reply$content$text[reply$content$type == "text"]
labels <- read.csv(text = txt)   # CSV from a string
str(labels)                      # 266 rows, one per name


# The World Bank's own list of economies and groups ----
req_cl <- request("https://api.worldbank.org/v2/country")
req_cl <- req_url_query(req_cl, format = "json", per_page = 400)   # every entry, one page
writeLines(resp_body_string(req_perform(req_cl)), "raw/wb_countries.json")


# Reading the World Bank's list ----
cl <- fromJSON("saved/wb_countries.json")[[2]]
nrow(cl)
table(cl$region$value == "Aggregates")   # TRUE: a group of economies


# The model's labels compared with the World Bank's list ----
miss <- is.na(match(wb$country, cl$name))   # TRUE: no exact match in the list
wb$country[miss]
pos <- match(trimws(wb$country), trimws(cl$name))   # each name's row in the list
wb$reference <- ifelse(cl$region$value[pos] == "Aggregates", "group", "economy")
wb$model <- labels$label[match(wb$id, labels$id)]   # each label on its name, by number
table(model = wb$model, list = wb$reference)
sum(wb$model == wb$reference)


# Tokens and what a call costs ----
c(input = reply$usage$input_tokens,                               # tokens in the prompt
  output = reply$usage$output_tokens,                             # written, reasoning included
  reasoning = reply$usage$output_tokens_details$thinking_tokens)  # of which reasoning
round(c(input = reply$usage$input_tokens,
        output = reply$usage$output_tokens) / nrow(wb), 1)   # per name


# Comparing three runs of the same request ----
runs <- lapply(paste0("saved/model_reply_", 1:3, ".json"), fromJSON)  # three runs of the labelling request
run_row <- function(r) {
  lab <- read.csv(text = r$content$text[r$content$type == "text"])
  data.frame(input = r$usage$input_tokens, output = r$usage$output_tokens,
             reasoning = r$usage$output_tokens_details$thinking_tokens,
             agree = sum(lab$label[match(wb$id, lab$id)] == wb$reference))
}
do.call(rbind, lapply(runs, run_row))   # tokens; agree: names whose label matches the list


# The same request with temperature = 0 ----
fromJSON("saved/model_temperature0.json")$error$message


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Practice ----
# Practice. Run in the 14-apis folder after source("wb_functions.R"), or
# work from the files in saved/. Tasks 6 and 7 need your own EIA key and
# the base request and eia_page() from the EIA request. Task 8 needs eia
# from the stacking step. Tasks 9 and 10: run source("model_call.R") first;
# it builds wb, prompt and req from saved/ and sends nothing.

# World Bank requests
#  1. Add an indicator argument to fetch(). Request agricultural land
#     (% of land area, AG.LND.AGRI.ZS) for 2020, every page. Compare the
#     rows with the total. How many economies have no value?
#  2. In one URL, request China's and India's access to electricity for
#     2000 to 2023 (country/CHN;IND, date=2000:2023). Plot both series.
#  3. Request 2023 at 20 rows a page. How many requests does that take,
#     and how long with Sys.sleep(1) between them?

# Errors and packages
#  4. Misspell the country code (INDD), then the indicator code
#     (EG.ELC.ACCS.ZZ). Record the status and body of each. Add a line to
#     fetch() that stops with the API's message when a reply has no total.
#  5. Get the 2023 table with WDI(..., extra = TRUE). Compare its row
#     count and India's value with yours; drop the rows whose region is
#     "Aggregates" (the groups of economies).

# The EIA (your own key)
#  6. Store your EIA key and confirm it loaded with nchar(). Request NYIS
#     demand for 24 June 2025 only (start 2025-06-24T00-04, end
#     2025-06-24T23-04). Compare the 24 rows with the same day in saved/.
#  7. Request every hour of 2025, local time, for Texas (ERCO, ERCOT, which
#     runs most of Texas's grid) or California (CISO, the California
#     Independent System Operator). Their hours carry their own offsets:
#     -06 for ERCO, -08 for CISO. Rows against the total and the calendar;
#     hours at 0; the peak hour.
#  8. Compute New York's daily peaks with
#     tapply(eia$demand, eia$date, max, na.rm = TRUE). List the ten highest
#     days. How many fall in June and July?

# Model replies
#  9. From saved/model_reply_1.json to _3.json: input and output tokens,
#     per name too, and each run's cost at prices from the provider's
#     pricing page. What would labelling 10,000 names cost?
# 10. Draw 20 names: set.seed(6850); s <- sort(sample(wb$id, 20)). Label
#     each one economy or group by hand, before you look at any answer.
#     Compare your labels with the model's (saved/model_reply_1.json) and
#     with the World Bank's list. With your own key: run
#     source("model_send.R") and compare your run's labels with the saved
#     ones.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =


# The end
