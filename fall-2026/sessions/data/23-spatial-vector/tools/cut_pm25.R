# AEM 6850, session 23. Cuts June 2023 from the EPA's daily PM2.5 file for 2023.
# Run once, in the 23-spatial-vector folder, after tools/fetch_data.R has saved
# data/epa/daily_88101_2023.zip (10 MB; 292 MB unzipped; it stays out of the class zip).
# Reads: data/epa/daily_88101_2023.zip. Writes: data_clean/pm25_june2023.csv.
# One row per monitor site and day: the mean of the site's instruments, 24-hour standard rows only.
  x <- read.csv(unz("data/epa/daily_88101_2023.zip", "daily_88101_2023.csv"))
  x <- x[substr(x$Date.Local, 1, 7) == "2023-06" & x$Pollutant.Standard == "PM25 24-hour 2012", ]
  x <- x[!x$State.Name %in% c("Alaska", "Hawaii", "Puerto Rico", "Virgin Islands", "Country Of Mexico"), ]
  x$site <- sprintf("%02d%03d%04d", as.integer(x$State.Code), x$County.Code, x$Site.Num)   # state, county, site
  pm <- aggregate(Arithmetic.Mean ~ site + Date.Local, x, mean)                           # one value per site-day
  ll <- x[!duplicated(x$site), c("site", "Longitude", "Latitude", "State.Name", "County.Name")]
  pm <- merge(pm, ll, by = "site")
  names(pm) <- c("site", "date", "pm25", "lon", "lat", "state", "county")
  pm$pm25 <- round(pm$pm25, 1)
  stopifnot(!anyDuplicated(pm[c("site", "date")]))
  write.csv(pm[order(pm$site, pm$date), ], "data_clean/pm25_june2023.csv", row.names = FALSE)
