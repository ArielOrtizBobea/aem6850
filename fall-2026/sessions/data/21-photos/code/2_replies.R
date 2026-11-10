# =============================================================
# AEM 6850 - Session 21: Photographs I
# Script 2 of 3 - the model's replies, one table, against the monitor.
#
# A general vision model was asked, before class, to rate the haze in each
# of the 365 photographs from 0 to 10 (tools/score_photos.R; the question is
# in replies/haze_prompt.txt). Here the monitor's hourly file becomes a daily
# mean, one saved reply is opened, three replies become a table joined to the
# daily mean, the shipped table of all 365 days is read against the monitor,
# and the last section rebuilds that table from the raw replies.
#
# Reads:  replies/haze/*.json, data/pollution/*.csv, data_clean/pm25_daily.csv,
#         data_clean/haze_pm25.csv
# Writes: data_clean/haze.csv, data_clean/haze_pm25.csv (section 6)
#
# Open 21-photos.Rproj first.
#   source("code/2_replies.R")
# =============================================================

# 1). Preliminary ----

  want <- c("jsonlite")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only=TRUE))
  rm(want, need)

# 2). The monitor's daily mean ----

  # What tools/monitor_daily.R does to make data_clean/pm25_daily.csv.
  h <- read.csv("data/pollution/Beijing_2014_HourlyPM25_created20150203.csv",
                skip = 2, fileEncoding = "latin1")     # two note lines above the header; the unit's symbol
  c(hours = nrow(h), missing = sum(h$Value == -999))    # -999 is the file's mark for a missing hour
  h$Value[h$Value == -999] <- NA
  h$date <- as.Date(sprintf("%d-%02d-%02d", h$Year, h$Month, h$Day))   # %d a number, %02d padded to two digits
  pm <- aggregate(Value ~ date, data = h, FUN = mean)   # one mean per day over its valid hours; NA rows dropped
  names(pm)[2] <- "pm25"; pm$pm25 <- round(pm$pm25, 1)
  nrow(pm)                                              # no day lost
  pm[pm$date %in% as.Date(c("2014-01-03", "2014-01-06")), ]   # the two mornings of script 1

# 3). One saved reply, as it came back ----

  files <- list.files("replies/haze", full.names = TRUE)
  length(files)                                     # one file per morning
  r <- fromJSON("replies/haze/2014-01-06.json")
  c(r$usage$input_tokens, r$usage$output_tokens)    # tokens in and out
  r$content$text[r$content$type == "text"]          # the one text block: JSON, as we asked
  a <- fromJSON(r$content$text[r$content$type == "text"])
  a$haze; a$sky

# 4). Reading each reply into a table ----

  read_reply <- function(f) {
    r <- fromJSON(f)
    a <- fromJSON(r$content$text[r$content$type == "text"])
    data.frame(date = as.Date(sub("\\.json$", "", basename(f))),   # basename(): the name alone; sub(): drop .json
               haze = a$haze, sky = a$sky, reason = a$reason)
  }
  x <- do.call(rbind, lapply(files[1:3], read_reply))   # three files, three rows
  merge(x[, 1:3], pm, by = "date")                      # merge(): joined to pm, the daily mean, by date; reason left out
  table(x$sky)                                          # table(): how often each value occurs

# 5). The monitor's reading at each score ----

  # The shipped table: all 365 replies joined to the monitor. Section 6 rebuilds it.
  d <- read.csv("data_clean/haze_pm25.csv"); d$date <- as.Date(d$date)
  round(cor(d$haze, d$pm25), 3)
  round(tapply(d$pm25, d$haze, median))     # the monitor's median at each score
  boxplot(pm25 ~ haze, data = d, xlab = "the model's haze score, 0 to 10",
          ylab = "PM2.5 at the monitor, micrograms per cubic metre")

# 6). All 365 replies into one table ----

  # All 365 replies into one table, joined to the monitor, correlated.
  haze <- do.call(rbind, lapply(files, read_reply))      # one row per day
  nrow(haze)
  table(haze$haze)                                       # no photograph scored 0
  table(haze$sky)
  pm <- read.csv("data_clean/pm25_daily.csv"); pm$date <- as.Date(pm$date)
  d <- merge(haze, pm, by = "date")                      # one row per day, score beside the monitor
  round(cor(d$haze, d$pm25), 3)
  write.csv(haze, "data_clean/haze.csv", row.names = FALSE)
  write.csv(d, "data_clean/haze_pm25.csv", row.names = FALSE)
