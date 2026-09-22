# Scrape "Recent job placements" (Ph.D. in Applied Economics & Management)
# from the Dyson "for hire" page and save it as data/placements.csv.
# Uses rvest for the HTML and base R for everything else.

library(rvest)

url <- "https://business.cornell.edu/admissions/graduate/phd-aem/for-hire/"
out <- file.path("data", "placements.csv")

page   <- read_html(url)
tables <- html_elements(page, "table")

# The page has several tables (e.g. "Currently for hire"); pick the one whose
# header is Year / Name / Position / Organization rather than relying on its
# position or TablePress id.
wanted  <- c("year", "name", "position", "organization")
headers <- lapply(tables, function(tb) tolower(html_text2(html_elements(tb, "th"))))
hit     <- which(vapply(headers, function(h) identical(h, wanted), logical(1)))
if (length(hit) != 1) {
  stop("Expected exactly one placements table with columns ",
       paste(wanted, collapse = ", "), "; found ", length(hit))
}

placements <- as.data.frame(html_table(tables[[hit]], header = TRUE),
                            stringsAsFactors = FALSE)
names(placements) <- wanted
placements$year   <- as.integer(placements$year)
for (v in wanted[-1]) placements[[v]] <- trimws(placements[[v]])

# Drop any completely empty rows (spacer rows in the table) but keep one
# row per graduate otherwise.
placements <- placements[placements$name != "", ]
rownames(placements) <- NULL

# Flag postdoc positions; spellings on the page include "Postdoc", "Post-doc",
# "Post Doctoral Fellow" and "Postdoctoral Associate".
placements$postdoc <- grepl("post[- ]?doc", placements$position, ignore.case = TRUE)

# Country of the organization. The page does not list it, so it is looked up
# in data/countries.csv (organization, country), a hand-filled file. Any
# organization missing from that file, or with an empty country, gets NA.
countries <- read.csv(file.path("data", "countries.csv"), stringsAsFactors = FALSE)
countries$country[trimws(countries$country) == ""] <- NA
placements$country <- countries$country[match(placements$organization,
                                              countries$organization)]

dir.create(dirname(out), showWarnings = FALSE, recursive = TRUE)
write.csv(placements, out, row.names = FALSE)

cat("Wrote", nrow(placements), "rows to", out, "\n")
