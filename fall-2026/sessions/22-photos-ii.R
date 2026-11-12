# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# AEM 6850 -- Empirical Methods for Applied Economists
# Prof. Ariel Ortiz-Bobea
# Session 22 -- Photographs II: counting & classifying
# Thursday, November 12, 2026
#
# Run it one line at a time: put the cursor on a line and press Cmd-Return
# (Mac) or Ctrl-Enter (Windows).
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# One row per detected object ----
boxes  <- read.csv("data_clean/boxes.csv",  colClasses = c(cam = "character", stamp = "character"))
frames <- read.csv("data_clean/frames.csv", colClasses = c(cam = "character", stamp = "character"))
head(boxes[boxes$cam == "16" & boxes$stamp == "20261110_083455", ], 3)   # three objects of the frame shown before
head(frames, 2)                                # one row per frame searched, with its file
c(objects = nrow(boxes), frames = nrow(frames), cameras = length(unique(frames$cam)))


# One camera over two days ----
one  <- boxes[boxes$cam == "16" & boxes$conf >= 0.25, ]        # one camera; boxes at confidence 0.25 or more
when <- frames$stamp[frames$cam == "16"]                       # its 122 frames
n <- table(factor(one$stamp, levels = when), one$label)        # objects per frame, by type
ny <- function(x) as.POSIXct(x, tz = "America/New_York")
d <- data.frame(hour = substr(when, 1, 11), cars = as.vector(n[, "car"]), large = as.vector(n[, "truck"] + n[, "bus"]))
h <- aggregate(cbind(cars, large, frames = 1) ~ hour, data = d, FUN = sum)   # one row per hour with frames
h <- h[h$frames >= 2, ]                                        # hours with at least two frames
h$t <- ny(strptime(h$hour, "%Y%m%d_%H", tz = "America/New_York"))
cars <- h$cars / h$frames; large <- h$large / h$frames         # the hour's mean per frame
all_hours <- seq(min(h$t), max(h$t), by = "hour")
miss <- all_hours[!all_hours %in% h$t]                         # hours with no frames
dusk <- ny(c("2026-11-09 16:44", "2026-11-10 16:43", "2026-11-11 16:42"))   # sunset
dawn <- ny(c("2026-11-10 06:37", "2026-11-11 06:38", "2026-11-12 06:39"))   # the next sunrise
par(mar = c(2.6, 4.2, 0.6, 0.6), bty = "n", mgp = c(2.6, 0.7, 0), tcl = -0.3)
plot(ny(c("2026-11-09 21:00", "2026-11-11 22:00")), c(0, 18), type = "n", xaxt = "n", xaxs = "i", yaxs = "i",
     xlab = "", ylab = "Vehicles per frame, mean of the hour", las = 1)
rect(dusk, 0, dawn, 18, col = "grey93", border = NA)                         # night: sunset to the next sunrise
rect(miss, 0, miss + 3600, 18, density = 14, col = "grey70", border = NA)   # hatched: no frames that hour
rect(h$t + 300, 0, h$t + 3300, cars, col = "grey20", border = NA)           # cars
rect(h$t + 300, cars, h$t + 3300, cars + large, col = "#B31B1B", border = NA)   # trucks and buses, stacked on top
axis.POSIXct(1, at = seq(ny("2026-11-10 00:00"), by = "6 hours", length.out = 8), format = "%a %H:%M")
text(ny("2026-11-10 01:30"), 17, "night", col = "grey45")
text(ny(c("2026-11-10 23:30", "2026-11-11 15:00")), c(9, 16.6), c("no frames saved", "no frames"), col = "grey30")
text(ny("2026-11-09 21:30"), c(15.2, 13.8), c("trucks and buses", "cars"), col = c("#B31B1B", "grey20"), pos = 4)


# Counting every frame at three cutoffs ----
vehicles <- c("car", "truck", "bus", "motorcycle")
count_frames <- function(cut) {                      # vehicles per frame at a confidence cutoff
  v <- boxes[boxes$label %in% vehicles & boxes$conf >= cut, ]
  n <- table(paste(v$cam, v$stamp))[paste(frames$cam, frames$stamp)]   # NA where a frame has no box
  n[is.na(n)] <- 0
  as.integer(n)
}
frames$n10 <- count_frames(0.10); frames$n25 <- count_frames(0.25); frames$n50 <- count_frames(0.50)
frames[frames$cam == "13" & frames$stamp == "20261110_083455", c("cam", "stamp", "n10", "n25", "n50")]
round(colMeans(frames[, c("n10", "n25", "n50")]), 1)      # the mean over all 4,037 frames


