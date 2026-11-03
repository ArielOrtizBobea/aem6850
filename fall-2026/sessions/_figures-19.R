# Figures for the session 19 page and slides (audio: speech to text).
# Base R plus pdftools (page renders), png (reading and cropping PNG
# images) and tuneR (the WAV files); ffmpeg for the video frame and
# headless Chrome for the Fed's page. Run from fall-2026/sessions:
#   Rscript _figures-19.R                 # every block
#   Rscript _figures-19.R f5_labels       # setup, then one block
# Writes figures/19-audio/*. Inputs: data/19-audio/ (the session project).
# F1 and F5 also read data/19-audio/data/media/ (the video and the WAV,
# kept out of git and out of the zip); the two captures go to the web.
#
# Each canvas is set in inches (1 user unit = 1 inch, origin bottom left)
# and drawn at res 200, sized so that 1 inch is about 100 px on the
# 1050 x 700 slide at the placement noted above it, so cex 1.2 prints at
# about 20 px.

# ---- Run named blocks only: Rscript _figures-19.R <block> [<block> ...] ----
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
suppressPackageStartupMessages({ library(pdftools); library(png) })
out  <- "figures/19-audio"
dat  <- "data/19-audio"
dir.create(out, showWarnings = FALSE, recursive = TRUE)
ink  <- "#222222"; acc <- "#B31B1B"; grey <- "#666666"; rule <- "#BBBBBB"
fill <- "#F2F2F2"; tint <- "#F7E6E6"; blue <- "#3A6C9C"; other <- "#8C8C8C"
# open a w x h inch canvas, 1 user unit = 1 inch, origin bottom left
canvas <- function(name, w, h, type = getOption("bitmapType")) {
  png(file.path(out, name), width = w, height = h, units = "in", res = 200, type = type)
  par(mar = c(0, 0, 0, 0), family = "sans")
  plot.new(); plot.window(xlim = c(0, w), ylim = c(0, h), xaxs = "i", yaxs = "i")
}
box_ <- function(x, y, w, h, col = fill, border = rule, lwd = 1.2, lty = 1)
  rect(x - w / 2, y - h / 2, x + w / 2, y + h / 2, col = col, border = border, lwd = lwd, lty = lty)
arr <- function(x0, y0, x1, y1, col = grey, lwd = 1.5)
  arrows(x0, y0, x1, y1, length = 0.1, col = col, lwd = lwd)
clock <- function(s) sprintf("%02d:%02d", floor(s / 60), floor(s %% 60))
# ==== END BLOCK ====

# ==== BLOCK: data DEPS: setup ====
# The session's tables, as the scripts in data/19-audio/code/ write them.
words <- readRDS(file.path(dat, "data_clean/words.rds"))
seg   <- readRDS(file.path(dat, "data_clean/seg.rds"))
utt   <- read.csv(file.path(dat, "data_clean/utterances.csv"))
# ==== END BLOCK ====

# ==== BLOCK: f1_conference DEPS: setup ====
# Slide 4 "The Fed press conference of 1 February 2023": a frame of the
# Fed's 270p video at 16:11 (Powell answering Howard Schneider) beside the
# top of transcript page 1, the turn counts the transcript tags under them.
# Full width: canvas 9.6 x 3.9 in. The frame is 480 px, so 4.8 in shows it
# at its own size on the slide.
fr <- file.path(tempdir(), "frame_971.png")
system2("ffmpeg", c("-hide_banner", "-loglevel", "error", "-y", "-ss", "971", "-i",
                    file.path(dat, "data/media/fomc20230201_270p.mp4"), "-frames:v", "1", fr))
frame <- readPNG(fr)
k  <- 200 / 72                                   # PDF points to pixels at 200 dpi
pg <- pdf_render_page(file.path(dat, "data/fomc20230201_transcript.pdf"), page = 1,
                      dpi = 200, numeric = TRUE)
# the header, the title and the first five lines: x 64-446 pt, y 14-244 pt
crop <- pg[round(14 * k):round(244 * k), round(64 * k):round(446 * k), 1:3]
canvas("f1-conference.png", 9.6, 3.9)
y0 <- 1.15; y1 <- 3.85
rasterImage(frame, 0, y0, 4.8, y1)
cw <- 4.5; ch <- cw * dim(crop)[1] / dim(crop)[2]
rasterImage(crop, 5.1, y1 - ch, 5.1 + cw, y1)
# the lines run on past the crop: fade the right edge to white
for (i in 1:30) rect(5.1 + cw - 0.3 + (i - 1) * 0.3 / 30, y1 - ch, 5.1 + cw, y1,
                     col = adjustcolor("white", 0.08), border = NA)
rect(5.1, y1 - ch, 5.1 + cw, y1, border = rule, lwd = 1)
rect(0, y0, 4.8, y1, border = rule, lwd = 1)
text(2.4, 0.93, "a frame of the Fed's video (44 min): the recording we transcribe", cex = 0.95, col = grey)
text(5.1 + cw / 2, 0.93, "the Fed's transcript (23 pages): the reference we check against", cex = 0.95, col = grey)
segments(0.2, 0.74, 9.4, 0.74, col = rule)
cx <- c(1.6, 4.8, 8.0)
text(cx, 0.5, c("30 turns", "17 turns", "29 turns"), cex = 1.25, font = 2, col = ink)
text(cx, 0.2, c("Chair Jerome Powell", "Michelle Smith, the moderator", "17 reporters"),
     cex = 1.0, col = ink)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f2_pipeline DEPS: setup ====
# Slide "What the models return, and the table we build" (opens Part 3): the
# recording goes through two different models, each with its own reply
# file, and the two replies are joined by time into the table; real sizes.
# Each model is a box of its own on its path, so the two read as separate
# models. Full width, above the three printed rows: canvas 9.6 x 2.95 in.
canvas("f2-pipeline.png", 9.6, 2.95)
fname <- function(x, y, s, cex = 0.85) text(x, y, s, family = "mono", font = 2, cex = cex, col = ink)
note  <- function(x, y, s, cex = 0.85) text(x, y, s, cex = cex, col = ink)
capt  <- function(x, y, s) text(x, y, s, cex = 0.8, col = grey)
model <- function(y, name, what) {
  box_(2.85, y, 1.95, 0.85, col = "white", border = blue, lwd = 1.8)
  text(2.85, y + 0.17, name, cex = 0.95, font = 2, col = blue)
  text(2.85, y - 0.15, what, cex = 0.8, col = ink)
}
ya <- 2.2; yb <- 0.8; ym <- (ya + yb) / 2
# the recording
box_(0.8, ym, 1.5, 0.9)
fname(0.8, ym + 0.15, "fomc20230201.wav")
note(0.8, ym - 0.15, "the recording, 44:37")
# the two models
model(ya, "speech-to-text model", "writes each word it\nhears, with its time")
model(yb, "speaker-label model", "groups 3-second\nwindows by voice")
# their replies
box_(5.4, ya, 2.35, 0.85)
fname(5.4, ya + 0.17, "replies/words.json")
note(5.4, ya - 0.15, "7,451 words:\nstart, end, probability")
box_(5.4, yb, 2.35, 0.85)
fname(5.4, yb + 0.17, "replies/speakers.rttm")
note(5.4, yb - 0.15, "86 stretches labelled\nSPK00, SPK01, ..., one per voice")
capt(2.85, ya + 0.6, "two different models")
capt(5.4, ya + 0.6, "each model's reply, a file")
# the table
box_(8.35, ym, 2.3, 0.9, col = tint, border = acc)
fname(8.35, ym + 0.15, "data_clean/utterances.csv")
note(8.35, ym - 0.15, "56 rows: speaker,\nstart, end, text")
text(8.35, ym + 0.75, "joined by time in R", cex = 0.85, col = ink)
capt(8.35, ym - 0.75, "utterance: one unbroken\nturn by one voice")
arr(1.6, ym + 0.2, 1.85, ya - 0.1); arr(1.6, ym - 0.2, 1.85, yb + 0.1)
arr(3.85, ya, 4.2, ya); arr(3.85, yb, 4.2, yb)
arr(6.6, ya - 0.1, 7.15, ym + 0.2); arr(6.6, yb + 0.1, 7.15, ym - 0.2)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f3_political_risk DEPS: setup ====
# Slide 15 "Political risk measured from earnings calls": the measure of
# Hassan, Hollander, van Lent & Tahoun (QJE, 2019) as one left-to-right flow
# of five boxes of equal height. The three phrases in the third box are from
# the paper's own table of top political bigrams. At 90% width: canvas
# 9.6 x 1.75 in.
canvas("f3-political-risk.png", 9.6, 1.75)
bw <- c(1.45, 1.7, 1.95, 1.4, 1.6); gap <- 0.34; bh <- 1.6; yc <- 0.875
x0 <- (9.6 - sum(bw) - 4 * gap) / 2
xl <- x0 + cumsum(c(0, bw[-5] + gap)); xc <- xl + bw / 2
for (i in 1:5) box_(xc[i], yc, bw[i], bh, col = if (i == 5) tint else fill,
                    border = if (i == 5) acc else rule)
