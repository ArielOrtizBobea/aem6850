# Figures for the session 21 page and slides (photographs: vision models and measurement).
# Base R, magick and jpeg. Run from fall-2026/sessions:
#   Rscript _figures-21.R                   # every block
#   Rscript _figures-21.R pixels_to_answer  # setup, then one block
# Writes figures/21-photos/*. Inputs: data/21-photos/ (the session project).
#
# Each canvas is set in inches (1 user unit = 1 inch, origin bottom left) and
# drawn at res 200, sized so that 1 inch is about 100 px on the 1050 x 700
# slide, so cex 1.2 prints at about 20 px.

# ---- Run named blocks only: Rscript _figures-21.R <block> [<block> ...] ----
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
suppressPackageStartupMessages({ library(magick); library(jpeg) })
out  <- "figures/21-photos"
dat  <- "data/21-photos"
dir.create(out, showWarnings = FALSE, recursive = TRUE)
ink  <- "#222222"; acc <- "#B31B1B"; grey <- "#666666"; rule <- "#BBBBBB"
fill <- "#F2F2F2"; blue <- "#3A6C9C"
canvas <- function(name, w, h, type = getOption("bitmapType")) {
  # type = "cairo" when the figure prints an arrow glyph: the quartz sans font has none
  png(file.path(out, name), width = w, height = h, units = "in", res = 200, type = type)
  par(mar = c(0, 0, 0, 0), family = "sans")
  plot.new(); plot.window(xlim = c(0, w), ylim = c(0, h), xaxs = "i", yaxs = "i")
}
box_ <- function(x, y, w, h, col = fill, border = rule, lwd = 1.2)
  rect(x - w / 2, y - h / 2, x + w / 2, y + h / 2, col = col, border = border, lwd = lwd)
arr <- function(x0, y0, x1, y1, col = grey, lwd = 1.5)
  arrows(x0, y0, x1, y1, length = 0.1, col = col, lwd = lwd)
# Wrap a sentence to a width in inches (user units are inches on every canvas).
wrap_in <- function(txt, w, cex = 1) {
  words <- strsplit(txt, " ")[[1]]; lines <- character(); cur <- ""
  for (wd in words) {
    nxt <- if (nzchar(cur)) paste(cur, wd) else wd
    if (strwidth(nxt, cex = cex) > w && nzchar(cur)) { lines <- c(lines, cur); cur <- wd } else cur <- nxt
  }
  c(lines, cur)
}
# Several lines centred on (x, y); lh is the line height in inches.
ltext <- function(x, y, lines, cex = 1, lh = 0.19 * cex / 0.9, col = ink, font = 1, adj = 0.5) {
  n <- length(lines); ys <- y + ((n - 1) / 2 - (seq_len(n) - 1)) * lh
  text(x, ys, lines, cex = cex, col = col, font = font, adj = adj)
  invisible(n * lh)
}
street <- file.path(dat, "data/street/porlamar.jpg")
tile   <- function(d) file.path(dat, "data_clean/tiles", paste0(d, ".jpg"))
daily  <- read.csv(file.path(dat, "data_clean/pm25_daily.csv"))
pm_of  <- function(d) daily$pm25[daily$date == d]
# ==== END BLOCK ====

# ==== BLOCK: street_and_composite DEPS: setup ====
# The raw renders for the slides: the composite at 1800 px, the street photo
# and the detector's renders at 1400 px.
image_write(image_scale(image_read(file.path(dat, "data/composite/beijing-smog.jpg")), "1800"),
            file.path(out, "composite.jpg"), quality = 85)
image_write(image_scale(image_read(street), "1400"), file.path(out, "street.jpg"), quality = 88)
for (f in c("boxes_010", "boxes_050", "masks"))
  image_write(image_scale(image_read(file.path(dat, "data_clean/street", paste0(f, ".jpg"))), "1400"),
              file.path(out, paste0("street_", f, ".jpg")), quality = 88)
# ==== END BLOCK ====

