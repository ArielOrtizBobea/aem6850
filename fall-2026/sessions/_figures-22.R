# Figures for the session 22 page and slides (photographs: counting and classifying).
# Base R and jpeg. Run from fall-2026/sessions:
#   Rscript _figures-22.R              # every block
#   Rscript _figures-22.R cutoffs      # setup, then one block
# Writes figures/22-photos-ii/*. Inputs: data/22-photos-ii/ (the session project,
# with the camera frames, the Ithaca views and the Fed frames in place).
#
# Each canvas is set in inches (1 user unit = 1 inch, origin bottom left) and drawn
# at res 200, sized so that 1 inch is about 100 px on the 1050 x 700 slide.

# ---- Run named blocks only: Rscript _figures-22.R <block> [<block> ...] ----
local({
  want <- commandArgs(trailingOnly = TRUE)
  self <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE))
  if (!length(want) || !length(self)) return(invisible())
  src <- readLines(self)
  s <- grep("^# ==== BLOCK: ", src); e <- grep("^# ==== END BLOCK ====", src)
  nm <- sub("^# ==== BLOCK: ([^ ]+).*", "\\1", src[s])
  dp <- lapply(src[s], function(l) if (grepl("DEPS:", l))
    strsplit(sub(".*DEPS: *([^ ]+).*", "\\1", l), ",")[[1]] else character())
  done <- character()
  run <- function(b) {
    if (b %in% done) return()
    k <- match(b, nm); if (is.na(k)) stop("no block named ", b)
    for (d in dp[[k]]) run(d)
    eval(parse(text = src[(s[k] + 1):(e[e > s[k]][1] - 1)]), envir = globalenv())
    done <<- c(done, b)
  }
  for (b in want) run(b)
  quit(save = "no")
})

# ==== BLOCK: setup ====
suppressPackageStartupMessages(library(jpeg))
out <- "figures/22-photos-ii"; dat <- "data/22-photos-ii"
dir.create(out, showWarnings = FALSE, recursive = TRUE)
ink <- "#222222"; acc <- "#B31B1B"; grey <- "#666666"; rule <- "#BBBBBB"; blue <- "#3A6C9C"
# photo-heavy figures are written as JPEG (a tenth of the size of a PNG), diagrams as PNG
dev_open <- function(name, w, h) {
  if (grepl("\\.jpg$", name)) jpeg(file.path(out, name), width = w, height = h, units = "in", res = 200, quality = 88)
  else png(file.path(out, name), width = w, height = h, units = "in", res = 200)
}
canvas <- function(name, w, h) {
  dev_open(name, w, h)
  par(mar = c(0, 0, 0, 0), family = "sans")
  plot.new(); plot.window(xlim = c(0, w), ylim = c(0, h), xaxs = "i", yaxs = "i")
}
boxes <- read.csv(file.path(dat, "data_clean/boxes.csv"), colClasses = c(cam = "character", stamp = "character"))
hand  <- read.csv(file.path(dat, "data_clean/handcount.csv"), colClasses = c(cam = "character", stamp = "character"))
cams  <- read.csv(file.path(dat, "data/cameras/cameras.csv"), colClasses = c(cam = "character"))
veh   <- c("car", "truck", "bus", "motorcycle")
col_of <- c(car = "#FFD400", truck = "#FF7A00", bus = "#00C8FF", motorcycle = "#FF4FD8", person = "#7CFC00", bicycle = "#7CFC00")
frame_file <- function(cam, stamp) file.path(dat, "data/cameras/frames", cam, paste0(stamp, ".jpg"))
# One camera frame (352 x 240) drawn w inches wide with its lower-left corner at (x, y).
# cut: draw the detector's boxes at this confidence or more. line: the hand-count line.
frame_panel <- function(x, y, w, cam, stamp, cut = NULL, line = NULL, title = NULL, zone_only = FALSE, labels = veh) {
  h <- w * 240 / 352; s <- w / 352
  rasterImage(readJPEG(frame_file(cam, stamp)), x, y, x + w, y + h)
  if (!is.null(cut)) {
    b <- boxes[boxes$cam == cam & boxes$stamp == stamp & boxes$conf >= cut & boxes$label %in% labels, ]
    if (zone_only && !is.null(line)) b <- b[b$y1 >= line, ]   # the whole box below the line
    if (nrow(b)) rect(x + b$x1 * s, y + h - b$y2 * s, x + b$x2 * s, y + h - b$y1 * s, border = col_of[b$label], lwd = 1.6)
  }
  if (!is.null(line)) segments(x, y + h - line * s, x + w, y + h - line * s, col = "white", lwd = 2, lty = 2)
  if (!is.null(title)) text(x, y + h + 0.16, title, adj = 0, cex = 1.0, col = ink)
  invisible(h)
}
n_at <- function(cam, stamp, cut, line = 0) sum(boxes$cam == cam & boxes$stamp == stamp & boxes$conf >= cut &
                                                 boxes$label %in% veh & boxes$y1 >= line)