for (i in 1:4) arr(xl[i] + bw[i] + 0.04, yc, xl[i + 1] - 0.04, yc, col = ink)
lh <- 0.22
txt <- list(c("one earnings", "call, typed"),
            c("find \u201crisk\u201d or", "\u201cuncertainty\u201d"),
            c("count political", "phrases within", "ten words of it"),
            c("divide by", "all phrases", "in the call"),
            c("political risk", "of one firm,", "one quarter"))
for (i in c(1, 2, 4, 5)) {
  y <- yc + lh * ((length(txt[[i]]) - 1) / 2 - seq_along(txt[[i]]) + 1)
  text(xc[i], y, txt[[i]], cex = 1.05, col = if (i == 5) acc else ink, font = if (i == 5) 2 else 1)
}
text(xc[2], yc - 0.45, "or a synonym", cex = 0.85, col = grey)
text(xc[3], yc + 0.6 - lh * 0:2, txt[[3]], cex = 1.05, col = ink)
text(xc[3], yc - 0.13, "for example", cex = 0.8, col = grey)
text(xc[3], yc - 0.33 - 0.17 * 0:2,
     c("\u201cthe constitution\u201d", "\u201cpublic opinion\u201d", "\u201cinterest groups\u201d"),
     cex = 0.85, col = acc)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f4_words_per_minute DEPS: setup ====
# Slide 11 "The small model's loop" (Part 1): words per minute of the
# conference, large model (replies/words.json) against small
# (replies/words_base.json). From 34:57 (the segment at 2097.9 s) the
# small model repeats one phrase. Full width: canvas 9.6 x 3.8 in.
suppressPackageStartupMessages(library(jsonlite))
wpm <- function(f) {
  s <- fromJSON(file.path(dat, f))
  w <- do.call(rbind, s$segments$words)
  as.vector(table(factor(floor(w$start / 60), levels = 0:44)))   # table(floor(start / 60))
}
large <- wpm("replies/words.json"); small <- wpm("replies/words_base.json")
m <- 0:44
png(file.path(out, "f4-words-per-minute.png"), width = 9.6, height = 3.8, units = "in", res = 200)
par(mar = c(3.4, 4.4, 0.6, 0.8), family = "sans", las = 1, mgp = c(2.3, 0.55, 0), tck = -0.012)
plot(NA, xlim = c(-0.5, 44.8), ylim = c(0, 580), xaxs = "i", yaxs = "i", axes = FALSE, ann = FALSE)
rect(2097.9 / 60, 0, 44.8, 580, col = tint, border = NA)
abline(h = seq(100, 500, 100), col = "#E6E6E6", lwd = 1)
lines(m, small, col = acc, lwd = 2.2); points(m, small, col = acc, pch = 16, cex = 0.75)
lines(m, large, col = blue, lwd = 2.2); points(m, large, col = blue, pch = 16, cex = 0.75)
axis(1, at = seq(0, 40, 5), labels = sprintf("%02d:00", seq(0, 40, 5)), col = grey, cex.axis = 1.0)
axis(2, at = seq(0, 500, 100), col = grey, cex.axis = 1.0)
mtext("minute of the Fed\u2019s press conference of 1 Feb 2023, as the video clock shows it", side = 1, line = 2.3, cex = 1.0)
mtext("words per minute", side = 2, line = 3.1, las = 0, cex = 1.0)
text(34.4, 505, "from 34:57 the small model repeats\n\u201cwe are going to be cautious about the fact that\u201d", adj = c(1, 0.5), cex = 1.0, col = acc)
arrows(34.5, 505, 36.2, 470, length = 0.08, col = acc, lwd = 1.3)
text(43.75, 40, "minute 44\nlasts 37 s", adj = c(1, 0.5), cex = 0.85, col = grey)
nw <- function(v) format(sum(v), big.mark = ",")
legend(0.5, 345, c(paste0("large model, ", nw(large), " words: replies/words.json, the table on the slides"),
                   paste0("small model, ", nw(small), " words: replies/words_base.json (base: the small size)")), col = c(blue, acc), lwd = 2.2, pch = 16,
       pt.cex = 0.75, bty = "n", cex = 1.0, y.intersp = 1.15)
box(bty = "l", col = grey)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f5_labels DEPS: data ====
# Slide 25 "Speaker labels across the conference". Top: the 86 labelled stretches of
# replies/speakers.rttm over the 44:37, one row per label (SPK00 on top,
# the rest in order of first appearance). Bottom: 915 to 935 s, the words
# with their times, the stretches, and the 3-s windows on the 1.5-s grid
# as tools/diarize_ecapa.py kept or dropped them. The energy gate is redone
# here on the full WAV (30-ms frames; a frame is speech when its energy is
# above 4 times the 20th percentile; a window is kept when more than half
# its frames are speech), which gives the tool's 1,566 kept windows. A
# kept window labels its middle 1.5 s. Canvas 9.6 x 5.6 in, at full width.
suppressPackageStartupMessages(library(tuneR))
wv <- readWave(file.path(dat, "data/media/fomc20230201.wav"))
x  <- wv@left / 32768
nf <- 480; n <- length(x) %/% nf                       # 30-ms frames at 16 kHz
en <- colMeans(matrix(x[1:(n * nf)]^2, nrow = nf))
sp <- en > max(quantile(en, 0.2, names = FALSE) * 4, 1e-6)
st <- seq(0, length(x) - 48000, by = 24000)           # a 3-s window every 1.5 s, in samples
share <- vapply(st, function(s) mean(sp[(s %/% nf + 1):((s + 48000) %/% nf)]), numeric(1))
win <- data.frame(start = st / 16000, share = share, kept = share > 0.5)
cat("windows kept:", sum(win$kept), "(the tool's log: 1566)\n")
rm(wv, x, en, sp)

canvas("f5-labels-timeline.png", 9.6, 5.6)
L <- 1.45; R <- 9.45
# -- top: the whole conference
tx <- function(s) L + s / 2677 * (R - L)
labs <- names(sort(tapply(seg$start, seg$speaker, min)))
ytop <- 5.15; ybot <- 3.6; rh <- (ytop - ybot) / length(labs)
ry <- ytop - (seq_along(labs) - 0.5) * rh
segments(L, ry, R, ry, col = "#EEEEEE", lwd = 0.8)
k <- match(seg$speaker, labs)
rect(tx(seg$start), ry[k] - rh * 0.4, tx(seg$end), ry[k] + rh * 0.4,
     col = ifelse(seg$speaker == "SPK00", blue, other), border = NA)
rect(tx(915), ybot, tx(935), ytop, border = acc, lwd = 1.3)
text(tx(925), ytop + 0.1, "zoom below", cex = 0.75, col = acc)
at <- c(seq(0, 2400, 300), 2677)
segments(tx(at), ybot, tx(at), ybot - 0.05, col = grey)
text(tx(at[-length(at)]), ybot - 0.18, clock(at[-length(at)]), cex = 0.85, col = grey)
text(tx(2677) + 0.1, ybot - 0.18, "44:37", adj = c(1, 0.5), cex = 0.85, col = grey)   # kept on the canvas
text(L - 0.1, ry[1], "SPK00", adj = c(1, 0.5), cex = 0.9, font = 2, col = blue)
segments(L - 0.08, ry[2] + rh * 0.4, L - 0.08, ry[length(ry)] - rh * 0.4, col = grey)
text(L - 0.16, mean(ry[-1]), "the other\n18 labels", adj = c(1, 0.5), cex = 0.85, col = grey)
text(0.1, 5.42, "86 labelled stretches over the 44:37 recording, one row per label", adj = c(0, 0.5),
     cex = 1.0, font = 2, col = ink)