# ==== BLOCK: street_crops DEPS: setup ====
# The lower 55 percent of the two box renders (every box at 0.50 sits there),
# so the labels read at slide size.
for (f in c("boxes_010", "boxes_050")) {
  im <- image_read(file.path(dat, "data_clean/street", paste0(f, ".jpg")))
  wh <- image_info(im); top <- floor(0.45 * wh$height)
  cr <- image_crop(im, sprintf("%dx%d+0+%d", wh$width, wh$height - top, top))
  image_write(image_scale(cr, "1400"), file.path(out, paste0("street_", f, "_lower.jpg")), quality = 88)
}
# ==== END BLOCK ====

# ==== BLOCK: six_mornings DEPS: setup ====
# Six tiles in a row, the date and the monitor's daily mean under each.
days <- c("2014-01-03", "2014-01-06", "2014-02-04", "2014-02-25", "2014-07-01", "2014-10-09")
canvas("six_mornings.png", 10.4, 3.4)
tw <- 1.45; th <- tw * 222 / 167; gap <- 0.2
x0 <- (10.4 - (6 * tw + 5 * gap)) / 2
top <- 3.4 - 0.2
for (i in seq_along(days)) {
  xl <- x0 + (i - 1) * (tw + gap)
  rasterImage(as.raster(readJPEG(tile(days[i]))), xl, top - th, xl + tw, top)
  rect(xl, top - th, xl + tw, top, border = rule, lwd = 0.8)
  text(xl + tw / 2, top - th - 0.27, days[i], cex = 1.0, col = ink)
  text(xl + tw / 2, top - th - 0.56, sprintf("monitor %.1f", pm_of(days[i])), cex = 1.0, col = blue, font = 2)
}
text(5.2, 0.22, "the monitor: PM2.5 daily mean at the US Embassy, Beijing, micrograms per cubic metre",
     cex = 0.85, col = grey)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: roles DEPS: setup ====
# Three roles a photograph has played in economics, one real study each, and
# today's role under them.
canvas("roles.png", 10.4, 3.6, type = "cairo")
bw <- 3.2; bh <- 2.15; xs <- c(1.75, 5.2, 8.65); yc <- 3.6 - 0.15 - bh / 2
heads <- c("Measuring instrument", "Record", "Stimulus")
defs  <- c("the photograph gives a number",
           "the photograph shows what was there",
           "the photograph is what a person saw before deciding")
exs   <- c("the image of a painting → its predicted auction price",
           "a street image → the cars on it",
           "an arrest photograph (a mug shot) → the judge's decision to jail")
paps  <- c("Aubry, Kräussl, Manso & Spaenjers (JF, 2023)",
           "Gebru et al. (PNAS, 2017)",
           "Ludwig & Mullainathan (QJE, 2024)")
for (i in 1:3) {
  box_(xs[i], yc, bw, bh, col = "white", border = rule, lwd = 1.4)
  text(xs[i], yc + bh / 2 - 0.3, heads[i], cex = 1.15, font = 2, col = blue)
  ltext(xs[i], yc + 0.42, wrap_in(defs[i], bw - 0.35, 0.95), cex = 0.95, col = ink)
  ltext(xs[i], yc - 0.22, wrap_in(exs[i], bw - 0.35, 0.95), cex = 0.95, col = ink)
  ltext(xs[i], yc - bh / 2 + 0.3, wrap_in(paps[i], bw - 0.35, 0.85), cex = 0.85, col = grey)
}
box_(5.2, 0.5, 6.2, 0.78, col = "white", border = blue, lwd = 1.8)
text(5.2, 0.65, "Today: 365 skyline photographs → the monitor's PM2.5", cex = 1.05, col = blue, font = 2)
text(5.2, 0.33, "a measuring instrument of the fine particles in the air (PM2.5)", cex = 0.9, col = grey)
arr(xs[1], yc - bh / 2 - 0.04, xs[1] + 1.2, 0.5 + 0.39 + 0.04)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: studies DEPS: setup ====
# One diagram per study: what was measured, with what, compared with what.
study <- function(name, body) {
  canvas(name, 10.4, 2.0)
  bw <- 3.0; bh <- 1.15; xs <- c(1.75, 5.2, 8.65); yc <- 0.78
  heads <- c("Measured", "With what", "Compared with")
  for (i in 1:3) {
    text(xs[i], yc + bh / 2 + 0.27, heads[i], cex = 0.95, col = grey)
    box_(xs[i], yc, bw, bh, col = fill, border = rule)
    ltext(xs[i], yc, wrap_in(body[i], bw - 0.3, 0.95), cex = 0.95, col = ink)
    if (i < 3) arr(xs[i] + bw / 2 + 0.05, yc, xs[i + 1] - bw / 2 - 0.05, yc)
  }
  dev.off()
}
study("study_aubry.png", c("a predicted price from the image and the catalogue facts",
                           "a model trained on 1.2 million earlier sales",
                           "the auction house's estimate, against the realized price"))
