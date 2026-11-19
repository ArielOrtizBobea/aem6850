# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# AEM 6850 -- Empirical Methods for Applied Economists
# Prof. Ariel Ortiz-Bobea
# Session 21 -- Photographs I: vision models & measurement
# Tuesday, November 10, 2026
#
# Run it one line at a time: put the cursor on a line and press Cmd-Return
# (Mac) or Ctrl-Enter (Windows).
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# A photograph as an array of numbers ----
want <- c("jpeg", "jsonlite")
need <- want[!(want %in% installed.packages()[,"Package"])]
if (length(need)) install.packages(need)
lapply(want, function(i) require(i, character.only = TRUE))


img <- readJPEG("data_clean/tiles/2014-01-06.jpg")
dim(img)                        # rows, columns, colour bands
round(img[1:3, 1:3, 1], 2)      # the top-left corner of the red band: sky
round(img[150, 80, ], 3)        # one pixel on the tower: its red, green and blue


# Two mornings as numbers ----
clear <- readJPEG("data_clean/tiles/2014-01-03.jpg")
par(mfrow = c(1, 2), mar = c(0, 0, 2, 0))      # two panels side by side, room for a title
plot(as.raster(clear)); title("2014-01-03, monitor 54.5")
plot(as.raster(img));   title("2014-01-06, monitor 154.6")
round(apply(clear[1:55, , ], 3, mean), 2)      # 3: one mean per band, over the sky rows
round(apply(img[1:55, , ], 3, mean), 2)


# The monitor's daily mean ----
h <- read.csv("data/pollution/Beijing_2014_HourlyPM25_created20150203.csv",
              skip = 2, fileEncoding = "latin1")     # two note lines above the header; the unit's symbol
c(hours = nrow(h), missing = sum(h$Value == -999))    # -999 is the file's mark for a missing hour
h$Value[h$Value == -999] <- NA
h$date <- as.Date(sprintf("%d-%02d-%02d", h$Year, h$Month, h$Day))   # %d a number, %02d padded to two digits
pm <- aggregate(Value ~ date, data = h, FUN = mean)   # one mean per day over its valid hours; NA rows dropped
names(pm)[2] <- "pm25"; pm$pm25 <- round(pm$pm25, 1)
nrow(pm)                                              # no day lost
pm[pm$date %in% as.Date(c("2014-01-03", "2014-01-06")), ]   # the two mornings shown above


# Reading each reply into a table ----
files <- list.files("replies/haze", full.names = TRUE)        # 365 files, one per morning
read_reply <- function(f) {
  r <- fromJSON(f)                                             # the saved reply, as an R list
  a <- fromJSON(r$content$text[r$content$type == "text"])      # its one text block, parsed again
  data.frame(date = as.Date(sub("\\.json$", "", basename(f))),  # the file's name is the date
             haze = a$haze, sky = a$sky, reason = a$reason)
}
x <- do.call(rbind, lapply(files[1:3], read_reply))            # three files, three rows
pm <- read.csv("data_clean/pm25_daily.csv"); pm$date <- as.Date(pm$date)   # the monitor's daily mean, one row per day
merge(x[, 1:3], pm[, 1:2], by = "date")                       # merge(): the two tables joined by date


# The monitor's reading at each score ----
d <- read.csv("data_clean/haze_pm25.csv"); d$date <- as.Date(d$date)
round(cor(d$haze, d$pm25), 3)
round(tapply(d$pm25, d$haze, median))     # the monitor's median at each score
boxplot(pm25 ~ haze, data = d, xlab = "the model's haze score, 0 to 10",
        ylab = "PM2.5 at the monitor, micrograms per cubic metre")


# Fitting days and held-out days ----
set.seed(6850)
fit <- sample(nrow(d), round(0.7 * nrow(d)))     # row numbers of the fitting days
c(fitting = length(fit), held_out = nrow(d) - length(fit))


