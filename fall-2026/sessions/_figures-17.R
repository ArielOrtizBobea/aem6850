# Diagrams for the session 17 page and slides (text II: language models).
# Base R, plus xml2 and png for the one screenshot. Run from fall-2026/sessions:
#   Rscript _figures-17.R              # every block
#   Rscript _figures-17.R tokens       # setup, then one block
# Writes figures/17-text-llms/*.png. F1 and F2 are drawn at render from data,
# and D9 waits for the two runs; neither is drawn here.
#
# D5 and D12 cut text into the real tokens of the open model used in Part 5:
# byte-level BPE over the vocabulary and merges stored in the model file, run
# on 2026-10-25. The counts match the prompt token counts the local model
# server reports for the same strings (15 for D12, 20 for D5's prompt).
# The statement screenshot is a headless Chrome capture of the cached page,
# made offline by the `statement` block.
#
# Each canvas is set in inches (1 user unit = 1 inch, origin bottom left)
# and drawn at res 200. Every canvas is sized so that 1 inch = 100 px on the
# 1050 x 700 slide at the placement noted above it, so cex 1.15 prints at
# about 19 px, cex 1.2 at 20 px and cex 1.3 at 22 px.
#
# The file stays ASCII: every non-ASCII character is written as a \u escape.

# ---- Run named blocks only: Rscript _figures-17.R <block> [<block> ...] ----
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
out <- "figures/17-text-llms"
dir.create(out, showWarnings = FALSE, recursive = TRUE)

ink  <- "#222222"
acc  <- "#B31B1B"    # the one accent
grey <- "#666666"
rule <- "#BBBBBB"
fill <- "#F2F2F2"    # neutral box fill
tint <- "#F7E6E6"    # a light tint of the accent
blue <- "#3A6C9C"    # link blue, as the Fed's pages use
mono <- if (file.exists("/System/Library/Fonts/Menlo.ttc")) "Menlo" else "mono"
# token chips: light fills, so that neighbours always differ
chip_cols <- c("#F4D6D6", "#D6E4F2", "#DCEBD3", "#F6E5BE", "#E4DAEF")

rq <- "\u2019"; ell <- "\u2026"

