# Figures for the session 20 page and slides (audio: tone and emotion).
# Base R and wrassp. Run from fall-2026/sessions:
#   Rscript _figures-20.R                 # every block
#   Rscript _figures-20.R f3_tracks       # setup, then one block
# Writes figures/20-audio-ii/*. Inputs: data/20-audio-ii/ (the session project).
#
# Each canvas is set in inches (1 user unit = 1 inch, origin bottom left) and
# drawn at res 200, sized so that 1 inch is about 100 px on the 1050 x 700
# slide at the placement noted above it, so cex 1.2 prints at about 20 px.

# ---- Run named blocks only: Rscript _figures-20.R <block> [<block> ...] ----
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
suppressPackageStartupMessages(library(wrassp))
out  <- "figures/20-audio-ii"
dat  <- "data/20-audio-ii"
dir.create(out, showWarnings = FALSE, recursive = TRUE)
ink  <- "#222222"; acc <- "#B31B1B"; grey <- "#666666"; rule <- "#BBBBBB"
fill <- "#F2F2F2"; tint <- "#F7E6E6"; blue <- "#3A6C9C"; other <- "#8C8C8C"
canvas <- function(name, w, h) {
  png(file.path(out, name), width = w, height = h, units = "in", res = 200)
  par(mar = c(0, 0, 0, 0), family = "sans")
  plot.new(); plot.window(xlim = c(0, w), ylim = c(0, h), xaxs = "i", yaxs = "i")
}
device <- function(name, w, h, ...) {
  png(file.path(out, name), width = w, height = h, units = "in", res = 200)
  par(family = "sans", col.axis = ink, col.lab = ink, las = 1, ...)
}
box_ <- function(x, y, w, h, col = fill, border = rule, lwd = 1.2, lty = 1)
  rect(x - w / 2, y - h / 2, x + w / 2, y + h / 2, col = col, border = border, lwd = lwd, lty = lty)
arr <- function(x0, y0, x1, y1, col = grey, lwd = 1.5)
  arrows(x0, y0, x1, y1, length = 0.1, col = col, lwd = lwd)
tone <- read.csv(file.path(dat, "data_clean/tone.csv"))
ans  <- tone[tone$type == "answer" & tone$end - tone$start >= 15, ]
ans  <- ans[order(ans$date, ans$start), ]
meet <- read.csv(file.path(dat, "data_clean/meetings.csv"))
z    <- function(x, base = x) (x - mean(base)) / sd(base)
voice <- function(f, from = 0, to = 0) {
  p <- ksvF0(f, beginTime = from, endTime = to, gender = "m", toFile = FALSE)
  e <- rmsana(f, beginTime = from, endTime = to, toFile = FALSE)
  v <- p$F0[p$F0 > 0]
  c(pitch = median(v), range = IQR(v), energy = mean(e$rms), voiced = mean(p$F0 > 0))
}
clip <- function(n) file.path(dat, "data/clips", paste0(n, ".wav"))
flow <- function(name, steps, w = 9.6, h = 2.1, below = NULL, bh = 1.45) {
  canvas(name, w, h)
  n <- length(steps); gap <- 0.32; bw <- (w - 0.2 - gap * (n - 1)) / n
  xs <- 0.1 + bw / 2 + (0:(n - 1)) * (bw + gap); y <- if (is.null(below)) h / 2 else h / 2 + 0.2
  for (i in seq_len(n)) {
    st <- steps[[i]]; m <- isTRUE(st$model)
    box_(xs[i], y, bw, bh, col = if (m) "white" else fill, border = if (m) blue else rule, lwd = if (m) 1.8 else 1.2)
    text(xs[i], y + bh / 2 - 0.27, st$head, cex = 1.0, font = 2, col = if (m) blue else ink)
    text(xs[i], y - 0.14, st$body, cex = 0.92, col = ink)
    if (i < n && !isTRUE(st$noarrow)) arr(xs[i] + bw / 2 + 0.03, y, xs[i + 1] - bw / 2 - 0.03, y)
  }
  if (!is.null(below)) text(w / 2, 0.2, below, cex = 0.92, col = grey)
  dev.off()
}
# ==== END BLOCK ====

