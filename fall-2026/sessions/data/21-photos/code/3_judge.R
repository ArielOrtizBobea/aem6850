# =============================================================
# AEM 6850 - Session 21: Photographs I
# Script 3 of 3 - the score judged against the monitor on held-out days,
# then a model trained on the monitor.
#
# The haze score is a number from 0 to 10; the monitor reads micrograms per
# cubic metre. A line fitted on a seeded 70 percent of the days turns the
# score into micrograms; the other 30 percent, kept out of the fitting, say
# how far off the photograph is on a day that did not shape the line. Then a
# regression on each photograph's 512 embedding numbers goes from the
# photograph to micrograms directly, fitted and judged on the same days.
#
# Reads:  data_clean/haze_pm25.csv, data_clean/tile_embeddings.csv,
#         replies/local/*.csv, data_clean/tiles/
# Writes: nothing
#
# Open 21-photos.Rproj first.
#   source("code/3_judge.R")
# =============================================================

# 1). Preliminary ----

  want <- c("jpeg")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only=TRUE))
  rm(want, need)

  if (!dir.exists("data_clean/tiles"))
    stop("The 365 photographs are in the class zip on Box (Cornell NetID), not in the zip on the\n",
         "  course page. Unzip the class zip and open its 21-photos.Rproj to run this script.")

  d <- read.csv("data_clean/haze_pm25.csv"); d$date <- as.Date(d$date)

# 2). Fitting days and held-out days ----

  set.seed(6850)
  fit <- sample(nrow(d), round(0.7 * nrow(d)))     # row numbers of the fitting days
  c(fitting = length(fit), held_out = nrow(d) - length(fit))

# 3). From a score to micrograms ----

  m <- lm(pm25 ~ haze, data = d[fit, ])           # fitted on the 255 fitting days only
  round(coef(m), 2)                                # micrograms at a score of 0, micrograms per point
  setNames(round(predict(m, newdata = data.frame(haze = 0:10))), 0:10)   # micrograms at each score
  d$pred <- predict(m, newdata = d)                # the line applied to all 365 days

# 4). The error on the held-out days ----

  held <- d[-fit, ]                                            # the 110 days kept out of the fitting
  round(c(mae = mean(abs(held$pred - held$pm25)),
          guess_the_mean = mean(abs(mean(d$pm25[fit]) - held$pm25))), 1)
  head(held[order(abs(held$pred - held$pm25)), c("date", "haze", "sky", "pm25", "pred")], 3)   # the smallest misses
  plot(held$pm25, held$pred, pch = 16, col = "grey30",
       xlab = "PM2.5 at the monitor, micrograms per cubic metre", ylab = "PM2.5 predicted from the photograph")
  abline(0, 1, lty = 2)                                        # where prediction equals measurement

# 5). Exercise 1 ----

  # The ten held-out days the photograph got most wrong, and what the camera saw.
  held$err <- held$pred - held$pm25               # positive: the photograph read too high
  worst <- held[order(-abs(held$err)), ][1:10, c("date", "haze", "sky", "pm25", "pred")]
  worst$pred <- round(worst$pred); worst        # whole micrograms
  sum(worst$pred > worst$pm25)                    # how many of the ten read too high
  par(mfrow = c(2, 5), mar = c(0, 0, 2, 0))
  for (i in 1:10) {
    plot(as.raster(readJPEG(sprintf("data_clean/tiles/%s.jpg", worst$date[i]))))   # the file name from the date
    title(sprintf("%s\nscore %d reads %.0f, monitor %.0f", worst$date[i], worst$haze[i],
                  worst$pred[i], worst$pm25[i]), cex.main = 0.8)   # %s text, %d a whole number, %.0f no decimals
  }

# 6). The monitor's mean at each score ----

  # The line treats every point of haze as worth the same. The fitting days say otherwise,
  # so the monitor's mean at each score is the prediction instead: a table in place of a line.
  mu <- tapply(d$pm25[fit], d$haze[fit], mean)        # the monitor's mean at each score, fitting days only
  round(rbind(mean_at_score = mu, line = predict(m, newdata = data.frame(haze = as.integer(names(mu))))))
  d$pred2 <- as.numeric(mu[as.character(d$haze)])     # each day's score looked up in that table
  held <- d[-fit, ]
  round(c(line = mean(abs(held$pred - held$pm25)), mean_at_score = mean(abs(held$pred2 - held$pm25))), 1)
  round(cor(d$haze, d$pm25, method = "spearman"), 2)  # the score ranks the days: its rank correlation

