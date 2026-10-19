# Diagrams for the session 15 page and slides (scraping). Base R only. Run
# from fall-2026/sessions:
#   Rscript _figures-15.R
# Writes figures/15-scraping/D01-three-routes.png to D06-captcha-login.png.
# The screenshots the diagrams quote (S*.png in the same folder) were
# captured with headless Chrome on 18 October 2026; D05 reads the real HTML
# of the January 2024 calendar row from data/15-scraping/cache/.
#
# Each canvas is set in inches (1 user unit = 1 inch, origin bottom left)
# and drawn at res 200. The comment above each figure gives the width it was
# sized for on the 1050 x 700 slide; at that width its text prints at about
# 19 to 23 px.

library(rvest)
out <- "figures/15-scraping"
dir.create(out, showWarnings = FALSE, recursive = TRUE)

ink  <- "#222222"
acc  <- "#B31B1B"    # the one accent
grey <- "#666666"
rule <- "#BBBBBB"
fill <- "#F2F2F2"    # neutral box fill
tint <- "#F7E6E6"    # a light tint of the accent
blue <- "#3A6C9C"    # link blue, as the Fed's pages use
mono <- if (file.exists("/System/Library/Fonts/Menlo.ttc")) "Menlo" else "mono"

# ---- Helpers ----
W <- H <- NA
open_d <- function(name, w, h) {
  W <<- w; H <<- h
  png(file.path(out, name), width = w, height = h, units = "in", res = 200,
      bg = "white", pointsize = 12)
  par(mar = c(0, 0, 0, 0), family = "sans", xpd = NA, col = ink, fg = ink,
      lend = 1, ljoin = 1)
  plot.new()
  plot.window(c(0, w), c(0, h), xaxs = "i", yaxs = "i")
}
close_d <- function() invisible(dev.off())

