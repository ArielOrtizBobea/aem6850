# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# AEM 6850 -- Empirical Methods for Applied Economists
# Session 3 -- Look at your data
# Tuesday, September 1, 2026
#
# Run it one line at a time: put the cursor on a line and press Cmd-Return
# (Mac) or Ctrl-Enter (Windows).
#
# Generated from 03-look-at-data.qmd -- edit the .qmd, not this file.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# Rebuild session 2's data frame ----
pm <- read.csv("data/epa_pm25_compton_2025.csv",
               colClasses = c("Site.ID"          = "character",
                              "State.FIPS.Code"  = "character",
                              "County.FIPS.Code" = "character"))
names(pm)[names(pm) == "Daily.Mean.PM2.5.Concentration"] <- "pm25"
pm$date <- as.Date(pm$Date, format = "%m/%d/%Y")

one <- pm[pm$date <= as.Date("2025-02-28") &
          pm$POC == 1 & pm$AQS.Parameter.Code == 88101, ]
nrow(one)   # 59 -- one row per day, as established Thursday


# If data/ is missing a file ----
# dir.create("data", showWarnings = FALSE)
# download.file(paste0("https://arielortizbobea.github.io/aem6850/",
#                      "fall-2026/sessions/data/epa_pm25_compton_2025.csv"),
#               "data/epa_pm25_compton_2025.csv")
# download.file(paste0("https://arielortizbobea.github.io/aem6850/",
#                      "fall-2026/sessions/data/la-weather-dec2024-feb2025.csv"),
#               "data/la-weather-dec2024-feb2025.csv")


# The first instrument: hist() ----
hist(one$pm25)


# Turning up the resolution ----
hist(one$pm25, breaks = 20,
     main = "", xlab = "Daily PM2.5 (ug/m3)")
abline(v = 35, col = "#b31b1b", lty = 2)   # the EPA 24-hour standard


# The sentinel ----
bad <- one$pm25
bad[c(40, 45, 50, 55)] <- -999   # four missing days, the AirNow way
mean(bad)
summary(bad)


# The histogram catches it ----
hist(bad, main = "", xlab = "Daily PM2.5 (ug/m3)")


# The repair ----
bad[bad == -999] <- NA        # sentinel to honest missing
mean(bad, na.rm = TRUE)       # back to 17.6


# A column through time ----
plot(one$date, one$pm25, type = "h", col = "grey30",
     xlab = "", ylab = "Daily PM2.5 (ug/m3)")
abline(v = as.Date("2025-01-07"), col = "#b31b1b", lwd = 2)


# Bring back session 1's weather ----
la <- read.csv("data/la-weather-dec2024-feb2025.csv", skip = 3)
names(la) <- c("date", "gust", "wind", "tmax", "rh_min", "precip")
la$date <- as.Date(la$date)


# Two columns together ----
plot(la$wind, la$gust,
     xlab = "Max sustained wind (km/h)", ylab = "Max gust (km/h)")


# The unit error ----
mixed <- la$wind
jan   <- format(la$date, "%Y-%m") == "2025-01"
mixed[jan] <- round(la$wind[jan] / 3.6, 1)   # January delivered in m/s

summary(la$wind)    # the honest column
summary(mixed)      # the corrupted one


# The scatterplot catches it ----
plot(mixed, la$gust,
     xlab = "Wind speed, as delivered", ylab = "Max gust (km/h)")


# A column by groups: boxplot() ----
one$month <- format(one$date, "%Y-%m")
boxplot(pm25 ~ month, data = one)


# Counts of categories: barplot() ----
year <- pm[pm$POC == 1 & pm$AQS.Parameter.Code == 88101, ]
barplot(table(format(year$date, "%m")),
        xlab = "Month of 2025", ylab = "Days with a reading")


# The missing spring: site or sampler? ----
table(format(year$date, "%m"))    # the numbers behind the bars

other <- pm[pm$POC == 3 & pm$AQS.Parameter.Code == 88502, ]
table(format(other$date, "%m"))   # the site's OTHER instrument


# Same summaries, different data: Anscombe 1973 ----
par(mfrow = c(2, 2), mar = c(4, 4, 1, 1))
plot(anscombe$x1, anscombe$y1)
plot(anscombe$x2, anscombe$y2)
plot(anscombe$x3, anscombe$y3)
plot(anscombe$x4, anscombe$y4)
par(mfrow = c(1, 1))


# Anscombe: check the claim ----
colMeans(anscombe)
cor(anscombe$x1, anscombe$y1)
cor(anscombe$x2, anscombe$y2)
cor(anscombe$x3, anscombe$y3)
cor(anscombe$x4, anscombe$y4)


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# You try (5 minutes) ----
# 1. hist(la$rh_min) -- each day's LOWEST relative humidity. Read it in one
#    sentence. Twelve days sit in single digits; la$date[la$rh_min < 10]
#    says when they were. What do those dates line up with?
#
# 2. plot(la$date, la$precip, type = "h") -- when did the drought break?
#    Now run summary(la$precip). Could you have read the break off that?
#
# 3. la$month <- format(la$date, "%Y-%m")
#    boxplot(gust ~ month, data = la)
#    Which month has the extremes -- and are they a shifted box, or dots
#    beyond the whisker? Those are different claims about January.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =


# The end
