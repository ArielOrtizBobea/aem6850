# Diagrams for the session 16 page and slides (text as data, regex). Base R
# only, plus readxl for the one data file. Run from fall-2026/sessions:
#   Rscript _figures-16.R
# Writes figures/16-text-regex/D02-epu-keyword-index.png to D08-two-hyphens.png.
# D02 plots the real US monthly index from
# data/16-text-regex/prep/US_Policy_Uncertainty_Data.xlsx (policyuncertainty.com,
# downloaded 2026-10-20). D05 quotes counts from data/16-text-regex/
# (171 statements, 73,839 words, the Loughran-McDonald lists). D06 and D07
# quote the pattern in data/16-text-regex/chat_reply.R as R code writes it.
# The screenshot S01-statement-20230322.png in the same folder is a headless
# Chrome capture, not drawn here.
#
# Each canvas is set in inches (1 user unit = 1 inch, origin bottom left)
# and drawn at res 200. Every canvas is sized so that 1 inch = 100 px on the
# 1050 x 700 slide at the placement noted above it, so cex 1.15 prints at
# about 19 px, cex 1.2 at 20 px and cex 1.3 at 22 px.
#
# The file stays ASCII: every non-ASCII character is written as a \u escape.
# Patterns are set in Menlo; the text they match is set in Helvetica, because
# Menlo draws the hyphen key as a long dash and 4-3/4 would read as 4 dash 3/4.

library(readxl)
out <- "figures/16-text-regex"
dir.create(out, showWarnings = FALSE, recursive = TRUE)

ink  <- "#222222"
acc  <- "#B31B1B"    # the one accent
grey <- "#666666"
rule <- "#BBBBBB"
fill <- "#F2F2F2"    # neutral box fill
tint <- "#F7E6E6"    # a light tint of the accent
blue <- "#3A6C9C"    # link blue, as the Fed's pages use
mono <- if (file.exists("/System/Library/Fonts/Menlo.ttc")) "Menlo" else "mono"

# Unicode used below
en  <- "\u2013"; to_ <- "\u2192"; lq <- "\u2018"; rq <- "\u2019"
minus <- "\u2212"; nbh <- "\u2011"
# Helvetica (sans) has no arrow glyph; Arial does
arw <- "Arial"

# ---- Helpers (open_d to arr as in _figures-15.R) ----
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
rbox <- function(x0, y0, x1, y1, r = 0.08, col = NA, border = ink, lwd = 2, lty = 1) {
  q <- seq(0, pi / 2, length.out = 12)
  polygon(c(x1 - r + r * cos(q), x0 + r - r * sin(q),
            x0 + r - r * cos(q), x1 - r + r * sin(q)),
          c(y1 - r + r * sin(q), y1 - r + r * cos(q),
            y0 + r - r * sin(q), y0 + r - r * cos(q)),
          col = col, border = border, lwd = lwd, lty = lty)
}
arr <- function(x0, y0, x1, y1, col = ink, lwd = 2.2, head = 0.14, wid = 0.065) {
  a <- atan2(y1 - y0, x1 - x0)
  xb <- x1 - head * cos(a); yb <- y1 - head * sin(a)
  segments(x0, y0, xb, yb, col = col, lwd = lwd)
  polygon(c(x1, xb + wid * sin(a), xb - wid * sin(a)),
          c(y1, yb - wid * cos(a), yb + wid * cos(a)), col = col, border = col)
}
# a piece of a line: text, colour, font (1 plain, 2 bold), family
sg <- function(s, col = ink, font = 1, fam = "sans") list(s, col, font, fam)
seg_w <- function(segs, cex) sum(sapply(segs, function(s) strwidth(s[[1]], cex = cex, font = s[[3]], family = s[[4]])))
# one line made of pieces, drawn left to right from x (adj_x = 0.5 centres it);
# a plain string is one piece
seg_line <- function(x, y, segs, cex = 1.2, adj_x = 0) {
  if (is.character(segs)) segs <- list(sg(segs))
  x <- x - adj_x * seg_w(segs, cex)
  for (s in segs)
    x <- x + tx(x, y, s[[1]], cex = cex, col = s[[2]], font = s[[3]], fam = s[[4]], adj = c(0, 0.5))
  invisible(seg_w(segs, cex))
}
# several such lines, the first centred at y, each step lower
seg_lines <- function(x, y, L, step = 0.245, cex = 1.2, adj_x = 0) {
  for (i in seq_along(L)) seg_line(x, y - (i - 1) * step, L[[i]], cex = cex, adj_x = adj_x)
}
# warn when lines are wider than the box they sit in
fits <- function(L, room, cex, what) {
  w <- max(sapply(L, function(l) seg_w(if (is.character(l)) list(sg(l)) else l, cex)))
  if (w > room) warning(sprintf("too wide for its box (%.2f > %.2f in): %s", w, room, what), call. = FALSE)
}
# a bracket under (side = 1) or over (side = 3) the span x0..x1 at height y
bracket <- function(x0, x1, y, side = 1, col = ink, tick = 0.08, lwd = 2) {
  d <- if (side == 1) tick else -tick
  segments(x0, y, x1, y, col = col, lwd = lwd)
  segments(c(x0, x1), y, c(x0, x1), y + d, col = col, lwd = lwd)
}