rect(6.1, 5.36, 6.32, 5.48, col = blue, border = NA)
text(6.38, 5.42, "SPK00", adj = c(0, 0.5), cex = 0.85, col = ink)
rect(7.0, 5.36, 7.22, 5.48, col = other, border = NA)
text(7.28, 5.42, "other labels", adj = c(0, 0.5), cex = 0.85, col = ink)
rect(8.35, 5.36, 8.57, 5.48, col = "white", border = grey)
text(8.63, 5.42, "no label", adj = c(0, 0.5), cex = 0.85, col = ink)
# -- bottom: 915 to 935 s
zx <- function(s) L + (s - 915) / 20 * (R - L)
text(0.1, 3.1, "915 to 935 s (15:15 to 15:35 in the video)", adj = c(0, 0.5), cex = 1.0, font = 2, col = ink)
wz <- words[words$start >= 915 & words$end <= 935, ]
who <- ifelse(wz$start < 923, "p", ifelse(wz$start < 925, "m", "r"))
yw <- 2.3
rect(zx(wz$start), yw - 0.08, zx(wz$end), yw + 0.08, border = "white", lwd = 0.8,
     col = c(p = blue, m = acc, r = other)[who])
text(zx(922.69), 2.78, "Powell", adj = c(1, 0.5), cex = 0.8, col = grey)
text(zx(922.69), 2.56, "\u2026as having a lot of work left to do.", adj = c(1, 0.5), cex = 0.9, col = blue)
text(zx(924.01), 2.78, "the moderator", cex = 0.8, col = grey)
text(zx(924.01), 2.56, "Howard.", cex = 0.95, font = 2, col = acc)
text(zx(925.93), 2.78, "the reporter", adj = c(0, 0.5), cex = 0.8, col = grey)
text(zx(925.93), 2.56, "Howard Schneider with Reuters, and thanks\u2026", adj = c(0, 0.5), cex = 0.9, col = grey)
ys <- 1.75
rect(zx(915), ys - 0.14, zx(921.75), ys + 0.14, col = blue, border = NA)
text(zx(918.4), ys, "SPK00", cex = 0.85, col = "white", font = 2)
rect(zx(926.25), ys - 0.14, zx(935), ys + 0.14, col = other, border = NA)
text(zx(930.6), ys, "SPK07", cex = 0.85, col = "white", font = 2)
rect(zx(921.75), ys - 0.14, zx(926.25), ys + 0.14, col = tint, border = acc, lty = 2)
text(zx(924), ys, "no label, 4.5 s", cex = 0.85, col = acc)
ww <- win[win$start >= 915 & win$start + 3 <= 935, ]
for (i in seq_len(nrow(ww))) {
  s <- ww$start[i]; y <- if (i %% 2) 1.25 else 1.0
  mid <- s + 1.5
  lab <- seg$speaker[seg$start <= mid & seg$end >= mid]
  col <- if (!ww$kept[i]) acc else if (length(lab) && lab == "SPK00") blue else other
  lt  <- if (ww$kept[i]) 1 else 2
  b <- c(s + 0.06, s + 2.94)                              # a small inset between neighbours
  segments(zx(b[1]), y, zx(b[2]), y, col = col, lwd = 1.3, lty = lt)
  segments(zx(b), y - 0.06, zx(b), y + 0.06, col = col, lwd = 1.3)
  if (ww$kept[i]) segments(zx(s + 0.75), y, zx(s + 2.25), y, col = col, lwd = 6, lend = 1)
  else text(zx(mid), y + if (i %% 2) 0.13 else -0.13,
            sprintf("%d%% speech", round(100 * ww$share[i])), cex = 0.75, col = acc)
}
at <- seq(915, 935, 2.5)
segments(zx(at), 0.78, zx(at), 0.72, col = grey)
segments(L, 0.78, R, 0.78, col = grey)
text(zx(at), 0.58, at, cex = 0.85, col = grey)
text(L - 0.1, yw, "words", adj = c(1, 0.5), cex = 0.85, col = grey)
text(L - 0.1, ys, "labelled\nstretches", adj = c(1, 0.5), cex = 0.85, col = grey)
text(L - 0.1, 1.12, "3-s windows,\none every 1.5 s", adj = c(1, 0.5), cex = 0.85, col = grey)
text(L, 0.3, "seconds into the recording", adj = c(0, 0.5), cex = 0.85, col = grey)
text(R, 0.3, "thick: the middle 1.5 s that a kept window labels; red dashed: a window under half speech, dropped",
     adj = c(1, 0.5), cex = 0.8, col = grey)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f6_findinterval DEPS: setup ====
# Slide 26 "A speaker label for every word": the toy.
# Three stretches start at 0, 2 and 5 s; the four times 0.5, 2.1, 4.9, 7.0
# get findInterval(c(0.5, 2.1, 4.9, 7.0), c(0, 2, 5)) = 1 2 2 3. Stretch 3
# ends at 6.5 s, so 7.0 lies past its end, in a gap: the end check makes it NA.
# Canvas 9.6 x 2.4 in.
canvas("f6-findinterval.png", 9.6, 2.4)
nx <- function(s) 0.6 + s / 8 * 8.6
starts <- c(0, 2, 5); tm <- c(0.5, 2.1, 4.9, 7.0); ans <- findInterval(tm, starts)
band <- c("#E3ECF5", "#F2F2F2", "#E3ECF5")
ends <- c(2, 5, 6.5)                                     # stretch 3 ends at 6.5 s: a gap after it
for (i in 1:3) {
  rect(nx(starts[i]), 0.95, nx(ends[i]), 1.4, col = band[i], border = NA)
  text(nx(starts[i] + c(0.62, 0.22, 0.12)[i]), 1.175, sprintf("stretch %d", i), adj = c(0, 0.5), cex = 0.95, col = ink)
}
segments(nx(starts), 0.72, nx(starts), 1.4, col = blue, lwd = 2.4)
segments(nx(0), 0.8, nx(8), 0.8, col = grey, lwd = 1.2)
segments(nx(0:8), 0.8, nx(0:8), 0.74, col = grey)
text(nx(0:8), 0.55, 0:8, cex = 0.95, col = ifelse(0:8 %in% starts, blue, grey),
     font = ifelse(0:8 %in% starts, 2, 1))
text(nx(8), 0.25, "seconds", adj = c(1, 0.5), cex = 0.85, col = grey)
text(nx(0), 0.25, "blue: the three starts", adj = c(0, 0.5), cex = 0.85, col = blue)
segments(nx(6.5), 0.8, nx(6.5), 1.4, col = grey, lwd = 1.6)
text(nx(6.45), 1.53, "stretch 3 ends at 6.5", adj = c(1, 0.5), cex = 0.85, col = grey)
text(nx(7.12), 1.175, "gap: NA", adj = c(0, 0.5), cex = 0.95, font = 2, col = acc)
segments(nx(tm), 0.8, nx(tm), 1.72, col = acc, lty = 3, lwd = 1.2)
points(nx(tm), rep(0.8, 4), pch = 21, bg = acc, col = acc, cex = 1.4)
text(nx(tm) - 0.2, 1.95, sprintf("%.1f", tm), adj = c(1, 0.5), cex = 1.15, font = 2, col = acc)
arrows(nx(tm) - 0.15, 1.95, nx(tm) + 0.12, 1.95, length = 0.06, col = acc, lwd = 1.5)
text(nx(tm) + 0.18, 1.95, ans, adj = c(0, 0.5), cex = 1.15, font = 2, col = acc)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f8_pauses DEPS: data ====
# Slide 40 "The pause before every Powell answer": for each of the 26
# answers, the pause in the utterance table (start minus the previous
# turn's end, data_clean/utterances.csv) as a hollow dot, and the silence
# between words (the largest gap between consecutive words from the
# previous turn's end to the answer's first word, data_clean/words.rds) as
# a filled dot, computed as in code/6_pauses.R. Full width: canvas 9.6 x 4.1 in.
words$gap <- words$start - c(NA, words$end[-nrow(words)])
utt$words <- lengths(strsplit(utt$text, " "))
powell <- names(which.max(tapply(utt$words, utt$speaker, sum)))
utt$pause <- utt$start - c(NA, utt$end[-nrow(utt)])
rows <- which(utt$speaker == powell & !is.na(utt$pause))
sil <- sapply(rows, function(r) max(words$gap[words$start >= utt$end[r - 1] - 0.005 &
                                               words$start <= utt$start[r] + 0.005]))
