# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# AEM 6850 -- Empirical Methods for Applied Economists
# Session 4 -- Wrangling I — dplyr
# Thursday, September 3, 2026
#
# Run it one line at a time: put the cursor on a line and press Cmd-Return
# (Mac) or Ctrl-Enter (Windows).
#
# Generated from 04-wrangling-verbs.qmd -- edit the .qmd, not this file.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# The first package (install once, in the console) ----
# install.packages("dplyr")   # run once per machine, then leave commented


# Load it (top of every script, every session) ----
library(dplyr)


# Rebuild session 2's data frame ----
pm <- read.csv("data/epa_pm25_compton_2025.csv",
               colClasses = c("Site.ID"          = "character",
                              "State.FIPS.Code"  = "character",
                              "County.FIPS.Code" = "character"))
names(pm)[names(pm) == "Daily.Mean.PM2.5.Concentration"] <- "pm25"
pm$date <- as.Date(pm$Date, format = "%m/%d/%Y")

nrow(pm)   # the whole year, both instruments: 662 rows


# filter(): keep rows ----
# session 2:  pm[pm$date <= as.Date("2025-02-28") &
#                pm$POC == 1 & pm$AQS.Parameter.Code == 88101, ]

one <- filter(pm,
              date <= as.Date("2025-02-28"),
              POC == 1,
              AQS.Parameter.Code == 88101)

nrow(one)   # session 2 says this must be 59


# select(): keep columns ----
# session 2:  one[, c("date", "pm25")]

head(select(one, date, pm25), 3)


# mutate(): add columns ----
# session 2:  one$above35 <- one$pm25 > 35

one <- mutate(one,
              above35 = pm25 > 35,
              month   = format(date, "%b"))

head(select(one, date, pm25, above35, month), 3)
sum(one$above35)   # session 3's histogram says this must be 4


# arrange(): sort rows ----
# session 2:  head(one[order(-one$pm25), c("date", "pm25")], 5)

worst <- arrange(one, desc(pm25))
head(select(worst, date, pm25), 3)


# The pipe ----
nrow(filter(pm, POC == 1))         # nested: read inside out

pm |> filter(POC == 1) |> nrow()   # piped: read left to right


# The chain, end to end ----
# session 2:  head(one[order(-one$pm25), c("date", "pm25")], 5)

pm |>
  filter(date <= as.Date("2025-02-28"),
         POC == 1, AQS.Parameter.Code == 88101) |>
  arrange(desc(pm25)) |>
  select(date, pm25) |>
  head(5)


# group_by() + summarize() ----
one |>
  group_by(month) |>
  summarize(days        = n(),
            mean_pm25   = mean(pm25),
            median_pm25 = median(pm25))


# Factors put the months in order ----
month.abb   # a vector R ships with

one <- mutate(one, month = factor(month, levels = month.abb))

one |>
  group_by(month) |>
  summarize(days = n(), median_pm25 = median(pm25))


# count(): the counting shorthand ----
# session 2:  table(pm$POC, pm$AQS.Parameter.Code)

pm |> count(POC, AQS.Parameter.Code)


# The missing spring, measured ----
year <- pm |>
  filter(POC == 1, AQS.Parameter.Code == 88101) |>
  mutate(month = factor(format(date, "%b"), levels = month.abb))


# The twelve counts ----
year |> count(month)


# What the gap does to an annual mean ----
mean(year$pm25)   # "the 2025 annual mean" -- of the days that exist


# The other instrument's spring ----
other <- pm |> filter(POC == 3, AQS.Parameter.Code == 88502)

mean(other$pm25)   # its full-year mean
other |>
  mutate(month = format(date, "%b")) |>
  filter(month == "Apr" | month == "May") |>
  summarize(days = n(), mean_pm25 = mean(pm25))


# system.time(): the one-line stopwatch ----
system.time(read.csv("data/epa_pm25_compton_2025.csv"))


# Bring back the weather frame ----
la <- read.csv("data/la-weather-dec2024-feb2025.csv", skip = 3)
names(la) <- c("date", "gust", "wind", "tmax", "rh_min", "precip")
la$date <- as.Date(la$date)


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# You try (5 minutes) ----
# 1. The windstorm, top three: chain arrange(), select(), and head() to
#    print the three biggest gust days with their dates. Session 1 says
#    which date must come first.
#
# 2. Rain days by month: make month a factor with
#    levels = c("Dec", "Jan", "Feb"), then group_by(month) |>
#    summarize(days = n(), rain_days = sum(precip > 0)).
#    Session 3's drought plot says which month must have the most rain.
#
# 3. One line: la |> count(precip > 0). Write both numbers down first.
#    Your table from task 2 already fixes what they must be.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =


# The end