# 7). A model trained on the monitor's readings ----

  # So far no model has seen the monitor. Here one does: a pre-trained model turned each
  # photograph into 512 numbers (tools/embed_tiles.py), and a regression fitted on the
  # fitting days turns those numbers into micrograms.
  E <- read.csv("data_clean/tile_embeddings.csv")       # one row per day: the date, then 512 numbers
  stopifnot(all(E$date == format(d$date)))               # the same days, in the same order as d
  X  <- as.matrix(E[, -1])
  pc <- prcomp(X[fit, ])                                 # the 512 numbers summarised, on the fitting days only
  Z  <- as.data.frame(predict(pc, X)[, 1:15])            # the 15 strongest combinations, for all 365 days
  tm <- lm(d$pm25[fit] ~ ., data = Z[fit, ])             # micrograms from the 15 numbers, fitting days only
  d$trained <- predict(tm, newdata = Z)                  # our regression's micrograms, all days
  held <- d[-fit, ]
  round(c(line = mean(abs(held$pred - held$pm25)), mean_at_score = mean(abs(held$pred2 - held$pm25)),
          trained = mean(abs(held$trained - held$pm25))), 1)

  # Two more routes, from an open model on a laptop (tools/score_local.R): the same 0-to-10
  # question with its own fitted line, and a direct question, "how many micrograms?".
  loc <- read.csv("replies/local/haze_local.csv");   loc$date <- as.Date(loc$date)
  ask <- read.csv("replies/local/direct_local.csv"); ask$date <- as.Date(ask$date)
  d$haze_local <- loc$haze_local[match(d$date, loc$date)]
  ml <- lm(pm25 ~ haze_local, data = d[fit, ])
  held$local  <- predict(ml, newdata = d[-fit, ])
  held$direct <- ask$pm25_direct[match(held$date, ask$date)]
  miss <- function(p) round(mean(abs(p - held$pm25)), 1)
  routes <- c(guess_the_mean = miss(mean(d$pm25[fit])), asked_directly = miss(held$direct),
              open_model_score_and_line = miss(held$local), score_and_line = miss(held$pred),
              score_and_mean_at_score = miss(held$pred2), trained_on_the_monitor = miss(held$trained))
  routes
  length(unique(held$direct))                            # how many different answers the direct question got

  # What the trained model reads as clean and as polluted: the five lowest and the five
  # highest predictions among the held-out days.
  o <- order(held$trained); show <- held[o[c(1:5, (nrow(held) - 4):nrow(held))], ]
  par(mfrow = c(2, 5), mar = c(0, 0, 2, 0))
  for (i in 1:10) {
    plot(as.raster(readJPEG(sprintf("data_clean/tiles/%s.jpg", show$date[i]))))
    title(sprintf("%s\ntrained %.0f, monitor %.0f", show$date[i], show$trained[i], show$pm25[i]), cex.main = 0.8)
  }

# 8). Exercise 2 ----

  # The trained model with fewer and with more numbers: the error on the fitting days and
  # on the held-out days, for 5, 15, 40 and 100 combinations.
  err <- function(k) {
    Zk <- as.data.frame(predict(pc, X)[, 1:k, drop = FALSE])
    mk <- lm(d$pm25[fit] ~ ., data = Zk[fit, , drop = FALSE])
    c(k = k, fitting = mean(abs(fitted(mk) - d$pm25[fit])),
      held_out = mean(abs(predict(mk, newdata = Zk[-fit, , drop = FALSE]) - d$pm25[-fit])))
  }
  round(t(sapply(c(5, 15, 40, 100), err)), 1)
  # The ten days the asked model got most wrong, under the trained model.
  w <- held[order(-abs(held$pred - held$pm25)), ][1:10, c("date", "pm25", "pred", "trained")]
  w$pred <- round(w$pred); w$trained <- round(w$trained); w
  sum(abs(w$trained - w$pm25) < abs(w$pred - w$pm25))   # on how many of the ten the trained model is closer

# 9). Error that depends on the weather ----

  # the mean score and the monitor's mean, by the sky the model named
  aggregate(cbind(haze, pm25) ~ sky, data = d, FUN = function(x) round(mean(x), 1))
  wx <- c("2014-09-02", "2014-09-30", "2014-06-21")           # fog or mist; two humid heavy-haze mornings
  par(mfrow = c(1, 3), mar = c(0, 0, 2, 0))
  for (day in wx) {
    plot(as.raster(readJPEG(sprintf("data_clean/tiles/%s.jpg", day))))
    k <- which(d$date == day)
    title(sprintf("%s\nscore %d, monitor %.1f", day, d$haze[k], d$pm25[k]), cex.main = 0.9)
  }

# 10). Error that biases a comparison ----

  # The same comparison answered twice: by the monitor (pm25) and by the photograph
  # (pred, the fitted line's micrograms). APEC week: 3 to 12 November 2014, cars restricted
  # and factories closed for a summit. Heating season: 15 November to 15 March.
  gap  <- function(v, g) round(mean(v[g]) - mean(v[!g]))    # one group's mean minus the other's
  apec <- d$date >= as.Date("2014-11-03") & d$date <= as.Date("2014-11-12")   # the APEC week
  near <- d$date >= as.Date("2014-10-13") & d$date <= as.Date("2014-12-03")   # that week and three weeks either side
  heat <- d$date <= as.Date("2014-03-15") | d$date >= as.Date("2014-11-15")   # the heating season
  cmp  <- rbind(apec_week      = c(monitor = gap(d$pm25[near], apec[near]), photograph = gap(d$pred[near], apec[near])),
                heating_season = c(monitor = gap(d$pm25, heat),             photograph = gap(d$pred, heat)))
  cmp
