# =============================================================
# AEM 6850 - Session 21: Photographs I
# Tool, run before class. Turns the US Embassy's hourly PM2.5 file for Beijing,
# 2014 (data/pollution/, the Mission China monitoring program) into one daily
# mean per day. -999 marks a missing hour. Writes data_clean/pm25_daily.csv
# with date, pm25 (micrograms per cubic metre, mean of the valid hours) and
# hours (how many of the 24 were valid). Every day of 2014 has at least 13 valid
# hours, so no day is lost.
#
#   Rscript tools/monitor_daily.R    from the project folder
# =============================================================

  f <- list.files("data/pollution", pattern = "csv$", full.names = TRUE)
  h <- read.csv(f, skip = 2, fileEncoding = "latin1", check.names = FALSE)
  h$Value[h$Value == -999] <- NA
  h$date <- as.Date(sprintf("%d-%02d-%02d", h$Year, h$Month, h$Day))
  d <- aggregate(Value ~ date, data = h, FUN = mean)   # NA rows dropped: one mean per day over its valid hours
  d$hours <- as.vector(tapply(!is.na(h$Value), h$date, sum))   # valid hours per day, 13 to 24
  d$Value <- round(d$Value, 1)
  names(d)[2] <- "pm25"
  write.csv(d, "data_clean/pm25_daily.csv", row.names = FALSE)
  cat(nrow(d), "days;", sum(d$hours < 24), "with a missing hour (", min(d$hours), "to 23 valid hours )\n")
  print(summary(d$pm25))
  print(table(h$`QC Name`))