# ---- Helpers (open_d to fits as in _figures-16.R) ----
W <- H <- NA; FILE <- NA
open_d <- function(name, w, h) {
  W <<- w; H <<- h; FILE <<- file.path(out, name)
  png(FILE, width = w, height = h, units = "in", res = 200,
      bg = "white", pointsize = 12)
  par(mar = c(0, 0, 0, 0), family = "sans", xpd = NA, col = ink, fg = ink,
      lend = 1, ljoin = 1)
  plot.new()
  plot.window(c(0, w), c(0, h), xaxs = "i", yaxs = "i")
}
close_d <- function() { invisible(dev.off()); cat("Saved:", FILE, "\n") }

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
rbox <- function(x0, y0, x1, y1, r = 0.08, col = NA, border = ink, lwd = 2, lty = 1) {
  q <- seq(0, pi / 2, length.out = 12)
  polygon(c(x1 - r + r * cos(q), x0 + r - r * sin(q),
            x0 + r - r * cos(q), x1 - r + r * sin(q)),
          c(y1 - r + r * sin(q), y1 - r + r * cos(q),
            y0 + r - r * sin(q), y0 + r - r * cos(q)),
          col = col, border = border, lwd = lwd, lty = lty)
}
arr <- function(x0, y0, x1, y1, col = ink, lwd = 2, head = 0.12, wid = 0.06) {
  a <- atan2(y1 - y0, x1 - x0)
  xb <- x1 - head * cos(a); yb <- y1 - head * sin(a)
  segments(x0, y0, xb, yb, col = col, lwd = lwd)
  polygon(c(x1, xb + wid * sin(a), xb - wid * sin(a)),
          c(y1, yb - wid * cos(a), yb + wid * cos(a)), col = col, border = col)
}
# a path through several points, with the head on the last leg
arr_path <- function(x, y, col = ink, lwd = 2, lty = 1, ...) {
  n <- length(x)
  if (n > 2) segments(x[1:(n - 2)], y[1:(n - 2)], x[2:(n - 1)], y[2:(n - 1)], col = col, lwd = lwd, lty = lty)
  arr(x[n - 1], y[n - 1], x[n], y[n], col = col, lwd = lwd, ...)
}
# a piece of a line: text, colour, font (1 plain, 2 bold, 3 italic), family
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
seg_lines <- function(x, y, L, step = 0.25, cex = 1.2, adj_x = 0) {
  for (i in seq_along(L)) seg_line(x, y - (i - 1) * step, L[[i]], cex = cex, adj_x = adj_x)
}
# warn when lines are wider than the box they sit in
fits <- function(L, room, cex, what) {
  w <- max(sapply(L, function(l) seg_w(if (is.character(l)) list(sg(l)) else l, cex)))
  if (w > room) warning(sprintf("too wide for its box (%.2f > %.2f in): %s", w, room, what), call. = FALSE)
}
as_segs <- function(l, font = 1, col = ink) if (is.character(l)) list(sg(l, col, font)) else l
# a box with its lines centred in it; the first line bold if asked
node <- function(x0, y0, x1, y1, L, cex = 1.2, step = 0.25, fill = "white", border = ink,
                 lwd = 1.8, lty = 1, bold_first = FALSE, col = ink, what = "") {
  rbox(x0, y0, x1, y1, col = fill, border = border, lwd = lwd, lty = lty)
  L <- lapply(seq_along(L), function(i) as_segs(L[[i]], if (bold_first && i == 1) 2 else 1, col))
  fits(L, x1 - x0 - 0.14, cex, what)
  seg_lines((x0 + x1) / 2, (y0 + y1) / 2 + (length(L) - 1) / 2 * step, L,
            step = step, cex = cex, adj_x = 0.5)
}
# lines centred under a point, the first centred at y
under <- function(x, y, L, cex = 1.15, step = 0.24, col = grey) {
  seg_lines(x, y, lapply(L, as_segs, col = col), step = step, cex = cex, adj_x = 0.5)
}
# tokens as touching chips from x0, on a line centred at y; a token's leading
# space sits inside its chip. Returns each chip's left and right edge.
chips <- function(tok, x0, y, cex = 1.3, h = 0.38, pad = 0.03, k0 = 0) {
  w <- strwidth(tok, cex = cex) + 2 * pad
  xl <- x0 + c(0, cumsum(w))[seq_along(tok)]; xr <- xl + w
  for (i in seq_along(tok)) {
    rect(xl[i], y - h / 2, xr[i], y + h / 2, col = chip_cols[(k0 + i - 1) %% length(chip_cols) + 1], border = NA)
    tx(xl[i] + pad, y, tok[i], cex = cex, adj = c(0, 0.5))
  }
  invisible(cbind(xl, xr))
}
# split tokens into rows no wider than room
wrap_tok <- function(tok, room, cex, pad = 0.03) {
  w <- strwidth(tok, cex = cex) + 2 * pad
  row <- integer(length(tok)); r <- 1; acc_w <- 0
  for (i in seq_along(tok)) {
    if (acc_w + w[i] > room) { r <- r + 1; acc_w <- 0 }
    row[i] <- r; acc_w <- acc_w + w[i]
  }
  split(seq_along(tok), row)
}
diamond <- function(xc, yc, hw, hh, col = "white", border = ink, lwd = 1.8)
  polygon(xc + c(0, hw, 0, -hw), yc + c(hh, 0, -hh, 0), col = col, border = border, lwd = lwd)
# a cloud: a rounded base and three bumps, outlined, then their insides
# painted over so that only the outer edge stays
cloud <- function(xc, yc, w, h, lwd = 1.8) {
  cx <- xc + w * c(-0.24, 0.03, 0.27); cy <- yc + h * c(0.02, 0.12, -0.02); r <- h * c(0.32, 0.42, 0.3)
  b <- c(xc - w / 2, yc - h / 2, xc + w / 2, yc + 0.05 * h); rr <- h * 0.22
  rbox(b[1], b[2], b[3], b[4], r = rr, col = "white", border = ink, lwd = lwd)
  symbols(cx, cy, circles = r, inches = FALSE, add = TRUE, fg = ink, bg = "white", lwd = lwd)
  e <- 0.014
  rbox(b[1] + e, b[2] + e, b[3] - e, b[4] - e, r = rr - e, col = "white", border = NA)
  symbols(cx, cy, circles = r - e, inches = FALSE, add = TRUE, fg = "white", bg = "white", lwd = 0.5)
}
# small glyphs for D11: a photo, a sound wave, lines of text
photo_glyph <- function(x0, y0, x1, y1) {
  rect(x0, y0, x1, y1, col = "#E3ECF5", border = ink, lwd = 1.6)
  w <- x1 - x0; h <- y1 - y0
  polygon(x0 + w * c(0.05, 0.38, 0.6, 0.75, 0.95), y0 + h * c(0.08, 0.68, 0.36, 0.52, 0.08),
          col = "#8FA9C4", border = NA)
  symbols(x0 + w * 0.78, y0 + h * 0.76, circles = h * 0.11, inches = FALSE, add = TRUE, fg = NA, bg = "#E0B04A")
}
wave_glyph <- function(x0, y0, x1, y1) {
  xs <- seq(x0, x1, length.out = 23); yc <- (y0 + y1) / 2
  amp <- (y1 - y0) / 2 * c(0.2, 0.45, 0.8, 0.5, 0.95, 0.6, 0.3, 0.7, 1, 0.75, 0.4, 0.2,
                           0.55, 0.85, 0.5, 0.3, 0.65, 0.9, 0.45, 0.25, 0.5, 0.3, 0.15)
  segments(xs, yc - amp, xs, yc + amp, col = ink, lwd = 2.4)
}
lines_glyph <- function(x0, y0, x1, y1, n = 3) {
  rect(x0, y0, x1, y1, col = "white", border = ink, lwd = 1.6)
  yy <- seq(y1 - (y1 - y0) / (n + 1), y0 + (y1 - y0) / (n + 1), length.out = n)
  segments(x0 + 0.07, yy, x1 - 0.07 - c(0, 0.1, 0.22)[seq_len(n)], yy, col = grey, lwd = 2.6)
}
# a double-headed arrow
arr2 <- function(x0, y, x1, ...) { arr(x0 + 0.06, y, x1, y, ...); arr(x1 - 0.06, y, x0, y, ...) }
# ==== END BLOCK ====


