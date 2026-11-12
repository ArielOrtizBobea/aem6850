# AEM 6850, session 22. Tool, run before class: the 30 frames counted by hand.
# Ten cameras with a clear view of the road, each at three moments: Tuesday about 3:00 (dark,
# empty), Tuesday about 8:30 (daylight, rush hour) and Wednesday about 18:30 (dark, busy).
#   Rscript tools/pick_handcount.R        from the 22-photos-ii folder
f <- read.csv("data_clean/frames.csv", colClasses = c(cam = "character", stamp = "character"))
f$t <- as.POSIXct(f$stamp, format = "%Y%m%d_%H%M%S", tz = "America/New_York")
cams <- c("00", "05", "08", "13", "15", "16", "18", "21", "26", "28")
when <- as.POSIXct(c(night = "2026-11-10 03:00", day = "2026-11-10 08:30", evening = "2026-11-11 18:30"), tz = "America/New_York")
pick <- do.call(rbind, lapply(cams, function(cm) do.call(rbind, lapply(names(when), function(w) {
  d <- f[f$cam == cm, ]; k <- which.min(abs(difftime(d$t, when[[w]], units = "mins")))
  data.frame(cam = cm, stamp = d$stamp[k], moment = w, file = d$file[k])
}))))
pick$id <- sprintf("h%02d", seq_len(nrow(pick)))
write.csv(pick[, c("id", "cam", "stamp", "moment", "file")], "data_clean/handcount_frames.csv", row.names = FALSE)
print(table(pick$moment)); print(range(pick$stamp))
