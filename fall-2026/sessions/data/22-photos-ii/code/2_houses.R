# AEM 6850, session 22. Classifying street views of Ithaca: does the view show a house?
# Run in the 22-photos-ii folder (open 22-photos-ii.Rproj first). Base R only.
# Reads data_clean/views.csv, hand_labels.csv, typed_labels.csv and view_embeddings.csv.
# No model runs here: the pre-trained model ran before class (tools/embed_views.py).

# ---- 1. The views and the labels made by looking ---------------------------------
views <- read.csv("data_clean/views.csv")             # 1,630 views: two per panorama, left and right of the car
hand_labels <- read.csv("data_clean/hand_labels.csv") # 200 of them: house 1 or 0 by looking, NA where left undecided
nrow(views); table(views$date)
table(house = hand_labels$house, useNA = "ifany")
hand_labels <- hand_labels[!is.na(hand_labels$house), ]            # the 189 views with a label

# ---- 2. A pre-trained model given six descriptions, with no training ----------------
typed <- read.csv("data_clean/typed_labels.csv")      # every view, every description, the model's share
shows <- typed[typed$set == "shows", ]                # set "shows": the six descriptions of what a view shows
shows[shows$view == hand_labels$view[hand_labels$n == 8], c("label", "share")]   # one view: six shares that sum to 1
top <- shows[order(shows$view, -shows$share), ]                   # each view's descriptions, largest share first
top <- top[!duplicated(top$view), c("view", "label", "share")]    # keep the first: the model's answer
mean(top$label == "a house")                                      # the share of all 1,630 views it calls a house
h <- merge(hand_labels, top, by = "view")
h$pretrained <- as.integer(h$label == "a house")
table(by_looking = ifelse(h$house == 1, "house", "no house"), model = ifelse(h$pretrained == 1, "house", "no house"))
mean(h$house == h$pretrained)                                     # the share of views where model and label match
mean(h$house == 0)                                                # the share that show no house

# ---- 3. A classifier trained on the labels -------------------------------------------
emb <- read.csv("data_clean/view_embeddings.csv")     # 512 numbers per view from the pre-trained model
X <- as.matrix(emb[, -1]); rownames(X) <- emb$view
set.seed(6850)
fit <- sample(nrow(hand_labels), 120)                 # 120 labelled views to fit on, the other 69 held out
pc  <- prcomp(X[hand_labels$view[fit], ])             # the 512 numbers summarised, on the fitting views only
Z   <- as.data.frame(predict(pc, X[hand_labels$view, ])[, 1:5]); Z$house <- hand_labels$house
m   <- glm(house ~ ., data = Z[fit, ], family = binomial)          # a logistic regression on 5 summaries
p   <- predict(m, newdata = Z[-fit, ], type = "response")          # a probability for each held-out view
table(by_looking = ifelse(Z$house[-fit] == 1, "house", "no house"), trained = ifelse(p > 0.5, "house", "no house"))
held <- hand_labels$view[-fit]
round(c(trained    = mean((p > 0.5) == Z$house[-fit]),
        pretrained = mean(h$pretrained[match(held, h$view)] == hand_labels$house[-fit]),
        never      = mean(hand_labels$house[-fit] == 0)), 3)

# ---- 4. Exercise 2: fewer and more labels ----------------------------------------------
agree <- function(n, seed) {                          # train on n of the 120 fitting views, judge on the same 69
  set.seed(seed); use <- sample(fit, n)
  pc <- prcomp(X[hand_labels$view[use], ])
  Z <- as.data.frame(predict(pc, X[hand_labels$view, ])[, 1:5]); Z$house <- hand_labels$house
  m <- suppressWarnings(glm(house ~ ., data = Z[use, ], family = binomial))
  mean((predict(m, newdata = Z[-fit, ], type = "response") > 0.5) == Z$house[-fit])
}
sizes <- c(20, 40, 80, 120)
round(sapply(sizes, function(n) mean(sapply(1:20, function(s) agree(n, s)))), 3)   # mean over 20 draws of the labels

# ---- 5. Every view in the city ---------------------------------------------------
Zall <- as.data.frame(predict(pc, X[views$view, ])[, 1:5])
views$house <- predict(m, newdata = Zall, type = "response") > 0.5
mean(views$house); table(views$date, views$house)
plot(views$lon, views$lat, pch = 16, cex = 0.5, asp = 1 / cos(42.44 * pi / 180),
     col = ifelse(views$house, "#B31B1B", "grey75"), xlab = "Longitude", ylab = "Latitude", las = 1)