# ==== BLOCK: two_tasks DEPS: setup ====
# D1, slide 4: the body, under the title (980 x 300 px)
open_d("two-tasks.png", 9.8, 3.0)
cx0 <- c(0.1, 2.1, 4.95, 7.6); cx1 <- c(1.7, 4.45, 7.1, 9.7)
lanes <- list(
  list(y = 2.4, L = list(list("a statement"),
                         list("What target range", "did the FOMC set?"),
                         list("a pattern", "or a model"),
                         list(list(sg("lower", acc, 2, mono), sg(", ", acc, 2), sg("upper", acc, 2, mono)))),
       ref = paste0("FRED", rq, "s daily record")),
  list(y = 0.95, L = list(list("one sentence"),
                          list("Hawkish, dovish", "or neutral?"),
                          list("a model with", "a codebook"),
                          list(list(sg("a label", acc, 2)))),
       ref = "labels two people made by hand"))
for (ln in lanes) {
  y0 <- ln$y - 0.36; y1 <- ln$y + 0.36
  node(cx0[1], y0, cx1[1], y1, ln$L[[1]], fill = fill, border = NA, what = "D1 text")
  node(cx0[2], y0, cx1[2], y1, ln$L[[2]], what = "D1 question")
  node(cx0[3], y0, cx1[3], y1, ln$L[[3]], what = "D1 tool")
  node(cx0[4], y0, cx1[4], y1, ln$L[[4]], fill = tint, border = acc, what = "D1 answer")
  for (k in 1:3) arr(cx1[k] + 0.06, ln$y, cx0[k + 1] - 0.06, ln$y)
  seg_line(cx1[4], y0 - 0.25, list(sg("Reference: ", font = 2), sg(ln$ref)), cex = 1.2, adj_x = 1)
}
close_d()
# ==== END BLOCK ====


# ==== BLOCK: what_a_model_does DEPS: setup ====
# D5, slide 7: the body, under the title (980 x 360 px). The prompt's tokens
# are the open model's; the probabilities are made up, and the figure says so.
d5_tok <- c("Label", " this", " Fed", " sentence", " as", " dov", "ish", ",", " hawk", "ish",
            " or", " neutral", ":", " In", "flation", " is", " well", " above", " target", ".")
stopifnot(paste(d5_tok, collapse = "") ==
            "Label this Fed sentence as dovish, hawkish or neutral: Inflation is well above target.")
open_d("what-a-model-does.png", 9.8, 3.6)
ytop <- 3.42                               # the column heads
# the prompt, in rows of chips
tx(0.1, ytop, "the prompt, cut into tokens", cex = 1.15, col = grey, adj = c(0, 0.5))
rows <- wrap_tok(d5_tok, 3.55, 1.2)
ry <- 2.98 - (seq_along(rows) - 1) * 0.46
k <- 0
for (i in seq_along(rows)) {
  ch <- chips(d5_tok[rows[[i]]], 0.1, ry[i], cex = 1.2, h = 0.36, k0 = k)
  k <- k + length(rows[[i]])
}
ym <- mean(ry)
# the slot where the drawn token is added
sx0 <- max(ch[, 2]) + 0.08; sx1 <- sx0 + strwidth(" hawk", cex = 1.2) + 0.12; sy <- ry[length(ry)]
rbox(sx0, sy - 0.18, sx1, sy + 0.18, r = 0.04, col = "white", border = acc, lwd = 1.8, lty = 2)
tx((sx0 + sx1) / 2, sy, "hawk", cex = 1.2, col = acc)
# the model
arr(3.78, ym, 4.16, ym)
node(4.22, ym - 0.42, 5.28, ym + 0.42, list(list(sg("the", ink, 2)), list(sg("model", ink, 2))),
     cex = 1.25, step = 0.28, fill = fill, what = "D5 model")