view_file <- function(v) file.path(dat, "data_clean/views", paste0(v, ".jpg"))
img_panel <- function(x, y, w, file, title = NULL, cex = 0.95, col = ink) {
  im <- readJPEG(file); h <- w * dim(im)[1] / dim(im)[2]
  rasterImage(im, x, y, x + w, y + h)
  if (!is.null(title)) text(x, y + h + 0.15, title, adj = 0, cex = cex, col = col)
  invisible(h)
}
# ==== END BLOCK ====

# ==== BLOCK: detector_one DEPS: setup ====
# One daytime frame with the detector's boxes at 0.25 or more, colour by class.
canvas("detector_one.jpg", 10.5, 5.0)
frame_panel(0.1, 0.1, 6.9, "16", "20261110_083455", cut = 0.25, labels = names(col_of))
b <- boxes[boxes$cam == "16" & boxes$stamp == "20261110_083455" & boxes$conf >= 0.25, ]
tb <- table(b$label)
text(7.25, 4.55, "Boxes at confidence", adj = 0, cex = 1.05, font = 2, col = ink)
text(7.25, 4.25, "0.25 or more", adj = 0, cex = 1.05, font = 2, col = ink)
for (i in seq_along(tb)) {
  rect(7.25, 3.75 - 0.42 * (i - 1) - 0.11, 7.5, 3.75 - 0.42 * (i - 1) + 0.11, border = col_of[names(tb)[i]], lwd = 3)
  text(7.65, 3.75 - 0.42 * (i - 1), sprintf("%s: %d", names(tb)[i], tb[i]), adj = 0, cex = 1.05, col = ink)
}
text(7.25, 2.5, "West Street at the Intrepid,", adj = 0, cex = 0.9, col = grey)
text(7.25, 2.25, "New York City DOT camera,", adj = 0, cex = 0.9, col = grey)
text(7.25, 2.0, "frame of 352 by 240 pixels", adj = 0, cex = 0.9, col = grey)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: three_moments DEPS: setup ====
# One camera at three moments, no boxes: Tuesday 2:55, Tuesday 8:35, Wednesday 18:31.
canvas("three_moments.jpg", 10.5, 2.75)
ttl <- c("Tuesday 2:55 am", "Tuesday 8:35 am", "Wednesday 6:31 pm")
st <- c("20261110_025447", "20261110_083455", "20261111_183031")
for (i in 1:3) frame_panel(0.1 + 3.48 * (i - 1), 0.08, 3.38, "08", st[i], title = ttl[i])
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: cutoffs DEPS: setup ====
# The same frame at three confidence cutoffs.
canvas("cutoffs.jpg", 10.5, 2.75)
cu <- c(0.10, 0.25, 0.50)
for (i in 1:3) frame_panel(0.1 + 3.48 * (i - 1), 0.08, 3.38, "13", "20261110_083455", cut = cu[i],
                           title = sprintf("Cutoff %.2f: %d vehicles", cu[i], n_at("13", "20261110_083455", cu[i])))
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: zone DEPS: setup ====
# The counting zone: a line per camera; vehicles entirely below it are counted.
canvas("zone.jpg", 10.5, 3.95)
ex <- hand[hand$id %in% c("h11", "h29"), ]
for (i in 1:2) frame_panel(0.1 + 5.2 * (i - 1), 0.08, 5.1, ex$cam[i], ex$stamp[i], cut = 0.25, line = ex$line_y[i], zone_only = TRUE,
                           title = sprintf("%s: by hand %d, detector %d", c("FDR Drive at 64th Street", "West Street at West Thames Street")[i], ex$count[i],
                                           n_at(ex$cam[i], ex$stamp[i], 0.25, ex$line_y[i])))
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: day_night DEPS: setup ====
# Two cameras in daylight and after dark, boxes at 0.25 inside the zone.
canvas("day_night.jpg", 10.5, 5.35)
ids <- c("h14", "h15", "h23", "h24")
for (i in 1:4) {
  r <- hand[hand$id == ids[i], ]
  frame_panel(0.1 + 5.2 * ((i - 1) %% 2), 2.72 - 2.66 * ((i - 1) %/% 2), 3.5 * 352 / 240 * 0.68, r$cam, r$stamp, cut = 0.25, line = r$line_y, zone_only = TRUE,
              title = sprintf("%s: by hand %d, detector %d", c("Daylight", "After dark")[(i - 1) %% 2 + 1], r$count, n_at(r$cam, r$stamp, 0.25, r$line_y)))
}
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: camera_turned DEPS: setup ====
# One camera on Tuesday morning and on Wednesday evening: it turned.
canvas("camera_turned.jpg", 10.5, 3.95)
frame_panel(0.1, 0.08, 5.1, "28", "20261110_083455", title = "Tuesday 8:35 am, stamped \"Facing North\"")
frame_panel(5.3, 0.08, 5.1, "28", "20261111_181436", title = "Wednesday 6:15 pm, stamped \"Facing East\"")
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: pano_views DEPS: setup ====
# One panorama and the two views cut from it.
v <- read.csv(file.path(dat, "data_clean/views.csv"), colClasses = c(panorama = "character"))
hl <- read.csv(file.path(dat, "data_clean/hand_labels.csv"))
pid <- v$panorama[v$view == hl$view[hl$n == 170]]
canvas("pano_views.jpg", 10.5, 5.95)
img_panel(0.1, 3.05, 5.2, file.path(dat, "data/ithaca/panoramas", paste0(pid, ".jpg")), title = "One panorama: the full circle around the car")
img_panel(5.6, 3.05, 3.4, view_file(paste0(pid, "_L")), title = "Cut from it: the view to the left")
img_panel(5.6, 0.1, 3.4, view_file(paste0(pid, "_R")), title = "and the view to the right")
text(0.1, 2.2, "The panorama is 4096 by 2048 pixels,", adj = 0, cex = 1.0, col = ink)
text(0.1, 1.9, "with the direction of travel in the middle.", adj = 0, cex = 1.0, col = ink)
text(0.1, 1.45, "Each view is 800 by 600 pixels and", adj = 0, cex = 1.0, col = ink)
text(0.1, 1.15, "80 degrees wide. It faces the buildings", adj = 0, cex = 1.0, col = ink)
text(0.1, 0.85, "on one side of the street.", adj = 0, cex = 1.0, col = ink)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: views_labelled DEPS: setup ====
# Eight hand-labelled views: four with a house, four without.
hl <- read.csv(file.path(dat, "data_clean/hand_labels.csv"))
canvas("views_labelled.jpg", 10.5, 4.3)
yes <- c(14, 25, 66, 100); no <- c(3, 13, 30, 59)
for (i in 1:4) {
  img_panel(0.1 + 2.6 * (i - 1), 2.2, 2.5, view_file(hl$view[hl$n == yes[i]]), title = if (i == 1) "Labelled by looking: a house" else NULL)
  img_panel(0.1 + 2.6 * (i - 1), 0.05, 2.5, view_file(hl$view[hl$n == no[i]]), title = if (i == 1) "Labelled by looking: no house" else NULL)
}
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: unsure_views DEPS: setup ====
# Views the labeller marked unsure, and views with rain on the lens.
hl <- read.csv(file.path(dat, "data_clean/hand_labels.csv"))
canvas("unsure_views.jpg", 10.5, 2.35)
pick <- c(31, 75, 106, 139)                                   # four of the eleven views he left undecided
for (i in 1:4) img_panel(0.1 + 2.6 * (i - 1), 0.05, 2.5, view_file(hl$view[hl$n == pick[i]]), title = if (i == 1) "Left undecided" else NULL, cex = 0.9)
dev.off()
canvas("rain_views.jpg", 10.5, 2.35)
pick <- c(2, 43, 49, 87)
for (i in 1:4) img_panel(0.1 + 2.6 * (i - 1), 0.05, 2.5, view_file(hl$view[hl$n == pick[i]]), title = if (i == 1) "Four views from the drive of April 11, 2024, in rain" else NULL, cex = 0.9)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: typed_wrong DEPS: setup ====
# Where the typed-label classifier and the hand label disagree.
hl <- read.csv(file.path(dat, "data_clean/hand_labels.csv"))
ty <- read.csv(file.path(dat, "data_clean/typed_labels.csv")); ty <- ty[ty$set == "shows", ]
top <- ty[order(ty$view, -ty$share), ]; top <- top[!duplicated(top$view), ]
m <- merge(hl[!is.na(hl$house), ], top, by = "view"); m$typed <- as.integer(m$label == "a house")
fp <- m[m$house == 0 & m$typed == 1, ]; fn <- m[m$house == 1 & m$typed == 0, ]
fp <- fp[order(-fp$share), ][1:4, ]; fn <- fn[order(-fn$share), ][1:4, ]
canvas("typed_wrong.jpg", 10.5, 4.45)
short <- c("a house" = "a house", "an apartment building" = "apartments", "a store or an office building" = "a store or office",
           "a parking lot" = "a parking lot", "trees or an empty lot" = "trees or an empty lot", "a road with no buildings" = "a road, no buildings")
