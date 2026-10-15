# wb_functions.R: fetch() and flat() for the World Bank's access to
# electricity series (EG.ELC.ACCS.ZS, % of population).
# Run it in the 14-apis folder with source("wb_functions.R").
# Needs httr2 and jsonlite. fetch() needs internet and writes each reply into raw/.
library(httr2)
library(jsonlite)

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