arr(5.34, ym, 5.72, ym)
# the next token's probabilities (illustrative)
bx <- c(6.3, 7.3, 8.3, 9.25); p <- c(0.80, 0.14, 0.05, 0.01)
b0 <- 1.25; bh <- 1.75
tx(mean(bx), ytop, "probability of the next token", cex = 1.15, col = grey)
segments(5.85, b0, 9.72, b0, col = grey, lwd = 1.4)
rect(bx - 0.24, b0, bx + 0.24, b0 + p * bh, col = c(acc, rep("#9A9A9A", 3)), border = NA)
for (i in 1:4) tx(bx[i], b0 + p[i] * bh + 0.14, sprintf("%.2f", p[i]), cex = 1.15, col = if (i == 1) acc else ink)
for (i in 1:3) tx(bx[i], b0 - 0.2, c("hawk", "neutral", "dov")[i], cex = 1.2)
tx(bx[4], b0 - 0.2, "any other", cex = 1.2); tx(bx[4], b0 - 0.45, "token", cex = 1.2)
# one token drawn, then added to the end, and again
arr(bx[1], b0 - 0.36, bx[1], 0.62, col = acc)
xs <- strwidth("hawk", cex = 1.2) / 2 + 0.06
rbox(bx[1] - xs, 0.24, bx[1] + xs, 0.6, r = 0.04, col = "white", border = acc, lwd = 2)
tx(bx[1], 0.42, "hawk", cex = 1.2, font = 2, col = acc)
tx(bx[1] - 0.14, 0.78, "one token drawn", cex = 1.15, col = acc, adj = c(1, 0.5))
xl <- (sx0 + sx1) / 2
arr_path(c(bx[1] - xs - 0.04, xl, xl), c(0.42, 0.42, sy - 0.2), col = acc)
seg_lines(0.1, 1.42, list("added to the end;", "next comes \"ish\";", "repeat until the", "reply is complete"), step = 0.25, cex = 1.15)
tx(9.72, 0.24, "illustrative numbers", cex = 1.15, font = 3, col = grey, adj = c(1, 0.5))
close_d()
# ==== END BLOCK ====


# ==== BLOCK: calling_a_model DEPS: setup ====
# D6, slide 10: a strip above two chunks (980 x 130 px)
open_d("calling-a-model.png", 9.8, 1.3)
bx0 <- c(0.05, 3.85, 6.85); bx1 <- c(3.35, 6.35, 9.75)
L <- list(list("your R script", "sends the model id, the", "instructions and one statement"),
          list(paste0("the provider", rq, "s computers"), "run the model"),
          list("the reply", "the answer and", "the tokens billed"))
for (k in 1:3)
  node(bx0[k], 0.06, bx1[k], 1.24, L[[k]], cex = 1.15, step = 0.28, bold_first = TRUE,
       fill = if (k == 3) tint else "white", border = if (k == 3) acc else ink, what = paste("D6", k))
for (k in 1:2) arr(bx1[k] + 0.06, 0.65, bx0[k + 1] - 0.06, 0.65)
close_d()
# ==== END BLOCK ====


# ==== BLOCK: labelling_flow DEPS: setup ====
# D8, slide 20: the body, under the title (980 x 230 px)
open_d("labelling-flow.png", 9.8, 2.45)
heads <- list("Codebook", "Random sample", "Person B", "Compare", "Settle", c("Reference", "labels"))
notes <- list(c("definitions,", "rules for cases", "in between"),
              c("2,480 Fed", "sentences"),
              c("each labels", "on their own"),
              list("same label on", list(sg("90.7%", acc, 2))),
              c("the codebook;", "new rules for", "new cases"),
              c("one label per", "sentence"))
cexh <- 1.2; cexn <- 1.15; pad <- 0.12
bw <- sapply(heads, function(h) max(strwidth(h, cex = cexh, font = 2))) + 2 * pad
nw <- sapply(notes, function(L) max(sapply(L, function(l) seg_w(as_segs(l), cexn))))
cw <- pmax(bw, nw)
gap <- (W - 0.1 - sum(cw)) / 5
stopifnot(gap > 0.3)
cxl <- 0.05 + c(0, cumsum(cw + gap))[1:6]; cc <- cxl + cw / 2
yb <- 1.3; hh <- 0.3                       # the main row: centre and half height
ya <- yb + 0.72                            # Person A, above Person B
for (k in 1:6) {
  last <- k == 6
  node(cc[k] - bw[k] / 2, yb - hh, cc[k] + bw[k] / 2, yb + hh,
       lapply(heads[[k]], function(h) list(sg(h, ink, 2))), cex = cexh, step = 0.25,
       fill = if (last) tint else if (k == 1) fill else "white",
       border = if (last) acc else if (k == 1) NA else ink, what = heads[[k]][1])
  under(cc[k], yb - hh - 0.24, notes[[k]], cex = cexn)
}
node(cc[3] - bw[3] / 2, ya - hh, cc[3] + bw[3] / 2, ya + hh, list("Person A"), cex = cexh,
     bold_first = TRUE, what = "Person A")
