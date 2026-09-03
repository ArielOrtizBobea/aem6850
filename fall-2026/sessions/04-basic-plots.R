# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# AEM 6850 -- Empirical Methods for Applied Economists
# Prof. Ariel Ortiz-Bobea
# Session 4 -- Basic plots I
# Thursday, September 3, 2026
#
# Run it one line at a time: put the cursor on a line and press Cmd-Return
# (Mac) or Ctrl-Enter (Windows).
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# Get the data ----
dir.create("data", showWarnings = FALSE)

f <- "data/epa_pm25_la_county_2025.csv"
if (!file.exists(f)) {
  download.file(paste0("https://arielortizbobea.github.io/aem6850/",
                       "fall-2026/sessions/", f), f)
}

file.exists(f)


# Build the working table ----
pm <- read.csv("data/epa_pm25_la_county_2025.csv",
               colClasses = c("Site.ID" = "character"))

names(pm)[names(pm) == "Daily.Mean.PM2.5.Concentration"] <- "pm25"
names(pm)[names(pm) == "Local.Site.Name"]                <- "site"
pm$date <- as.Date(pm$Date, format = "%m/%d/%Y")


# Cut to four stations ----
transect <- c("Pasadena", "Compton",
              "Long Beach-Route 710 Near Road", "Lancaster - Fairgrounds")

d <- pm[pm$site %in% transect &
        pm$POC == 1 & pm$AQS.Parameter.Code == 88101, ]

table(d$site)


# One series through time ----
comp_y <- d[d$site == "Compton", ]
plot(comp_y$date, comp_y$pm25, type = "l",
     xlab = "", ylab = "Daily PM2.5 (ug/m3)")

comp_y$date[which.max(comp_y$pm25)]


# The same call on the whole frame ----
plot(d$date, d$pm25, type = "l",
     xlab = "", ylab = "Daily PM2.5 (ug/m3)")


# Cut to January ----
jan  <- d[d$date < as.Date("2025-02-01"), ]
comp <- jan[jan$site == "Compton", ]
lb   <- jan[jan$site == "Long Beach-Route 710 Near Road", ]
lanc <- jan[jan$site == "Lancaster - Fairgrounds", ]
pas  <- jan[jan$site == "Pasadena", ]

xr   <- as.Date(c("2025-01-01", "2025-01-31"))   # one window for every panel


# Four stations, first attempt ----
plot(comp$date, comp$pm25, type = "l", col = "#b31b1b",
     xlab = "", ylab = "Daily PM2.5 (ug/m3)")
lines(lb$date,   lb$pm25,   col = "grey30")
lines(lanc$date, lanc$pm25, col = "#1f6fb4")
lines(pas$date,  pas$pm25,  col = "darkorange")


# The repair ----
plot(comp$date, comp$pm25, type = "l", col = "#b31b1b", lwd = 2,
     ylim = c(0, 75), xlab = "", ylab = "Daily PM2.5 (ug/m3)")
lines(lb$date,   lb$pm25,   col = "grey30")
lines(lanc$date, lanc$pm25, col = "#1f6fb4")
points(pas$date, pas$pm25,  col = "darkorange", pch = 16)
legend("topright", c("Compton", "Long Beach", "Lancaster", "Pasadena"),
       col = c("#b31b1b", "grey30", "#1f6fb4", "darkorange"),
       lty = c(1, 1, 1, NA), pch = c(NA, NA, NA, 16), bty = "n")


# The distribution of one variable ----
hist(d$pm25, breaks = 40, col = "grey85",
     main = "", xlab = "Daily mean PM2.5 (ug/m3)")
abline(v = 0, col = "#b31b1b", lty = 2)


# The same column as six numbers ----
summary(d$pm25)


# Four columns with the same mean and the same sd ----
set.seed(1)
std <- function(x, m = 20, s = 8) (x - mean(x)) / sd(x) * s + m
q   <- list("Normal"       = std(rnorm(500)),
            "Two humps"    = std(c(rnorm(250, -2), rnorm(250, 2))),
            "Right-skewed" = std(rlnorm(500, 0, 1)),
            "Flat"         = std(runif(500)))