# ---- D02: the EPU keyword rule and the real index (slide: right column, 470 x 430 px) ----
epu <- read_excel("data/16-text-regex/prep/US_Policy_Uncertainty_Data.xlsx",
                  sheet = "Main News Index")
epu <- epu[!is.na(epu$Month) & grepl("^[0-9]{4}$", epu$Year), ]
epu$yr <- as.numeric(epu$Year)
epu <- epu[epu$yr >= 1985, ]                    # the 10-newspaper index starts in 1985
epu$t <- epu$yr + (epu$Month - 0.5) / 12
epu <- epu[order(epu$t), ]
v <- epu$News_Based_Policy_Uncert_Index
at <- function(y, m) epu[epu$yr == y & epu$Month == m, c("t", "News_Based_Policy_Uncert_Index")]
stopifnot(nrow(at(2001, 9)) == 1, nrow(at(2008, 9)) == 1, nrow(at(2011, 8)) == 1)

open_d("D02-epu-keyword-index.png", 4.7, 4.3)
# each box as wide as its widest line; the two AND gaps share what is left
lists <- list(economy = c("economic", "economy"), uncertainty = c("uncertain", "uncertainty"),
              policy = c("Congress, deficit,", "Federal Reserve,", "legislation,", "regulation,", "White House"))
pad <- 0.06
bw <- sapply(names(lists), function(n) max(strwidth(n, cex = 1.15, font = 2),
                                           strwidth(lists[[n]], cex = 1.15)) + 2 * pad)
gap <- (W - 0.04 - sum(bw)) / 2
bx0 <- 0.02 + c(0, bw[1] + gap, bw[1] + bw[2] + 2 * gap)
for (k in 1:3) {
  x0 <- bx0[k]; x1 <- x0 + bw[k]; y1 <- 4.24
  y0 <- y1 - 0.38 - length(lists[[k]]) * 0.225
  rbox(x0, y0, x1, y1, col = "white", border = ink, lwd = 1.8)
  tx(x0 + pad, y1 - 0.19, names(lists)[k], cex = 1.15, font = 2, adj = c(0, 0.5))
  for (i in seq_along(lists[[k]])) tx(x0 + pad, y1 - 0.45 - (i - 1) * 0.225, lists[[k]][i], cex = 1.15, adj = c(0, 0.5))
  if (k < 3) tx(x1 + gap / 2, 3.83, "AND", cex = 1.05, font = 2, col = acc)
}
seg_lines(0.06, 3.16, list("an article counts if it has", "a word from each list"), step = 0.225, cex = 1.15)
arr(2.3, 3.05, 2.3, 2.62, lwd = 1.8, head = 0.1, wid = 0.05)
seg_lines(0.06, 2.47, list("monthly share of articles in 10 US newspapers,",
                           list(sg("scaled, standardized, averaged "), sg(to_, ink, 1, arw), sg(" the index"))), step = 0.225, cex = 1.15)