text(0.1, 4.3, "The model said \"a house\"; my label is no house", adj = 0, cex = 0.95, col = ink)
text(0.1, 2.08, "My label is a house; the model said:", adj = 0, cex = 0.95, col = ink)
for (i in 1:4) {
  img_panel(0.1 + 2.6 * (i - 1), 2.3, 2.5, view_file(fp$view[i]))
  img_panel(0.1 + 2.6 * (i - 1), 0.05, 2.3, view_file(fn$view[i]))
  text(0.1 + 2.6 * (i - 1), 1.86, short[fn$label[i]], adj = 0, cex = 0.85, col = acc)
}
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: fed_faces DEPS: setup ====
# One frame of a Fed press conference with the face the detector found, and twelve
# face crops with the typed-label classifier's answer and the label by looking.
fr <- read.csv(file.path(dat, "data_clean/fed_frames.csv"), colClasses = c(date = "character"))
ex <- read.csv(file.path(dat, "data_clean/fed_expressions.csv"))
fh <- read.csv(file.path(dat, "data_clean/fed_hand_labels.csv"))
one <- fr[fr$date == "20230322" & !is.na(fr$face_found) & fr$face_found == 1, ][20, ]
canvas("fed_faces.jpg", 10.5, 4.15)
im <- readJPEG(file.path(dat, "data/fed/frames", paste0("fomc", one$date), sprintf("%05d.jpg", one$seconds)))
w <- 5.0; h <- w * 270 / 480; s <- w / 480; y0 <- 4.15 - h - 0.35
rasterImage(im, 0.1, y0, 0.1 + w, y0 + h)
rect(0.1 + one$x * s, y0 + h - (one$y + one$h) * s, 0.1 + (one$x + one$w) * s, y0 + h - one$y * s, border = "#FFD400", lwd = 3)
text(0.1, y0 + h + 0.16, "One frame, 480 by 270 pixels, and the face a detector found", adj = 0, cex = 0.95, col = ink)
f <- merge(fh, ex[, c("file", "top")], by = "file"); f <- f[order(f$n), ]
pick <- c(which(f$label == "happy")[1], which(f$label == "neutral" & (is.na(f$note) | f$note == ""))[1:11])
for (i in 1:12) {
  x <- 5.45 + 1.26 * ((i - 1) %% 4); y <- 2.80 - 1.30 * ((i - 1) %/% 4)
  rasterImage(readJPEG(file.path(dat, f$file[pick[i]])), x, y, x + 1.05, y + 1.05)
  text(x, y - 0.11, f$top[pick[i]], adj = 0, cex = 0.72, col = ink)
}
text(5.45, 4.02, "Twelve of the faces, each with the model's answer", adj = 0, cex = 0.95, col = ink)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: three_types DEPS: setup ====
# Three types of vision model, in the layout of the session 21 figure (the question, what you
# give, the model, what you get), with today's own examples and real outputs.
fill <- "#F2F2F2"
box_ <- function(x, y, w, h, col = fill, border = rule, lwd = 1.2) rect(x - w / 2, y - h / 2, x + w / 2, y + h / 2, col = col, border = border, lwd = lwd)
arr <- function(x0, y0, x1, y1, col = grey, lwd = 1.5) arrows(x0, y0, x1, y1, length = 0.1, col = col, lwd = lwd)
wrap_in <- function(txt, w, cex = 1) {
  words <- strsplit(txt, " ")[[1]]; lines <- character(); cur <- ""
  for (wd in words) { nxt <- if (nzchar(cur)) paste(cur, wd) else wd
    if (strwidth(nxt, cex = cex) > w && nzchar(cur)) { lines <- c(lines, cur); cur <- wd } else cur <- nxt }
  c(lines, cur)
}
ltext <- function(x, y, lines, cex = 1, lh = 0.19 * cex / 0.9, col = ink, font = 1) {
  n <- length(lines); text(x, y + ((n - 1) / 2 - (seq_len(n) - 1)) * lh, lines, cex = cex, col = col, font = font)
}
b <- boxes[boxes$cam == "16" & boxes$stamp == "20261110_083455" & boxes$conf >= 0.25, ]
top_conf <- function(l) sprintf("%.2f", max(b$conf[b$label == l]))
canvas("three_types.png", 10.4, 4.75)
cw <- 3.25; xs <- c(1.75, 5.2, 8.65)
heads <- c("A model that matches pictures and words", "A model built for one task", "A model you train")
defs  <- c("already trained, on pictures with their captions; scores how well each sentence you write describes a picture",
           "already trained, on many labelled photographs, for one fixed question; you download and run it",
           "you mark a few hundred photographs with the right answer; a trained model's last step is refit to them")
