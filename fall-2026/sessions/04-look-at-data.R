# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# AEM 6850 -- Empirical Methods for Applied Economists
# Prof. Ariel Ortiz-Bobea
# Session 4 -- Look at your data
# Thursday, September 3, 2026
#
# Run it one line at a time: put the cursor on a line and press Cmd-Return
# (Mac) or Ctrl-Enter (Windows).
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# Rebuild the table ----
pm <- read.csv("data/epa_pm25_la_county_2025.csv",
               colClasses = c("Site.ID" = "character"))
names(pm)[names(pm) == "Daily.Mean.PM2.5.Concentration"] <- "pm25"
pm$date  <- as.Date(pm$Date, format = "%m/%d/%Y")
pm$month <- format(pm$date, "%m")

frm <- pm[pm$AQS.Parameter.Code == 88101 & pm$POC == 1, ]   # one instrument per site
tb  <- tapply(frm$pm25, list(frm$Local.Site.Name, frm$month), mean)
dim(tb)                                                     # 8 sites, 12 months


# One site, one winter ----
one <- frm[frm$Local.Site.Name == "Compton" &
           frm$date <= as.Date("2025-02-28"), ]
nrow(one)   # 59 -- one row per day


# If data/ is missing a file ----
# dir.create("data", showWarnings = FALSE)
# download.file(paste0("https://arielortizbobea.github.io/aem6850/",
#                      "fall-2026/sessions/data/epa_pm25_la_county_2025.csv"),
#               "data/epa_pm25_la_county_2025.csv")
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


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Exercise 1 (5 minutes) ----
# 1. hist(frm$pm25) -- every monitor, every day of 2025, not one winter.
#    How does the shape differ from hist(one$pm25), and would you have
#    expected that?
#
# 2. Your turn to corrupt. Copy one$pm25 and set three days to 0 instead
#    of -999. Does hist() catch it? Does summary()? Why is 0 the harder
#    one?
#
# 3. tb is a matrix, and hist(tb) works anyway. What is it drawing, and
#    how many values went into it?
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




# A column through time ----
plot(one$date, one$pm25, type = "h", col = "grey30",
     xlab = "", ylab = "Daily PM2.5 (ug/m3)")
abline(v = as.Date("2025-01-07"), col = "#b31b1b", lwd = 2)


# The same days, ranked ----
head(one[order(-one$pm25), c("date", "pm25")], 5)


# Load the weather file ----
wx <- read.csv("data/la-weather-dec2024-feb2025.csv", skip = 3)
names(wx) <- c("date", "gust", "wind", "tmax", "rh_min", "precip")
wx$date <- as.Date(wx$date)


# Two columns together ----
plot(wx$wind, wx$gust,
     xlab = "Max sustained wind (km/h)", ylab = "Max gust (km/h)")


# The unit error ----
mixed <- wx$wind
jan   <- format(wx$date, "%Y-%m") == "2025-01"
mixed[jan] <- round(wx$wind[jan] / 3.6, 1)   # January delivered in m/s

summary(wx$wind)    # the honest column
summary(mixed)      # the corrupted one


# The scatterplot catches it ----
plot(mixed, wx$gust,
     xlab = "Wind speed, as delivered", ylab = "Max gust (km/h)")


# A column by groups: boxplot() ----
one$month <- format(one$date, "%Y-%m")
boxplot(pm25 ~ month, data = one)


# Drawing a matrix margin ----
par(mar = c(4, 14, 1, 1))                      # room for the site names
barplot(sort(apply(tb, 1, mean)), horiz = TRUE, las = 1, cex.names = 0.85,
        xlab = "Mean PM2.5, 2025 (ug/m3)")
par(mar = c(5, 4, 4, 2) + 0.1)                 # put the margins back


# Counts of categories: barplot() ----
par(mar = c(4, 14, 1, 1))
barplot(sort(table(frm$Local.Site.Name)), horiz = TRUE, las = 1, cex.names = 0.85,
        xlab = "Days with a reading, 2025")
par(mar = c(5, 4, 4, 2) + 0.1)


# The missing spring: site or sampler? ----
compton <- frm[frm$Local.Site.Name == "Compton", ]
table(compton$month)              # the regulatory sampler, month by month

other <- pm[pm$Local.Site.Name == "Compton" &
            pm$POC == 3 & pm$AQS.Parameter.Code == 88502, ]
table(other$month)                # the site's OTHER instrument


# Two series on one plot ----
reg <- frm[frm$Local.Site.Name == "Compton", ]
con <- pm[pm$Local.Site.Name == "Compton" &
          pm$POC == 3 & pm$AQS.Parameter.Code == 88502, ]

plot(con$date, con$pm25, type = "l", col = "grey60",
     xlab = "", ylab = "Daily PM2.5 (ug/m3)")
points(reg$date, reg$pm25, pch = 16, cex = 0.5, col = "#b31b1b")
legend("topright", c("continuous (POC 3)", "regulatory (POC 1)"),
       col = c("grey60", "#b31b1b"), lty = c(1, NA), pch = c(NA, 16),
       bty = "n")


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
# Exercise 2 (5 minutes) ----
# 1. hist(wx$rh_min) -- each day's LOWEST relative humidity. Read it in one
#    sentence. Twelve days sit in single digits; wx$date[wx$rh_min < 10]
#    says when they were. What do those dates line up with?
#
# 2. plot(wx$date, wx$precip, type = "h") -- when did the drought break?
#    Now run summary(wx$precip). Could you have read the break off that?
#
# 3. wx$month <- format(wx$date, "%Y-%m")
#    boxplot(gust ~ month, data = wx)
#    Which month has the extremes -- and are they a shifted box, or dots
#    beyond the whisker? Those are different claims about January.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Practice ----
# Everything below uses pm, frm, tb, one and wx, built earlier in this
# script. Every plot needs one written sentence that reads it.

# One column
#  1. hist(wx$tmax). Describe the shape in one sentence.
#  2. Compton's whole year through time, not just the winter. Add the
#     35 ug/m3 line. How many days cleared it?
#  3. Which month is worst covered across ALL monitors? One line.

# Two columns
#  4. plot(wx$tmax, wx$rh_min). What relationship, and does it make
#     physical sense?
#  5. Pick two monitors. Draw one as a line, add the other with
#     points(), and label them with legend().

# Groups
#  6. boxplot(pm25 ~ Local.Site.Name, data = frm). Which monitor has the
#     widest spread, and is that the same as the dirtiest?
#  7. barplot(apply(tb, 2, mean)) -- the county month by month. Which
#     month is worst, and does it match what you saw at Compton?
#  8. table() then barplot() the AQS.Parameter.Code column. What are the
#     two numbers, and why does the file carry both?

# Panels
#  9. par(mfrow = c(2, 2)): four monitors, one histogram each. Do they
#     have the same shape? Reset mfrow when you are done.
# 10. All four Anscombe correlations are 0.82. Which dataset would that
#     number mislead you about most, and which instrument shows it?
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =


# The end