study("study_gebru.png", c("the make, model and year of every car in view",
                           "a detector and a classifier trained on labelled car photographs",
                           "census income, race, education; election results"))
study("study_ludwig.png", c("which faces predict jailing",
                            "an algorithm trained on mug shots and judges' decisions",
                            "the defendant's record and the judge's actual decision"))
# ==== END BLOCK ====

# ==== BLOCK: builders DEPS: setup ====
# Three routes to a vision model on the one street photo. Each column: the
# question, what you give, what you get. Routes 1 and 2 show real outputs
# (replies/street/, data_clean/street/boxes.csv); route 3 is an example, not run.
b <- read.csv(file.path(dat, "data_clean/street/boxes.csv"))
top_conf <- function(l) sprintf("%.2f", max(b$conf[b$label == l]))
canvas("builders.png", 10.4, 4.75)
cw <- 3.25; xs <- c(1.75, 5.2, 8.65)
heads <- c("Route 1 · a general model, asked in words", "Route 2 · a model built for one task",
           "Route 3 · a model you train")
defs  <- c("already trained; answers any question you write; runs at a company (an API) or on your computer",
           "already trained, on millions of labelled photographs, for one fixed question; you download and run it",
           "you mark a few hundred photographs with the right answer; a trained model's last step is refit to them")
qs    <- list(c("yours, in words: \"How busy is", "this street, from 0 to 10?\""),
              c("fixed by its builders: \"Which of 80", "kinds of object are here, and where?\""),
              c("yours, shown by example:", "\"Is this street busy or quiet?\""))
gives <- c("the photograph and the question", "the photograph",
           "300 photographs you marked busy or quiet")
gets  <- list(c("\"6\"", "or a label, a count, a caption:", "whatever you ask"),
              c("9 boxes round objects",
                sprintf("car %s, person %s, truck %s ...", top_conf("car"), top_conf("person"), top_conf("truck")),
                "each a kind of object and how sure"),
              c("\"busy\" or \"quiet\" for", "any new street photograph", "(an example; today's is Beijing)"))
lab <- function(x, y, t) text(x - cw / 2 + 0.08, y, t, cex = 0.8, col = grey, adj = 0)
for (i in 1:3) {
  x <- xs[i]
  text(x, 4.55, heads[i], cex = 1.0, font = 2, col = blue)
  ltext(x, 4.12, wrap_in(defs[i], cw - 0.15, 0.8), cex = 0.8, col = grey, lh = 0.175)
  lab(x, 3.68, "the question")
  box_(x, 3.3, cw, 0.6, col = "white", border = blue, lwd = 1.4)
  ltext(x, 3.3, qs[[i]], cex = 0.88, col = ink, lh = 0.22)
  arr(x, 2.97, x, 2.83)
  lab(x, 2.72, "you give")
  box_(x, 2.43, cw, 0.4, col = fill, border = rule)
  text(x, 2.43, gives[i], cex = 0.9, col = ink)
  arr(x, 2.2, x, 2.06)
  box_(x, 1.9, cw * 0.5, 0.3, col = "white", border = blue, lwd = 1.6)
  text(x, 1.9, "model", cex = 0.9, col = blue, font = 2)
  arr(x, 1.73, x, 1.59)
  lab(x, 1.48, "you get")
  box_(x, 0.8, cw, 1.15, col = fill, border = rule)
  text(x, 1.08, gets[[i]][1], cex = 1.0, col = ink, font = 2)
  ltext(x, 0.58, gets[[i]][-1], cex = 0.85, col = if (i == 3) grey else ink, lh = 0.24)
}
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: hour_window DEPS: setup ====
# Two days, hour by hour: the monitor at the photograph's hour against the day.
h <- read.csv(file.path(dat, "data/pollution/Beijing_2014_HourlyPM25_created20150203.csv"),
              skip = 2, fileEncoding = "latin1")