# ==== BLOCK: f1_hikes DEPS: setup ====
# Slide "The 24 press conferences" (full width at 90%): top of the target range
# after each of the 24 meetings; hikes filled. Canvas 9.6 x 3.3 in.
d <- as.Date(meet$date); hike <- meet$decision == "hike"
device("f1-hikes.png", 9.6, 3.3, mar = c(2.6, 5.4, 0.6, 0.6))
plot(d, meet$upper, type = "s", col = grey, lwd = 2, xlab = "", ylab = "Top of the Fed's target\nrange (percent)",
     ylim = c(0, 6), cex.axis = 1.05, cex.lab = 1.05, bty = "l")
points(d, meet$upper, pch = ifelse(hike, 19, 21), bg = "white", col = ifelse(hike, acc, ink), cex = 1.4)
f <- which(hike)[1]; l <- max(which(hike))
text(d[f] - 15, meet$upper[f] + 0.75, "First hike, 16 Mar 2022", adj = 1, cex = 1.05, col = acc)
text(d[l], meet$upper[l] - 1.0, "Last hike, 26 Jul 2023", adj = 0.5, cex = 1.05, col = acc)
legend("topleft", c("Rate hike (11)", "Hold (13)"), pch = c(19, 21), col = c(acc, ink), pt.bg = "white", bty = "n", cex = 1.05)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f3_tracks DEPS: setup ====
# Slide "Pitch and energy tracks of one answer" (full width at 94%): the 15 s of
# the answer at 25:15, 3 Nov 2021. Top, voiced frames, median and the middle half
# of the frames (the range); bottom, energy. Canvas 9.6 x 3.6 in.
f <- clip("activated"); p <- ksvF0(f, gender = "m", toFile = FALSE); e <- rmsana(f, toFile = FALSE)
tp <- attr(p, "startTime") + (seq_along(p$F0) - 1) / attr(p, "sampleRate")
te <- attr(e, "startTime") + (seq_along(e$rms) - 1) / attr(e, "sampleRate")
v <- as.vector(p$F0); keep <- v > 0; q <- quantile(v[keep], c(.25, .5, .75))
w <- read.csv(file.path(dat, "data_clean/words.csv"))
w <- w[w$date == "2021-11-03" & w$start >= 1514.68 & w$start < 1529.68, ]; w$t <- w$start - 1514.68
device("f3-tracks.png", 9.6, 3.6, mfrow = c(2, 1), oma = c(2.8, 0, 0, 0.3))
par(mar = c(0.3, 4.6, 1.5, 0.3))
plot(tp[keep], v[keep], pch = 16, cex = 0.35, col = ink, ylim = c(60, 265), xlim = c(0, 15), xaxs = "i", xaxt = "n",
     xlab = "", ylab = "Pitch, Hz", bty = "l", cex.lab = 1.05)
rect(0, q[1], 15, q[3], col = adjustcolor(acc, 0.13), border = NA)
abline(h = q[2], col = acc, lwd = 1.6)
text(15, 250, sprintf("level (median) %.1f Hz; range (middle half of the frames) %.1f Hz", q[2], q[3] - q[1]), adj = 1, col = acc, cex = 1.05)
sh <- w[w$word %in% c("That's", "decision", "Committee.", "way.", "maximum", "employment,", "labor", "market", "inflation"), ]
axis(3, at = sh$t, labels = sub("[.,]$", "", sh$word), tick = FALSE, line = -0.75, cex.axis = 0.88, col.axis = grey)
par(mar = c(0.5, 4.6, 0.5, 0.3))
plot(te, e$rms, type = "l", col = blue, xlim = c(0, 15), ylim = c(15, 95), xaxs = "i", xlab = "", ylab = "Energy, dB", bty = "l", cex.lab = 1.05, cex.axis = 1)
abline(h = mean(e$rms), col = acc, lwd = 1.6)
text(15, 89, sprintf("mean %.1f dB", mean(e$rms)), adj = 1, col = acc, cex = 1.05)
mtext("Seconds into the answer", side = 1, outer = TRUE, line = 1.5, cex = 0.95)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f4_scatter DEPS: setup ====
# Slide "Arousal and valence" (at 72%): first 15 s of each of the 571 answers,
# direct scores; the two answers already heard labelled. Canvas 7.2 x 3.7 in.
device("f4-scatter.png", 7.2, 3.7, mar = c(4, 4.2, 0.5, 0.5))
plot(ans$arousal15, ans$valence15, pch = 16, cex = 0.7, col = adjustcolor(other, 0.7), bty = "l",
     xlab = "Arousal: calm to excited", ylab = "Valence: negative to positive", cex.lab = 1.1)