qs    <- list(c("yours, in words: \"Which of these six", "descriptions fits this street view?\""),
              c("fixed by its builders: \"Which of 80", "types of object are here, and where?\""),
              c("yours, shown by example:", "\"Does this street view show a house?\""))
gives <- c("the photograph and six descriptions", "the photograph", "120 street views you marked house or no house")
gets  <- list(c("\"a house\"", "the description that fits best,", "of the six you wrote"),
              c(sprintf("%d boxes round vehicles", nrow(b)),
                sprintf("car %s, truck %s ...", top_conf("car"), top_conf("truck")),
                "each a type of object and how sure"),
              c("\"house\" or \"no house\" for", "any new street view", ""))
lab <- function(x, y, t) text(x - cw / 2 + 0.08, y, t, cex = 0.8, col = grey, adj = 0)
for (i in 1:3) {
  x <- xs[i]
  text(x, 4.55, heads[i], cex = 1.0, font = 2, col = blue)
  ltext(x, 4.12, wrap_in(defs[i], cw - 0.15, 0.8), cex = 0.8, col = grey, lh = 0.175)
  lab(x, 3.68, "the question")
  box_(x, 3.3, cw, 0.6, col = "white", border = blue, lwd = 1.4); ltext(x, 3.3, qs[[i]], cex = 0.88, col = ink, lh = 0.22)
  arr(x, 2.97, x, 2.83); lab(x, 2.72, "you give")
  box_(x, 2.43, cw, 0.4, col = fill, border = rule); text(x, 2.43, gives[i], cex = if (i == 3) 0.8 else 0.9, col = ink)
  arr(x, 2.2, x, 2.06)
  box_(x, 1.9, cw * 0.5, 0.3, col = "white", border = blue, lwd = 1.6); text(x, 1.9, "model", cex = 0.9, col = blue, font = 2)
  arr(x, 1.73, x, 1.59); lab(x, 1.48, "you get")
  box_(x, 0.8, cw, 1.15, col = fill, border = rule)
  text(x, 1.08, gets[[i]][1], cex = 1.0, col = ink, font = 2)
  ltext(x, 0.58, gets[[i]][-1], cex = 0.85, col = ink, lh = 0.24)
}
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: embedding_setup DEPS: setup ====
# The labelled views, their 512 numbers, and the same split and summaries as code/2_houses.R.
hl <- read.csv(file.path(dat, "data_clean/hand_labels.csv")); hl <- hl[!is.na(hl$house), ]
emb <- read.csv(file.path(dat, "data_clean/view_embeddings.csv")); X <- as.matrix(emb[, -1]); rownames(X) <- emb$view
set.seed(6850); fit <- sample(nrow(hl), 120)
pc <- prcomp(X[hl$view[fit], ]); Z <- predict(pc, X[hl$view, ])[, 1:5]
vw <- function(n) hl$view[hl$n == n]
red <- "#B31B1B"
# ==== END BLOCK ====