tx <- function(x, y, s, cex = 1.2, font = 1, col = ink, adj = c(0.5, 0.5),
               fam = "sans", ...) {
  text(x, y, s, cex = cex, font = font, col = col, adj = adj, family = fam, ...)
  wd <- strwidth(s, cex = cex, font = font, family = fam)
  ht <- strheight(s, cex = cex, font = font, family = fam)
  if (any(x - adj[1] * wd < 0 | x + (1 - adj[1]) * wd > W |
          y - adj[2] * ht < 0 | y + (1 - adj[2]) * ht > H))
    warning("off canvas: ", paste(s, collapse = " "), call. = FALSE)
  invisible(wd)
}
# several lines, top-left anchored, with a line step
lines_tx <- function(x, y, s, step = 0.26, cex = 1.05, col = ink, font = 1, adj = c(0, 1), fam = "sans") {
  for (i in seq_along(s)) tx(x, y - (i - 1) * step, s[i], cex = cex, col = col, font = font, adj = adj, fam = fam)
}
rbox <- function(x0, y0, x1, y1, r = 0.08, col = NA, border = ink, lwd = 2) {
  q <- seq(0, pi / 2, length.out = 12)
  polygon(c(x1 - r + r * cos(q), x0 + r - r * sin(q),
            x0 + r - r * cos(q), x1 - r + r * sin(q)),
          c(y1 - r + r * sin(q), y1 - r + r * cos(q),
            y0 + r - r * sin(q), y0 + r - r * cos(q)),
          col = col, border = border, lwd = lwd)
}
arr <- function(x0, y0, x1, y1, col = ink, lwd = 2.2, head = 0.14, wid = 0.065) {
  a <- atan2(y1 - y0, x1 - x0)
  xb <- x1 - head * cos(a); yb <- y1 - head * sin(a)
  segments(x0, y0, xb, yb, col = col, lwd = lwd)
  polygon(c(x1, xb + wid * sin(a), xb - wid * sin(a)),
          c(y1, yb - wid * cos(a), yb + wid * cos(a)), col = col, border = col)
}
# a raster image fitted into a box, keeping its aspect ratio, with a frame
pic <- function(file, x0, y0, x1, y1, frame = TRUE) {
  im <- png::readPNG(file)
  ar <- dim(im)[2] / dim(im)[1]           # width / height
  bw <- x1 - x0; bh <- y1 - y0
  if (bw / bh > ar) { w <- bh * ar; h <- bh } else { w <- bw; h <- bw / ar }
  cx <- (x0 + x1) / 2; cy <- (y0 + y1) / 2
  rasterImage(im, cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2, interpolate = TRUE)
  if (frame) rect(cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2, border = rule, lwd = 1.5)
  invisible(c(cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2))
}
# a small "web page" glyph: a window with a title bar and some text lines
page_glyph <- function(x0, y0, x1, y1, lines = 4, col = fill) {
  rbox(x0, y0, x1, y1, r = 0.06, col = "white", border = ink, lwd = 1.8)
  rect(x0, y1 - 0.16, x1, y1, col = col, border = ink, lwd = 1.8)
  for (i in seq_len(lines)) {
    yy <- y1 - 0.32 - (i - 1) * 0.17
    if (yy < y0 + 0.08) break
    segments(x0 + 0.1, yy, x1 - 0.1 - (i %% 3) * 0.12, yy, col = rule, lwd = 3)
  }
}
# a small table glyph
table_glyph <- function(x0, y0, x1, y1, rows = 4, cols = 3, header = TRUE) {
  rect(x0, y0, x1, y1, col = "white", border = ink, lwd = 1.8)
  rh <- (y1 - y0) / rows; cw <- (x1 - x0) / cols
  if (header) rect(x0, y1 - rh, x1, y1, col = fill, border = ink, lwd = 1.8)
  for (i in 1:(rows - 1)) segments(x0, y0 + i * rh, x1, y0 + i * rh, col = rule, lwd = 1.2)
  for (j in 1:(cols - 1)) segments(x0 + j * cw, y0, x0 + j * cw, y1, col = rule, lwd = 1.2)
}
# a simple person: head and body
person <- function(x, y, h = 0.6, col = ink) {
  symbols(x, y + h * 0.82, circles = h * 0.14, inches = FALSE, add = TRUE, fg = col, lwd = 2)
  segments(x, y + h * 0.68, x, y + h * 0.3, col = col, lwd = 2.2)
  segments(x, y + h * 0.3, x - h * 0.16, y, col = col, lwd = 2.2)
  segments(x, y + h * 0.3, x + h * 0.16, y, col = col, lwd = 2.2)
  segments(x, y + h * 0.6, x - h * 0.2, y + h * 0.42, col = col, lwd = 2.2)
  segments(x, y + h * 0.6, x + h * 0.22, y + h * 0.5, col = col, lwd = 2.2)
}
barcode <- function(x0, y0, x1, y1) {
  rect(x0, y0, x1, y1, col = "white", border = ink, lwd = 1.5)
  set.seed(15)
  xs <- seq(x0 + 0.04, x1 - 0.04, length.out = 18)
  segments(xs, y0 + 0.04, xs, y1 - 0.04, col = ink, lwd = sample(c(1.2, 2.4, 3.2), 18, TRUE))
}

# ---- D01: three routes to the Fed's data (slide: full width) ----
open_d("D01-three-routes.png", 12, 4.3)
cx <- c(2, 6, 10); top <- 4.0
heads <- c("Download a file", "Request a feed or API", "Scrape a page built for people")
subs  <- c("the H.15 page offers its series as a CSV file",
           "ne-press.json: every press release in one JSON file",
           "one statement page, read by a program")
thumbs <- c("S12-h15-page.png", "S13-feed-raw.png", "S02-statement-20220615.png")
backs  <- c("a file on your disk", "a structured reply", "the page's HTML, to pick apart")
for (i in 1:3) {
  tx(cx[i], top, heads[i], cex = 1.35, font = 2)
  tx(cx[i], top - 0.36, subs[i], cex = 0.95, col = grey)
  pic(file.path(out, thumbs[i]), cx[i] - 1.7, 1.25, cx[i] + 1.7, 3.3)
  arr(cx[i], 1.2, cx[i], 0.78, col = acc)
  tx(cx[i], 0.45, backs[i], cex = 1.3)
}
segments(c(4, 8), 0.1, c(4, 8), 4.2, col = rule, lwd = 1.5, lty = 3)
close_d()

