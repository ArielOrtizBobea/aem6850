# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# AEM 6850 -- Empirical Methods for Applied Economists
# Prof. Ariel Ortiz-Bobea
# Basic plots II
# Thursday, September 3, 2026 · not taught in class
#
# Run it one line at a time: put the cursor on a line and press Cmd-Return
# (Mac) or Ctrl-Enter (Windows).
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# Build the table ----
pm <- read.csv("data/epa_pm25_la_county_2025.csv",
               colClasses = c("Site.ID" = "character"))
names(pm)[names(pm) == "Daily.Mean.PM2.5.Concentration"] <- "pm25"
names(pm)[names(pm) == "Local.Site.Name"]                <- "site"
pm$date <- as.Date(pm$Date, format = "%m/%d/%Y")

transect <- c("Pasadena", "Compton",
              "Long Beach-Route 710 Near Road", "Lancaster - Fairgrounds")
d      <- pm[pm$site %in% transect &
             pm$POC == 1 & pm$AQS.Parameter.Code == 88101, ]
comp_y <- d[d$site == "Compton", ]
jan    <- d[d$date < as.Date("2025-02-01"), ]
comp   <- jan[jan$site == "Compton", ]
xr     <- as.Date(c("2025-01-01", "2025-01-31"))

dim(d)


# A layout matrix ----
matrix(c(1, 1, 2, 3), nrow = 2, byrow = TRUE)


# What that matrix makes ----
layout(matrix(c(1, 1, 2, 3), nrow = 2, byrow = TRUE), heights = c(2, 1))
layout.show(3)
layout(1)


# A layout in use ----
op <- par(mar = c(3, 4, 2, 1))
layout(matrix(c(1, 1, 2, 3), nrow = 2, byrow = TRUE), heights = c(2, 1))

plot(comp$date, comp$pm25, type = "o", xlim = xr,
     xlab = "", ylab = "PM2.5 (ug/m3)", main = "Compton, January 2025")
hist(d$pm25[d$site == "Compton"], breaks = seq(-5, 60, by = 5),
     main = "Compton, all year", xlab = "")
hist(d$pm25[d$site == "Lancaster - Fairgrounds"], breaks = seq(-5, 60, by = 5),
     main = "Lancaster, all year", xlab = "")

layout(1)
par(op)


# Shaded areas: rect() ----
plot(comp_y$date, comp_y$pm25, type = "l", col = "grey30",
     xlab = "", ylab = "PM2.5 (ug/m3)")
rect(xleft = as.Date("2025-01-01"), xright = as.Date("2025-01-21"),
     ybottom = -5, ytop = 80,
     col = adjustcolor("#b31b1b", alpha.f = 0.15), border = NA)


# Confidence bands: polygon() ----
set.seed(2)
x <- runif(200, 0, 10)
y <- 20 + 3*x - 1.5*x^2 + 0.11*x^3 + 5*rnorm(200)
fit  <- lm(y ~ x + I(x^2) + I(x^3))
X    <- cbind(1, x, x^2, x^3)
se   <- sqrt(diag(X %*% vcov(fit) %*% t(X)))
i    <- order(x)

plot(x, y, pch = 21, col = "grey40", bg = "grey85", xlab = "x", ylab = "y")
polygon(c(x[i], rev(x[i])),
        c(fitted(fit)[i] + 1.96*se[i], rev(fitted(fit)[i] - 1.96*se[i])),
        col = adjustcolor("#b31b1b", alpha.f = 0.25), border = NA)
lines(x[i], fitted(fit)[i], col = "#b31b1b", lwd = 2)


# Colour scales ----
library(RColorBrewer)
cols <- colorRampPalette(brewer.pal(11, "Spectral"))(100)
v    <- runif(200, 0, 100)
plot(v, seq_along(v), pch = 16, col = cols[findInterval(v, seq(0, 100, length.out = 100))],
     xlab = "value", ylab = "")


# Custom axes ----
op <- par(mar = c(3, 4, 1, 1))
plot(comp_y$date, comp_y$pm25, type = "l", col = "grey30",
     axes = FALSE, xlab = "", ylab = "")
firsts <- as.Date(paste0("2025-", sprintf("%02d", 1:12), "-01"))
axis(1, at = firsts, labels = month.abb)
axis(1, at = firsts + 15, tck = -0.01, lwd = 0, lwd.tick = 1, labels = FALSE)
axis(2, las = 2)
box()
mtext("PM2.5 (ug/m3)", side = 2, line = 2.5)
par(op)