k <- ans$date == "2021-11-03" & abs(ans$start - c(2388.72)) < 0.02; j <- ans$date == "2021-11-03" & abs(ans$start - 1514.68) < 0.02
points(ans$arousal15[k | j], ans$valence15[k | j], pch = 19, col = acc, cex = 1.4)
text(ans$arousal15[k], ans$valence15[k], "39:49", pos = 1, col = acc, cex = 1.1)
text(ans$arousal15[j], ans$valence15[j], "25:15", pos = 3, col = acc, cex = 1.1)
dev.off(); print(c(ans$arousal15[k], ans$valence15[k], ans$arousal15[j], ans$valence15[j]))
# ==== END BLOCK ====

# ==== BLOCK: f5_baseline DEPS: setup ====
# Slide "A speaker's baseline and the z-score" (full width at 92%). Left, four
# turns in three minutes of 3 Nov 2021; right, Powell's 21 openings that day
# with the two clips. Canvas 9.6 x 2.9 in.
turns <- read.csv(file.path(dat, "data_clean/turns_excerpt.csv"))
g <- clip("excerpt_20211103"); pt <- sapply(1:nrow(turns), function(i) voice(g, turns$start[i] - 480, turns$end[i] - 480)["pitch"])
nov <- ans[ans$date == "2021-11-03", ]; A <- voice(clip("activated")); C <- voice(clip("calm"))
device("f5-baseline.png", 9.6, 2.9)
layout(matrix(1:2, 1), widths = c(4, 5.6))
par(mar = c(3.1, 4.2, 2, 0.5))
bp <- barplot(pt, names.arg = c("Reporter", "Powell", "Reporter", "Powell"), col = c(other, acc, other, acc), border = NA, ylim = c(0, 150),
              ylab = "Median pitch, Hz", cex.names = 1, cex.axis = 1, cex.lab = 1.05)
text(bp, pt + 9, sprintf("%.1f", pt), cex = 1, col = ink); title("Four turns in three minutes", adj = 0, font.main = 1, cex.main = 1.1)
par(mar = c(3.1, 1.5, 2, 1))
plot(nov$pitch15, rep(0, nrow(nov)), pch = 21, bg = "white", col = grey, cex = 1.4, yaxt = "n", ylab = "", xlab = "", ylim = c(-1, 1.4), xlim = c(90, 116), bty = "n", cex.axis = 1)
m <- mean(nov$pitch15); s <- sd(nov$pitch15); abline(v = m, col = ink, lwd = 1.4)
mtext("Hz", side = 1, line = 2, cex = 0.9)
text(m + 0.4, -0.8, sprintf("his mean %.1f Hz, SD %.1f", m, s), adj = 0, cex = 1, col = ink)
for (x in list(list(C, "39:49"), list(A, "25:15"))) {
  v <- x[[1]][["pitch"]]; points(v, 0, pch = 19, col = acc, cex = 1.8)
  text(v, 0.65, sprintf("%s: %.1f Hz\nz = %+.1f", x[[2]], v, (v - m) / s), col = acc, cex = 1)
}
title("Powell's 21 answers that day, first 15 s", adj = 0, font.main = 1, cex.main = 1.1)
dev.off(); print(pt); print(c(m, s, (A[["pitch"]] - m) / s, (C[["pitch"]] - m) / s))
# ==== END BLOCK ====