# Detector count against hand count ----
vehicles <- c("car", "truck", "bus", "motorcycle")
hand <- read.csv("data_clean/handcount.csv", colClasses = c(cam = "character", stamp = "character"))
in_zone <- function(cut) sapply(seq_len(nrow(hand)), function(i)      # one frame at a time
  sum(boxes$cam == hand$cam[i] & boxes$stamp == hand$stamp[i] & boxes$label %in% vehicles &
      boxes$conf >= cut & boxes$y1 >= hand$line_y[i]))                 # y1: the box's top edge, so the whole box is below the line
hand$det <- in_zone(0.25)
hand[13:15, c("id", "cam", "moment", "line_y", "count", "det")]             # Twelfth Avenue at 57th Street
mean(abs(hand$det - hand$count))               # the average miss, in vehicles per frame


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Exercise 1 (5 minutes) ----
# Exercise 1 (5 minutes). The cutoff that comes closest to the hand counts, by day and in the dark.
# The detector's count moves with the cutoff; the 30 frames counted by hand say which cutoff to trust, and when.
# In the 22-photos-ii folder, with boxes, vehicles, hand and in_zone() from the lines just above
# (or run code/1_count.R sections 1 to 3 first).
# 1. cuts <- c(0.10, 0.15, 0.25, 0.35, 0.50)
# 2. tapply(abs(in_zone(0.25) - hand$count), hand$moment, mean)        # the average miss at one cutoff, by moment
# 3. miss <- sapply(cuts, function(k) tapply(abs(in_zone(k) - hand$count), hand$moment, mean))
#    colnames(miss) <- cuts; round(miss, 1)                            # rows: day, evening (after dark), night (2:55 am)
# 4. One line: the cutoff you would use in daylight, and what no cutoff fixes.
# Two answers to compare with the room: the best cutoff in daylight and its average miss,
# and the smallest average miss after dark.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




# My count against a model's ----
table(same_count = hand$count == hand$count_model)                 # count: mine, by hand; count_model: a vision model
mean(abs(hand$count - hand$count_model))                           # the average difference between the two counters
aggregate(cbind(by_hand = count, model = count_model, detector = det) ~ moment, data = hand,
          FUN = function(x) round(mean(x), 1))


# Vehicles per frame by hour ----
frames$day  <- substr(frames$stamp, 1, 8); frames$hour <- as.integer(substr(frames$stamp, 10, 11))   # yyyymmdd_hhmmss
tue <- frames[frames$day == "20261110" & frames$hour <= 11, ]
by_hour <- aggregate(cbind(n10, n25, n50) ~ hour, data = tue, FUN = mean)
par(mar = c(4, 4.5, 0.5, 6))
matplot(by_hour$hour, by_hour[, -1], type = "b", pch = 16, lty = 1, col = c("grey60", "black", "grey60"),
        xlab = "Hour of Tuesday, November 10", ylab = "Vehicles per frame", las = 1)
text(11.4, unlist(by_hour[12, -1]), c("cutoff 0.10", "0.25", "0.50"), pos = 4, xpd = NA)


# Reading the model's shares in R ----
hand_labels <- read.csv("data_clean/hand_labels.csv")      # 200 views: house 1 or 0 by looking, NA where undecided
hand_labels <- hand_labels[!is.na(hand_labels$house), ]    # the 189 views with a label
typed <- read.csv("data_clean/typed_labels.csv")           # every view, every description, the model's share
shows <- typed[typed$set == "shows", ]                      # set "shows": the six descriptions of what a view shows
shows[shows$view == hand_labels$view[hand_labels$n == 8], c("label", "share")]   # one view: six shares that sum to 1
top <- shows[order(shows$view, -shows$share), ]                     # each view's descriptions, largest share first
top <- top[!duplicated(top$view), c("view", "label", "share")]      # keep the first: the model's answer
mean(top$label == "a house")                                        # the share of all 1,630 views it calls a house


# The pre-trained model matches 169 of 189 labels ----
h <- merge(hand_labels, top, by = "view")              # the 189 labelled views, each with the model's answer
h$pretrained <- as.integer(h$label == "a house")       # 1 when the model's answer is "a house"
table(by_looking = ifelse(h$house == 1, "house", "no house"),
      model      = ifelse(h$pretrained == 1, "house", "no house"))
mean(h$house == h$pretrained)                          # the share of views where model and label match
mean(h$house == 0)                                     # the share that show no house


# Training a classifier on my labels ----
emb <- read.csv("data_clean/view_embeddings.csv")      # one row per view: view, e1 to e512
X <- as.matrix(emb[, -1]); rownames(X) <- emb$view
set.seed(6850)
fit <- sample(nrow(hand_labels), 120)                  # 120 labelled views to fit on; the other 69 held out
pc  <- prcomp(X[hand_labels$view[fit], ])              # principal components, from the fitting views only
Z   <- as.data.frame(predict(pc, X[hand_labels$view, ])[, 1:5]); Z$house <- hand_labels$house
m   <- glm(house ~ ., data = Z[fit, ], family = binomial)          # logistic regression on 5 components
p   <- predict(m, newdata = Z[-fit, ], type = "response")          # a probability for each held-out view
table(by_looking = ifelse(Z$house[-fit] == 1, "house", "no house"), trained = ifelse(p > 0.5, "house", "no house"))


