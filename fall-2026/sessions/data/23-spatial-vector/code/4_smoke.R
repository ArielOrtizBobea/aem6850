# AEM 6850, session 23 (Spatial I: vectors). An application to wildfire smoke
# Script 4 of 6 - counties under smoke each day of June 2023, people under heavy smoke, ground monitors
# Reads: data/noaa/hms/*.zip, data/census/ county and state zips, co-est2024-alldata.csv, data_clean/pm25_june2023.csv
# Writes: smoke_june2023.gif
# Open 23-spatial-vector.Rproj first, so R starts in the project folder; then
#   source("code/4_smoke.R")
# Every section matches a slide of the same name; the live script 23-spatial-vector.R runs them all in order.

# 1). Preliminary ----
# Clean up workspace and load or install necessary packages if necessary
  rm(list = ls())
  want <- c("sf")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only = TRUE))
  rm(want, need)

# 2). The layers from scripts 1 to 3 ----
  # the Census county file (unzipped once into data_clean/)
  if (!file.exists("data_clean/counties/cb_2024_us_county_500k.shp"))
    unzip("data/census/cb_2024_us_county_500k.zip", exdir = "data_clean/counties")
  co <- st_read("data_clean/counties/cb_2024_us_county_500k.shp", quiet = TRUE)
  if (!file.exists("data_clean/states/cb_2024_us_state_500k.shp"))
    unzip("data/census/cb_2024_us_state_500k.zip", exdir = "data_clean/states")
  states <- st_read("data_clean/states/cb_2024_us_state_500k.shp", quiet = TRUE)
  states_m <- st_transform(states, 5070)
  pop <- read.csv("data/census/co-est2024-alldata.csv", fileEncoding = "latin1",
                  colClasses = c(STATE = "character", COUNTY = "character"))   # codes stay text: "01"
  pop <- pop[pop$SUMLEV == 50, ]
  pop$GEOID <- paste0(pop$STATE, pop$COUNTY)
  off <- c("AK", "HI", "PR", "AS", "GU", "MP", "VI")         # Alaska, Hawaii and the five territories
  low <- st_transform(co[!co$STUSPS %in% off, ], 5070)      # the lower 48 and DC, in metres
  wh_m <- st_transform(st_as_sf(data.frame(name = "Warren Hall", lon = -76.4797, lat = 42.4490),
                               coords = c("lon", "lat"), crs = 4326), 5070)    # Warren Hall, in metres

# 3). Counties under smoke on 7 June 2023 ----
  s <- st_read("/vsizip/data/noaa/hms/hms_smoke20230607.zip", quiet = TRUE)   # /vsizip/ reads inside the zip
  s <- st_transform(st_make_valid(s), 5070)                      # 88 plumes, in metres
  lev <- c(Light = 1, Medium = 2, Heavy = 3)                     # densities as numbers
  densest <- function(s) sapply(st_within(low, s), function(k) if (length(k)) max(lev[s$Density[k]]) else 0)
  d7 <- densest(s)
  table(d7)                                                      # 0 none, 1 light, 2 medium, 3 heavy
  low$pop <- pop$POPESTIMATE2023[match(low$GEOID, pop$GEOID)]   # people, July 2023
  sum(low$pop[d7 == 3]) / 1e6                                    # millions under heavy smoke

# 4). One day of smoke outlines ----
  table(s$Density)
  st_drop_geometry(st_join(wh_m, s[c("Density", "Start", "End")]))            # every plume over Warren Hall

# 5). Thirty days, one table ----
  hms_files <- list.files("data/noaa/hms", full.names = TRUE)        # one zip per day of June 2023
  smoke <- function(f) st_transform(st_make_valid(st_read(paste0("/vsizip/", f), quiet = TRUE)), 5070)
  day   <- as.Date(substr(basename(hms_files), 10, 17), "%Y%m%d")    # hms_smoke20230607.zip: 7 June
  dens  <- sapply(hms_files, function(f) densest(smoke(f)))           # counties x days, about 6 seconds
  colnames(dens) <- format(day); dim(dens)
  heavy <- colSums(low$pop * (dens == 3), na.rm = TRUE) / 1e6        # millions under heavy smoke, each day
  round(heavy[c("2023-06-07", "2023-06-15", "2023-06-29")])

# 6). June 2023, day by day ----
  want <- c("magick")                                             # joins the frames into a GIF
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  pal <- c("#EDEBE6", "#FDE6A8", "#F4A03C", "#9C3D0B")            # none, light, medium, heavy
  tmp <- file.path(tempdir(), "smoke"); dir.create(tmp, showWarnings = FALSE)
  for (d in seq_along(day)) {
    png(file.path(tmp, sprintf("f%02d.png", d)), width = 900, height = 560, pointsize = 15)
    layout(matrix(1:2), heights = c(3.9, 1.7))
    par(mar = c(0, 0, 1.6, 0))
    plot(st_geometry(low), col = pal[dens[, d] + 1], border = NA)
    plot(st_geometry(states_m[states_m$STUSPS %in% low$STUSPS, ]), col = NA, border = "white", lwd = 0.5, add = TRUE)
    mtext(format(day[d], "%B %e, %Y"), side = 3, line = 0.2, font = 2, cex = 1.1, adj = 0.05)
    legend("bottomleft", c("no smoke", "light", "medium", "heavy"), fill = pal, border = "white", bty = "n", cex = 0.8)
    par(mar = c(2.2, 5.2, 0.8, 1), las = 1, bty = "n")
    barplot(heavy, col = ifelse(seq_along(heavy) == d, "#B31B1B", "#D9CFC4"), border = NA, ylim = c(0, 120),
            names.arg = format(day, "%e"), cex.names = 0.7, ylab = "millions under\nheavy smoke", cex.lab = 0.85)
    dev.off()
  }
  gif <- magick::image_animate(magick::image_read(list.files(tmp, full.names = TRUE)), fps = 2)
  magick::image_write(gif, "smoke_june2023.gif")                  # two frames a second

# 7). Ground monitors under the plumes ----
  pm  <- read.csv("data_clean/pm25_june2023.csv", colClasses = c(site = "character"))   # site, date, pm25, lon, lat
  mon <- st_transform(st_as_sf(pm, coords = c("lon", "lat"), crs = 4326), 5070)
  mon$smoke <- NA
  for (k in seq_along(hms_files)) {                                # day by day: that day's monitors, that day's plumes
    s <- smoke(hms_files[k]); w <- which(mon$date == format(day[k]))
    over <- st_intersects(mon[w, ], s)                             # plumes over each monitor that day
    mon$smoke[w] <- sapply(over, function(j) if (length(j)) max(lev[s$Density[j]]) else 0)
  }
  hv <- mon[mon$smoke == 3, ]                                      # monitor-days under a heavy plume
  round(tapply(hv$pm25, hv$date, median)[c("2023-06-08", "2023-06-15", "2023-06-28")])

# the end ----