# arrows: edge to edge; the sample forks to A and B, and both meet at Compare
ex <- function(k, side) cc[k] + side * bw[k] / 2
arr(ex(1, 1) + 0.05, yb, ex(2, -1) - 0.05, yb)
arr(ex(2, 1) + 0.05, yb, ex(3, -1) - 0.05, yb)
arr(ex(2, 1) + 0.05, yb + 0.14, ex(3, -1) - 0.05, ya)
arr(ex(3, 1) + 0.05, yb, ex(4, -1) - 0.05, yb)
arr(ex(3, 1) + 0.05, ya, ex(4, -1) - 0.05, yb + 0.14)
for (k in 4:5) arr(ex(k, 1) + 0.05, yb, ex(k + 1, -1) - 0.05, yb)
close_d()
# ==== END BLOCK ====


# ==== BLOCK: saving_replies DEPS: setup ====
# D10, slide 46: the body, above three code lines (980 x 230 px)
open_d("saving-replies.png", 9.8, 2.3)
ym <- 0.75; yt <- 1.8                      # the main row and the skip row
node(0.05, ym - 0.28, 1.05, ym + 0.28, list("items"), cex = 1.2, fill = fill, border = NA)
arr(1.1, ym, 1.42, ym)
dx <- 2.45; dhw <- 1.0; dhh <- 0.6
diamond(dx, ym, dhw, dhh)
seg_lines(dx, ym + 0.12, list("file saved", "already?"), step = 0.25, cex = 1.15, adj_x = 0.5)
# no: call, write
c1 <- c(3.95, 5.5); c2 <- c(5.95, 7.75); c3 <- c(8.2, 9.75)
arr(dx + dhw + 0.03, ym, c1[1] - 0.06, ym)
tx(dx + dhw + 0.12, ym - 0.2, "no", cex = 1.15, font = 2, adj = c(0, 0.5))
node(c1[1], ym - 0.3, c1[2], ym + 0.3, list("call the model"), cex = 1.15)
arr(c1[2] + 0.06, ym, c2[1] - 0.06, ym)
node(c2[1], ym - 0.3, c2[2], ym + 0.3, list("write one", "JSON file"), cex = 1.15, step = 0.24)
arr(c2[2] + 0.06, ym, c3[1] - 0.06, ym)
node(c3[1], ym - 0.3, c3[2], ym + 0.3, list("the analysis", "reads the files"), cex = 1.15,
     step = 0.24, fill = tint, border = acc)
# yes: skip
arr_path(c(dx, dx, c1[1] - 0.06), c(ym + dhh + 0.02, yt, yt))
tx(dx - 0.12, ym + dhh + 0.22, "yes", cex = 1.15, font = 2, adj = c(1, 0.5))
node(c1[1], yt - 0.27, c2[2], yt + 0.27, list(list(sg("skip ", font = 2), sg("(no call, no cost)"))), cex = 1.15)
arr_path(c(c2[2] + 0.06, mean(c3), mean(c3)), c(yt, yt, ym + 0.32))
close_d()
# ==== END BLOCK ====


# ==== BLOCK: how_models_were_trained DEPS: setup ====
# D11, slide 26: the body, under the title (980 x 330 px)
open_d("how-models-were-trained.png", 9.8, 3.3)
ry <- c(2.88, 2.05, 1.22); hh <- 0.32
labs <- c("Text", "Images", "Speech")
desc <- list(list("the next word in raw text"),
             list("photos paired with the text posted beside them",
                  list(sg("online "), sg("(400 million pairs)", acc, 2))),
             list("audio paired with transcripts people had posted",
                  list(sg("online "), sg("(680,000 hours)", acc, 2))))
