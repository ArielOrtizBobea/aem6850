# AEM 6850, session 22. Counting vehicles in traffic-camera frames.
# Run in the 22-photos-ii folder (open 22-photos-ii.Rproj first). Base R only.
# Reads data_clean/boxes.csv, frames.csv and handcount.csv. No model runs here:
# the detector ran before class (tools/detect_frames.py) and its boxes are saved.

# ---- 1. The box table: one row per object the detector found ------------------
boxes  <- read.csv("data_clean/boxes.csv",  colClasses = c(cam = "character", stamp = "character"))
frames <- read.csv("data_clean/frames.csv", colClasses = c(cam = "character", stamp = "character"))
cams   <- read.csv("data/cameras/cameras.csv", colClasses = c(cam = "character"))
dim(boxes); nrow(frames); length(unique(frames$cam))
head(boxes, 4)
table(boxes$label)

# ---- 2. From boxes to a count per frame ---------------------------------------
vehicles <- c("car", "truck", "bus", "motorcycle")
count_frames <- function(cut, b = boxes) {           # vehicles per frame at a confidence cutoff
  v <- b[b$label %in% vehicles & b$conf >= cut, ]
  n <- table(paste(v$cam, v$stamp))[paste(frames$cam, frames$stamp)]   # NA where a frame has no box
  n[is.na(n)] <- 0
  as.integer(n)
}
frames$n10 <- count_frames(0.10); frames$n25 <- count_frames(0.25); frames$n50 <- count_frames(0.50)
round(colMeans(frames[, c("n10", "n25", "n50")]), 1)
frames[frames$cam == "13" & frames$stamp == "20261110_083455", ]      # one frame, three counts

# ---- 3. The hand counts: 30 frames, ten cameras at three moments ---------------
hand <- read.csv("data_clean/handcount.csv", colClasses = c(cam = "character", stamp = "character"))
table(hand$moment)                                # count: the instructor's; count_model: a general vision model's
# the detector's count on the same frame, inside the same zone (boxes entirely below the line)
in_zone <- function(cut) sapply(seq_len(nrow(hand)), function(i)
  sum(boxes$cam == hand$cam[i] & boxes$stamp == hand$stamp[i] & boxes$label %in% vehicles &
      boxes$conf >= cut & boxes$y1 >= hand$line_y[i]))   # y1: the box's top edge
hand$det <- in_zone(0.25)
hand[13:15, c("id", "cam", "moment", "line_y", "count", "det")]

# ---- 4. Exercise 1: the cutoff that comes closest to the hand counts ------------
cuts <- c(0.10, 0.15, 0.25, 0.35, 0.50)
miss <- sapply(cuts, function(k) mean(abs(in_zone(k) - hand$count)))
names(miss) <- cuts; round(miss, 2)
bias <- sapply(cuts, function(k) mean(in_zone(k) - hand$count)); names(bias) <- cuts; round(bias, 2)

# ---- 5. Where the detector misses: by moment and by how full the frame is -------
hand$miss <- hand$det - hand$count                    # negative: the detector found fewer
aggregate(cbind(by_hand = count, detector = det, miss) ~ moment, data = hand, FUN = function(x) round(mean(x), 1))
round(coef(lm(det ~ count, data = hand[hand$moment == "day", ])), 2)       # daylight: a slope near 1
round(coef(lm(det ~ count, data = hand[hand$moment == "evening", ])), 2)   # after dark: a slope near 0
# two counters on the same frames: the instructor and a general vision model
table(same_count = hand$count == hand$count_model)
mean(abs(hand$count - hand$count_model))
aggregate(cbind(by_hand = count, model = count_model, detector = det) ~ moment, data = hand, FUN = function(x) round(mean(x), 1))

# ---- 6. Counts through the day --------------------------------------------------
frames$day  <- as.Date(substr(frames$stamp, 1, 8), "%Y%m%d")
frames$hour <- as.integer(substr(frames$stamp, 10, 11))
tue <- frames[frames$day == as.Date("2026-11-10") & frames$hour <= 11, ]
by_hour <- aggregate(cbind(n10, n25, n50) ~ hour, data = tue, FUN = mean)
round(by_hour, 1)
matplot(by_hour$hour, by_hour[, -1], type = "b", pch = 16, lty = 1, col = c("grey60", "black", "grey60"),
        xlab = "Hour of Tuesday, November 10", ylab = "Vehicles per frame, mean of 33 cameras", las = 1)
text(11, unlist(by_hour[12, -1]), c("cutoff 0.10", "0.25", "0.50"), pos = 3, xpd = NA)
wed <- frames[frames$day == as.Date("2026-11-11") & frames$hour >= 11, ]
round(aggregate(n25 ~ hour, data = wed, FUN = mean), 1)                # Wednesday afternoon into the evening
