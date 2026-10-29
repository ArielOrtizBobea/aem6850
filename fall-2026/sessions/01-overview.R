# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# AEM 6850 -- Empirical Methods for Applied Economists
# Prof. Ariel Ortiz-Bobea
# Session 1 -- Overview
# Tuesday, August 25, 2026
#
# Run it one line at a time: put the cursor on a line and press Cmd-Return
# (Mac) or Ctrl-Enter (Windows).
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# Check the install ----
R.version.string


# Pull the data ----
url <- paste0(
  "https://archive-api.open-meteo.com/v1/archive",
  "?latitude=34.05&longitude=-118.24",
  "&start_date=2024-12-01&end_date=2025-02-28",
  "&daily=wind_gusts_10m_max,wind_speed_10m_max,",
  "temperature_2m_max,relative_humidity_2m_min,precipitation_sum",
  "&timezone=America%2FLos_Angeles&format=csv"
)

la <- read.csv(url, skip = 3)
names(la) <- c("date", "gust", "wind", "tmax", "rh_min", "precip")
la$date <- as.Date(la$date)


# Look at what arrived ----
dim(la)
str(la)
summary(la$gust)


# One plot ----
plot(la$date, la$gust,
     type = "h", col = "grey30",
     xlab = "", ylab = "Maximum wind gust (km/h)",
     main = "Downtown Los Angeles, daily maximum gust")

abline(h = median(la$gust), lty = 2, col = "grey60")
abline(v = as.Date("2025-01-07"), col = "#b31b1b", lwd = 2)
text(as.Date("2025-01-07"), max(la$gust), "  Jan 7",
     col = "#b31b1b", adj = c(0, 1))


# Reconcile against what you wrote down ----
la$date[which.max(la$gust)]                 # 1. the windiest day
max(la$gust) / median(la$gust)              # 2. how unusual it was
sum(la$precip[format(la$date, "%Y-%m") == "2024-12"])  # 3. December rain, in mm


# The end