a <- data.frame(start = utt$start[rows], pause = utt$pause[rows], silence = sil)
cat("answers:", nrow(a), " medians:", median(a$pause), median(a$silence), "\n")
png(file.path(out, "f8-pauses.png"), width = 9.6, height = 4.1, units = "in", res = 200)
par(mar = c(3.4, 4.4, 0.6, 0.8), family = "sans", las = 1, mgp = c(2.3, 0.55, 0), tck = -0.012)
plot(NA, xlim = c(380, 2700), ylim = c(-0.25, 7.3), xaxs = "i", yaxs = "i", axes = FALSE, ann = FALSE)
abline(h = 1:7, col = "#EEEEEE")
abline(h = median(a$pause), col = ink, lty = 2, lwd = 1.3)
abline(h = median(a$silence), col = blue, lty = 2, lwd = 1.3)
segments(a$start, a$pause, a$start, a$silence, col = rule, lwd = 1.4)
points(a$start, a$pause, pch = 21, bg = "white", col = ink, cex = 1.6, lwd = 1.4)
points(a$start, a$silence, pch = 16, col = blue, cex = 1.05)   # on top: where the two agree, a dot in a ring
top <- a[order(a$pause, decreasing = TRUE)[1:5], ]
side <- ifelse(top$start %in% a$start[c(which.max(a$start))], 2, 4)
text(top$start, top$pause, clock(top$start), pos = side, offset = 0.6, cex = 0.95, col = ink)
axis(1, at = seq(600, 2400, 300), labels = clock(seq(600, 2400, 300)), col = grey)
axis(2, at = 0:7, col = grey)
mtext("start of the answer, as the video clock shows it", side = 1, line = 2.3)
mtext("seconds before the answer", side = 2, line = 2.6, las = 0)
lx <- 1590; ly <- c(6.95, 6.62, 6.17, 5.84)
points(lx + 25, ly[1], pch = 21, bg = "white", col = ink, cex = 1.6, lwd = 1.4)
text(lx + 70, ly[1], sprintf("pause in the table, median %.2f s", median(a$pause)), adj = c(0, 0.5), cex = 0.92)
text(lx + 70, ly[2], "start minus the previous end (utterances.csv)", adj = c(0, 0.5), cex = 0.78, col = grey)
points(lx + 25, ly[3], pch = 16, col = blue, cex = 1.05)
text(lx + 70, ly[3], sprintf("silence between words, median %.2f s", median(a$silence)), adj = c(0, 0.5), cex = 0.92, col = blue)
text(lx + 70, ly[4], "the longest gap between words (words.rds)", adj = c(0, 0.5), cex = 0.78, col = grey)
text(lx + 70, 5.42, "dashed: the two medians", adj = c(0, 0.5), cex = 0.78, col = grey)
points(lx + 25, 5.07, pch = 21, bg = "white", col = ink, cex = 1.6, lwd = 1.4)
points(lx + 25, 5.07, pch = 16, col = blue, cex = 1.05)
text(lx + 70, 5.07, "a dot inside a ring: the two measures agree", adj = c(0, 0.5), cex = 0.78, col = grey)
box(bty = "l", col = grey)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f9_alignment DEPS: setup ====
# Slide 43 "Word-error rate on an eleven-word example": the reference over
# the model's words, lined up as adist() lines them up (its path
# MMMDMMMSMIMM), the three edits marked. Canvas 9.6 x 2.5 in.
ref <- strsplit("so we can now say that the process has really started", " ")[[1]]
hyp <- strsplit("so we can say that the processes has really really started", " ")[[1]]
vocab <- unique(c(ref, hyp))
d <- adist(intToUtf8(match(ref, vocab) + 1000), intToUtf8(match(hyp, vocab) + 1000), counts = TRUE)
ops <- strsplit(attr(d, "trafos")[1, 1], "")[[1]]
i <- 0; j <- 0; cr <- ch <- character(length(ops))
for (s in seq_along(ops)) {
  if (ops[s] %in% c("M", "S", "D")) { i <- i + 1; cr[s] <- ref[i] }
  if (ops[s] %in% c("M", "S", "I")) { j <- j + 1; ch[s] <- hyp[j] }
}
canvas("f9-alignment.png", 9.6, 2.5)
cxw <- 1.05
wd <- pmax(strwidth(cr, cex = cxw), strwidth(ch, cex = cxw)) + 0.13
x0 <- 1.12 + c(0, cumsum(wd + 0.04))[seq_along(wd)]
xm <- x0 + wd / 2
yr <- 1.85; yh <- 1.15; bh <- 0.46
for (s in seq_along(ops)) {
  e <- ops[s] != "M"
  if (ops[s] != "I") box_(xm[s], yr, wd[s], bh, col = if (e) tint else fill, border = if (e) acc else rule)
  else box_(xm[s], yr, wd[s], bh, col = "white", border = acc, lty = 2)
  if (ops[s] != "D") box_(xm[s], yh, wd[s], bh, col = if (e) tint else fill, border = if (e) acc else rule)
  else box_(xm[s], yh, wd[s], bh, col = "white", border = acc, lty = 2)
  text(xm[s], yr, cr[s], cex = cxw, col = ink); text(xm[s], yh, ch[s], cex = cxw, col = ink)
  if (e) {
    points(xm[s], 0.55, pch = 21, bg = acc, col = acc, cex = 3.2)
    text(xm[s], 0.55, ops[s], cex = 1.05, font = 2, col = "white")
  }
}
text(1.0, yr, "reference", adj = c(1, 0.5), cex = 1.0, col = ink)
text(1.0, yh, "model", adj = c(1, 0.5), cex = 1.0, col = ink)
xe <- max(x0 + wd)
s3 <- which(ops != "M")
text(xm[s3], 0.17, c(D = "deletion", S = "substitution", I = "insertion")[ops[s3]], cex = 0.85, col = acc)
text((xe + 9.6) / 2, 1.62, "3 / 11 = 0.27", cex = 1.35, font = 2, col = acc)
text((xe + 9.6) / 2, 1.25, "edits / reference\nwords", cex = 0.82, col = grey)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f10_spectrogram DEPS: setup ====
# Slide 9 "From samples to a picture of sound" (Part 1, the left column, 58%):
# the sound wave and the spectrogram of "Good afternoon", 6.62 to 7.46 s of
# data/clips/open2min.wav, the word times from replies/words.json. 25-ms
# windows (400 samples, Hamming) every 10 ms (160 samples), each through
# fft(); energy in decibels. One window, 7.40 to 7.425 s, is shaded. The
# amplitude is the raw 16-bit sample, as on the slide before. A key in the
# spectrogram's top left says what the shade means. At about 560
# px: canvas 7 x 4.6 in.
suppressPackageStartupMessages(library(tuneR))
a0 <- 6.62; a1 <- 7.46; N <- 400; hop <- 160
wv <- readWave(file.path(dat, "data/clips/open2min.wav"), from = a0 - 0.0125, to = a1 + 0.0125,
               units = "seconds")
x  <- wv@left; sr <- wv@samp.rate
t_x <- a0 - 0.0125 + (seq_along(x) - 1) / sr
st <- seq(1, length(x) - N + 1, by = hop)
hw <- 0.54 - 0.46 * cos(2 * pi * (0:(N - 1)) / (N - 1))
S  <- sapply(st, function(i) Mod(fft(x[i:(i + N - 1)] * hw))[1:(N / 2 + 1)])
db <- 20 * log10(S + 1e-9)
tt <- a0 - 0.0125 + (st - 1 + N / 2) / sr               # the centre of each window
ff <- (0:(N / 2)) * sr / N / 1000                       # kHz
w0 <- 7.40; w1 <- 7.425                                 # the window shaded
png(file.path(out, "f10-spectrogram.png"), width = 7, height = 4.6, units = "in", res = 200)
layout(matrix(1:2), heights = c(1.55, 3.05)); par(cex = 1)
par(mar = c(0.4, 5.8, 1.8, 0.6), family = "sans", las = 1, mgp = c(2.4, 0.55, 0), tck = -0.015)
keep <- t_x >= a0 & t_x <= a1
plot(t_x[keep], x[keep], type = "l", col = ink, lwd = 0.6, xlim = c(a0, a1), xaxs = "i",
     axes = FALSE, ann = FALSE)