# Fills, shapes and options ----
op <- par(mfrow = c(2, 2), mar = c(3, 3, 2, 1))
hist(d$pm25, breaks = 30, col = "#b31b1b", density = 25, angle = 45,
     border = "#b31b1b", main = "density = / angle =", xlab = "")

m <- table(format(d$date, "%m"), d$site)[1:4, ]
barplot(m, col = grey.colors(4), main = "stacked", las = 2, cex.names = 0.5)
barplot(m, col = grey.colors(4), beside = TRUE, space = c(0, 2),
        main = "beside = TRUE", las = 2, cex.names = 0.5)

boxplot(pm25 ~ site, data = d, notch = TRUE, boxwex = 0.5,
        main = "notch = / boxwex =", xlab = "", ylab = "", names = rep("", 4))
par(op)


# Heat maps with image() ----
mm <- tapply(d$pm25, list(d$site, format(d$date, "%m")), mean)
op <- par(mar = c(3, 12, 2, 1))
image(t(mm), col = colorRampPalette(c("white", "#b31b1b"))(20), axes = FALSE)
axis(1, at = seq(0, 1, length.out = 12), labels = month.abb, tick = FALSE)
mtext(rownames(mm), side = 2, at = seq(0, 1, length.out = 4), las = 2,
      cex = 0.7, line = 0.5)
box()
par(op)


# Maps ----
library(maps)
library(mapproj)
op <- par(mfrow = c(1, 2), mar = c(0, 0, 2, 0))
map("state"); title("map(\"state\")")
map("world", proj = "orthographic", orientation = c(15, 260, 0))
map("state", proj = "orthographic", orientation = c(15, 260, 0), add = TRUE)
title("orthographic")
par(op)


# Animation ----
# A GIF is just a folder of PNGs shown in order. Write the frames, then
# stitch them. Needs the magick package, or ImageMagick on the command line.

# invisible(lapply(200:300, function(angle) {
#   png(sprintf("frame_%04d.png", angle), width = 600, height = 600)
#   par(mar = c(0, 0, 0, 0))
#   map("world", proj = "orthographic", orientation = c(15, angle, 0))
#   dev.off()
# }))

# magick::image_write(magick::image_animate(
#   magick::image_read(list.files(pattern = "^frame_.*png$")), fps = 10),
#   "globe.gif")


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Practice ----
# Everything below uses d, comp_y, jan, comp and xr, built at the top of
# this script.

# Unequal panels
#  1. layout(matrix(c(1, 2, 1, 3), nrow = 2)) -- before you run anything,
#     say which cells panel 1 covers. Then check with layout.show(3).
#  2. Fill that layout: Compton's whole year in the tall panel, and
#     histograms of Compton and Lancaster in the two small ones. Put the
#     device back afterwards -- both settings.
#  3. Make the top row of a c(1,1,2,3) layout three times as tall as the
#     bottom. Which argument, and is it in inches?

# Shaded areas
#  4. Redraw Compton's January and shade Jan 1 to Jan 21 in translucent
#     red behind the line. The shading must not hide the data.
#  5. Compton's monthly means: shade every month whose mean is above
#     12 ug/m3. How many bands do you get? Do it with ONE rect() call.
#  6. Overlay Compton's and Lancaster's full-year histograms on one plot
#     with translucent fills. (Hint: hist(..., add = TRUE), and both need
#     the same breaks.)

# Confidence bands
#  7. Fit Compton's pm25 on day-of-year and its square. Draw the fitted
#     curve over a scatter of the raw days, with a 95% band. What does the
#     curve say about the shape of the year?

# Colour scales
#  8. Colour the AQI-versus-PM2.5 scatter by month, using a 12-colour ramp
#     built from a Brewer palette. Add a legend.
#  9. Bucket the four annual means into 5 classes with findInterval() and
#     draw a bar chart coloured by bucket.

# Custom axes
# 10. Compton's year with NO default axes: month names along the bottom,
#     small unlabelled ticks at mid-month, horizontal y numbers, a box,
#     and the y label written with mtext().

# Fills, shapes, options
# 11. Days reported per month per station, once stacked and once beside.
#     Which of the two answers "did every station report every month?"
# 12. Box plots by station with notch = TRUE. Which stations' medians are
#     clearly different, and which are not?

# Heat maps and maps
# 13. Site-by-month heat map of mean PM2.5, with the sites sorted by their
#     annual mean. Which site is the outlier, and which month is worst?
# 14. Draw California and put the four monitors on it, sized by annual
#     mean. The coordinates are already in the file.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =


# The end