# ==== BLOCK: f6_chain DEPS: setup ====
# Slide "How a recording changes a voice measure" (full width at 92%). Canvas 9.6 x 1.8.
canvas("f6-chain.png", 9.6, 1.8)
lab <- c("Powell's\nvoice", "press\nroom", "microphone", "sound-desk\ngain", "the Fed's\nvideo", "WAV file,\n16,000 samples\na second", "pitch, energy,\nemotion score")
n <- length(lab); gap <- 0.22; bw <- (9.6 - 0.2 - gap * (n - 1)) / n; xs <- 0.1 + bw / 2 + (0:(n - 1)) * (bw + gap)
for (i in 1:n) {
  box_(xs[i], 1.15, bw, 1.05, col = if (i == 1) tint else if (i == n) "white" else fill, border = if (i == 1) acc else if (i == n) blue else rule, lwd = if (i %in% c(1, n)) 1.8 else 1.2)
  text(xs[i], 1.15, lab[i], cex = 0.92, col = ink)
  if (i < n) arr(xs[i] + bw / 2 + 0.01, 1.15, xs[i + 1] - bw / 2 - 0.01, 1.15)
}
text(xs[1], 0.28, "speaker", col = acc, cex = 1, font = 2)
segments(xs[2] - bw / 2, 0.48, xs[6] + bw / 2, 0.48, col = grey, lwd = 1.3); text(mean(xs[2:6]), 0.28, "recording", col = grey, cex = 1, font = 2)
text(xs[7], 0.28, "the number", col = blue, cex = 1, font = 2)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f7_congress DEPS: setup ====
# Slide "Vocal pitch in Congress" (full width at 90%): the published paper.
flow("f7-congress.png", list(
  list(head = "Measured", body = "pitch, in SDs above or below\nthe speaker's own mean;\n74,158 floor speeches", noarrow = TRUE),
  list(head = "With what", body = "Praat,\na pitch tracker", model = TRUE, noarrow = TRUE),
  list(head = "Compared with what", body = "male colleagues;\nher own speech\non other topics")), h = 1.65)
# ==== END BLOCK ====

# ==== BLOCK: f8_fed DEPS: setup ====
# Slide "Tone of voice and share prices" (full width at 90%): the accepted manuscript.
flow("f8-fed.png", list(
  list(head = "Audio", body = "692 answers, three chairs,\nApr 2011 to Jun 2019"),
  list(head = "Deep learning model", body = "trained on two sets\nof acted speech", model = TRUE),
  list(head = "Tone score", body = "how positive\nthe voice sounds"),
  list(head = "Share prices", body = "SPY, an S&P 500 fund,\nover the following days")),
  below = "Held fixed: the Fed's actions and the sentiment of its policy texts.", h = 2.1)
# ==== END BLOCK ====

# ==== BLOCK: f9_listeners DEPS: setup ====
# Slide "Listeners rating voices" (full width at 90%): the draft revised Jan 2009.
# Gaps with full controls, relative to distinctly identified whites.
flow("f9-listeners.png", list(
  list(head = "Recorded voices", body = "excerpts of\nphone interviews"),
  list(head = "130 listeners", body = "judge the speaker's\nrace from the voice", model = TRUE),
  list(head = "Distinctly identified", body = "Black speakers earn\n12.4% less", noarrow = TRUE),
  list(head = "Indistinctly identified", body = "Black speakers earn\nunder 1% less")),
  below = "Wage gaps with full controls, relative to distinctly identified whites.", h = 2.05)
# ==== END BLOCK ====

# ==== BLOCK: f10_training DEPS: setup ====
# Slide "How an emotion model is trained" (full width at 92%). The triple is the
# direct 15-s score of the clip at 25:15, replies/emotion_clips.csv.
s <- read.csv(file.path(dat, "replies/emotion_clips.csv")); s <- s[s$clip == "activated", ]
flow("f10-training.png", list(
  list(head = "Podcast clips", body = "natural speech,\nrecorded for\nanother purpose"),
  list(head = "Rated by listeners", body = "human listeners,\n1-to-7 scales,\nmapped to 0 to 1"),
  list(head = "The model learns", body = "to predict\nthe ratings", model = TRUE),
  list(head = "Powell, 25:15", body = sprintf("arousal %.3f\ndominance %.3f\nvalence %.3f", s$arousal, s$dominance, s$valence))),
  h = 1.8)