h$Value[h$Value == -999] <- NA
png(file.path(out, "hour_window.png"), width = 10.4, height = 4.2, units = "in", res = 200)
par(mfrow = c(1, 2), mar = c(3.6, 4.2, 2.2, 0.8), family = "sans", mgp = c(2.3, 0.7, 0))
panel <- function(mo, dy, date, title, photo_h, lab_h, lab_txt, tile_x, tile_y, mean_x, mean_dy,
                  lab_y = lab_h, lab_adj = c(0, -0.6)) {
  x <- h[h$Month == mo & h$Day == dy, ]
  v <- x$Value; dm <- pm_of(date)
  plot(x$Hour, v, type = "s", lwd = 2, col = ink, xaxt = "n", bty = "l", las = 1,
       xlim = c(0, 23.5), ylim = c(0, max(v, na.rm = TRUE) * 1.22),
       xlab = "hour of the day", ylab = "PM2.5, micrograms per cubic metre", main = title,
       cex.main = 1.05, cex.lab = 0.95, cex.axis = 0.9, font.main = 1)
  axis(1, at = c(0, 6, 12, 18, 23), labels = c("00:00", "06:00", "12:00", "18:00", "23:00"), cex.axis = 0.9)
  abline(h = dm, lty = 2, col = blue, lwd = 1.6)
  text(mean_x, dm + mean_dy, sprintf("daily mean %.1f", dm), col = blue, cex = 0.95, adj = 0)
  segments(photo_h, 0, photo_h, lab_h, col = acc, lty = 3, lwd = 1.6)
  points(photo_h, lab_h, pch = 16, col = acc, cex = 1.3)
  text(photo_h + 0.4, lab_y, lab_txt, col = acc, cex = 0.95, adj = lab_adj)
  # the tile at its hour, in inches turned into user units
  usr <- par("usr"); pin <- par("pin")
  xpi <- (usr[2] - usr[1]) / pin[1]; ypi <- (usr[4] - usr[3]) / pin[2]
  tw <- 0.9; th <- tw * 222 / 167
  rasterImage(as.raster(readJPEG(tile(date))), tile_x, tile_y, tile_x + tw * xpi, tile_y + th * ypi)
  rect(tile_x, tile_y, tile_x + tw * xpi, tile_y + th * ypi, border = acc, lwd = 1.2)
  text(tile_x + tw * xpi / 2, tile_y - 0.05 * (usr[4] - usr[3]), "the photograph", col = acc, cex = 0.85)
}
panel(12, 28, "2014-12-28", "28 December: photographed 08:12, haze score 2", photo_h = 8.2,
      lab_h = 160, lab_txt = "08:00 reading 160", tile_x = 11.2, tile_y = 305, mean_x = 16.6, mean_dy = 22)
panel(5, 27, "2014-05-27", "27 May: photographed 06:30, haze score 7", photo_h = 6.5,
      lab_h = 99, lab_txt = "06:00 to 08:00 mean 99", tile_x = 15.3, tile_y = 48, mean_x = 9.8, mean_dy = 6,
      lab_y = 113, lab_adj = c(0, 0))
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: judged_like DEPS: setup ====
# Today's judging set beside Aubry et al.'s, aligned by role.
canvas("judged_like.png", 10.4, 3.0)
cx <- c(3.1, 5.9, 8.7); bw <- 2.6; bh <- 0.88
heads <- c("The reference", "The held-out observations", "The alternative measure")
rows  <- list(today = c("the monitor's daily PM2.5", "110 days kept out of the fitting",
                        "guessing the fitting days' mean"),
              aubry = c("the price each work later fetched",
                        "the 2015 sales; the model was fitted on 2008 to 2014",
                        "the auction house's presale estimate"))