# ---- D02: Cavallo (slide: 44% column) ----
open_d("D02-cavallo.png", 5.2, 5.2)
tx(1.3, 5.0, "Online", cex = 1.2, font = 2); tx(3.9, 5.0, "In the store", cex = 1.2, font = 2)
page_glyph(0.45, 3.4, 2.15, 4.75, lines = 5)
tx(1.3, 3.25, "the retailer's site", cex = 0.9, col = grey, adj = c(0.5, 1))
arr(1.3, 3.3, 1.3, 2.75, col = acc)
tx(1.55, 3.05, "a scraper", cex = 0.95, col = acc, adj = c(0, 0.5))
table_glyph(0.45, 1.55, 2.15, 2.65, rows = 4, cols = 3)
tx(1.3, 1.35, "product · day · online price", cex = 0.85, col = grey)
# the store side
person(3.35, 3.45, h = 1.1)
barcode(3.95, 3.75, 4.75, 4.2)
tx(4.35, 4.35, "the same product", cex = 0.85, col = grey)
tx(3.9, 3.28, "a hired worker scans the barcode", cex = 0.9, col = grey)
tx(3.9, 3.05, "and writes down the shelf price", cex = 0.9, col = grey)
arr(3.9, 2.92, 3.9, 2.72, col = acc)
table_glyph(3.05, 1.55, 4.75, 2.65, rows = 4, cols = 3)
tx(3.9, 1.35, "product · day · shelf price", cex = 0.85, col = grey)
arr(1.6, 1.15, 2.45, 0.75, col = ink); arr(3.6, 1.15, 2.75, 0.75, col = ink)
rbox(1.55, 0.25, 3.65, 0.75, col = tint, border = acc)
tx(2.6, 0.5, "identical 72% of the time", cex = 1.05, font = 2, col = acc)
close_d()

# ---- D03: a crawler over a job board (slide: 44% column) ----
open_d("D03-crawler.png", 5.2, 5.2)
tx(2.6, 5.0, "A crawler follows links from page to page", cex = 1.1, font = 2)
page_glyph(0.4, 2.9, 1.9, 4.6, lines = 6)
tx(1.15, 2.72, "listing page 1", cex = 0.85, col = grey)
page_glyph(1.7, 1.1, 3.2, 2.8, lines = 6, col = fill)
tx(2.45, 0.92, "listing page 2", cex = 0.85, col = grey)
ads_y <- c(4.35, 3.75, 3.15)
for (k in 1:3) {
  page_glyph(3.6, ads_y[k] - 0.22, 4.9, ads_y[k] + 0.22, lines = 2)
  arr(1.9, 4.45 - (k - 1) * 0.3, 3.58, ads_y[k], col = acc, lwd = 1.6, head = 0.1, wid = 0.045)
}
tx(4.25, 2.72, "one ad each, saved", cex = 0.85, col = grey)
arr(1.15, 2.6, 1.7, 2.1, col = ink, lwd = 1.8)
tx(0.4, 2.2, "next page", cex = 0.85, col = grey, adj = c(0, 0.5))
arr(4.25, 2.6, 4.25, 1.75, col = acc)
table_glyph(3.45, 0.55, 5.1, 1.6, rows = 4, cols = 3)
tx(4.27, 0.38, "job · employer ·", cex = 0.78, col = grey)
tx(4.27, 0.18, "asks for a man or a woman", cex = 0.78, col = grey)
tx(0.4, 0.45, "1,051,706 ads", cex = 1.05, font = 2, col = acc, adj = c(0, 0.5))
close_d()

# ---- D04: Christensen & Timmins (slide: 44% column) ----
open_d("D04-inquiries.png", 5.2, 5.2)
page_glyph(0.4, 3.7, 1.9, 5.0, lines = 5)
tx(1.15, 3.52, "rental listings", cex = 0.85, col = grey)
arr(1.9, 4.35, 2.55, 4.35, col = acc)
tx(2.22, 4.6, "scraper", cex = 0.85, col = acc)
table_glyph(2.6, 3.7, 4.9, 5.0, rows = 4, cols = 3)
tx(3.75, 3.52, "home · neighbourhood amenities · pollution", cex = 0.78, col = grey)
arr(3.75, 3.35, 3.75, 2.85, col = ink)
tx(3.75, 2.62, "an inquiry to each listing", cex = 0.95)
tx(2.85, 2.38, "from renters whose names signal different groups", cex = 0.8, col = grey)
for (k in 1:3) {
  x0 <- 1.1 + (k - 1) * 1.45
  rect(x0, 1.3, x0 + 1.1, 1.95, col = "white", border = ink, lwd = 1.8)
  segments(x0, 1.95, x0 + 0.55, 1.6, col = ink, lwd = 1.5); segments(x0 + 1.1, 1.95, x0 + 0.55, 1.6, col = ink, lwd = 1.5)
  tx(x0 + 0.55, 1.1, paste("name", k), cex = 0.85, col = grey)
  arr(3.75 - 0.2 + (k - 2) * 0.2, 2.2, x0 + 0.55, 1.98, col = acc, lwd = 1.5, head = 0.1, wid = 0.045)
  arr(x0 + 0.55, 0.95, x0 + 0.55, 0.6, col = ink, lwd = 1.5, head = 0.1, wid = 0.045)
}
rbox(0.8, 0.15, 4.5, 0.55, col = tint, border = acc)
tx(2.65, 0.35, "replies recorded: who was answered, and how", cex = 0.95, col = acc, font = 2)
close_d()