rect(w0, par("usr")[3], w1, par("usr")[4], col = adjustcolor(blue, 0.25), border = blue, lwd = 0.8)
abline(v = 7.14, lty = 2, col = acc)
axis(2, col = grey, cex.axis = 1.0, at = c(-6000, 0, 6000))
mtext("amplitude", side = 2, line = 4.5, las = 0, cex = 1.05)
mtext("(sample value)", side = 2, line = 3.4, las = 0, cex = 0.9)
mtext(c("Good", "afternoon"), side = 3, line = 0.3, at = c((a0 + 7.14) / 2, (7.14 + a1) / 2),
      font = 2, col = acc, cex = 1.25)
par(mar = c(3.3, 5.8, 0.4, 0.6))
zl <- c(max(db) - 55, max(db))
image(tt, ff, t(pmax(db, zl[1])), zlim = zl, col = hcl.colors(60, "Grays", rev = TRUE),
      xlim = c(a0, a1), ylim = c(0, 8), xaxs = "i", yaxs = "i", axes = FALSE, ann = FALSE)
rect(w0, 0, w1, 8, col = adjustcolor(blue, 0.25), border = blue, lwd = 0.8)
text(w0 - 0.008, 7.25, "one window,\n25 ms", adj = c(1, 0.5), col = blue, cex = 1.0)
abline(v = 7.14, lty = 2, col = acc)
axis(1, at = seq(6.7, 7.4, 0.1), col = grey, cex.axis = 1.0)
axis(2, at = 0:8, col = grey, cex.axis = 1.0)
mtext("seconds into the recording", side = 1, line = 2.2, cex = 1.05)
mtext("frequency (kHz)", side = 2, line = 2.4, las = 0, cex = 1.05)
# the key: shade = energy on a log scale
rect(6.635, 6.2, 6.98, 7.88, col = "white", border = rule)
text(6.65, 7.6, "energy (log scale)", adj = c(0, 0.5), cex = 0.9, col = ink)
kx <- seq(6.65, 6.965, length.out = 61)
rect(kx[-61], 6.95, kx[-1], 7.25, col = hcl.colors(60, "Grays", rev = TRUE), border = NA)
text(6.65, 6.62, "less", adj = c(0, 0.5), cex = 0.85, col = grey)
text(6.965, 6.62, "darker = more", adj = c(1, 0.5), cex = 0.85, col = grey)
box(col = grey)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f11_when_labels DEPS: setup ====
# Slide 21 "When a speaker-label model is needed": two rows. One voice goes
# through the speech-to-text model alone and gives words with their times;
# several voices go through it and the speaker-label model and give who
# said what, when. Canvas 9.6 x 2.0 in, at 80% width.
canvas("f11-when-labels.png", 9.6, 2.0)
row <- function(y, input, sub, model, out, hot = FALSE) {
  box_(1.3, y, 2.45, 0.72)
  text(1.3, y + 0.12, input, cex = 1.15, font = 2, col = ink)
  text(1.3, y - 0.16, sub, cex = 0.85, col = grey)
  box_(4.9, y, 3.4, 0.72)
  text(4.9, y, model, cex = 1.05, col = ink)
  box_(8.3, y, 2.3, 0.72, col = if (hot) tint else fill, border = if (hot) acc else rule)
  text(8.3, y, out, cex = 1.1, font = 2, col = if (hot) acc else ink)
  arr(2.6, y, 3.12, y); arr(6.67, y, 7.08, y)
}
row(1.5, "one voice", "a lecture, a read statement", "speech-to-text model", "words with times")
row(0.5, "several voices", "a press conference, an interview",
    "speech-to-text model\n+ speaker-label model", "who said what, when", hot = TRUE)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f12_storage DEPS: setup ====
# Slide 8 "How sound is stored": the microphone, the samples at 16 kHz, and
# the sizes of the project's own files written both ways: the 2-min clip
# (data/clips/open2min.wav and .mp3) and the whole conference
# (data/media/fomc20230201.wav, and the AAC sound track inside the Fed's
# video, copied out with ffmpeg -vn -c:a copy). Full width at 88%: canvas
# 9.6 x 2.7 in.
mb <- function(bytes) { x <- bytes / 1e6; sprintf(if (x < 10) "%.2f MB" else "%.1f MB", x) }
aac <- file.path(tempdir(), "fomc20230201_aac.m4a")
system2("ffmpeg", c("-hide_banner", "-loglevel", "error", "-y", "-i",
                    file.path(dat, "data/media/fomc20230201_270p.mp4"), "-vn", "-c:a", "copy", aac))
size <- c(clip_wav = file.size(file.path(dat, "data/clips/open2min.wav")),
          clip_mp3 = file.size(file.path(dat, "data/clips/open2min.mp3")),
          conf_wav = file.size(file.path(dat, "data/media/fomc20230201.wav")),
          conf_aac = file.size(aac))
canvas("f12-storage.png", 9.6, 2.7)
# the microphone: a rounded capsule with a grille, a stem and a base
mx <- 0.7; r <- 0.27
th <- seq(0, pi, length.out = 40)
polygon(c(mx + r * cos(th), mx - r * cos(th)), c(2.05 + r * sin(th), 1.6 - r * sin(th)),
        col = fill, border = grey, lwd = 1.4)
segments(mx - r, seq(1.55, 2.1, 0.11), mx + r, seq(1.55, 2.1, 0.11), col = rule)
segments(mx, 1.33, mx, 1.12, col = grey, lwd = 2); segments(mx - 0.25, 1.12, mx + 0.25, 1.12, col = grey, lwd = 2)
text(mx, 0.85, "microphone", cex = 1.05, font = 2, col = ink)
text(mx, 0.52, "air pressure\nto a voltage", cex = 0.85, col = grey)
arr(1.15, 1.8, 1.7, 1.8)
# the samples: a wave read at regular times
x0 <- 1.85; x1 <- 4.5; y0 <- 1.8
tx <- seq(x0, x1, length.out = 400)
wave <- function(t) y0 + 0.4 * sin(2 * pi * (t - x0) / 1.1) + 0.15 * sin(2 * pi * (t - x0) / 0.37)
lines(tx, wave(tx), col = rule, lwd = 1.4)
ts <- seq(x0 + 0.05, x1 - 0.05, length.out = 27)
segments(ts, y0, ts, wave(ts), col = blue, lwd = 1.2); points(ts, wave(ts), pch = 16, cex = 0.55, col = blue)
segments(x0, y0, x1, y0, col = grey, lwd = 0.8)
text((x0 + x1) / 2, 2.5, "16,000 samples a second", cex = 1.05, font = 2, col = ink)
text((x0 + x1) / 2, 0.85, "sample: one reading of the voltage, a whole", cex = 0.85, col = grey)
text((x0 + x1) / 2, 0.6, "number from -32,768 to 32,767 (16 bits, 2 bytes)", cex = 0.85, col = grey)
arr(4.65, 1.8, 5.15, 1.8)
# the sizes, written both ways
cl <- 5.3; cw <- 7.75; cc <- 8.85
rect(cc - 0.62, 0.7, cc + 0.62, 2.66, col = tint, border = NA)
text(cl, 2.47, "the Fed's press conference", cex = 0.85, col = ink, adj = c(0, 0.5))
text(cl, 2.24, "of 1 Feb 2023", cex = 0.85, col = ink, adj = c(0, 0.5))
text(cw, 2.47, "WAV", cex = 1.05, font = 2, col = ink)
text(cw, 2.2, "every sample", cex = 0.82, col = grey)
text(cc, 2.47, "MP3, AAC", cex = 1.05, font = 2, col = acc)
text(cc, 2.2, "compressed", cex = 0.82, col = grey)
segments(cl, 2.02, 9.5, 2.02, col = rule)
text(cl, 1.72, "the opening, 2:00", cex = 0.95, col = ink, adj = c(0, 0.5))
text(cl, 1.5, "data/clips/open2min", cex = 0.78, col = grey, adj = c(0, 0.5), family = "mono")
text(cw, 1.62, mb(size["clip_wav"]), cex = 1.0, col = ink)
text(cc, 1.62, paste(mb(size["clip_mp3"]), "MP3"), cex = 1.0, col = acc)
segments(cl, 1.3, 9.5, 1.3, col = rule)
text(cl, 1.0, "the conference, 44:37", cex = 0.95, col = ink, adj = c(0, 0.5))
text(cl, 0.78, "data/media/fomc20230201", cex = 0.78, col = grey, adj = c(0, 0.5), family = "mono")
text(cw, 0.9, mb(size["conf_wav"]), cex = 1.0, col = ink)
text(cc, 0.9, paste(mb(size["conf_aac"]), "AAC"), cex = 1.0, col = acc)
text(cl, 0.4, "AAC: the sound track of the Fed's video, 48,000 samples a second,", cex = 0.78, col = grey, adj = c(0, 0.5))
text(cl, 0.18, "stereo (two channels). WAV: 16,000 a second, mono (one channel).", cex = 0.78, col = grey, adj = c(0, 0.5))
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: flow DEPS: setup ====
# A row of boxes joined by arrows, for the two study slides of Part 2. Each
# step is list(head, body, model = FALSE); a model step gets the blue border
# of the pipeline figure.
flow <- function(name, steps, w = 9.6, h = 2.3, below = NULL) {
  canvas(name, w, h)
  n <- length(steps); gap <- 0.32; bw <- (w - 0.2 - gap * (n - 1)) / n
  xs <- 0.1 + bw / 2 + (0:(n - 1)) * (bw + gap); y <- if (is.null(below)) h / 2 else h / 2 + 0.25
  for (i in seq_len(n)) {
    st <- steps[[i]]; m <- isTRUE(st$model)
    box_(xs[i], y, bw, 1.45, col = if (m) "white" else fill, border = if (m) blue else rule, lwd = if (m) 1.8 else 1.2)
    text(xs[i], y + 0.45, st$head, cex = 0.9, font = 2, col = if (m) blue else ink)
    text(xs[i], y - 0.12, st$body, cex = 0.78, col = ink)
    if (i < n) arr(xs[i] + bw / 2 + 0.03, y, xs[i + 1] - bw / 2 - 0.03, y)
  }
  if (!is.null(below)) text(w / 2, 0.22, below, cex = 0.8, col = grey)
  dev.off()
}
# ==== END BLOCK ====