# ==== BLOCK: embedding_views DEPS: embedding_setup ====
# Three views and their 512 numbers drawn as a grid of coloured cells, with the similarity of the lists.
pick <- c(14, 25, 13); ttl <- c("A house", "Another house", "A hotel and a car park")
ramp <- colorRampPalette(c("#2B5C8A", "white", "#B31B1B"))(101); lim <- 0.12
canvas("embedding_views.jpg", 10.5, 5.15)
for (i in 1:3) {
  x0 <- 0.15 + 3.5 * (i - 1); e <- X[vw(pick[i]), ]
  img_panel(x0, 2.45, 3.2, view_file(vw(pick[i])), title = ttl[i], cex = 1.0)
  g <- matrix(e, nrow = 16, byrow = TRUE)                      # 512 numbers as 16 rows of 32, number 1 at top left
  cw <- 3.2 / 32; ch <- 1.5 / 16
  for (r in 1:16) rect(x0 + (0:31) * cw, 0.85 + (16 - r) * ch, x0 + (1:32) * cw, 0.85 + (17 - r) * ch,
                       col = ramp[pmin(101, pmax(1, round(50 * g[r, ] / lim) + 51))], border = NA)
  rect(x0, 0.85, x0 + 3.2, 2.35, border = rule)
  text(x0, 0.66, sprintf("its first five numbers: %s", paste(sprintf("%.3f", e[1:5]), collapse = "  ")), adj = 0, cex = 0.72, col = ink)
}
# colour key: the value each colour stands for
kx <- seq(3.6, 6.9, length.out = 102)
rect(kx[-102], 0.2, kx[-1], 0.36, col = ramp, border = NA); rect(3.6, 0.2, 6.9, 0.36, border = rule)
text(c(3.6, 5.25, 6.9), 0.08, c(sprintf("%.2f or less", -lim), "0", sprintf("%.2f or more", lim)), cex = 0.75, col = grey)
text(3.45, 0.28, "value of a number", adj = 1, cex = 0.8, col = grey)
text(7.05, 0.28, "top left: number 1; bottom right: number 512", adj = 0, cex = 0.8, col = grey)
s12 <- sum(X[vw(pick[1]), ] * X[vw(pick[2]), ]); s13 <- sum(X[vw(pick[1]), ] * X[vw(pick[3]), ])
cat(sprintf("similarity house-house %.2f, house-hotel %.2f\n", s12, s13))
dev.off()
writeLines(sprintf("%.2f %.2f", s12, s13), file.path(out, "embedding_similarity.txt"))
# ==== END BLOCK ====