# ---- D05: the January 2024 row, HTML beside its rendering (slide: full width) ----
open_d("D05-html-row.png", 12, 4.35)
html_lines <- c('<div class="row fomc-meeting">',
                '  <div class="fomc-meeting__month"><strong>January</strong></div>',
                '  <div class="fomc-meeting__date">30-31</div>',
                '  <div>',
                '    <strong>Statement:</strong>',
                '    <a href="/monetarypolicy/files/monetary20240131a1.pdf">PDF</a> |',
                '    <a href="/newsevents/pressreleases/monetary20240131a.htm">HTML</a>',
                '    <a href="/newsevents/pressreleases/monetary20240131a1.htm">Implementation Note</a>',
                '  </div>',
                '</div>')
tx(0.25, 4.2, "The HTML, trimmed to the month, the dates and the Statement links", cex = 1.1, font = 2, adj = c(0, 1))
tx(7.8, 4.2, "The same row as the browser draws it", cex = 1.1, font = 2, adj = c(0, 1))
rect(0.2, 0.3, 7.35, 3.85, col = "#FAFAFA", border = rule, lwd = 1.5)
y0 <- 3.6; step <- 0.33
for (i in seq_along(html_lines))
  text(0.35, y0 - (i - 1) * step, html_lines[i], adj = c(0, 0.5), cex = 0.88, family = mono, col = ink)
# the rendered row
bb <- pic(file.path(out, "S06-row-2024-01-rendered.png"), 7.75, 2.15, 11.9, 3.75)
# arrows from four HTML lines to the rendering: month, dates, HTML link, Implementation Note
# positions in the raster (fractions of its width and height, from the capture)
px <- function(fx, fy) c(bb[1] + fx * (bb[3] - bb[1]), bb[2] + fy * (bb[4] - bb[2]))
targets <- list(month = px(0.08, 0.72), dates = px(0.22, 0.72), html = px(0.37, 0.6), note = px(0.33, 0.33))
from_y  <- c(y0 - 1 * step, y0 - 2 * step, y0 - 6 * step, y0 - 7 * step)
for (k in 1:4) {
  t <- targets[[k]]
  arr(7.4, from_y[k], t[1] - 0.05, t[2], col = acc, lwd = 1.6, head = 0.11, wid = 0.05)
}
tx(7.8, 1.15, "The full row holds seven links; the next slides", cex = 1.0, col = grey, adj = c(0, 1))
tx(7.8, 0.85, "pick them out by these class names.", cex = 1.0, col = grey, adj = c(0, 1))
close_d()

# ---- D06: a CAPTCHA and a login wall (slide: r-stretch) ----
open_d("D06-captcha-login.png", 12, 5.6)
segments(6, 0.3, 6, 5.4, col = rule, lwd = 1.5, lty = 3)
# left: CAPTCHA
tx(0.3, 5.35, "A CAPTCHA", cex = 1.45, font = 2, adj = c(0, 1))
tx(0.3, 4.95, "a test that a person is at the keyboard", cex = 1.1, col = grey, adj = c(0, 1))
rbox(0.5, 3.3, 3.2, 4.55, col = "white", border = ink)
rect(0.7, 3.5, 1.1, 3.9, col = "white", border = ink, lwd = 1.8)
tx(1.3, 3.7, "I'm not a robot", cex = 1.05, adj = c(0, 0.5))
text(1.85, 4.25, "7 k Q 2 m", cex = 1.6, family = mono, col = grey, srt = 6)
tx(3.45, 4.25, "The site is refusing", cex = 1.15, font = 2, adj = c(0, 1))
tx(3.45, 3.92, "programs.", cex = 1.15, font = 2, adj = c(0, 1))
lines_tx(0.5, 2.9, c("Stop, and slow down.",
                      "Put your name and address in the user agent.",
                      "Ask the site for access or for its feed:",
                      "agencies and publishers often grant one."), step = 0.37, cex = 1.25)
