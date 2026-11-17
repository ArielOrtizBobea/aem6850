# AEM 6850, session 23. Cuts the Census primary-roads file to the Interstates near New York.
# Run in the 23-spatial-vector folder, after tools/fetch_data.R:  source("tools/cut_interstates.R")
# Reads: data/census/tl_2024_us_primaryroads.zip (38 MB, not in the class zip), cb_2024_us_state_500k.zip.
# Writes: data_clean/interstates_ny_box.gpkg (569 lines, 3.2 MB), which the slides read.

# 1). Preliminary ----
  want <- c("sf")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only = TRUE))
  rm(want, need)
  misc <- list(roads = "data/census/tl_2024_us_primaryroads.zip", states = "data/census/cb_2024_us_state_500k.zip",
               out = "data_clean/interstates_ny_box.gpkg")

# 2). The Interstates that touch New York's bounding box ----
  rd <- st_read(paste0("/vsizip/", misc$roads), quiet = TRUE)        # 17,522 primary-road lines, NAD83
  it <- rd[rd$RTTYP == "I", ]; rm(rd)                               # RTTYP "I": Interstate (5,619 lines)
  st <- st_read(paste0("/vsizip/", misc$states), quiet = TRUE)
  box <- st_as_sfc(st_bbox(st[st$STUSPS == "NY", ]))
  # keep s2 on (the default): with sf_use_s2(FALSE) the planar test keeps 571 lines in place of 569
  it <- it[lengths(st_intersects(it, box)) > 0, ]
  nrow(it)

# 3). Save ----
  if (file.exists(misc$out)) unlink(misc$out)
  st_write(it, misc$out, quiet = TRUE)

# the end ----