# From a score to micrograms ----
m <- lm(pm25 ~ haze, data = d[fit, ])           # fitted on the 255 fitting days only
round(coef(m), 2)                                # micrograms at a score of 0, micrograms per point
setNames(round(predict(m, newdata = data.frame(haze = 0:10))), 0:10)   # micrograms at each score
d$pred <- predict(m, newdata = d)                # the line applied to all 365 days


# The error on the held-out days ----
held <- d[-fit, ]                                            # the 110 days kept out of the fitting
round(c(mae = mean(abs(held$pred - held$pm25)),
        guess_the_mean = mean(abs(mean(d$pm25[fit]) - held$pm25))), 1)
head(held[order(abs(held$pred - held$pm25)), c("date", "haze", "sky", "pm25", "pred")], 3)   # the smallest misses
plot(held$pm25, held$pred, pch = 16, col = "grey30",
     xlab = "PM2.5 at the monitor, micrograms per cubic metre", ylab = "PM2.5 predicted from the photograph")
abline(0, 1, lty = 2)                                        # where prediction equals measurement


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Exercise 1 (5 minutes) ----
# Exercise 1 (5 minutes). The ten held-out days the photograph got most wrong.
# An average miss hides which days went wrong; the largest misses show what the measure cannot see.
# In the 21-photos folder, with held (the 110 held-out days, with pred) as on the slides before
# (or run code/3_judge.R sections 1 to 4 first).
# 1. held$err <- held$pred - held$pm25               # positive: the photograph read too high
# 2. worst <- held[order(-abs(held$err)), ][1:10, c("date", "haze", "sky", "pm25", "pred")]
#    worst$pred <- round(worst$pred); worst                  # whole micrograms
# 3. Draw the ten tiles, each titled with its date, score, prediction and the monitor's reading:
#    par(mfrow = c(2, 5), mar = c(0, 0, 2, 0))
#    for (i in 1:10) {
#      plot(as.raster(readJPEG(sprintf("data_clean/tiles/%s.jpg", worst$date[i]))))   # the file name from the date
#      title(sprintf("%s\nscore %d reads %.0f, monitor %.0f", worst$date[i], worst$haze[i],
#                    worst$pred[i], worst$pm25[i]), cex.main = 0.8)   # %s text, %d a whole number, %.0f no decimals
#    }
# 4. One line on what nine of the ten share, and one on the day that does not fit.
# Two answers to compare with the room: on how many of the ten the photograph read too low,
# and what nine of those mornings have in common.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




# The monitor's mean at each score ----
mu <- tapply(d$pm25[fit], d$haze[fit], mean)        # the monitor's mean at each score, fitting days only
round(rbind(mean_at_score = mu, line = predict(m, newdata = data.frame(haze = as.integer(names(mu))))))
d$pred2 <- as.numeric(mu[as.character(d$haze)])     # each day's score looked up in that table
held <- d[-fit, ]                                   # the 110 held-out days, as before
round(c(line = mean(abs(held$pred - held$pm25)), mean_at_score = mean(abs(held$pred2 - held$pm25))), 1)


