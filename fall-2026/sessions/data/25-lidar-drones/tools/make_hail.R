# AEM 6850, session 25. Copies the tables of my hail pilot (October 2026) into data_clean/hail/ and logs their numbers.
# Run in the 25-lidar-drones folder:
#   source("tools/make_hail.R")
# What it does: reads the pilot's county-day and county-month tables and its county outlines, keeps the columns the
#   slides use, writes them to data_clean/hail/, and logs the numbers quoted on the slides with the code that made them.
# Reads: ../../../../_planning/hail_pilot/ (county_day.csv, panel_county_month.csv, counties_7states.gpkg).
#   The pilot made those files from NOAA's MRMS radar (mesh_pipeline.R), NCEI Storm Events and USDA RMA cause of
#   loss (analysis.R); copies of both scripts are in tools/hail_pilot/. Their raw downloads are not kept.
# Writes: data_clean/hail/hail_county_day.csv, data_clean/hail/hail_county_month.csv,
#   data_clean/hail/counties_7states.gpkg, logs/prep_hail.txt.

# 1). Preliminary ----
  # Clean up workspace and load or install necessary packages if necessary
  rm(list = ls())
  want <- c("sf")
  need <- want[!(want %in% installed.packages()[, "Package"])]
  if (length(need)) install.packages(need)
  invisible(lapply(want, function(i) suppressMessages(require(i, character.only = TRUE))))
  rm(want, need)

  misc <- list(pilot = "../../../../_planning/hail_pilot",
               out   = "data_clean/hail",
               log   = "logs/prep_hail.txt")
  dir.create(misc$out, recursive = TRUE, showWarnings = FALSE)
  dir.create("tools/hail_pilot", recursive = TRUE, showWarnings = FALSE)
  cat("Session 25 hail prep, run", format(Sys.time(), "%Y-%m-%d %H:%M %Z"), "\n", R.version.string, "\n", file = misc$log)
  say <- function(...) { s <- paste0(...); cat(s, "\n"); cat(s, "\n", file = misc$log, append = TRUE) }
  # log a value with the code line that made it
  lg  <- function(label, expr) {
    code <- paste(deparse(substitute(expr), width.cutoff = 500), collapse = " ")
    v <- expr; say(label, ": ", paste(format(v), collapse = " "), "    <- ", code); invisible(v)
  }

# 2). The pilot's tables, trimmed ----
  cd  <- read.csv(file.path(misc$pilot, "county_day.csv"), colClasses = c(geoid = "character"))
  pan <- read.csv(file.path(misc$pilot, "panel_county_month.csv"), colClasses = c(geoid = "character"))
  cty <- st_read(file.path(misc$pilot, "counties_7states.gpkg"), quiet = TRUE)

  # county-days: one row for each county and day with radar hail of 1 inch or more, or a hail report.
  # cday is the radar day, 12:00 UTC to 12:00 UTC the next morning; report-only rows have no "date", so use cday
  hd <- cd[cd$area_25mm > 0 | cd$n_rep > 0, c("geoid", "cday", "area_25mm", "max_mm", "n_rep", "dens_q")]
  names(hd) <- c("geoid", "date", "km2_1in", "max_mm", "reports", "density_fifth")
  write.csv(hd, file.path(misc$out, "hail_county_day.csv"), row.names = FALSE)
  # county-months: every county and month, with radar hail, reports and crop-insurance hail losses
  hm <- pan[, c("geoid", "st", "yr", "mo", "a25", "nrep", "indem")]
  names(hm) <- c("geoid", "state", "year", "month", "km2_1in", "reports", "loss_usd")
  write.csv(hm, file.path(misc$out, "hail_county_month.csv"), row.names = FALSE)
  # counties of the seven states
  cty <- cty[, c("GEOID", "NAME", "STUSPS", "ALAND")]
  st_write(cty, file.path(misc$out, "counties_7states.gpkg"), delete_dsn = TRUE, quiet = TRUE)
  file.copy(file.path(misc$pilot, c("mesh_pipeline.R", "analysis.R")), "tools/hail_pilot", overwrite = TRUE)

# 3). The numbers on the slides ----
  say("\n== Files ==")
  lg("County-days in the pilot (any radar hail or a report)", nrow(cd))
  lg("County-days kept (radar hail >= 1 inch or a report)", nrow(hd))
  lg("First and last day", range(hd$date))
  lg("Counties", nrow(cty))
  lg("States", sort(unique(cty$STUSPS)))
  lg("County-months", nrow(hm))
  lg("File sizes, MB", round(file.size(list.files(misc$out, full.names = TRUE)) / 1e6, 2))

  say("\n== 12 June 2022 ==")
  d <- hd[hd$date == "2022-06-12", ]
  lg("Counties with radar hail of 1 inch or more", sum(d$km2_1in > 0))
  lg("... of which with a hail report", sum(d$km2_1in > 0 & d$reports > 0))
  lg("Counties with a hail report", sum(d$reports > 0))
  lg("Largest radar area of hail >= 1 inch in one county, km2", max(d$km2_1in))
  lg("That county", cty$NAME[cty$GEOID == d$geoid[which.max(d$km2_1in)]])

  say("\n== Radar hail against reports, county-days ==")
  big <- hd[hd$km2_1in >= 25, ]
  lg("County-days with 25 km2 or more of radar hail >= 1 inch", nrow(big))
  lg("... percent with no report", round(100 * mean(big$reports == 0), 1))
  lg("... percent with no report, by density fifth (Q1 least dense)",
     round(100 * tapply(big$reports == 0, big$density_fifth, mean)))
  lg("County-days with a report: percent with radar hail >= 0.75 inch", round(100 * mean(hd$max_mm[hd$reports > 0] >= 19.05), 1))

  say("\n== Crop-insurance hail losses, county-months ==")
  # AUC: the chance that a county-month with a large loss gets a higher score than one without (ties count half)
  auc <- function(score, y) { r <- rank(score); n1 <- sum(y); n0 <- sum(!y); (sum(r[y]) - n1 * (n1 + 1) / 2) / (n1 * n0) }
  big_loss <- hm$loss_usd > 1e5
  lg("County-months with hail losses over $100,000", sum(big_loss))
  lg("AUC, radar area of hail >= 1 inch", round(auc(hm$km2_1in, big_loss), 3))
  lg("AUC, number of hail reports", round(auc(hm$reports, big_loss), 3))
  lg("Hail losses in all county-months, $ million", round(sum(hm$loss_usd) / 1e6, 1))
  lg("... percent in county-months with no report", round(100 * sum(hm$loss_usd[hm$reports == 0]) / sum(hm$loss_usd), 1))

# the end ----