# ==== END BLOCK ====

# ==== BLOCK: f11_ewertz DEPS: setup ====
# Slide "Models trained on actors fail on executives": AUC, version of record, p. 245
# (Table 2). Three classes of tone; 50 is a model that guesses. Canvas 7.6 x 2.9 in.
auc <- c(98.67, 52.91, 81.66)
device("f11-ewertz.png", 7.6, 2.9, mar = c(3.4, 4.2, 0.6, 0.5))
bp <- barplot(auc, names.arg = rep("", 3), col = c(other, other, blue), border = NA,
              ylim = c(0, 115), xlim = c(0.1, 4.3), ylab = "AUC score", cex.axis = 1, cex.lab = 1.05, yaxt = "n")
axis(2, at = c(0, 50, 100)); abline(h = 50, lty = 2, col = acc, lwd = 1.6)
mtext(c("Trained on actors,\ntested on actors", "Trained on actors,\ntested on executives", "Trained on calls,\ntested on other executives"),
      side = 1, at = bp, line = 1.9, cex = 0.95)
text(bp, auc + 8, sprintf("%.0f", auc), cex = 1.05, col = ink)
text(4.28, 57, "guessing", adj = 1, col = acc, cex = 1)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f12_draws DEPS: setup ====
# Slide "Arousal follows pitch and energy, valence does not" (at 84%): each score against its fitted
# value from pitch level, pitch range and energy, all z-scored within conference.
wz <- function(v) ave(ans[[v]], ans$date, FUN = z)
X <- data.frame(p = wz("pitch"), r = wz("pitch_iqr"), e = wz("energy"))
fa <- lm(wz("arousal") ~ p + r + e, X); fv <- lm(wz("valence") ~ p + r + e, X)
device("f12-draws.png", 8.4, 2.9, mfrow = c(1, 2), mar = c(4, 4.2, 1.9, 0.6))
for (x in list(list(fa, "Arousal"), list(fv, "Valence"))) {
  plot(fitted(x[[1]]), model.frame(x[[1]])[, 1], pch = 16, cex = 0.55, col = adjustcolor(other, 0.75), xlim = c(-2.6, 2.6), ylim = c(-3.5, 3.5), bty = "l",
       xlab = "Predicted from pitch level, range, energy", ylab = paste("Model's", tolower(x[[2]]), "score (z)"), cex.lab = 1.02)
  abline(0, 1, col = acc, lwd = 1.5)
  title(sprintf("%s: %.0f%% explained", x[[2]], 100 * summary(x[[1]])$r.squared), adj = 0, font.main = 1, cex.main = 1.1)
}
dev.off(); print(c(summary(fa)$r.squared, summary(fv)$r.squared))
# ==== END BLOCK ====