# A model trained on the monitor's readings ----
E  <- read.csv("data_clean/tile_embeddings.csv")       # one row per day: the date, then 512 numbers
X  <- as.matrix(E[, -1])                               # the same days, in the same order as d
pc <- prcomp(X[fit, ])                                 # the 512 numbers summarised, on the fitting days only
Z  <- as.data.frame(predict(pc, X)[, 1:15])            # the 15 strongest combinations, for all 365 days
tm <- lm(d$pm25[fit] ~ ., data = Z[fit, ])             # micrograms from the 15 numbers, fitting days only
d$trained <- predict(tm, newdata = Z)                  # our regression's micrograms, all days
held <- d[-fit, ]                                      # the 110 held-out days, as before
miss <- function(p) mean(abs(p - held$pm25))            # the average miss on the held-out days
round(c(line = miss(held$pred), mean_at_score = miss(held$pred2), trained = miss(held$trained)), 1)


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Exercise 2 (5 minutes) ----
# Exercise 2 (5 minutes). The trained model with fewer and with more numbers.
# More numbers always fit the fitting days better. Do they predict the held-out days better?
# In the 21-photos folder, with pc, X, d (with pred and trained), fit and held as on the slides before
# (or run code/3_judge.R sections 1 to 7 first).
# 1. err <- function(k) {
#      Zk <- as.data.frame(predict(pc, X)[, 1:k, drop = FALSE])
#      mk <- lm(d$pm25[fit] ~ ., data = Zk[fit, , drop = FALSE])
#      c(k = k, fitting = mean(abs(fitted(mk) - d$pm25[fit])),
#        held_out = mean(abs(predict(mk, newdata = Zk[-fit, , drop = FALSE]) - d$pm25[-fit])))
#    }
# 2. round(t(sapply(c(5, 15, 40, 100), err)), 1)      # one row per k
# 3. w <- held[order(-abs(held$pred - held$pm25)), ][1:10, c("date", "pm25", "pred", "trained")]
#    sum(abs(w$trained - w$pm25) < abs(w$pred - w$pm25))
# Two answers to compare with the room: which miss keeps falling as k grows,
# and on how many of the ten days the trained model is closer.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




# Error that depends on the weather ----
# the mean score and the monitor's mean, by the sky the model named
aggregate(cbind(haze, pm25) ~ sky, data = d,
          FUN = function(x) round(mean(x), 1))


# Error that biases a comparison ----
gap  <- function(v, g) round(mean(v[g]) - mean(v[!g]))    # one group's mean minus the other's
apec <- d$date >= as.Date("2014-11-03") & d$date <= as.Date("2014-11-12")   # the APEC week
near <- d$date >= as.Date("2014-10-13") & d$date <= as.Date("2014-12-03")   # that week and three weeks either side
heat <- d$date <= as.Date("2014-03-15") | d$date >= as.Date("2014-11-15")   # the heating season
cmp  <- rbind(apec_week      = c(monitor = gap(d$pm25[near], apec[near]), photograph = gap(d$pred[near], apec[near])),
              heating_season = c(monitor = gap(d$pm25, heat),             photograph = gap(d$pred, heat)))
cmp


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Practice ----
# Practice. Run in the 21-photos folder after the slides' code has built
# files, read_reply(), h, d (with pred), fit, m and held.
# None needs a key, Python or the network.

# The replies table
#  1. The mean score by the sky the model named, beside the monitor's mean.
#     Which day did the model call "fog or mist", and what did the monitor read?
#     Which three sky levels did it never choose?
#  2. By month: d$month <- format(d$date, "%m"), then aggregate() the score and
#     the monitor. Which month scores highest, which lowest? Do December's low
#     scores mean clean air?
#  3. The words in the reasons, with grepl(): how often "sharp", "washed",
#     "grey" or "gray", and "blue" appear in the reasons at scores of 2 or less,
#     and at 8 or more.
# The reference and the split
#  4. The monitor at the photograph's hour: from h keep Hour %in% 6:8, one mean
#     per day with aggregate(), merge() by date, cor() with the score. Compare
#     with 0.68 for the daily mean. Then Hour %in% 5:10.
#  5. Days with a missing hour: keep hours == 24 (333 days) and redo the split,
#     the line and the held-out error. How much moves?
#  6. Another seed: set.seed(1), then 2 and 3. How much do the line and the
#     held-out error move?
# The street photograph
#  7. b <- read.csv("data_clean/street/boxes.csv"); table(b$label[b$conf >= 0.25]),
#     then 0.75. Then s <- readJPEG("data/street/porlamar.jpg"); dim(s); and cut
#     the truck's box (x1 1304, y1 807, x2 1895, y2 1253) out of the array with
#     plot(as.raster(s[807:1253, 1304:1895, ])). Rows are y, columns are x.
# A photograph of your own
#  8. A JPEG from a phone (convert HEIC first): readJPEG(), dim(), one pixel, the
#     mean red, green and blue of its top rows. A phone photograph is thousands
#     of pixels on a side, so dim() is the first thing to look at.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =


# The end