# the chart, in inches: x from 1985 to the last month, y from 0 to 760
cx0 <- 0.52; cx1 <- 4.6; cy0 <- 0.36; cy1 <- 2.08
t0 <- 1985; t1 <- max(epu$t) + 0.1; ymax <- 760
xm <- function(t) cx0 + (t - t0) / (t1 - t0) * (cx1 - cx0)
ym <- function(v) cy0 + v / ymax * (cy1 - cy0)
for (g in c(200, 400, 600)) segments(cx0, ym(g), cx1, ym(g), col = "#E4E4E4", lwd = 1)
segments(cx0, cy0, cx1, cy0, col = grey, lwd = 1.2)
for (g in c(0, 200, 400, 600)) tx(cx0 - 0.06, ym(g), g, cex = 1.15, col = grey, adj = c(1, 0.5))
for (yr in c(1990, 2000, 2010, 2020)) {
  segments(xm(yr), cy0, xm(yr), cy0 - 0.05, col = grey, lwd = 1.2)
  tx(xm(yr), cy0 - 0.09, yr, cex = 1.15, col = grey, adj = c(0.5, 1))
}
lines(xm(epu$t), ym(v), col = ink, lwd = 1.3)
# three peaks the paper's own chart names, marked where the data has them
p1 <- at(2001, 9); p2 <- at(2008, 9); p3 <- at(2011, 8)
points(xm(c(p1$t, p2$t, p3$t)), ym(c(p1[[2]], p2[[2]], p3[[2]])), pch = 19, cex = 0.7, col = acc)
tx(xm(p1$t), ym(p1[[2]]) + 0.07, "9/11", cex = 1.15, col = acc, adj = c(0.5, 0))
segments(xm(p2$t), ym(p2[[2]]) + 0.05, xm(p2$t) - 0.12, ym(p2[[2]]) + 0.3, col = acc, lwd = 1.2)
tx(xm(p2$t) - 0.12, ym(p2[[2]]) + 0.33, "Lehman", cex = 1.15, col = acc, adj = c(0.5, 0))
segments(xm(p3$t), ym(p3[[2]]) + 0.05, xm(p3$t) + 0.18, ym(p3[[2]]) + 0.57, col = acc, lwd = 1.2)
tx(xm(p3$t) + 0.18, ym(p3[[2]]) + 0.6, "debt ceiling", cex = 1.15, col = acc, adj = c(0.5, 0))
close_d()


# ---- D03: Shapiro and Wilson's steps (slide: right column, 470 x 430 px) ----
open_d("D03-fed-tone-flow.png", 4.7, 4.3)
steps <- list(
  list(paste0("FOMC meeting transcripts, 2000", en, "2011:"),
       "what each speaker said"),
  list("count negative and positive words from a",
       "finance word list (Loughran & McDonald);",
       paste0("words after ", lq, "not", rq, " ignored")),
  list("14 research assistants scored 182 random",
       list(sg("texts, 1 to 5: rank correlation "), sg("0.40", acc, 2)),
       list(sg("(finance list) vs "), sg("0.14", acc, 2), sg(" (a general list)"))),
  list(paste0("relate negative tone to the staff", rq, "s inflation"),
       "forecast: least negative near 1.5% inflation",
       list(sg(to_, acc, 2, arw), sg(paste0(" the committee", rq, "s implicit target"), acc, 2))))
step <- 0.245; ytop <- 4.2
for (k in seq_along(steps)) {
  L <- steps[[k]]
  h <- 0.4 + (length(L) - 1) * step
  last <- k == length(steps)
  rbox(0.06, ytop - h, 4.64, ytop, col = if (last) tint else "white",
       border = if (last) acc else ink, lwd = 1.8)
  fits(L, 4.58 - 0.2, 1.2, paste("D03 box", k))
  seg_lines(0.2, ytop - 0.2, L, step = step, cex = 1.2)
  if (!last) arr(2.35, ytop - h - 0.02, 2.35, ytop - h - 0.23, lwd = 1.8, head = 0.1, wid = 0.055)
  ytop <- ytop - h - 0.25
}
close_d()


# ---- D04: the AP style change on a time line (slide: right column, 470 x 430 px) ----
open_d("D04-ap-style-timeline.png", 4.7, 4.3)
rbox(0.06, 3.5, 4.64, 4.24, col = fill, border = NA)
seg_lines(0.2, 4.03, list(list(sg("AP copy: ", font = 2), sg("stories from the Associated Press")),
                          "that local papers reprint"), step = 0.25, cex = 1.2)
# time runs down the line
arr(0.32, 3.3, 0.32, 0.12, col = grey, lwd = 2, head = 0.14, wid = 0.065)
tx(0.5, 3.22, "before", cex = 1.15, col = grey, adj = c(0, 0.5))
symbols(0.32, 2.78, circles = 0.08, inches = FALSE, add = TRUE, fg = acc, bg = acc)
tx(0.55, 2.9, "April 2013", cex = 1.3, font = 2, col = acc, adj = c(0, 0.5))
tx(0.55, 2.64, paste0("the AP style guide drops ", lq, "illegal immigrant", rq), cex = 1.2, adj = c(0, 0.5))
tx(0.5, 2.3, "after", cex = 1.15, col = grey, adj = c(0, 0.5))
after <- list(
  list(list(sg("articles using the phrase "), sg("fell 28%", acc, 2), sg(" in outlets")),
       "that rely on AP copy, compared with other",
       "outlets (2,000+ outlets)"),
  list("readers in counties whose papers rely",
       list(sg("on AP: "), sg("less support", acc, 2), sg(" for restrictive")),
       "immigration policy (CCES survey)"))