# ==== BLOCK: f13_strips DEPS: setup ====
# Slide "Two clips, each compared with that day's answers" (full width at 92%).
device("f13-strips.png", 9.6, 2.5, mar = c(3.2, 8.6, 0.5, 1))
o <- list(list("2021-11-03", "answer_20211103", "3 Nov 2021"), list("2023-02-01", "answer_20230201", "1 Feb 2023"))
plot(NA, xlim = c(80, 116), ylim = c(0.4, 2.6), yaxt = "n", xlab = "", ylab = "", bty = "n", cex.axis = 1)
mtext("Pitch level in the first 15 s of each answer that day, Hz", side = 1, line = 2.1, cex = 0.98)
for (i in 1:2) {
  y <- 3 - i; a <- ans[ans$date == o[[i]][[1]], ]; v <- voice(clip(o[[i]][[2]]))[["pitch"]]
  m <- mean(a$pitch15); s <- sd(a$pitch15)
  points(a$pitch15, rep(y, nrow(a)), pch = 21, bg = "white", col = grey, cex = 1.3); segments(m, y - 0.28, m, y + 0.28, col = ink, lwd = 1.5)
  points(v, y, pch = 19, col = acc, cex = 2); text(v, y + 0.47, sprintf("clip: %.1f Hz, z = %+.2f", v, (v - m) / s), col = acc, cex = 1.05)
  axis(2, at = y, labels = o[[i]][[3]], tick = FALSE, cex.axis = 1.05)
}
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f14_scale DEPS: setup ====
# Slide "Rating arousal by ear" (full width at 88%). Canvas 9.6 x 1.9 in.
canvas("f14-scale.png", 9.6, 1.9)
lab <- c("1\ncalm and flat", "2", "3\nordinary", "4", "5\nanimated and urgent"); xs <- seq(1.3, 8.3, length.out = 5)
segments(xs[1], 1.5, xs[5], 1.5, col = grey, lwd = 1.5); points(xs, rep(1.5, 5), pch = 21, bg = "white", col = ink, cex = 2)
for (i in 1:5) text(xs[i], 1.5, lab[i], pos = 1, offset = 0.8, cex = 1.05, col = ink)
xc <- seq(0.8, 8.8, length.out = 8); text(0.25, 0.3, "Clip", cex = 1, col = grey)
for (i in 1:8) { box_(xc[i], 0.3, 0.72, 0.42, col = "white"); text(xc[i], 0.3, i, col = rule, cex = 1.05) }
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f16_conferences DEPS: setup ====
# Slide "Energy and pitch by conference" (full width at 94%). Left, Powell's and
# the reporters' energy; right, Powell's pitch level. One point per conference.
conf <- aggregate(cbind(energy, pitch) ~ date, ans, median)
rep_ <- tone[tone$type == "other" & tone$end - tone$start >= 10 & !is.na(tone$energy), ]
rr <- aggregate(energy ~ date, rep_, median); names(rr)[2] <- "reporters"
conf <- merge(merge(conf, rr), meet[, c("date", "decision")]); d <- as.Date(conf$date); back <- as.Date("2022-05-04")
device("f16-conferences.png", 9.6, 3.1, mfrow = c(1, 2), mar = c(2.4, 4.2, 1.8, 0.6))
plot(d, conf$energy, type = "o", pch = 19, cex = 0.9, col = acc, ylim = range(conf$energy, conf$reporters), xlab = "", ylab = "Median energy, dB", bty = "l", cex.axis = 1, cex.lab = 1.02)
lines(d, conf$reporters, type = "o", pch = 1, cex = 0.9, col = ink); abline(v = back, lty = 2, col = grey)
legend("topleft", c("Powell", "Reporters"), pch = c(19, 1), lty = 1, col = c(acc, ink), bty = "n", cex = 1)
title("Energy moves together", adj = 0, font.main = 1, cex.main = 1.1)
plot(d, conf$pitch, pch = ifelse(conf$decision == "hike", 19, 1), cex = 1.1, col = acc, ylim = c(85, 105), xlab = "", ylab = "Powell's median pitch, Hz", bty = "l", cex.axis = 1, cex.lab = 1.02)
abline(v = back, lty = 2, col = grey); legend("topright", c("Rate hike", "Hold"), pch = c(19, 1), col = acc, bty = "n", cex = 1)
title("Pitch level falls and stays low", adj = 0, font.main = 1, cex.main = 1.1)
dev.off(); print(cor(conf$energy, conf$reporters))
# ==== END BLOCK ====

# ==== BLOCK: f20_beyond DEPS: setup ====
# Slide "Sound beyond speech" (full width at 92%): Carr & Doleac (published abstract,
# June 2017 draft); Mueller et al. (published).
flow("f20-beyond.png", list(
  list(head = "Gunfire sensors", body = "DC curfew moved to 11 pm:\ngunfire up 150%,\n11 to 11:59 pm on weekdays", noarrow = TRUE),
  list(head = "911 calls", body = "same curfew:\ncalls suggested\na fall", noarrow = TRUE),
  list(head = "Forest soundscapes", body = "43 plots, Ecuador, farmland\nto old forest: a bird-sound\nmodel tracks the experts", model = TRUE)), h = 1.75, bh = 1.55)
# ==== END BLOCK ====