# ==== BLOCK: summaries DEPS: embedding_setup ====
# Left: the 189 labelled views on the first two summaries, by my label. Right: three houses and three
# views with no house, each with its five summaries as bars.
png(file.path(out, "summaries.png"), width = 10.5, height = 4.6, units = "in", res = 200)
layout(cbind(rep(1, 6), 2:7, 8:13), widths = c(5.2, 1.5, 3.8))
par(mar = c(4, 4.2, 1.2, 1), family = "sans", cex = 1)
plot(Z[, 1], Z[, 2], pch = 16, cex = 0.9, col = ifelse(hl$house == 1, red, "grey65"), las = 1, bty = "n",
     xlab = "Summary 1", ylab = "Summary 2")
legend("topleft", legend = c("my label: house", "my label: no house"), col = c(red, "grey65"), pch = 16, bty = "n", cex = 0.9)
ex <- c(14, 25, 66, 3, 13, 30)
for (n in ex) { par(mar = c(0.15, 0.2, 0.15, 0.2)); im <- readJPEG(view_file(vw(n)))
  plot.new(); plot.window(c(0, 4), c(0, 3), asp = 1, xaxs = "i", yaxs = "i"); rasterImage(im, 0, 0, 4, 3) }
for (n in ex) { par(mar = c(0.25, 0.5, 0.25, 0.5)); z <- Z[hl$n == n, ]
  plot.new(); plot.window(c(0.4, 5.6), c(-0.42, 0.42)); abline(h = 0, col = rule)
  rect(1:5 - 0.36, 0, 1:5 + 0.36, pmax(-0.42, pmin(0.42, z)), col = if (hl$house[hl$n == n] == 1) red else "grey55", border = NA)
  if (n == ex[1]) text(1:5, 0.34, paste("summary", 1:5), cex = 0.62, col = grey) }