ytop <- 2.1
for (k in 1:2) {
  L <- after[[k]]; h <- 0.4 + (length(L) - 1) * 0.245
  rbox(0.55, ytop - h, 4.64, ytop, col = "white", border = ink, lwd = 1.8)
  fits(L, 4.64 - 0.55 - 0.24, 1.2, paste("D04 box", k))
  seg_lines(0.67, ytop - 0.2, L, step = 0.245, cex = 1.2)
  ytop <- ytop - h - 0.12
}
close_d()


# ---- D05: terms for text as data, on the Fed statements (slide: body, 980 x 425 px) ----
open_d("D05-text-terms.png", 9.8, 4.25)
# a box: the term in bold, a definition, then the example in the accent colour
term_box <- function(x0, y0, x1, y1, term, def, ex, ex_fam = "sans", lty = 1, border = ink) {
  rbox(x0, y0, x1, y1, col = "white", border = border, lwd = 1.8, lty = lty)
  if (is.character(term)) term <- list(sg(term, font = 2))
  nm <- term[[1]][[1]]
  seg_line(x0 + 0.12, y1 - 0.22, term, cex = 1.3)
  fits(list(term), x1 - x0 - 0.24, 1.3, nm)
  fits(as.list(def), x1 - x0 - 0.24, 1.2, nm)
  fits(as.list(ex), x1 - x0 - 0.24, if (ex_fam == "sans") 1.2 else 1.15, nm)
  y <- y1 - 0.52
  for (d in def) { tx(x0 + 0.12, y, d, cex = 1.2, adj = c(0, 0.5)); y <- y - 0.25 }
  for (e in ex) {
    tx(x0 + 0.12, y, e, cex = if (ex_fam == "sans") 1.2 else 1.15, col = acc, fam = ex_fam, adj = c(0, 0.5))
    y <- y - 0.25
  }
}
# left column: corpus, then document
term_box(0.06, 3.2, 1.98, 4.17, "corpus", "all the documents", "171 statements")
arr(1.02, 3.2, 1.02, 2.84, lwd = 1.8, head = 0.11, wid = 0.055)
term_box(0.06, 1.62, 1.98, 2.82, "document", c("one statement,", "one row"), "22 March 2023")
# the two lanes leave the document
cols <- list(c(2.35, 4.45), c(4.7, 7.38), c(7.62, 9.74))
top <- c(2.72, 4.17); bot <- c(0.82, 2.27)
arr(1.98, 2.5, cols[[1]][1] - 0.02, 3.3, lwd = 1.8, head = 0.11, wid = 0.055)
arr(1.98, 1.9, cols[[1]][1] - 0.02, 1.62, lwd = 1.8, head = 0.11, wid = 0.055)
term_box(cols[[1]][1], top[1], cols[[1]][2], top[2], "pattern (regex)",
         c("a description of", "text to find"),
         c(paste0("e.g. a number, ", lq, "to", rq, ","), paste0("a number, ", lq, "percent", rq)))
term_box(cols[[2]][1], top[1], cols[[2]][2], top[2], "match", "the text found",
         "to 4-3/4 to 5 percent")
term_box(cols[[3]][1], top[1], cols[[3]][2], top[2], "variables", "new columns",
         c("lower 4.75", "upper 5"))
term_box(cols[[1]][1], bot[1], cols[[1]][2], bot[2], "tokens", "one word each",
         "73,839 in the corpus")
term_box(cols[[2]][1], bot[1], cols[[2]][2], bot[2], "word list (dictionary)",
         c("positive and", "negative words"),
         c("+ strong, gains", paste0(minus, " declined, weakened")))
term_box(cols[[3]][1], bot[1], cols[[3]][2], bot[2], list(sg("counts ", font = 2), sg(to_, ink, 2, arw), sg(" variable", font = 2)),
         c("each list, counted", "in each statement"), "net tone")
for (y in c(mean(top), mean(bot))) {
  arr(cols[[1]][2] + 0.02, y, cols[[2]][1] - 0.02, y, lwd = 1.8, head = 0.11, wid = 0.055)
  arr(cols[[2]][2] + 0.02, y, cols[[3]][1] - 0.02, y, lwd = 1.8, head = 0.11, wid = 0.055)
}
# a string, the smallest unit: one strip along the bottom
rbox(0.06, 0.06, 9.74, 0.6, col = fill, border = NA)
tx(0.18, 0.33, "string", cex = 1.3, font = 2, adj = c(0, 0.5))
seg_line(1.3, 0.33, list(sg("text in R, written between quotes: "), sg('"inflation"', acc, 1, mono)), cex = 1.2)
close_d()


