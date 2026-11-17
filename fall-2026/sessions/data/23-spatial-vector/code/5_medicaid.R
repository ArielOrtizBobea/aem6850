# AEM 6850, session 23 (Spatial I: vectors). Medicaid expansion at state lines (a worked example on the page)
# Script 5 of 6 - county pairs across the line, signed distance, uninsured share by year
# Reads: data/census/ county and state zips, data_clean/medicaid_expansion.csv, data_clean/sahie_uninsured.csv
# Writes: nothing
# Open 23-spatial-vector.Rproj first, so R starts in the project folder; then
#   source("code/5_medicaid.R")
# Every section matches a slide of the same name; the live script 23-spatial-vector.R runs them all in order.

# 1). Preliminary ----
# Clean up workspace and load or install necessary packages if necessary
  rm(list = ls())
  want <- c("sf")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only = TRUE))
  rm(want, need)

# 2). The layers from scripts 1 and 2 ----
  # the Census county file (unzipped once into data_clean/)
  if (!file.exists("data_clean/counties/cb_2024_us_county_500k.shp"))
    unzip("data/census/cb_2024_us_county_500k.zip", exdir = "data_clean/counties")
  co <- st_read("data_clean/counties/cb_2024_us_county_500k.shp", quiet = TRUE)
  if (!file.exists("data_clean/states/cb_2024_us_state_500k.shp"))
    unzip("data/census/cb_2024_us_state_500k.zip", exdir = "data_clean/states")
  states <- st_read("data_clean/states/cb_2024_us_state_500k.shp", quiet = TRUE)
  states_m <- st_transform(states, 5070)
  off <- c("AK", "HI", "PR", "AS", "GU", "MP", "VI")         # Alaska, Hawaii and the five territories
  low <- st_transform(co[!co$STUSPS %in% off, ], 5070)      # the lower 48 and DC, in metres

# 3). Cross-border county pairs ----
  med   <- read.csv("data_clean/medicaid_expansion.csv")   # state, month, group: I typed it from KFF's table
  exp14 <- med$state[med$group == "expanded 2014"]
  not14 <- med$state[med$group == "not expanded by 2018"]
  k <- low[low$STUSPS %in% c(exp14, not14), c("GEOID", "NAME", "STUSPS")]
  k$exp14 <- k$STUSPS %in% exp14                           # TRUE in a state that expanded in 2014
  nbk   <- st_touches(k)
  pairs <- data.frame(e = rep(seq_along(nbk), lengths(nbk)), n = unlist(nbk))   # every touching pair
  pairs <- pairs[k$exp14[pairs$e] & !k$exp14[pairs$n], ]   # keep each pair once: expansion county first
  nrow(pairs)

# 4). Signed distance to the state line ----
  states_k <- states_m[states_m$STUSPS %in% c(exp14, not14), ]
  ln <- st_intersection(st_union(states_k[states_k$STUSPS %in% exp14, ]),   # the expansion states as one shape
                        st_union(states_k[states_k$STUSPS %in% not14, ]))   # where it meets the rest: a line
  round(as.numeric(st_length(ln)) / 1e3)                                    # km
  pt_co <- st_point_on_surface(st_geometry(k))                              # one point inside each county
  k$dist_km <- ifelse(k$exp14, 1, -1) * as.numeric(st_distance(pt_co, ln)) / 1e3   # minus: did not expand

# 5). Uninsured share by county and year ----
  sahie <- read.csv("data_clean/sahie_uninsured.csv", colClasses = c(GEOID = "character"))  # GEOID, year, pctui
  pp <- data.frame(GEOID_e = k$GEOID[pairs$e], GEOID_n = k$GEOID[pairs$n])
  pp <- merge(pp, setNames(sahie, c("GEOID_e", "year", "pctui_e")), by = "GEOID_e")             # expansion side
  pp <- merge(pp, setNames(sahie, c("GEOID_n", "year", "pctui_n")), by = c("GEOID_n", "year"))  # its neighbour
  nrow(pp)                                                  # 377 pairs x 11 years
  sp <- pp$GEOID_e == "21213" & pp$GEOID_n == "47147"       # Simpson, KY, and Robertson, TN
  pp[sp & pp$year %in% 2013:2016, c("year", "pctui_e", "pctui_n")]

# 6). Uninsured share fell more where Medicaid expanded ----
  w  <- merge(sahie[sahie$year == 2013, c("GEOID", "pctui")], sahie[sahie$year == 2016, c("GEOID", "pctui")],
              by = "GEOID", suffixes = c("_2013", "_2016"))
  kd <- merge(st_drop_geometry(k), w, by = "GEOID")
  nrow(kd)                                                                  # of 2,830 counties
  kd$change <- kd$pctui_2016 - kd$pctui_2013                                # percentage points
  m  <- tapply(kd$change, cut(kd$dist_km, seq(-150, 150, 25)), mean)        # mean change in 25 km bands
  round(m, 1)
  par(mar = c(4.2, 6, 0.5, 0.5), las = 1, bty = "n")
  x <- seq(-137.5, 137.5, 25)
  plot(x, m, pch = 16, cex = 1.4, col = ifelse(x > 0, "#3A6C9C", "#9A6B00"), ylim = c(-22, 0),
       xlab = "distance from a county to the line, km (minus: did not expand)",
       ylab = "change in uninsured share,\n2013 to 2016 (points)")
  abline(v = 0, lty = 2); abline(h = 0, col = "grey80")
  text(x, m, sprintf("%.1f", m), pos = 1, cex = 0.75)

# 7). Pair gap by year ----
  gap <- tapply(pp$pctui_e - pp$pctui_n, pp$year, mean)     # expansion county minus its neighbour, mean over pairs
  round(gap - gap["2013"], 2)                                # relative to 2013
  yr <- as.numeric(names(gap)); y <- gap - gap["2013"]
  par(mar = c(3, 6, 0.5, 0.5), las = 1, bty = "n")
  plot(yr, y, type = "b", pch = 16, cex = 1.3, col = "#B31B1B", ylim = c(-11.5, 2), xaxt = "n",
       xlab = "", ylab = "pair gap minus its 2013 value\n(percentage points)")
  axis(1, at = yr); abline(h = 0, col = "grey60"); abline(v = 2013.5, lty = 2)
  text(2013.6, 1.6, "Medicaid expansion, January 2014", adj = 0, cex = 0.8)
  text(yr, y, sprintf("%.2f", y), pos = ifelse(yr < 2014, 3, 1), cex = 0.75)

# the end ----