ys <- c(1.95, 0.75)
for (j in 1:3) text(cx[j], 2.68, heads[j], cex = 0.95, col = grey)
text(0.15, ys[1], "Today", cex = 1.05, font = 2, col = blue, adj = 0)
ltext(0.15, ys[2], c("Aubry et al.", "(JF, 2023)"), cex = 1.0, font = 2, col = ink, adj = 0, lh = 0.26)
for (i in 1:2) for (j in 1:3) {
  box_(cx[j], ys[i], bw, bh, col = if (i == 1) "white" else fill, border = if (i == 1) blue else rule,
       lwd = if (i == 1) 1.6 else 1.2)
  ltext(cx[j], ys[i], wrap_in(rows[[i]][j], bw - 0.3, 0.95), cex = 0.95, col = ink)
}
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: pixels_to_answer DEPS: setup ====
# Four panels: the numbers of a 6 by 6 patch, the edges of the SUV crop, the
# detector's box on the crop, and what the last step returns. Full width of a
# slide at about 10.4 x 3.1 in.
im   <- image_read(street)                                   # 2367 x 1374
crop <- image_crop(im, "640x500+1280+780")                   # the blue SUV
edge <- image_negate(image_canny(crop, "0x1+10%+30%"))
px   <- readJPEG(street)
patch <- apply(px[1036:1041, 1511:1516, ], c(1, 2), mean)   # plate edge, 0 to 1

canvas("pixels_to_answer.png", 10.4, 3.1)
pw <- 2.15; ph <- 1.68; y <- 1.75
xs <- c(1.25, 3.75, 6.25, 8.95)
# panel 1: numbers
cell <- ph / 6
x0 <- xs[1] - pw / 2 + (pw - ph) / 2; y0 <- y - ph / 2
for (i in 1:6) for (j in 1:6) {
  v <- patch[i, j]
  rect(x0 + (j - 1) * cell, y0 + (6 - i) * cell, x0 + j * cell, y0 + (7 - i) * cell,
       col = grey(v), border = "white", lwd = 0.8)
  text(x0 + (j - 0.5) * cell, y0 + (6.5 - i) * cell, sprintf("%.2f", v), cex = 0.6,
       col = if (v > 0.55) ink else "white")
}
# panel 2: edges
rasterImage(as.raster(edge), xs[2] - pw / 2, y - ph / 2, xs[2] + pw / 2, y + ph / 2)
rect(xs[2] - pw / 2, y - ph / 2, xs[2] + pw / 2, y + ph / 2, border = rule)
# panel 3: the detector's box on the crop
rasterImage(as.raster(crop), xs[3] - pw / 2, y - ph / 2, xs[3] + pw / 2, y + ph / 2)
sx <- pw / 640; sy <- ph / 500
pl <- xs[3] - pw / 2; pt <- y + ph / 2                      # panel left and top
rect(pl + (1304 - 1280) * sx, pt - (1253 - 780) * sy, pl + (1895 - 1280) * sx, pt - (807 - 780) * sy,
     border = "#C8E000", lwd = 2.2)
rect(pl + (1304 - 1280) * sx, pt - (807 - 780) * sy - 0.2, pl + (1304 - 1280) * sx + 0.78,
     pt - (807 - 780) * sy, col = "#C8E000", border = NA)
text(pl + (1304 - 1280) * sx + 0.39, pt - (807 - 780) * sy - 0.1,
     "truck 0.67", cex = 0.72, col = ink, font = 2)