round(sapply(q, function(x) c(mean = mean(x), sd = sd(x), max = max(x))), 2)


# The same four columns as histograms ----
op <- par(mfrow = c(2, 2), mar = c(4, 4, 2.5, 1))
invisible(lapply(names(q), function(nm) {
  hist(q[[nm]], breaks = 30, xlim = c(-10, 55), col = "grey80",
       border = "white", main = nm, xlab = "", ylab = "")
  abline(v = mean(q[[nm]]), col = "#b31b1b", lwd = 2)
}))
par(op)


# Anscombe's quartet: the summaries ----
round(colMeans(anscombe), 2)

round(c(cor(anscombe$x1, anscombe$y1), cor(anscombe$x2, anscombe$y2),
        cor(anscombe$x3, anscombe$y3), cor(anscombe$x4, anscombe$y4)), 3)


# Anscombe's quartet: the pictures ----
op <- par(mfrow = c(2, 2), mar = c(4, 4, 1, 1))
plot(anscombe$x1, anscombe$y1)
plot(anscombe$x2, anscombe$y2)
plot(anscombe$x3, anscombe$y3)
plot(anscombe$x4, anscombe$y4)
par(op)


# Many distributions at once ----
boxplot(pm25 ~ site, data = d)


# Counts of categories ----
op <- par(mar = c(4, 15, 1, 1))
barplot(table(d$site), horiz = TRUE, las = 1, col = "grey85",
        xlab = "Days with a reading in 2025")
par(op)


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Exercise 1 (3 minutes) ----
# Three minutes. The histogram had a bar left of zero.
#
# 1. Print the readings below zero.
# 2. Print which station filed them.
# 3. One sentence: keep them or delete them?
#
# Two answers to compare with the room: a count, and one station name.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




# The same arguments on a histogram ----
hist(d$pm25, col = "grey85", las = 1,
     main = "Four LA County monitors, 2025",
     xlab = "Daily mean PM2.5 (ug/m3)")


# par() is sticky ----
par("mar")                       # 5.1 4.1 4.1 2.1 -- R's default
op <- par(mar = c(3, 3, 1, 1))   # set it, and keep the old value in op
par("mar")                       # 3 3 1 1 -- still, and for every plot after
par(op)                          # put it back


# Give the labels room ----
op <- par(mar = c(4, 15, 1, 1))
boxplot(pm25 ~ site, data = d, horizontal = TRUE, las = 1,
        xlab = "Daily mean PM2.5 (ug/m3)", ylab = "", col = "grey85")
par(op)


# Four stations, four panels ----
op <- par(mfrow = c(2, 2), mar = c(3, 4, 2, 1), oma = c(0, 0, 3, 0))
invisible(lapply(transect, function(s) {
  x <- jan[jan$site == s, ]
  plot(x$date, x$pm25, type = "o", ylim = c(0, 75), xlim = xr, main = s,
       xlab = "", ylab = "PM2.5 (ug/m3)")
  abline(v = as.Date("2025-01-07"), col = "#b31b1b", lty = 2)
}))
mtext("January 2025, four LA County monitors", outer = TRUE, line = 1)
par(op)


# Writing a figure to disk ----
png("compton.png", width = 1600, height = 900, pointsize = 26)

plot(comp_y$date, comp_y$pm25, type = "l", col = "grey30",
     xlab = "", ylab = "Daily PM2.5 (ug/m3)")
abline(h = 35, col = "#b31b1b", lty = 2)

dev.off()                    # without this the file is unusable

file.exists("compton.png")


# Resolution, bitmap and vector ----
# Same figure, three ways.

png("fig-draft.png", width = 800,  height = 600)              # screen draft
plot(comp$date, comp$pm25, type = "l"); dev.off()

png("fig-print.png", width = 2400, height = 1800, res = 300)  # print quality
plot(comp$date, comp$pm25, type = "l"); dev.off()