# ---- D06: the number pattern in three pieces (slide: strip under code, 980 x 180 px) ----
open_d("D06-num-pattern.png", 9.8, 1.6)
pcs  <- c("\\\\d+", "(?:\\\\.\\\\d+)?", "(?:-\\\\d+/\\\\d+|/\\\\d+)?")
pcol <- c(acc, blue, acc)
pcex <- 1.6
pw <- sapply(pcs, strwidth, cex = pcex, family = mono)
x <- (W - sum(pw)) / 2; xs <- x + c(0, cumsum(pw))
labs <- list(
  list(list(sg("one or more")), list(sg("digits: "), sg("4", pcol[1], 2))),
  list(list(sg("optional: a period")), list(sg("and digits: "), sg(".25", pcol[2], 2))),
  list(list(sg("optional: either")), list(sg("-3/4", pcol[3], 2), sg(" or "), sg("/4", pcol[3], 2))))
for (i in 1:3) {
  tx(xs[i], 1.27, pcs[i], cex = pcex, col = pcol[i], fam = mono, adj = c(0, 0.5))
  bracket(xs[i] + 0.04, xs[i + 1] - 0.04, 0.97, side = 1, col = pcol[i])
  # the first label hangs left of its short piece so it clears the second
  if (i == 1) seg_lines(xs[2] - 0.04, 0.65, labs[[i]], step = 0.27, cex = 1.2, adj_x = 1)
  else seg_lines((xs[i] + xs[i + 1]) / 2, 0.65, labs[[i]], step = 0.27, cex = 1.2, adj_x = 0.5)
}
close_d()


# ---- D07: the range pattern in four pieces (slide: full width, 980 x 230 px) ----
open_d("D07-range-pattern.png", 9.8, 2.1)
pcs  <- c("\\\\b(?:to|at|of)\\\\s+", "(num)", "(?:\\\\s+to\\\\s+(num))?", "\\\\s+percent\\\\b")
txt  <- c("to", "4-3/4", "to 5", "percent")
pcol <- c(acc, blue, acc, blue)
pcex <- 1.4
pw <- sapply(pcs, strwidth, cex = pcex, family = mono)
x <- (W - sum(pw)) / 2; xs <- x + c(0, cumsum(pw))
labs <- list(
  list(list(sg(paste0("to, at or of, then spaces")))),
  list("group 1: the", "lower limit,", list(sg("4-3/4", pcol[2], 2))),
  list(list(sg("optional: "), sg('" to "', pcol[3], 2, mono), sg(" and")), "group 2, the upper",
       list(sg("limit, "), sg("5", pcol[3], 2))),
  list(list(sg(paste0(lq, "percent", rq, " as a whole"))), "word, so not",
       paste0(lq, "percentage", rq)))
for (i in 1:4) {
  mid <- (xs[i] + xs[i + 1]) / 2
  tx(mid, 1.88, txt[i], cex = 1.5, col = pcol[i])
  bracket(xs[i] + 0.04, xs[i + 1] - 0.04, 1.66, side = 3, col = pcol[i])
  tx(xs[i], 1.4, pcs[i], cex = pcex, col = pcol[i], fam = mono, adj = c(0, 0.5))
  bracket(xs[i] + 0.04, xs[i + 1] - 0.04, 1.14, side = 1, col = pcol[i])
  seg_lines(mid, 0.85, labs[[i]], step = 0.25, cex = 1.15, adj_x = 0.5)
}
close_d()


# ---- D08: two hyphens that look the same (slide: small strip, 520 x 170 px) ----
# The glyphs are set in Helvetica, where the two are drawn alike; Menlo draws
# U+2011 shorter than the hyphen key.
open_d("D08-two-hyphens.png", 5.2, 1.7)
hy <- c("-", nbh)
lab <- list(list(sg(as.character(utf8ToInt(hy[1])), acc, 2), sg(": the hyphen key")),
            list(sg(as.character(utf8ToInt(hy[2])), acc, 2), sg(paste0(": the Fed", rq, "s web pages"))))
for (k in 1:2) {
  x0 <- c(0.08, 2.7)[k]; x1 <- x0 + 2.42
  rbox(x0, 0.62, x1, 1.62, col = fill, border = NA)
  seg_line((x0 + x1) / 2, 1.12, list(sg("3"), sg(hy[k], acc), sg("3/4")), cex = 2.6, adj_x = 0.5)
  seg_line((x0 + x1) / 2, 0.32, lab[[k]], cex = 1.2, adj_x = 0.5)
}
close_d()

cat("drawn:", paste(list.files(out, pattern = "^D0"), collapse = ", "), "\n")
