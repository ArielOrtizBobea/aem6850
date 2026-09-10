# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# AEM 6850 -- Empirical Methods for Applied Economists
# Prof. Ariel Ortiz-Bobea
# Session 6 -- How to code
# Thursday, September 10, 2026
#
# Run it one line at a time: put the cursor on a line and press Cmd-Return
# (Mac) or Ctrl-Enter (Windows).
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# Get the data ----
dir.create("data", showWarnings = FALSE)

f <- "data/epa_pm25_compton_2025.csv"
if (!file.exists(f)) {
  download.file(paste0("https://arielortizbobea.github.io/aem6850/",
                       "fall-2026/sessions/", f), f)
}

f <- "data/epa_pm25_la_county_2025.csv"
if (!file.exists(f)) {
  download.file(paste0("https://arielortizbobea.github.io/aem6850/",
                       "fall-2026/sessions/", f), f)
}

list.files("data", pattern = "^epa_.*\\.csv$")


# Build the Compton frame ----
pm <- read.csv("data/epa_pm25_compton_2025.csv",
               colClasses = c("Site.ID" = "character"))
names(pm)[names(pm) == "Daily.Mean.PM2.5.Concentration"] <- "pm25"
names(pm)[names(pm) == "Local.Site.Name"]                <- "site"
pm$date <- as.Date(pm$Date, format = "%m/%d/%Y")
pm <- pm[pm$POC == 1 & pm$AQS.Parameter.Code == 88101, ]

nrow(pm)   # one regulatory instrument, the days it ran


# Naming things and named constants ----
STANDARD <- 35   # US EPA 24-hour PM2.5 standard, ug/m3

sum(pm$pm25 > STANDARD)   # days above the standard, 2025


# function(): naming a block of code ----
days_above <- function(x, standard = STANDARD) {
  sum(x > standard)
}

dec <- pm[format(pm$date, "%m") == "12", ]
days_above(dec$pm25)                  # December, at the 35 standard
days_above(dec$pm25, standard = 50)   # the same days, a higher bar
days_above(c(1, 50))                  # a case you can check by eye


# Local names and global names ----
count_pos <- function(x) {
  n <- sum(x > 0)   # n exists inside the call
  n
}
count_pos(c(-1, 2, 3))
n                     # and not outside it


# A function can read a global name ----
standard <- 35
share_above <- function(x) sum(x > standard) / length(x)
share_above(dec$pm25)

rm(standard)
share_above(dec$pm25)   # worked until the global was gone


# Writing the five lines once ----
read_epa <- function(path) {
  d <- read.csv(path, colClasses = c("Site.ID" = "character"))
  names(d)[names(d) == "Daily.Mean.PM2.5.Concentration"] <- "pm25"
  names(d)[names(d) == "Local.Site.Name"]                <- "site"
  d$date <- as.Date(d$Date, format = "%m/%d/%Y")
  d[d$POC == 1 & d$AQS.Parameter.Code == 88101, ]
}

files  <- list.files("data", pattern = "^epa_.*\\.csv$", full.names = TRUE)
frames <- lapply(files, read_epa)
names(frames) <- basename(files)

la      <- frames[["epa_pm25_la_county_2025.csv"]]
la_jan  <- la[format(la$date, "%m") == "01", ]
by_site <- split(la_jan, la_jan$site)

sapply(by_site, nrow)


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Exercise (5 minutes) ----
# 1. Write mean_above(x, standard = 35): the mean of the readings in x
#    that are above the standard.
# 2. Run it on every site in by_site with sapply().
# 3. One number to compare with the room: Pasadena.
# 4. One site returns NaN. Say why in one sentence, and whether that is
#    wrong.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




# stopifnot(): a check that stops the script ----
jan <- pm[format(pm$date, "%m") == "01", ]
stopifnot(nrow(pm) == 301)
stopifnot(nrow(jan) == 31)


# Test small, then run big ----
days_above(c(1, 50))                              # a case you can check by eye
nrow(read_epa(files[1]))                          # one file before the folder
system.time(lapply(files, read_epa))              # the whole folder, timed


# traceback(): where it died ----
frames <- lapply(c("data/epa_pm25_compton_2025.csv", "data/nope.csv"), read_epa)
traceback()


# print() and cat(): how a value evolved ----
for (site in names(by_site)[1:3]) {
  s <- by_site[[site]]
  cat(site, ": ", nrow(s), " days, ", days_above(s$pm25), " above\n", sep = "")
}

print(c(days = nrow(jan), above = days_above(jan$pm25)))


# Documenting a diagnosis: line, mechanism, fix, proof ----
# Line:      share_above <- function(x) sum(x > standard) / length(x)
# Mechanism: standard is not an argument; the function reads it from the
#            workspace and fails in a fresh session
# Fix:       the standard comes in as an argument, with a default
share_above <- function(x, standard = 35) sum(x > standard) / length(x)
# Proof:
stopifnot(share_above(c(1, 50)) == 0.5)


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Practice ----
# Everything below uses pm, dec, jan, files, frames, la, by_site,
# read_epa() and days_above(), all built earlier in this script.

# Functions
#  1. Write peak_day(d): the date of the highest pm25 in a data frame d.
#     Run it on pm. Check the answer against the row that which.max()
#     points at.
#  2. Run peak_day() on every site in by_site. Which site peaked last in
#     January? (sapply() turns dates into numbers; wrap the call in
#     format() to keep them readable.)
#  3. From memory, without scrolling up: write share_above(x, standard = 35)
#     so that it works in a fresh session, with nothing read from the
#     workspace. Run it on dec$pm25 and on c(1, 50).

# Lists and loops
#  4. How many sites does each frame in frames hold? One sapply() call.
#  5. One plot per site, written to disk: for each site in by_site, a
#     line plot of pm25 against date saved as a PNG named after the site.
#     Do not run it until it works for one site.

# Checks
#  6. After read_epa() on the county file, write one stopifnot() with two
#     conditions: exactly 8 sites, and no date outside 2025.
#  7. This check fails on la. Say why, and whether the data or the check
#     is wrong. Then write the check that is right for this frame.
#       stopifnot(nrow(la) == length(unique(la$date)))
#  8. Time read_epa() on the county file alone, then lapply() over both
#     files. Does the second take more than the first? By roughly how much?
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =


# The end