# ==== BLOCK: f16_asr_study DEPS: flow ====
# Slide "Machine transcripts of political speech" (Part 2, full width at
# 90%): Proksch, Wratil & Waeckerle (Political Analysis, 2019). From the
# paper: word-error rates on the 2011 European Parliament State of the Union
# debate (English; French and German higher), the two applications (2017
# Austrian TV debates, EU Council budget talks), and the conclusion that ASR
# or human transcripts make no substantive difference to the results. Each
# speaker's speech is pooled into one document before Wordfish (Slapin and
# Proksch 2008) scales it. Canvas 9.6 x 2.3 in.
flow("f16-asr-study.png", list(
  list(head = "recordings", body = "speech nobody types:\nAustrian TV debates,\nEU Council talks"),
  list(head = "speech recognition", body = "YouTube's automatic\ncaptions", model = TRUE),
  list(head = "transcripts", body = "each speaker's\nwords pooled\ninto one text"),
  list(head = "word counts", body = "one row per speaker,\none column per word"),
  list(head = "Wordfish", body = "places each speaker\non one scale from\nthe words they use", model = TRUE)),
  below = "Checked on a 2011 European Parliament debate: the positions from machine transcripts track those from human ones.")
# ==== END BLOCK ====

# ==== BLOCK: f17_bodycam_study DEPS: flow ====
# Slide "Police body-camera footage as data" (Part 2, full width at 90%):
# Voigt et al. (PNAS, 2017), from the paper: 981 stops by 245 Oakland police
# officers in April 2014, 183 hours; professional transcribers typed each
# stop and labelled who spoke when; 70 participants rated 414 officer
# utterances, not told the driver's race; the model scored 36,738.
# Canvas 9.6 x 2.0 in.
flow("f17-bodycam-study.png", list(
  list(head = "body-camera video", body = "981 traffic stops,\n245 officers, Oakland,\nApril 2014, 183 hours"),
  list(head = "transcripts", body = "typed by professionals,\nwith who spoke when"),
  list(head = "people rate", body = "70 people rate 414\nofficer utterances,\nnot told the race"),
  list(head = "a model", body = "learns the ratings;\nscores all 36,738\nofficer utterances", model = TRUE),
  list(head = "compared", body = "by the driver's race;\nofficer's race, offense,\nplace, outcome fixed")), h = 2.0)
# ==== END BLOCK ====

# ==== BLOCK: f15a_wave DEPS: setup ====
# Slide "Sound is a wave" (Part 1, full width at 88%): a vibrating source
# pushes the air into bands of high and low pressure that travel away from
# it. Top: air molecules at one instant, each displaced from an even grid by
# 0.8 / k * sin(k x), so they bunch where the pressure is high. Bottom: the
# pressure along the same line. Three wavelengths; at 145 Hz in air at 20 C
# one wavelength is 343 / 145 = 2.4 m. Canvas 9.6 x 3.0 in.
canvas("f15a-wave.png", 9.6, 3.0)
x0 <- 1.5; x1 <- 9.3; lam <- (x1 - x0) / 3; k <- 2 * pi / lam
# the source: a membrane that moves back and forth
rect(0.3, 0.55, 0.45, 2.6, col = grey, border = NA)
arrows(0.1, 2.82, 0.65, 2.82, length = 0.07, code = 3, col = acc, lwd = 1.6)
text(0.1, 0.32, "vibrating object", cex = 0.85, col = ink, adj = c(0, 0.5))
# the air: rows of molecules, bunched at high pressure
set.seed(19)
xe <- seq(x0 - 0.2, x1 + 0.2, by = 0.055)
for (r in 1:6) {
  xr <- xe + 0.8 / k * sin(k * (xe - x0)) + runif(length(xe), -0.008, 0.008)
  keep <- xr > x0 & xr < x1
  points(xr[keep], 2.0 + 0.11 * r + runif(sum(keep), -0.02, 0.02), pch = 16, cex = 0.32, col = blue)
}
xh <- x0 + lam / 2; xl <- x0 + lam
text(xh, 2.86, "high pressure", cex = 0.85, col = acc)
text(xl, 2.86, "low pressure", cex = 0.85, col = grey)
arr(x1 - 1.6, 1.82, x1 - 0.1, 1.82, col = ink)
text(x1 - 1.7, 1.82, "travels at 343 m/s in air", cex = 0.85, col = ink, adj = c(1, 0.5))
# the pressure along the same line
ym <- 1.0; amp <- 0.42
xs <- seq(x0, x1, length.out = 600)
segments(x0, ym, x1, ym, col = rule, lty = 2)
lines(xs, ym - amp * cos(k * (xs - x0)), col = ink, lwd = 1.6)
text(x0 - 0.1, ym + 0.33, "air", cex = 0.85, col = grey, adj = c(1, 0.5))
text(x0 - 0.1, ym + 0.12, "pressure", cex = 0.85, col = grey, adj = c(1, 0.5))
# one wavelength, crest to crest
c1 <- x0 + lam / 2; c2 <- c1 + lam
segments(c(c1, c2), ym + amp + 0.05, c(c1, c2), ym + amp + 0.2, col = acc, lwd = 1.2)
arrows(c1, ym + amp + 0.13, c2, ym + amp + 0.13, length = 0.07, code = 3, col = acc, lwd = 1.4)
text((c1 + c2) / 2, ym + amp + 0.27, "one wavelength: 2.4 m at 145 Hz", cex = 0.85, col = acc)
# the amplitude, from normal pressure to a crest
xa <- x0 + 2.5 * lam
arrows(xa, ym, xa, ym + amp, length = 0.06, code = 3, col = blue, lwd = 1.4)
text(xa + 0.12, ym + amp + 0.14, "amplitude", cex = 0.85, col = blue, adj = c(0, 0.5))
text((x0 + x1) / 2, 0.3, "A microphone at one spot feels the pressure rise and fall: 145 times a second at 145 Hz.",
     cex = 0.85, col = grey)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f15b_travel DEPS: setup ====