for (k in 1:3) {
  node(0.05, ry[k] - hh, 1.3, ry[k] + hh, list(labs[k]), cex = 1.25, bold_first = TRUE,
       fill = fill, border = NA)
  fits(desc[[k]], W - 4.05 - 0.05, 1.2, labs[k])
  seg_lines(4.05, ry[k] + (length(desc[[k]]) - 1) * 0.13, desc[[k]], step = 0.26, cex = 1.2)
}
# glyphs, between x 1.6 and 3.75
g0 <- 1.6; g1 <- 3.75
seg_line(g0, ry[1], list(sg(paste0(ell, "the sky is "), grey)), cex = 1.15)
w <- strwidth(paste0(ell, "the sky is "), cex = 1.15)
tw <- strwidth("blue", cex = 1.15, font = 2)
rbox(g0 + w + 0.02, ry[1] - 0.17, g0 + w + tw + 0.16, ry[1] + 0.17, r = 0.04, col = "white", border = acc, lwd = 1.8, lty = 2)
tx(g0 + w + 0.09, ry[1], "blue", cex = 1.15, font = 2, col = acc, adj = c(0, 0.5))
photo_glyph(g0, ry[2] - 0.26, g0 + 0.75, ry[2] + 0.26)
arr2(g0 + 0.85, ry[2], g1 - 0.85, col = ink, lwd = 1.8, head = 0.1, wid = 0.05)
lines_glyph(g1 - 0.75, ry[2] - 0.26, g1, ry[2] + 0.26)
wave_glyph(g0, ry[3] - 0.26, g0 + 0.75, ry[3] + 0.26)
arr2(g0 + 0.85, ry[3], g1 - 0.85, col = ink, lwd = 1.8, head = 0.1, wid = 0.05)
lines_glyph(g1 - 0.75, ry[3] - 0.26, g1, ry[3] + 0.26)
# then tuning by people
node(0.05, 0.08, 9.75, 0.62, list(list(sg("Then ", acc, 2),
     sg("people wrote answers and ranked replies to tune the language models"))),
     cex = 1.2, fill = tint, border = acc)
close_d()
# ==== END BLOCK ====


# ==== BLOCK: tokens DEPS: setup ====
# D12, slide 36: a strip under the title (980 x 190 px)
d12_tok <- c("In", "flation", " remains", " elevated", ",", " and", " the", " Committee",
             " is", " highly", " attentive", " to", " inflation", " risks", ".")
d12_txt <- "Inflation remains elevated, and the Committee is highly attentive to inflation risks."
stopifnot(paste(d12_tok, collapse = "") == d12_txt)
open_d("tokens.png", 9.8, 1.9)
cx <- 1.55
r1 <- chips(d12_tok[1:8], 0.1, 1.6, cex = 1.55, h = 0.46)
r2 <- chips(d12_tok[9:15], 0.1, 0.92, cex = 1.55, h = 0.46, k0 = 8)
for (r in list(list(r1, 1.6, 0), list(r2, 0.92, 8)))
  tx(rowMeans(r[[1]]), r[[2]] - 0.36, seq_len(nrow(r[[1]])) + r[[3]], cex = 1.0, col = grey)
xr <- max(r1[, 2], r2[, 2]) + 0.45
seg_line(xr, 1.62, list(sg(length(d12_tok), acc, 2), sg(" tokens", acc, 2)), cex = 1.5)
seg_line(xr, 1.27, list(sg(paste(nchar(d12_txt), "characters"), grey)), cex = 1.15)
tx(0.1, 0.2, "tokens of one open model; other models cut text differently", cex = 1.15,
   font = 3, col = grey, adj = c(0, 0.5))
close_d()
# ==== END BLOCK ====


# ==== BLOCK: hosted_or_local DEPS: setup ====
# D13, slide 38: a strip under the title (980 x 220 px)
open_d("hosted-or-local.png", 9.8, 2.2)
c0 <- c(0.05, 2.3, 4.45, 7.0); c1 <- c(1.85, 4.0, 6.55, 9.75)
yt <- 1.68; yb <- 0.52; hh <- 0.34
# a hosted model
node(c0[1], yt - hh, c1[1], yt + hh, list("your R script"), cex = 1.2, fill = fill, border = NA)
cloud(mean(c(c0[2], c1[2])), yt - 0.05, 1.7, 0.66)
tx(mean(c(c0[2], c1[2])), yt - 0.12, "the internet", cex = 1.2)
node(c0[3], yt - hh, c1[3], yt + hh, list("a closed model on the", paste0("provider", rq, "s computers")), cex = 1.2, step = 0.25)
node(c0[4], yt - hh, c1[4], yt + hh, list("a bill per token"), cex = 1.2, fill = tint, border = acc, col = acc)
arr(c1[1] + 0.06, yt, c0[2] - 0.02, yt)
arr(c1[2] + 0.02, yt, c0[3] - 0.06, yt)
arr(c1[3] + 0.06, yt, c0[4] - 0.06, yt)
# an open model on the laptop
node(c0[1], yb - hh, c1[1], yb + hh, list("your R script"), cex = 1.2, fill = fill, border = NA)
node(c0[2], yb - hh, c1[3], yb + hh, list("an open-weight model file", "in a model server on your laptop"), cex = 1.2, step = 0.25)
node(c0[4], yb - hh, c1[4], yb + hh, list("no bill; the text never", "leaves your computer"),
     cex = 1.2, step = 0.25)
arr(c1[1] + 0.06, yb, c0[2] - 0.06, yb)
arr(c1[3] + 0.06, yb, c0[4] - 0.06, yb)
close_d()
# ==== END BLOCK ====