dev.off()
cat("range of the five summaries on the examples:", round(range(Z[hl$n %in% ex, ]), 2), "\n")
# ==== END BLOCK ====

# ==== BLOCK: split_diagram DEPS: embedding_setup ====
# The labelled views divided into fitting views and held-out views, with the real counts.
box_ <- function(x, y, w, h, col = "#F2F2F2", border = rule, lwd = 1.2) rect(x - w / 2, y - h / 2, x + w / 2, y + h / 2, col = col, border = border, lwd = lwd)
arr <- function(x0, y0, x1, y1) arrows(x0, y0, x1, y1, length = 0.1, col = grey, lwd = 1.5)
canvas("split_diagram.png", 10.5, 4.2)
box_(5.25, 3.8, 4.6, 0.6); text(5.25, 3.8, "200 street views, drawn at random from 1,630", cex = 1.0, col = ink)
arr(5.25, 3.5, 5.25, 3.2)
box_(4.0, 2.85, 5.2, 0.6, col = "white", border = blue, lwd = 1.6)
text(4.0, 2.85, sprintf("%d views with my label: %d house, %d no house", nrow(hl), sum(hl$house == 1), sum(hl$house == 0)), cex = 1.0, col = ink)
box_(8.75, 2.85, 3.0, 0.6); text(8.75, 2.85, "11 left undecided: set aside", cex = 0.95, col = grey)
arr(2.9, 2.55, 2.4, 2.05); arr(5.1, 2.55, 6.6, 2.05)
text(4.0, 2.3, "divided at random", cex = 0.9, col = grey)
box_(2.4, 1.55, 4.2, 0.95, col = "white", border = red, lwd = 2)
text(2.4, 1.75, "120 fitting views", cex = 1.1, font = 2, col = red); text(2.4, 1.38, "the regression learns from these", cex = 0.95, col = ink)
box_(7.6, 1.55, 4.6, 0.95, col = "white", border = ink, lwd = 2)
text(7.6, 1.75, sprintf("%d held-out views", nrow(hl) - 120), cex = 1.1, font = 2, col = ink); text(7.6, 1.38, "never shown to it; it is judged on these", cex = 0.95, col = ink)
arr(2.4, 1.07, 2.4, 0.75); arr(7.6, 1.07, 7.6, 0.75)
text(2.4, 0.5, "a rule: five summaries in, \"house\" or \"no house\" out", cex = 0.95, col = ink)
text(7.6, 0.5, "the share of the held-out views where the rule matches my label", cex = 0.95, col = ink)
arrows(4.6, 0.5, 5.0, 0.5, length = 0.08, col = grey, lwd = 1.5)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: house_map DEPS: embedding_setup ====
# Every view at the car's position on a street map of Ithaca: red where the trained classifier
# finds a house. Base map: OpenStreetMap tiles stitched by hand (figures/22-photos-ii/src/).
bm <- jsonlite::fromJSON(file.path(out, "src/ithaca_osm.json")); base <- readJPEG(file.path(out, "src/ithaca_osm.jpg"))
base <- base * 0.6 + 0.4                                         # paler, so the dots stand out
vv <- read.csv(file.path(dat, "data_clean/views.csv"))
mfit <- suppressWarnings(glm(house ~ ., data = data.frame(Z[fit, ], house = hl$house[fit]), family = binomial))
vv$house <- predict(mfit, newdata = as.data.frame(predict(pc, X[vv$view, ])[, 1:5]), type = "response") > 0.5
merc <- function(lat) asinh(tan(lat * pi / 180)); rad <- function(lon) lon * pi / 180
xl <- rad(c(-76.548, -76.447)); yl <- merc(c(42.4265, 42.4665))
dev_open("house_map.jpg", 10.5, 10.5 * diff(yl) / diff(xl))
par(mar = c(0, 0, 0, 0)); plot.new(); plot.window(xl, yl, xaxs = "i", yaxs = "i")
rasterImage(base, rad(bm$west), bm$south_merc, rad(bm$east), bm$north_merc)
points(rad(vv$lon[!vv$house]), merc(vv$lat[!vv$house]), pch = 16, cex = 0.75, col = "#33333399")
points(rad(vv$lon[vv$house]), merc(vv$lat[vv$house]), pch = 16, cex = 0.95, col = "#B31B1B")
legend("topleft", legend = c("the classifier finds a house", "no house"), col = c("#B31B1B", "#333333"), pch = 16, bg = "white", box.col = rule, cex = 1.1, inset = 0.015)
dev.off()
cat("views:", nrow(vv), "| called a house:", sum(vv$house), round(mean(vv$house), 3), "\n")
# ==== END BLOCK ====