# Slide "How sound travels" (Part 1, full width at 88%). Left: the speed of
# sound at 20 C (air 343 m/s, helium 1,007, fresh water 1,481; none in a
# vacuum) and the wavelength of a 145 Hz voice in each. Right: a source
# moving right at half the speed of sound, with the crests it sent out
# at six past moments: bunched ahead, spread behind. The numbers: a 145 Hz
# hum on a car at 30 m/s is heard at 145 * 343 / (343 - 30) = 159 Hz ahead,
# 145 * 343 / (343 + 30) = 133 Hz behind. Canvas 9.6 x 2.8 in.
canvas("f15b-travel.png", 9.6, 2.8)
# left: the speed by medium
text(0.2, 2.6, "speed of sound", cex = 1.0, font = 2, col = ink, adj = c(0, 0.5))
med <- c("air", "helium", "water"); v <- c(343, 1007, 1481)
yb <- c(2.05, 1.5, 0.95); bx <- 1.05; sc <- 1.9 / 1500
rect(bx, yb - 0.16, bx + v * sc, yb + 0.16, col = blue, border = NA)
text(bx - 0.1, yb, med, cex = 0.95, col = ink, adj = c(1, 0.5))
text(bx + v * sc + 0.08, yb + 0.06, paste(format(v, big.mark = ","), "m/s"), cex = 0.9, col = ink, adj = c(0, 0.5))
text(bx + v * sc + 0.08, yb - 0.13, sprintf("wavelength at 145 Hz: %.1f m", v / 145), cex = 0.75, col = grey, adj = c(0, 0.5))
text(0.2, 0.45, "vacuum: no sound, nothing to carry it", cex = 0.9, col = ink, adj = c(0, 0.5))
segments(4.95, 0.25, 4.95, 2.7, col = rule)
# right: a moving source
text(5.2, 2.6, "a moving source", cex = 1.0, font = 2, col = ink, adj = c(0, 0.5))
sx <- 7.85; sy <- 1.45; cs <- 0.45; vs <- 0.5 * cs; th <- seq(0, 2 * pi, length.out = 200)
for (age in seq(0.3, 1.8, 0.3)) {
  cx <- sx - vs * age; rr <- cs * age
  lines(cx + rr * cos(th), sy + rr * sin(th), col = blue, lwd = 1.1)
}
points(sx, sy, pch = 16, cex = 1.3, col = acc)
arr(sx + 0.1, sy, sx + 0.5, sy, col = acc, lwd = 1.8)
text(9.4, 0.4, "ahead: crests bunched,\nhigher pitch (159 Hz)", cex = 0.8, col = ink, adj = c(1, 0.5))
text(5.25, 0.4, "behind: crests spread,\nlower pitch (133 Hz)", cex = 0.8, col = ink, adj = c(0, 0.5))
text(7.3, 2.6, "a 145 Hz hum on a car at 30 m/s", cex = 0.8, col = grey, adj = c(0, 0.5))
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: voice DEPS: setup ====
# Shared by f13a, f13b and f13c: Chair Powell's "afternoon", 7.32 to 7.42 s
# of data/clips/open2min.wav (100 ms, 1,600 samples, about 14 cycles), a
# stretch where his voice is steady (the onset of "Good", 7.05 s, is too
# irregular to show one cycle). The spectrum of the same 100 ms: Hamming
# window, zero-padded to 16,384 points, 0 to 2,000 Hz, in dB above its
# quietest point in that range, so nothing is negative. f0 is the first peak
# within 10 dB of the strongest (about 145 Hz); dotted lines mark 2, 3, 4 ...
# times f0. Each canvas is 8.5 in wide, for full width at 90%.
suppressPackageStartupMessages(library(tuneR))
v0 <- 7.32; v1 <- 7.42
wv <- readWave(file.path(dat, "data/clips/open2min.wav"), from = v0, to = v1, units = "seconds")
x  <- wv@left; sr <- wv@samp.rate; n <- length(x)
tx <- v0 + (seq_along(x) - 1) / sr
nf <- 16384
hw <- 0.54 - 0.46 * cos(2 * pi * (0:(n - 1)) / (n - 1))
S  <- Mod(fft(c((x - mean(x)) * hw, rep(0, nf - n))))[1:(nf / 2 + 1)]
fq <- (0:(nf / 2)) * sr / nf
sh <- fq <= 2000
db <- 20 * log10(S); db <- db - min(db[sh])               # dB above the quietest point shown
k  <- which(fq > 50 & sh)
pk <- k[db[k] > db[k - 1] & db[k] > db[k + 1]]
f0 <- fq[pk[db[pk] > max(db[sh]) - 10][1]]
hk <- 1:floor(2000 / f0)
pkd <- sapply(hk, function(h) max(db[abs(fq - h * f0) < f0 / 4]))
cat(sprintf("voice: f0 = %.1f Hz, one cycle = %.2f ms, about %.0f cycles; samples %d to %d; peak %.1f dB above the floor\n",
            f0, 1000 / f0, (v1 - v0) * f0, min(x), max(x), max(db[sh])))
# the wave, shared by f13a and f13b
wave_panel <- function(main, ylo = -7400) {
  par(mar = c(3.3, 5.6, 1.9, 0.8), family = "sans", las = 1, mgp = c(2.4, 0.55, 0), tck = -0.015)
  plot(tx, x, type = "l", col = ink, lwd = 1, xlim = c(v0, v1), ylim = c(ylo, 6000),
       xaxs = "i", axes = FALSE, ann = FALSE)
  abline(h = 0, col = rule, lty = 2)
  at <- seq(7.32, 7.42, by = 0.02)
  axis(1, at = at, labels = sprintf("%.2f", at), col = grey, cex.axis = 1.0)
  axis(2, at = c(-4000, 0, 4000), labels = c("-4,000", "0", "4,000"), col = grey, cex.axis = 1.0)
  mtext("seconds into the recording", side = 1, line = 2.2, cex = 1.05)
  mtext("amplitude", side = 2, line = 4.3, las = 0, cex = 1.05)
  mtext(main, side = 3, line = 0.5, adj = 0, font = 2, cex = 1.1, col = ink)
  box(col = grey, bty = "l")
}
# ==== END BLOCK ====

# ==== BLOCK: f13a_amplitude DEPS: voice ====
# Slide "Loudness is amplitude" (Part 1, full width at 90%): the 100 ms of
# "afternoon", the amplitude marked from rest (0) to the highest crest.
# Canvas 8.5 x 2.6 in.
png(file.path(out, "f13a-amplitude.png"), width = 8.5, height = 2.6, units = "in", res = 200)
wave_panel("100 ms of Powell's \"afternoon\", 7.32 to 7.42 s")
ja <- which.max(x)
arrows(tx[ja] + 0.0008, 0, tx[ja] + 0.0008, x[ja], length = 0.07, code = 3, col = acc, lwd = 1.8)
text(tx[ja] - 0.0012, x[ja] + 900, "amplitude, heard as loudness", adj = c(1, 0.5), col = acc, cex = 1.0)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f13b_pitch DEPS: voice ====
# Slide "Pitch is frequency" (Part 1, full width at 90%): the same 100 ms,
# one cycle marked trough to trough, 1 / f0.
# Canvas 8.5 x 2.6 in.
png(file.path(out, "f13b-pitch.png"), width = 8.5, height = 2.6, units = "in", res = 200)
wave_panel("100 ms of Powell's \"afternoon\", 7.32 to 7.42 s", ylo = -8900)
tr <- which(tx > 7.345 & tx < 7.352); t1 <- tx[tr][which.min(x[tr])]
segments(c(t1, t1 + 1 / f0), -4700, c(t1, t1 + 1 / f0), -6300, col = blue, lwd = 1.3)
arrows(t1, -6000, t1 + 1 / f0, -6000, length = 0.06, code = 3, col = blue, lwd = 1.7)
text(t1, -7700, sprintf("one cycle, %.1f ms: the pitch, %.0f Hz (cycles a second)", 1000 / f0, f0),
     adj = c(0, 0.5), col = blue, cex = 1.0)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f13c_timbre DEPS: voice ====
# Slide "Timbre is the mix of overtones" (Part 1, full width at 90%): the
# spectrum of the same 100 ms, 0 to 2,000 Hz, in dB above its quietest point;
# f0 to 4f0 labelled, the 85 to 180 Hz band of a man's pitch shaded.
# Canvas 8.5 x 2.6 in.
png(file.path(out, "f13c-timbre.png"), width = 8.5, height = 2.6, units = "in", res = 200)
par(mar = c(3.3, 5.6, 1.9, 1.6), family = "sans", las = 1, mgp = c(2.4, 0.55, 0), tck = -0.015)
top <- 110
plot(fq[sh], db[sh], type = "n", xlim = c(0, 2000), ylim = c(-3, top),
     xaxs = "i", yaxs = "i", axes = FALSE, ann = FALSE)