# ==== BLOCK: agent_route DEPS: setup ====
# D14, slide 41: the body, under the title (980 x 260 px)
open_d("agent-route.png", 9.8, 2.6)
bw <- 2.2; g <- (W - 0.1 - 4 * bw) / 3
x0 <- 0.05 + (0:3) * (bw + g); x1 <- x0 + bw
y0 <- 0.52; y1 <- 2.52
heads <- list(c("A coding agent", "writes the pipeline"),
              c("A test run on 20", "sentences, judged by", "their hand labels"),
              c("The open model labels", "all 2,480 sentences", "on your computer"),
              c("The hand-labelled", "sample judges the run"))
notes <- list(c("prompt file, answer", "format, saving loop"),
              c("seconds; the", "pipeline works"),
              c("no charge per call"),
              c("agreement rate,", "confusion table"))
for (k in 1:4) {
  last <- k == 4
  rbox(x0[k], y0, x1[k], y1, col = if (last) tint else "white", border = if (last) acc else ink, lwd = 1.8)
  symbols(x0[k] + 0.22, y1 - 0.22, circles = 0.14, inches = FALSE, add = TRUE, fg = acc, bg = acc)
  tx(x0[k] + 0.22, y1 - 0.22, k, cex = 1.1, font = 2, col = "white")
  fits(as.list(heads[[k]]), bw - 0.2, 1.15, paste("D14 head", k))
  fits(as.list(notes[[k]]), bw - 0.2, 1.15, paste("D14 note", k))
  for (i in seq_along(heads[[k]]))
    tx(x0[k] + 0.12, y1 - 0.56 - (i - 1) * 0.25, heads[[k]][i], cex = 1.15, font = 2, adj = c(0, 0.5))
  for (i in seq_along(notes[[k]]))
    tx(x0[k] + 0.12, y0 + 0.2 + (length(notes[[k]]) - i) * 0.25, notes[[k]][i], cex = 1.15,
       col = grey, adj = c(0, 0.5))
  if (k < 4) arr(x1[k] + 0.05, (y0 + y1) / 2, x0[k + 1] - 0.05, (y0 + y1) / 2)
}
close_d()
# ==== END BLOCK ====


# ==== BLOCK: uses_map DEPS: setup ====
# D16, slide 7: three uses, each with a real input and what a model returns
# (980 x 400 px). Classify takes the top row with two examples, a headline and
# a survey answer coded into a category. Examples: Lopez-Lira & Tang (JFE
# 2026), Mellon et al. (Research & Politics 2024), Li et al. (RFS 2026),
# Allen & Hatfield (FEDS 2025).
open_d("uses-map.png", 9.8, 4.0)
cells <- list(
  list("Classify", "one label from a list: good or bad news, a survey category",
       c("\u201cCigna Calls Off Humana Pursuit,", "Plans Big Stock Buyback\u201d"),
       c("for Humana:", "bad news")),
  list(NULL, NULL,
       c("\u201cMost important issue facing", "the country?\u201d  \u201cImmergration\u201d"),
       c("category:", "immigration")),
  list("Extract fields", "named values in the text",
       c("analyst report on Macy\u2019s, 2012:", "\u201cfocused selling culture\u201d \u2026",
         "\u201cdouble-digit earnings growth\u201d"),
       c("cause:", "selling culture", "effect:", "earnings growth")),
  list("Match names", "the same entity in two lists",
       c("\u201cMellat Ins. Co.\u201d", "vs \u201cMellat Insurance Company\u201d"),
       c("model: the same", "firm; edit distance:", "no match")))
x0s <- c(0.05, 5.0); y1s <- c(3.95, 1.95); cw <- 4.75
k <- 0
for (r in 1:2) for (cc in 1:2) {
  k <- k + 1; u <- cells[[k]]; x0 <- x0s[cc]; y1 <- y1s[r]
  if (!is.null(u[[1]]))
    seg_line(x0, y1 - 0.17, list(sg(u[[1]], acc, 2), sg(paste0("  \u2014 ", u[[2]]), grey)), cex = 1.15)
  node(x0, y1 - 1.75, x0 + 2.75, y1 - 0.42, as.list(u[[3]]), cex = 1.05, step = 0.26, fill = fill, border = NA,
       what = if (is.null(u[[1]])) "Classify" else u[[1]])
  arr(x0 + 2.8, y1 - 1.085, x0 + 2.98, y1 - 1.085)
  node(x0 + 3.02, y1 - 1.75, x0 + cw, y1 - 0.42, as.list(u[[4]]), cex = 1.05, step = 0.26, fill = tint,
       border = acc, col = acc, what = if (is.null(u[[1]])) "Classify" else u[[1]])
}
close_d()
# ==== END BLOCK ====


