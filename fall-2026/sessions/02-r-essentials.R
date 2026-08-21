# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# AEM 6850 -- Unconventional Data for Economists
# Session 2 -- R essentials
# Thursday, August 27, 2026
#
# Run it one line at a time: put the cursor on a line and press Cmd-Return
# (Mac) or Ctrl-Enter (Windows).
#
# Generated from 02-r-essentials.qmd -- edit the .qmd, not this file.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# Objects and assignment ----
x <- c(1, 2, 3, 4, 5)
x
class(x)
length(x)

ls()          # what is in your workspace right now


# Building vectors ----
1:10
seq(0, 100, by = 25)
seq(0, 1, length.out = 5)
rep(c("a", "b"), times = 3)
rep(c("a", "b"), each = 3)


# Vector arithmetic ----
x * 2
x + c(10, 20, 30, 40, 50)
x + c(0, 100)      # lengths do not match -- R recycles, and warns


# Types ----
class(1)
class("a")
class(TRUE)
class(as.Date("2025-01-07"))


# Silent type conversion ----
c(1, 2, 3)
c(1, 2, "three")          # one text value converts the whole vector
class(c(1, 2, "three"))

sum(c(TRUE, FALSE, TRUE))  # TRUE becomes 1, FALSE becomes 0
mean(c(TRUE, FALSE, TRUE)) # ... so the mean of a logical is a proportion

sort(c(10, 9, 100))
sort(c("10", "9", "100"))  # text sorts character by character


# What silent conversion costs you ----
readings <- c(12.4, 18.1, 9.7, "n/a", 22.3)
class(readings)
mean(readings)


# The repair ----
readings <- as.numeric(readings)   # "n/a" cannot convert -- it becomes NA
readings
mean(readings, na.rm = TRUE)


# Missing values ----
temps <- c(21.0, NA, 19.4, 23.8)
mean(temps)
mean(temps, na.rm = TRUE)

is.na(temps)
sum(is.na(temps))
temps == NA        # not how you test for NA -- use is.na()


# Indexing ----
x <- c(10, 20, 30, 40, 50)
x[1]
x[c(1, 3)]
x[-1]              # everything except the first
x[length(x)]       # the last, however long it is


# Logical subsetting ----
x > 25             # a TRUE/FALSE for every element
x[x > 25]          # keep the elements where it is TRUE
sum(x > 25)        # count them -- TRUE is 1
x[x > 25 & x < 45] # & is and, | is or


# Data frames ----
d <- data.frame(
  site = c("Compton", "Compton", "Reseda"),
  date = c("2025-01-01", "2025-01-02", "2025-01-01"),
  pm25 = c(53.2, 33.6, 47.0)
)
d
str(d)


# Getting at rows and columns ----
d$pm25            # one column, by name
d[1, ]            # first row, all columns
d[, "pm25"]       # all rows, one column
d[d$pm25 > 40, ]  # the rows where a condition is TRUE


# Where am I ----
getwd()
list.files()


# Read the file ----
pm <- read.csv("data/epa_pm25_compton_2025.csv")


# If you do not have the file yet ----
# Uncomment and run once. Same file, fetched instead of clicked.
# dir.create("data", showWarnings = FALSE)
# download.file(paste0("https://arielortizbobea.github.io/aem6850/",
#                      "fall-2026/sessions/data/epa_pm25_compton_2025.csv"),
#               "data/epa_pm25_compton_2025.csv")


# Arrival checks ----
dim(pm)
names(pm)


# Rename, then str() ----
names(pm)[names(pm) == "Daily.Mean.PM2.5.Concentration"] <- "pm25"

str(pm[, 1:6])
summary(pm$pm25)


# The identifier trap ----
pm$Site.ID[1]
class(pm$Site.ID)
pm$State.FIPS.Code[1]
pm$County.FIPS.Code[1]


# Protect identifiers at read time ----
pm <- read.csv("data/epa_pm25_compton_2025.csv",
               colClasses = c("Site.ID"          = "character",
                              "State.FIPS.Code"  = "character",
                              "County.FIPS.Code" = "character"))
names(pm)[names(pm) == "Daily.Mean.PM2.5.Concentration"] <- "pm25"

pm$Site.ID[1]
pm$County.FIPS.Code[1]
class(pm$pm25)     # the concentration is still a number, as it should be


# One site, two instruments ----
table(pm$POC, pm$AQS.Parameter.Code)


# Dates, one line deep ----
pm$Date[1]
class(pm$Date)

pm$date <- as.Date(pm$Date, format = "%m/%d/%Y")
class(pm$date)
range(pm$date)


# Subset to the window ----
win <- pm[pm$date <= as.Date("2025-02-28"), ]
nrow(win)                      # rows...
length(unique(win$date))       # ...for how many calendar days?

one <- win[win$POC == 1 & win$AQS.Parameter.Code == 88101, ]
nrow(one)
nrow(one) == length(unique(one$date))   # one row per day now?


# Predict, then reconcile ----
one$date[which.max(one$pm25)]
max(one$pm25)
median(one$pm25)

head(one[order(-one$pm25), c("date", "pm25")], 5)


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# You try (5 minutes) ----
# 1. How many days in the window were above 35 ug/m3 -- the EPA 24-hour
#    standard? (One line. TRUE is 1.)
#
# 2. Compare January's mean with February's. format(one$date, "%Y-%m") gives
#    you "2025-01" and "2025-02" to subset on.
#
# 3. The site's OTHER instrument is POC 3, parameter 88502. Pull its rows for
#    the window and compare its January mean with POC 1's. Two instruments,
#    one site, same air -- how close do they agree?
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =


# The end