rect(85, -3, 180, 78, col = fill, border = NA)
segments(hk * f0, -3, hk * f0, pkd, col = adjustcolor(blue, 0.45), lty = 3)
lines(fq[sh], db[sh], col = ink, lwd = 1.1)
axis(1, at = seq(0, 2000, 250), labels = format(seq(0, 2000, 250), big.mark = ","), col = grey, cex.axis = 1.0)
axis(2, at = seq(0, 80, 20), col = grey, cex.axis = 1.0)
mtext("frequency (Hz)", side = 1, line = 2.2, cex = 1.05)
mtext("energy (dB above", side = 2, line = 4.0, las = 0, cex = 1.0)
mtext("the quietest point)", side = 2, line = 2.9, las = 0, cex = 1.0)
mtext("energy at each frequency, Powell's \"afternoon\", 7.32 to 7.42 s", side = 3, line = 0.5, adj = 0,
      font = 2, cex = 1.1, col = ink)
text(f0 * 1:4, pkd[1:4] + 7, c(expression(f[0]), expression(2 * f[0]), expression(3 * f[0]), expression(4 * f[0])),
     col = c(acc, blue, blue, blue), font = 2, cex = 1.0)
text(205, 102, sprintf("the pitch, %.0f Hz", f0), adj = c(0, 0.5), col = acc, cex = 0.95)
text(205, 91, "shaded: a man's pitch, 85 to 180 Hz", adj = c(0, 0.5), col = grey, cex = 0.95)
text(1980, 102, "overtones at 2, 3, 4 ... times the pitch;", adj = c(1, 0.5), col = blue, cex = 0.95)
text(1980, 91, "which are strong is the timbre", adj = c(1, 0.5), col = blue, cex = 0.95)
box(col = grey, bty = "l")
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: f14_transcript_recording DEPS: setup ====
# Slide 13 "When a transcript is not enough" (Part 2, at 80%): what a typed
# transcript gives against what the recording adds, as two boxes side by
# side. Canvas 9.6 x 1.2 in.
canvas("f14-transcript-recording.png", 9.6, 1.2)
box_(2.35, 0.6, 4.55, 1.05)
text(2.35, 0.82, "the transcript gives", cex = 1.15, font = 2, col = ink)
text(2.35, 0.4, "the words, edited  ·  who speaks", cex = 1.05, col = ink)
box_(7.25, 0.6, 4.55, 1.05, col = tint, border = acc)
text(7.25, 0.82, "the recording adds", cex = 1.15, font = 2, col = acc)
text(7.25, 0.4, "a time on every word  ·  “um”, restarts  ·  the sound", cex = 1.05, col = ink)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: cap_fomc1993 DEPS: setup ====
# Slide 14 "FOMC meeting transcripts as data on deliberation": the top of the
# first page of the transcript of the FOMC meeting of November 16, 1993, at
# 150 dpi. The PDF's page 1 is the attendance list; the transcript, with
# its speaker tags, starts on the PDF's page 3, which is rendered here.
# From federalreserve.gov/monetarypolicy/fomchistorical1993.htm.
f93 <- file.path(tempdir(), "FOMC19931116meeting.pdf")
if (!file.exists(f93))
  download.file("https://www.federalreserve.gov/monetarypolicy/files/FOMC19931116meeting.pdf",
                f93, mode = "wb", quiet = TRUE, headers = c("User-Agent" = "Mozilla/5.0"))
# Cut to the title and the first two speaker turns (CHAIRMAN GREENSPAN, MR.
# MATTINGLY), so the capture fills its column beside the slide's list.
pg <- pdf_render_page(f93, page = 3, dpi = 150, numeric = TRUE)
writePNG(pg[195:1105, 125:1130, ], file.path(out, "cap-fomc1993-p1.png"))
# ==== END BLOCK ====

# ==== BLOCK: cap_fed_page DEPS: setup ====
# Page only, "Where recordings come from" (after slide 15): the Fed's page for the conference, with the embedded
# player and the Transcript (PDF) link, by headless Chrome at 1200 px wide,
# light theme (the site's only one), cut below "Last Update".
shot <- file.path(tempdir(), "fedpage.png")
system2("/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
        c("--headless=new", paste0("--screenshot=", shot), "--window-size=1200,2000",
          "--force-device-scale-factor=1", "--virtual-time-budget=15000", "--hide-scrollbars",
          paste0("--user-data-dir=", tempfile("chrome")),
          "https://www.federalreserve.gov/monetarypolicy/fomcpresconf20230201.htm"),
        stdout = FALSE, stderr = FALSE)
im <- readPNG(shot)
writePNG(im[1:825, , ], file.path(out, "cap-fed-page.png"))
# ==== END BLOCK ====

# ==== BLOCK: cap_terminal_live DEPS: setup ====
# Page only, "The Python route" under slide 33 "Other routes, more complex";
# the second fallback of slide 32's live run: the terminal after a rehearsal of the Python route,
# drawn from data/19-audio/logs/live_run.txt (its comment lines left out),
# long lines wrapped at 118 columns as a terminal wraps them. Canvas 9.6 in
# wide, as tall as the text. The cairo device, whose font fallback draws
# the full-width punctuation in mlx-whisper's Args line (the quartz device
# draws empty boxes there).
txt <- readLines(file.path(dat, "logs/live_run.txt"), encoding = "UTF-8", warn = FALSE)
txt <- txt[!grepl("^#", txt)]
txt <- txt[cumsum(nzchar(txt)) > 0]                       # drop the blank line at the top
txt <- txt[rev(cumsum(rev(nzchar(txt)))) > 0]             # and any at the bottom
cols <- 118
# wrap at 118 terminal columns; a full-width character takes two
wrapw <- function(l) {
  if (!nzchar(l)) return("")
  ch <- strsplit(l, "")[[1]]; w <- nchar(ch, type = "width")
  out <- character(); cur <- ""; used <- 0
  for (i in seq_along(ch)) {
    if (used + w[i] > cols) { out <- c(out, cur); cur <- ""; used <- 0 }
    cur <- paste0(cur, ch[i]); used <- used + w[i]
  }
  c(out, cur)
}
pieces <- lapply(txt, wrapw)
wrap <- unlist(pieces)
cmd  <- rep(grepl("^\\$|^    --", txt), lengths(pieces))   # the typed lines, in green
lh <- 0.158; h <- length(wrap) * lh + 0.36
canvas("cap-terminal-live.png", 9.6, h, type = "cairo")
rect(0, 0, 9.6, h, col = "#1E1E1E", border = NA)
cx <- 9.1 / strwidth(strrep("M", cols), family = "mono")
y <- h - 0.18 - (seq_along(wrap) - 0.5) * lh
text(0.15, y, wrap, adj = c(0, 0.5), family = "mono", cex = cx,
     col = ifelse(cmd, "#9FD39F", "#D8D8D8"))
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: cap_terminal_r DEPS: setup ====
# Slide 32 "The 30-second clip transcribed in R", its first fallback (on the page): the R
# console after the rehearsal of the live run, drawn from
# data/19-audio/logs/live_run_r.txt (its comment lines left out), long lines
# wrapped at 118 columns as a console wraps them; the typed lines, which
# start with "> ", in green. Canvas 9.6 in wide, as tall as the text.
txt <- readLines(file.path(dat, "logs/live_run_r.txt"), encoding = "UTF-8", warn = FALSE)
txt <- txt[!grepl("^#", txt)]
txt <- txt[cumsum(nzchar(txt)) > 0]                       # drop the blank line at the top
txt <- txt[rev(cumsum(rev(nzchar(txt)))) > 0]             # and any at the bottom
cols <- 118
wrapr <- function(l) {
  if (!nzchar(l)) return("")
  n <- nchar(l); substring(l, seq(1, n, cols), pmin(seq(1, n, cols) + cols - 1, n))
}
pieces <- lapply(txt, wrapr)
wrap <- unlist(pieces)
cmd  <- rep(grepl("^> ", txt), lengths(pieces))
lh <- 0.158; h <- length(wrap) * lh + 0.36
canvas("cap-terminal-live-r.png", 9.6, h, type = "cairo")
rect(0, 0, 9.6, h, col = "#1E1E1E", border = NA)
cx <- 9.1 / strwidth(strrep("M", cols), family = "mono")
y <- h - 0.18 - (seq_along(wrap) - 0.5) * lh
text(0.15, y, wrap, adj = c(0, 0.5), family = "mono", cex = cx,
     col = ifelse(cmd, "#9FD39F", "#D8D8D8"))
dev.off()
# ==== END BLOCK ====