rbox(0.5, 0.55, 5.6, 1.3, col = tint, border = acc)
tx(3.05, 0.92, "Do not have a program solve it.", cex = 1.15, font = 2, col = acc)
# right: login wall
tx(6.4, 5.35, "A login wall", cex = 1.45, font = 2, adj = c(0, 1))
tx(6.4, 4.95, "the page shows only after you sign in", cex = 1.1, col = grey, adj = c(0, 1))
rbox(6.6, 3.1, 9.3, 4.55, col = "white", border = ink)
rect(6.8, 4.05, 9.1, 4.35, col = fill, border = rule); tx(6.9, 4.2, "user name", cex = 0.9, col = grey, adj = c(0, 0.5))
rect(6.8, 3.6, 9.1, 3.9, col = fill, border = rule); tx(6.9, 3.75, "password", cex = 0.9, col = grey, adj = c(0, 0.5))
rbox(6.8, 3.2, 8.0, 3.48, col = blue, border = blue); tx(7.4, 3.34, "Sign in", cex = 0.9, col = "white")
tx(9.55, 4.25, "The site's terms decide", cex = 1.15, font = 2, adj = c(0, 1))
lines_tx(9.55, 3.9, c("what a program", "may copy."), step = 0.34, cex = 1.15)
lines_tx(6.4, 2.9, c("Where the terms allow it: your own login,",
                      "in your own session, at the rate a person reads.",
                      "The site records those requests under your name."), step = 0.37, cex = 1.25)
rbox(6.4, 0.55, 11.7, 1.3, col = tint, border = acc)
tx(9.05, 0.92, "Read the terms before the first request.", cex = 1.15, font = 2, col = acc)
close_d()


# ---- D07: a browser agent's run, drawn from its transcript (slide: 58% column) ----
open_d("D07-browser-agent.png", 6.4, 4.4)
rbox(0.15, 0.15, 6.25, 4.25, r = 0.1, col = "white", border = rule, lwd = 1.5)
rect(0.15, 3.85, 6.25, 4.25, col = fill, border = rule, lwd = 1.5)
tx(0.35, 4.05, "A browser agent, in the browser pane", cex = 1.0, font = 2, adj = c(0, 0.5))
# the question
rbox(0.35, 3.0, 6.05, 3.72, r = 0.1, col = tint, border = NA)
lines_tx(0.5, 3.55, c("On the Fed's meeting calendar page, how many rows does",
                      "the 2025 panel list, and which row is not a meeting?"), step = 0.3, cex = 1.0)
# the steps
steps <- c("opened  federalreserve.gov/monetarypolicy/fomccalendars.htm",
           "searched the page for \"notation vote\" (1 match)",
           "scrolled to the 2025 panel and read its rows")
for (i in seq_along(steps)) {
  yy <- 2.72 - (i - 1) * 0.3
  symbols(0.5, yy, circles = 0.05, inches = FALSE, add = TRUE, fg = acc, bg = acc)
  text(0.7, yy, steps[i], adj = c(0, 0.5), cex = 0.9, family = mono, col = ink)
}
# the answer
rbox(0.35, 0.85, 6.05, 1.92, r = 0.1, col = "white", border = ink)
lines_tx(0.5, 1.72, c("Its answer: nine rows.",
                      "The row that is not a meeting is \"August 22 (notation vote)\":",
                      "it links only a Statement on Longer-Run Goals."), step = 0.3, cex = 1.05)
tx(0.35, 0.58, "The same question, put to the page with code (Exercise 1): nine rows, row 6.", cex = 0.9, adj = c(0, 0.5))
tx(0.35, 0.33, "The agent kept no copy of the page. Each run reads it afresh and answers afresh.", cex = 0.85, col = grey, adj = c(0, 0.5))
close_d()

cat("drawn:", paste(list.files(out, pattern = "^D0"), collapse = ", "), "\n")