# panel 4: the detector's answer
box_(xs[4], y, 2.6, ph, col = "white", border = blue, lwd = 1.8)
text(xs[4], y + 0.56, "the detector's one question:", cex = 0.8, col = grey)
text(xs[4], y + 0.3, "\"Which of 80 kinds of object?\"", cex = 0.88, col = ink)
text(xs[4], y - 0.12, "truck", cex = 1.5, col = ink, font = 2)
text(xs[4], y - 0.5, "how sure, 0 to 1:  0.67", cex = 0.88, col = ink)
# arrows and captions
for (i in 1:3) arr(xs[i] + pw / 2 + 0.06, y, xs[i + 1] - (if (i == 3) 1.3 else pw / 2) - 0.06, y)
heads <- c("Numbers", "Edges", "An object", "The answer")
subs  <- c("what the photo is", "what the first layers find", "what the middle layers find",
           "what the last layer returns")
for (i in 1:4) {
  text(xs[i], y + ph / 2 + 0.3, heads[i], cex = 1.05, font = 2, col = if (i == 4) blue else ink)
  text(xs[i], y - ph / 2 - 0.28, subs[i], cex = 0.88, col = grey)
}
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: photo_figures DEPS: setup ====
# The one street photo on the left, arrows to a stack of boxes on the right.
# Three figures from one helper: the model hub's tasks (five boxes), Dell's
# families (three), and our six questions (six, numbered). Every box shows the
# real output saved in the project.
im    <- image_read(street)
boxes <- image_read(file.path(dat, "data_clean/street/boxes_050.jpg"))
masks <- image_read(file.path(dat, "data_clean/street/masks.jpg"))
reg   <- "1000x560+950+740"                                  # the cars and the people on the right
thumb_b <- image_crop(boxes, reg); thumb_m <- image_crop(masks, reg)
or_ <- function(a, b) if (is.null(a)) b else a
photo_boxes <- function(name, rows, H) {
  canvas(name, 10.4, H, type = "cairo")
  pw <- 3.9; ph <- pw * 1374 / 2367; x_ph <- 0.15
  rasterImage(as.raster(im), x_ph, H / 2 - ph / 2, x_ph + pw, H / 2 + ph / 2)
  text(x_ph + pw / 2, H / 2 + ph / 2 + 0.2, "one photograph", cex = 0.95, col = grey)
  hts <- sapply(rows, function(r) r$h); gap <- 0.07
  xb0 <- 5.3; xb1 <- 10.25
  top0 <- H / 2 + (sum(hts) + gap * (length(rows) - 1)) / 2
  tops <- top0 - c(0, cumsum(hts + gap))[seq_along(rows)]
  for (i in seq_along(rows)) {
    r <- rows[[i]]; bot <- tops[i] - hts[i]; yc <- (tops[i] + bot) / 2
    rect(xb0, bot, xb1, tops[i], col = fill, border = rule, lwd = 1)
    arr(x_ph + pw + 0.08, H / 2, xb0 - 0.04, yc)
    text(xb0 + 0.12, tops[i] - 0.15, r$title, adj = c(0, 1), cex = 0.9, font = 2, col = blue)
    if (!is.null(r$right)) text(xb1 - 0.12, tops[i] - 0.15, r$right, adj = c(1, 1), cex = 0.85, col = grey)
    ya <- tops[i] - 0.4; xc <- xb0 + 0.12
    if (!is.null(r$thumb)) {
      tw <- 1.2; th <- tw * 560 / 1000
      rasterImage(as.raster(r$thumb), xc, ya - th, xc + tw, ya)
      xc <- xc + tw + 0.12; ya <- ya - 0.05
    }
    text(xc, ya - (seq_along(r$lines) - 1) * 0.24, r$lines, adj = c(0, 1), cex = or_(r$cex, 0.85), col = ink)
  }
  dev.off()
}
lab_l <- "\"shopping street\"   (from seven labels we listed)"
box_l <- c("9 boxes, confidence 0.50 up:", "5 people, 2 cars, 1 truck, 1 handbag")
msk_l <- c("15 masks: the pixels", "of each object found")
emb_l <- "512 numbers:  0.028, 0.003, 0.033, 0.025, -0.007, ..."
emb_hub <- c("512 numbers summarising the photograph, its embedding:  0.028, 0.003, ...",
             "no number has a name; similar photographs get similar lists")