# ==== BLOCK: statement DEPS: setup ====
# S1, slide 3: the left column (about 475 px wide). A headless Chrome capture
# of the cached statement page of 22 March 2023 (federalreserve.gov, public
# domain), taken offline: the date, the title and the decision paragraph are
# copied from the cached page into a local page with no scripts or links,
# styled in the site's colours (Arial #333, a Georgia title in #163855) at
# 450 px text width, and Chrome runs with every host name unresolvable and a
# dead proxy, so it cannot reach the network. The paragraph is cut after the
# line that ends the blue sentence. The words are the page's own.
library(xml2)
pg <- read_html("data/15-scraping/cache/monetary20230322a.htm")
date_html  <- as.character(xml_find_first(pg, "//p[@class='article__time']"))
title_html <- as.character(xml_find_first(pg, "//h3[@class='title']"))
ps <- xml_find_all(pg, "//div[@id='article']//p")
dec <- ps[grepl("decided to raise the target range", xml_text(ps), fixed = TRUE)]
stopifnot(length(dec) == 1)
p_html <- as.character(dec)
yellow <- "the Committee decided to raise the target range for the federal funds rate to 4-3/4 to 5 percent"
blue   <- paste("The Committee anticipates that some additional policy firming may be appropriate",
                "in order to attain a stance of monetary policy that is sufficiently restrictive",
                "to return inflation to 2 percent over time.")
stopifnot(grepl(yellow, p_html, fixed = TRUE), grepl(blue, p_html, fixed = TRUE))
p_html <- sub(yellow, paste0('<mark class="y">', yellow, "</mark>"), p_html, fixed = TRUE)
p_html <- sub(blue, paste0('<mark class="b">', blue, "</mark>"), p_html, fixed = TRUE)
p_html <- sub("^<p>", '<p class="dec">', p_html)
css <- "
html, body { margin: 0; background: #fff; }
body { width: 450px; padding: 12px 12px 0; font-family: Arial, Helvetica, sans-serif; color: #333; }
.article__time { font-size: 17px; color: #163855; margin: 0 0 8px; }
h3.title { font-family: Georgia, serif; font-size: 25px; font-weight: normal; color: #163855;
           margin: 0 0 18px; line-height: 1.25; }
.cut { border-top: 2px dashed #bbb; height: 0; }
p.dec { font-size: 18px; line-height: 29px; margin: 18px 0 14px; max-height: calc(10 * 29px); overflow: hidden; }
mark { color: inherit; padding: 1px 0; }
mark.y { background: #FFEC99; }
mark.b { background: #CFE2F6; }
"
page <- c("<!doctype html><html><head><meta charset='utf-8'><style>", css, "</style></head><body>",
          date_html, title_html, "<div class='cut'></div>", p_html, "<div class='cut'></div>",
          "</body></html>")
tmp <- tempfile("s1-"); dir.create(tmp)
html <- file.path(tmp, "statement.html"); shot <- file.path(tmp, "shot.png")
writeLines(page, html)
chrome <- "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
system2(chrome, shQuote(c("--headless=new", paste0("--screenshot=", shot), "--window-size=474,700",
                          "--force-device-scale-factor=2", "--hide-scrollbars",
                          "--host-resolver-rules=MAP * ~NOTFOUND", "--proxy-server=127.0.0.1:9",
                          "--disable-background-networking", "--disable-component-update",
                          "--no-first-run", "--no-default-browser-check",
                          paste0("--user-data-dir=", file.path(tmp, "profile")),
                          paste0("file://", html))), stdout = FALSE, stderr = FALSE)
stopifnot(file.exists(shot))
im <- png::readPNG(shot)
ink_rows <- which(apply(im[, , 1:3], 1, min) < 0.9)   # rows with any drawn pixel
FILE <- file.path(out, "statement-2023-03-22.png")
png::writePNG(im[1:min(dim(im)[1], max(ink_rows) + 14), , ], FILE)
unlink(tmp, recursive = TRUE)
cat("Saved:", FILE, "\n")
# ==== END BLOCK ====


# ==== BLOCK: calling_a_model_sentence DEPS: setup ====
# D6 again for section 3, slide "Calling the closed model from R": one sentence, not one statement
open_d("calling-a-model-sentence.png", 9.8, 1.3)
bx0 <- c(0.05, 3.85, 6.85); bx1 <- c(3.35, 6.35, 9.75)
L <- list(list("your R script", "sends the model id, the", "instructions and one sentence"),
          list(paste0("the provider", rq, "s computers"), "run the model"),
          list("the reply", "the answer and", "the tokens billed"))
for (k in 1:3)
  node(bx0[k], 0.06, bx1[k], 1.24, L[[k]], cex = 1.15, step = 0.28, bold_first = TRUE,
       fill = if (k == 3) tint else "white", border = if (k == 3) acc else ink, what = paste("D6s", k))
for (k in 1:2) arr(bx1[k] + 0.06, 0.65, bx0[k + 1] - 0.06, 0.65)
close_d()
# ==== END BLOCK ====
