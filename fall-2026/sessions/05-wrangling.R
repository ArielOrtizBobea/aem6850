# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# AEM 6850 -- Empirical Methods for Applied Economists
# Prof. Ariel Ortiz-Bobea
# Session 5 -- Wrangling with dplyr
# Tuesday, September 8, 2026
#
# Run it one line at a time: put the cursor on a line and press Cmd-Return
# (Mac) or Ctrl-Enter (Windows).
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# The first package (install once, in the console) ----
# install.packages("dplyr")   # run once per machine, then leave commented


# Load it (top of every script, every session) ----
library(dplyr)


# Rebuild the frame ----
pm <- read.csv("data/epa_pm25_compton_2025.csv",
               colClasses = c("Site.ID"          = "character",
                              "State.FIPS.Code"  = "character",
                              "County.FIPS.Code" = "character"))
names(pm)[names(pm) == "Daily.Mean.PM2.5.Concentration"] <- "pm25"
pm$date <- as.Date(pm$Date, format = "%m/%d/%Y")

nrow(pm)   # the whole year, both instruments: 662 rows


# filter(): keep rows ----
# base R:  pm[pm$date <= as.Date("2025-02-28") &
#                pm$POC == 1 & pm$AQS.Parameter.Code == 88101, ]

one <- filter(pm,
              date <= as.Date("2025-02-28"),
              POC == 1,
              AQS.Parameter.Code == 88101)

nrow(one)   # must be 59: one row per calendar day


# select(): keep columns ----
# base R:  one[, c("date", "pm25")]

head(select(one, date, pm25), 3)


# mutate(): add columns ----
# base R:  one$above35 <- one$pm25 > 35

one <- mutate(one,
              above35 = pm25 > 35,
              month   = format(date, "%b"))

head(select(one, date, pm25, above35, month), 3)
sum(one$above35)   # must be 4


# arrange(): sort rows ----
# base R:  head(one[order(-one$pm25), c("date", "pm25")], 5)

worst <- arrange(one, desc(pm25))
head(select(worst, date, pm25), 3)


# The pipe ----
nrow(filter(pm, POC == 1))         # nested: read inside out

pm |> filter(POC == 1) |> nrow()   # piped: read left to right


# The chain, end to end ----
# base R:  head(one[order(-one$pm25), c("date", "pm25")], 5)

pm |>
  filter(date <= as.Date("2025-02-28"), POC == 1, AQS.Parameter.Code == 88101) |>
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
# base R:  table(pm$POC, pm$AQS.Parameter.Code)

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


# The end