cap_l <- c("\"A busy commercial street lined with shops and green awnings,",
           "where a man in a red-and-blue striped soccer jersey walks past ...\"")
# 1. the hub's tasks
photo_boxes("hub_tasks.png", list(
  list(title = "image classification",     h = 0.55, lines = lab_l),
  list(title = "object detection",         h = 1.15, lines = box_l, thumb = thumb_b),
  list(title = "image segmentation",       h = 1.10, lines = msk_l, thumb = thumb_m),
  list(title = "image feature extraction", h = 0.8,  lines = emb_hub, cex = 0.8),
  list(title = "image-to-text",            h = 0.75, lines = cap_l, cex = 0.78)), H = 4.95)
# 2. Dell's families
photo_boxes("dell_families.png", list(
  list(title = "Classifiers", right = "a category", h = 1.15,
       lines = c("for the whole image:  \"shopping street\"", "for each object found:  the 9 boxes' labels",
                 "for each pixel:  the 15 masks")),
  list(title = "Regression", right = "a continuous value", h = 0.9,
       lines = c("how busy, 0 to 10:  6", "the coordinates of each box")),
  list(title = "Embedding models", right = "a vector", h = 0.9,
       lines = c("the 512 numbers of feature extraction, an embedding;",
                 "to link and group images, or as inputs to a regression"))), H = 4.2)
# 3. our six questions
qs <- c("What is it?", "How much, on a scale?", "What objects, and how many?",
        "Which pixels are each object?", "What does it look like, as numbers?", "What does it show, in words?")
qt <- paste0(1:6, " · ", qs)
photo_boxes("six_questions.png", list(
  list(title = qt[1], right = "a label",           h = 0.55, lines = lab_l),
  list(title = qt[2], right = "a number",          h = 0.55, lines = "how busy, 0 to 10:  6"),
  list(title = qt[3], right = "boxes and a count", h = 1.15, lines = box_l, thumb = thumb_b),
  list(title = qt[4], right = "a mask",            h = 1.10, lines = msk_l, thumb = thumb_m),
  list(title = qt[5], right = "an embedding",      h = 0.55, lines = emb_l),
  list(title = qt[6], right = "a caption",         h = 0.75, lines = cap_l, cex = 0.78)), H = 5.25)
# ==== END BLOCK ====

# ==== BLOCK: camera_frames DEPS: setup ====
# Four New York City DOT traffic-camera frames with the vehicle boxes an open
# detector draws at confidence 0.25 or more. Inputs: figures/21-photos/camera_src/
# (the frames and boxes.csv), written by _camera_boxes-21.py.
src <- file.path(out, "camera_src")
bx  <- read.csv(file.path(src, "boxes.csv"), colClasses = c(cam = "character", stamp = "character"))
cap <- c("08" = "Queensboro Bridge exit ramp, 62 St", "17" = "2 Ave at 36 St, Midtown Tunnel",
         "13" = "FDR Drive at 64 St", "26" = "FDR Drive at Brooklyn Bridge")