cairo_pdf("fig-final.pdf", width = 7, height = 5)             # vector, in inches
plot(comp$date, comp$pm25, type = "l"); dev.off()


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Exercise 2 (4 minutes) ----
# Four minutes.
#
# 1. Add ONE line above the four plot() calls so they fill a 2 x 2 grid.
# 2. Run it. Which station landed in the BOTTOM-LEFT panel?
# 3. Change ONE word in your line so that Pasadena lands TOP-RIGHT.
#
# Two answers to compare with the room: a station name, and one word.

# your line goes here

plot(comp$date, comp$pm25, type="l", lwd=2, ylim=c(0,75), xlim=xr, main="Compton")
plot(lb$date,   lb$pm25,   type="l", lwd=2, ylim=c(0,75), xlim=xr, main="Long Beach")
plot(pas$date,  pas$pm25,  type="l", lwd=2, ylim=c(0,75), xlim=xr, main="Pasadena")
plot(lanc$date, lanc$pm25, type="l", lwd=2, ylim=c(0,75), xlim=xr, main="Lancaster")

# put the device back
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




# Two columns against each other ----
plot(d$pm25, d$Daily.AQI.Value,
     xlab = "Daily mean PM2.5 (ug/m3)", ylab = "Daily AQI", col = "grey40")


# The correlation that hides the kinks ----
round(cor(d$pm25, d$Daily.AQI.Value), 3)


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Practice ----
# Everything below uses d, comp_y, jan, comp, lb, lanc, pas and xr, all
# built earlier in this script. Every plot needs one written sentence that
# reads it.

# Choosing the plot
#  1. Name the function you would reach for, one word each:
#     (a) How did PM2.5 at Compton move through 2025?
#     (b) How does the spread of daily readings compare across the four?
#     (c) What does the distribution of every reading look like?
#     (d) How many days did each station report?

# One series
#  2. Draw Lancaster's whole year as a line. What is its highest reading,
#     and on what day?
#  3. Draw Compton's December only, as a line. Add a dashed horizontal
#     reference line at 35 ug/m3. How many December days cleared it?

# Distributions
#  4. Histogram of d$pm25 with default bins. How many bins did you get,
#     and where does the first one start?
#  5. Draw it again with breaks = 5, then breaks = 40. Which one changes
#     the shape you would report, and which only the resolution?
#  6. Histogram of Lancaster's readings only, with breaks = seq(-5, 30, 2.5).
#     One sentence on how its shape differs from the pooled column.

# Groups and counts
#  7. Box plots of pm25 by station, on their side, all four names legible.
#     Which station has the widest box, and is that the same as the highest?
#  8. Box plots of Compton's pm25 by month. Two months look strange --
#     count the days in each month and say why.
#  9. Bar chart of how many days each station reported, sorted from most to
#     fewest. (Hint: sort() works on a table.)

# Several series
# 10. Replicate this figure. January 2025, one panel: Compton in red, Long
#     Beach in grey, Lancaster in blue, all lwd = 2, y from 0 to 60, a
#     dashed horizontal line at 35, and a legend with no box in the top
#     right. Title: "January 2025, three stations". Then say what Lancaster
#     does that the other two do not.
# 11. Compton's whole year twice, stacked in two panels: once type = "l",
#     once type = "p". The line tells one lie the points do not. Find it.

# Panels and the canvas
# 12. Four histograms, one per station, in a 2 x 2 grid, all on the same
#     breaks and the same x range. Put the device back when you are done.
# 13. Take exercise 10's figure and give it a left margin of 6 lines, a
#     y-axis label written with mtext(), and horizontal axis numbers.

# To disk
# 14. Write exercise 12's figure to "stations.png" at 2000 x 1500 pixels
#     with pointsize = 30. Open the file. Then write the same figure to
#     "stations.pdf" with cairo_pdf() at 8 x 6 inches, and open that.
#     Zoom both to 400%. Which one still has clean edges?
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =


# The end