# Agreement on 69 held-out views ----
held <- hand_labels$view[-fit]                         # the 69 views kept out of the fitting
round(c(trained = mean((p > 0.5) == Z$house[-fit]),
        pretrained = mean(h$pretrained[match(held, h$view)] == hand_labels$house[-fit]),
        never   = mean(hand_labels$house[-fit] == 0)), 3)


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Exercise 2 (5 minutes) ----
# Exercise 2 (5 minutes). The trained classifier with fewer and with more labels.
# Every label costs a look; this shows what the next 40 labels buy.
# In the 22-photos-ii folder, with X, hand_labels and fit as on the slides before
# (or run code/2_houses.R sections 1 to 3 first).
# 1. agree <- function(n, seed) {              # train on n of the 120 fitting views, judge on the same 69
#      set.seed(seed); use <- sample(fit, n)
#      pc <- prcomp(X[hand_labels$view[use], ])
#      Z <- as.data.frame(predict(pc, X[hand_labels$view, ])[, 1:5]); Z$house <- hand_labels$house
#      m <- suppressWarnings(glm(house ~ ., data = Z[use, ], family = binomial))
#      mean((predict(m, newdata = Z[-fit, ], type = "response") > 0.5) == Z$house[-fit])
#    }
# 2. sizes <- c(20, 40, 80, 120)
#    round(sapply(sizes, function(n) mean(sapply(1:20, function(s) agree(n, s)))), 3)
# 3. One line: where the gain flattens, and how 20 labels compare with the pre-trained model's 0.826.
# Two answers to compare with the room: the agreement with 20 labels,
# and the gain from the last 40 labels.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




# Where the classifier finds houses ----
views <- read.csv("data_clean/views.csv")              # all 1,630 views, with the car's position
Zall <- as.data.frame(predict(pc, X[views$view, ])[, 1:5])
views$house <- predict(m, newdata = Zall, type = "response") > 0.5
par(mar = c(4, 4.5, 0.5, 0.5))
plot(views$lon, views$lat, pch = 16, cex = 0.6, asp = 1 / cos(42.44 * pi / 180),   # asp: a degree of longitude is shorter
     col = ifelse(views$house, "#B31B1B", "grey75"), xlab = "Longitude", ylab = "Latitude", las = 1)


# The model calls most faces worried ----
ex <- read.csv("data_clean/fed_expressions.csv")       # one row per face: a share for each of four descriptions
round(prop.table(table(ex$top)), 3)                    # the label with the largest share, all 1,181 faces
fh <- read.csv("data_clean/fed_hand_labels.csv")       # 80 of the faces, labelled by looking
f  <- merge(fh, ex[, c("file", "top")], by = "file")
table(by_looking = f$label, pretrained = f$top)
mean(f$label == f$top)                                 # the share of faces where the two agree


# The answer depends on the descriptions ----
sets <- read.csv("data_clean/fed_expressions_sets.csv")    # the same 1,181 faces, three sets of descriptions
sets[, c("set", "description", "share")]                   # share: the faces given that description


# Detector error by day and night ----
aggregate(cbind(by_hand = count, detector = det) ~ moment, data = hand, FUN = function(x) round(mean(x), 1))
round(coef(lm(det ~ count, data = hand[hand$moment == "day", ])), 2)       # daylight: a slope near 1
round(coef(lm(det ~ count, data = hand[hand$moment == "evening", ])), 2)   # after dark: a slope near 0


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Practice ----
# Practice. Run in the 22-photos-ii folder after the slides' code has built
# boxes, frames (with n25, day, hour), hand (with det), in_zone(), hand_labels, X, fit, Z, m and p.
# None needs Python or the network.

# The box table
#  1. Buses and trucks by hour on Tuesday morning: from boxes keep conf >= 0.25 and
#     label "bus" or "truck", take the hour from stamp, and table() label by hour.
#  2. The busiest camera: mean n25 by cam with aggregate(), merged with
#     data/cameras/cameras.csv for the name. Which three cameras see most vehicles?
# The hand counts
#  3. The detector's average miss at cutoff 0.25 on the frames where the two
#     counters gave the same count, and on the others.
#  4. Over the ten daylight frames, the average error with its sign at each
#     cutoff: at which cutoff do too-high and too-low counts come closest to cancelling?
# The house labels
#  5. The trained classifier with 10 components in place of 5: the agreement on
#     the fitting views and on the held-out views. Does the held-out agreement improve?
#  6. The held-out views the classifier is least sure of: the five with p closest
#     to 0.5, with their label by looking.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =


# The end