cams <- unique(bx$cam); fw <- 2.3; fh <- fw * 240 / 352; gap <- 0.13
canvas("camera_frames.png", length(cams) * fw + (length(cams) - 1) * gap, fh + 0.55)
for (i in seq_along(cams)) {
  x0 <- (i - 1) * (fw + gap); y0 <- 0.55
  rasterImage(readJPEG(file.path(src, paste0(cams[i], ".jpg"))), x0, y0, x0 + fw, y0 + fh)
  b <- bx[bx$cam == cams[i] & !is.na(bx$x1), ]
  if (nrow(b)) rect(x0 + b$x1 / 352 * fw, y0 + fh - b$y2 / 240 * fh, x0 + b$x2 / 352 * fw,
                    y0 + fh - b$y1 / 240 * fh, border = "#FFD400", lwd = 1.6)
  text(x0 + fw / 2, 0.38, cap[[cams[i]]], cex = 0.85, col = ink)
  text(x0 + fw / 2, 0.14, sprintf("%d vehicle%s found", nrow(b), if (nrow(b) == 1) "" else "s"),
       cex = 0.85, col = blue, font = 2)
}
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: design DEPS: setup ====
# The application's design on two real mornings: the photograph and one question go
# to the model, a score comes back, and the monitor's reading is set beside it
# afterwards. Scores from replies/haze/ (via data_clean/haze_pm25.csv), readings from
# data_clean/pm25_daily.csv.
hz <- read.csv(file.path(dat, "data_clean/haze_pm25.csv"))
days <- c("2014-01-03", "2014-01-06")
canvas("design.png", 10.4, 3.5, type = "cairo")
tw <- 1.02; th <- tw * 222 / 167
ys <- c(2.45, 0.85)
text(c(0.75, 3.55, 6.15, 8.85), 3.33, c("one photograph", "the model, asked in words", "its reply", "the monitor, that day"),
     cex = 0.9, col = grey)
for (k in 1:2) {
  y <- ys[k]; d <- days[k]
  rasterImage(readJPEG(tile(d)), 0.75 - tw / 2, y - th / 2, 0.75 + tw / 2, y + th / 2)
  text(0.75, y - th / 2 - 0.12, d, cex = 0.75, col = grey)
  arr(1.4, y, 1.95, y)
  box_(3.55, y, 3.0, 0.95, col = "white", border = blue, lwd = 1.6)
  ltext(3.55, y, c("\"Rate the haze in the air", "from 0 to 10.\""), cex = 0.92, col = ink, lh = 0.26)
  arr(5.15, y, 5.6, y)
  box_(6.15, y, 0.9, 0.95, col = fill, border = rule)
  text(6.15, y + 0.08, hz$haze[hz$date == d], cex = 1.7, font = 2, col = ink)
  text(6.15, y - 0.3, "of 10", cex = 0.78, col = grey)
  segments(6.7, y, 7.6, y, lty = 3, col = grey, lwd = 1.5)
  box_(8.85, y, 2.3, 0.95, col = fill, border = rule)
  text(8.85, y + 0.08, sprintf("%.1f", pm_of(d)), cex = 1.5, font = 2, col = acc)
  text(8.85, y - 0.3, "micrograms of PM2.5", cex = 0.78, col = grey)
}
text(7.15, 1.65, "set side by side", cex = 0.78, col = grey)
text(7.15, 1.45, "afterwards", cex = 0.78, col = grey)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: houses DEPS: setup ====
# Two public-domain photographs of houses, each with an open vision model's answers to
# four questions. Inputs: figures/21-photos/houses_src/ (the photographs, answers.csv),
# written by _house_questions-21.R.
src <- file.path(out, "houses_src")
ans <- read.csv(file.path(src, "answers.csv"))
canvas("houses.png", 10.4, 2.5)
pw <- 2.6; x0 <- c(0.05, 5.25)
yn <- function(v) if (isTRUE(as.logical(v))) "yes" else "no"
for (k in 1:2) {
  h <- ans$house[k]; im <- readJPEG(file.path(src, sprintf("house_%s.jpg", h)))
  ph <- pw * dim(im)[1] / dim(im)[2]; yc <- 1.25
  rasterImage(im, x0[k], yc - ph / 2, x0[k] + pw, yc + ph / 2)
  xq <- x0[k] + pw + 0.2
  qs <- c("Boarded up?", "Car in the driveway?", "Solar panels?", "Curb appeal, 0 to 10")
  as_ <- c(yn(ans$boarded_up[k]), yn(ans$car_in_driveway[k]), yn(ans$solar_panels[k]), ans$curb_appeal[k])
  ys <- 2.05 - (0:3) * 0.5
  text(xq, ys, qs, adj = 0, cex = 1.05, col = ink)
  text(xq + 2.0, ys, as_, adj = 0.5, cex = 1.25, font = 2, col = ifelse(as_ %in% c("no"), grey, blue))
}
dev.off()
# ==== END BLOCK ====