# ==== BLOCK: shares_views DEPS: setup ====
# The pre-trained model's output for two views: a share for each of the six descriptions we wrote.
hl <- read.csv(file.path(dat, "data_clean/hand_labels.csv")); ty <- read.csv(file.path(dat, "data_clean/typed_labels.csv")); ty <- ty[ty$set == "shows", ]
dev_open("shares_views.jpg", 10.5, 3.9)
layout(matrix(1:4, 2, byrow = TRUE), widths = c(2.6, 7.9)); par(family = "sans")
for (n in c(8, 13)) {
  v <- hl$view[hl$n == n]; d <- ty[ty$view == v, ]; d <- d[nrow(d):1, ]
  par(mar = c(0.4, 0.4, 0.4, 0.4)); plot.new(); plot.window(c(0, 4), c(0, 3), asp = 1, xaxs = "i", yaxs = "i"); rasterImage(readJPEG(view_file(v)), 0, 0, 4, 3)
  par(mar = c(if (n == 13) 2.4 else 0.6, 15, 0.6, 3), mgp = c(2, 0.6, 0), tcl = -0.3)
  bp <- barplot(d$share, horiz = TRUE, names.arg = d$label, las = 1, xlim = c(0, 1), border = NA, cex.names = 1.05,
                col = ifelse(d$share == max(d$share), "#B31B1B", "grey70"), xaxt = if (n == 13) "s" else "n")
  text(d$share, bp, sprintf(" %.2f", d$share), pos = 4, xpd = NA, cex = 1.0, col = ink)
}
dev.off()
# ==== END BLOCK ====
