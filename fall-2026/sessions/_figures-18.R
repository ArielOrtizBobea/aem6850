# Figures for the session 18 page and slides (documents & scans).
# Base R plus magick (crops and composites), pdftools (page renders) and
# maps (one small map). Run from fall-2026/sessions:
#   Rscript _figures-18.R               # every block
#   Rscript _figures-18.R table5_crop   # setup, then one block
# Writes figures/18-documents/*. Inputs: data/18-documents/ (the session
# project) and, for the two blocks marked so, the prep scratch folder.
#
# Each canvas is set in inches (1 user unit = 1 inch, origin bottom left)
# and drawn at res 200, sized so that 1 inch is about 100 px on the
# 1050 x 700 slide at the placement noted above it, so cex 1.2 prints at
# about 20 px.

# ---- Run named blocks only: Rscript _figures-18.R <block> [<block> ...] ----
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
suppressPackageStartupMessages({ library(magick); library(pdftools) })
out  <- "figures/18-documents"
dat  <- "data/18-documents"
dir.create(out, showWarnings = FALSE, recursive = TRUE)
ink  <- "#222222"; acc <- "#B31B1B"; grey <- "#666666"; rule <- "#BBBBBB"
fill <- "#F2F2F2"; tint <- "#F7E6E6"; blue <- "#3A6C9C"
# Crop a page rendered at `dpi` to a box given in PDF points (72 per inch).
crop_pts <- function(png, x0, y0, x1, y1, dpi = 150) {
  k <- dpi / 72
  image_crop(image_read(png), geometry_area(round((x1 - x0) * k), round((y1 - y0) * k),
                                           round(x0 * k), round(y0 * k)))
}
band <- function(img, h = 6, col = "#FFFFFF") image_blank(image_info(img)$width, h, col)
dots <- function(w, h = 26) {                 # a row of dots marking cut rows
  im <- image_blank(w, h, "white")
  image_draw(im); points(seq(w * 0.5 - 30, w * 0.5 + 30, by = 30), rep(h / 2, 3), pch = 16, cex = 0.8, col = grey); dev.off()
  im
}
# ==== END BLOCK ====

# ==== BLOCK: pages DEPS: setup ====
# Fed pages 6, 8 and 9 at 150 dpi, into the scratch of this script.
pg <- pdf_convert(file.path(dat, "h41.pdf"), pages = c(6, 8, 9), dpi = 150,
                  filenames = file.path(tempdir(), c("p6.png", "p8.png", "p9.png")), verbose = FALSE)
names(pg) <- c("p6", "p8", "p9")
# ==== END BLOCK ====

# ==== BLOCK: table5_crop DEPS: pages ====
# Slide "Table 5 of the H.4.1": the table title, the header and the rows down
# to Total assets (y 404 pt), page 6. Placed at 92% width.
im <- crop_pts(pg["p6"], 28, 60, 590, 413)
image_write(image_border(im, rule, "1x1"), file.path(out, "table5-crop.png"))
# ==== END BLOCK ====

# ==== BLOCK: table6_pages DEPS: pages ====
# Slide "Table 6, one table printed across two pages": page 8's title and
# header with its Total assets row, then page 9's with Total liabilities and
# Total liabilities and capital. Rows between are cut and marked with dots.
top8 <- crop_pts(pg["p8"], 10, 60, 600, 114)
row8 <- crop_pts(pg["p8"], 10, 264, 600, 281)
top9 <- crop_pts(pg["p9"], 10, 60, 600, 114)
row9a <- crop_pts(pg["p9"], 10, 252, 600, 268)
row9b <- crop_pts(pg["p9"], 10, 323, 600, 340)
w <- image_info(top8)$width
p8 <- image_append(c(top8, dots(w), row8), stack = TRUE)
p9 <- image_append(c(top9, dots(w), row9a, band(row9a, 4), row9b), stack = TRUE)
lab <- function(txt) { im <- image_blank(w, 34, "white"); image_annotate(im, txt, size = 26, color = acc, gravity = "west", location = "+8+0") }
im <- image_append(c(lab("page 8"), image_border(p8, rule, "1x1"), band(p8, 18), lab("page 9"), image_border(p9, rule, "1x1")), stack = TRUE)
image_write(im, file.path(out, "table6-pages.png"))
# ==== END BLOCK ====

# ==== BLOCK: comp1899 DEPS: setup ====
# The 1899 page: full page at 100 dpi for the paper slide, and the table's
# top (title, header, New England block) with its last row for Part 3.
# Reads the two renders made in prep (pdftoppm) from the scratch folder.
scr <- "/private/tmp/claude-501/-Users-ao332-github-aem6850/f96c179c-1948-428f-95c1-3931b2b58aa5/scratchpad/s18fig"
full <- image_read(file.path(scr, "comp1899_100-693.png"))
image_write(image_border(full, rule, "1x1"), file.path(out, "comp1899-page.png"))
p200 <- image_read(file.path(scr, "comp1899_200-693.png"))
info <- image_info(p200)
# boxes found by eye on the 110-dpi render, scaled to 200 dpi
k <- 200 / 110
topbox <- geometry_area(round(560 * k), round((275 - 75) * k), round(45 * k), round(75 * k))   # title to Total New England
botbox <- geometry_area(round(560 * k), round((858 - 836) * k), round(45 * k), round(836 * k))  # Total United States
top <- image_crop(p200, topbox); bot <- image_crop(p200, botbox)
wd <- image_info(top)$width
im <- image_append(c(top, dots(wd), bot), stack = TRUE)
image_write(image_border(im, rule, "1x1"), file.path(out, "comp1899-table.png"))
# ==== END BLOCK ====

# ==== BLOCK: three_documents DEPS: pages ====
# Slide "Three documents to turn into data": page 6 of the H.4.1, the 1899
# page and the 1870s sheet, side by side at one height.
scr <- "/private/tmp/claude-501/-Users-ao332-github-aem6850/f96c179c-1948-428f-95c1-3931b2b58aa5/scratchpad/s18fig"
h <- 900
a <- image_scale(image_read(pg["p6"]), paste0("x", h))
b <- image_scale(image_read(file.path(scr, "comp1899_100-693.png")), paste0("x", h))
sheet <- if (file.exists(file.path(dat, "sheets/abbotsbury_1870s.jpg"))) file.path(dat, "sheets/abbotsbury_1870s.jpg") else file.path(scr, "sheet-000.jpg")
c3 <- image_scale(image_read(sheet), paste0("x", h))
gap <- image_blank(40, h, "white")
cap <- function(img, txt) {
  w <- image_info(img)$width
  l <- image_blank(w, 44, "white")
  l <- image_annotate(l, txt, size = 30, color = ink, gravity = "center")
  image_append(c(image_border(img, rule, "1x1"), l), stack = TRUE)
}
im <- image_append(c(cap(a, "born-digital PDF"), gap, cap(b, "scan of print"), gap, cap(c3, "handwriting")))
image_write(im, file.path(out, "three-documents.png"))
# ==== END BLOCK ====

# ==== BLOCK: doc_crops DEPS: setup ====
# Slide "Our three documents and what is already typed": the top of each
# document, cut to one 4:3 shape so the three sit in one table row.
# Boxes in pixels: H.4.1 page 1 at 150 dpi, the 1899 page at 300 dpi
# (comp1899_p.png), the 1870s sheet as published (170 ppi).
p1 <- pdf_convert(file.path(dat, "h41.pdf"), pages = 1, dpi = 150,
                  filenames = file.path(tempdir(), "h41_p1.png"), verbose = FALSE)
cut43 <- function(file, x0, y0, w) {
  im <- image_crop(image_read(file), geometry_area(w, round(w * 3 / 4), x0, y0))
  image_border(image_scale(im, "900x675!"), rule, "2x2")
}
image_write(cut43(p1, 40, 50, 1200), file.path(out, "doc-h41.png"))
image_write(cut43(file.path(dat, "comp1899_p.png"), 60, 20, 1540), file.path(out, "doc-comp1899.png"))
image_write(cut43(file.path(dat, "sheets/abbotsbury_1870s.jpg"), 70, 40, 590), file.path(out, "doc-sheet.png"))
# ==== END BLOCK ====

# ==== BLOCK: agent_routes DEPS: setup ====
# Slide "A coding agent can take any route": three documents on the left,
# the five routes in the middle, the check on the right; the agent spans the
# three routes it can run. Placed at 78% width (about 820 px): canvas 9 x 3.6 in.
png(file.path(out, "agent-routes.png"), width = 9, height = 3.6, units = "in", res = 200)
par(mar = c(0, 0, 0, 0), family = "sans")
plot.new(); plot.window(xlim = c(0, 9), ylim = c(0, 3.6))
box_ <- function(x, y, w, h, txt, col = fill, border = rule, cex = 1.05, tcol = ink, lwd = 1.2) {
  rect(x - w / 2, y - h / 2, x + w / 2, y + h / 2, col = col, border = border, lwd = lwd)
  text(x, y, txt, cex = cex, col = tcol)
}
docs <- c("born-digital PDF", "scan of print", "handwriting")
routes <- c("text layer", "OCR", "vision model", "hand entry", "volunteer transcription")
dy <- c(2.9, 1.8, 0.7)
for (i in 1:3) box_(1.25, dy[i], 2.2, 0.6, docs[i])
ry <- c(3.1, 2.5, 1.9, 1.15, 0.5)
for (j in 1:5) box_(4.5, ry[j], 2.1, 0.5, routes[j])
box_(7.75, 1.8, 2.2, 0.9, "the sum the\npage prints", col = tint, border = acc)
arr <- function(x0, y0, x1, y1) arrows(x0, y0, x1, y1, length = 0.08, col = grey, lwd = 1.3)
arr(2.4, 2.9, 3.4, 3.1)                                  # PDF -> text layer
arr(2.4, 1.82, 3.4, 2.5); arr(2.4, 1.78, 3.4, 1.9)       # scan -> OCR, vision
arr(2.4, 0.74, 3.4, 1.9); arr(2.4, 0.7, 3.4, 1.15); arr(2.4, 0.66, 3.4, 0.5)   # handwriting -> vision, hand, volunteers
for (j in 1:5) arr(5.6, ry[j], 6.6, 1.8 + (ry[j] - 1.8) * 0.25)
rect(3.3, 1.58, 5.7, 3.42, border = acc, lwd = 1.6, lty = 2)
text(4.5, 3.5, "a coding agent can run any of these three", cex = 0.95, col = acc)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: abbotsbury_map DEPS: setup ====
# Slide "Five ten-year sheets from Abbotsbury Castle": southern England with
# the station marked. Placed at about 400 px wide: canvas 3.6 x 2.4 in.
suppressPackageStartupMessages(library(maps))
png(file.path(out, "abbotsbury-map.png"), width = 3.6, height = 2.4, units = "in", res = 200)
par(mar = c(0, 0, 0, 0), family = "sans")
map("world", regions = c("UK", "Ireland", "France"), xlim = c(-6.5, 1.6), ylim = c(49.5, 53.4),
    col = fill, fill = TRUE, border = rule, lwd = 0.8)
points(-2.60, 50.665, pch = 21, bg = acc, col = acc, cex = 1.5)
text(-2.60, 50.665, "Abbotsbury, Dorset", pos = 3, offset = 0.6, cex = 1.05, col = ink)
text(-0.12, 51.5, "London", pos = 1, cex = 0.9, col = grey); points(-0.12, 51.5, pch = 16, cex = 0.5, col = grey)
dev.off()
# ==== END BLOCK ====

# ==== BLOCK: sheets DEPS: setup ====
# The two sheet images the slides show, copied from the project.
for (s in c("1870s", "1880s")) {
  f <- file.path(dat, sprintf("sheets/abbotsbury_%s.jpg", s))
  if (file.exists(f)) file.copy(f, file.path(out, sprintf("sheet-%s.jpg", s)), overwrite = TRUE)
}
# ==== END BLOCK ====

# ==== BLOCK: dpi_crops DEPS: setup ====
# Slide "The Fed's page 8 at 300 and 100 dpi": the Total assets row of page 8
# from the two OCR input images made in prep (ocr/h41_p8_300.png, _100.png).
# The row sits at y 264-281 pt; x 10-780 pt (the page is landscape, 792 pt wide).
im <- lapply(c(300, 100), function(d) {
  f <- file.path(dat, sprintf("ocr/h41_p8_%d.png", d))
  r <- crop_pts(f, 10, 262, 780, 283, dpi = d)
  r <- image_scale(r, sprintf("%dx", round(1700 * d / 300)))   # one scale for both: at 100 dpi the row is a third as wide
  l <- image_blank(1700, 40, "white")
  l <- image_annotate(l, sprintf("%d dpi", d), size = 30, color = acc, gravity = "west", location = "+6+0")
  image_append(c(l, image_border(r, rule, "1x1")), stack = TRUE)
})
image_write(image_append(c(im[[1]], band(im[[1]], 14), im[[2]]), stack = TRUE), file.path(out, "dpi-crops.png"))
# ==== END BLOCK ====

# ==== BLOCK: cells_1870s DEPS: setup ====
# Slide "Model against volunteers, cell by cell": the one cell of the 1870s
# sheet where the two readings differ (September 1877), from the crop made
# in prep (sheets/crops/, 130 x 90 px around the cell at 3x), with the two
# readings and the written total beside it. Placed at about 70% width.
cr <- image_read(file.path(dat, "sheets/crops/1870s_1877_sep.png"))
cr <- image_scale(cr, "x240")
l <- image_blank(820, image_info(cr)$height, "white")
l <- image_annotate(l, "September 1877", size = 30, color = ink, gravity = "northwest", location = "+18+22")
l <- image_annotate(l, "volunteers 2.55   model 2.65", size = 28, color = ink, gravity = "northwest", location = "+18+78")
l <- image_annotate(l, "written total 34.47: the months add up only with 2.55", size = 26, color = acc, gravity = "northwest", location = "+18+134")
im <- image_append(c(image_border(cr, rule, "1x1"), l))
image_write(im, file.path(out, "cells-1870s.png"))
# ==== END BLOCK ====


# ==== BLOCK: col_1877 DEPS: setup ====
# Slide "Your typing of 1877 against the volunteers'": the month labels and
# the 1877 column of the 1870s sheet, side by side, at 2x, so students can
# type the twelve months from the screen. Pixel boxes on the 671 x 1090 JPEG.
sh <- image_read(file.path(dat, "sheets/abbotsbury_1870s.jpg"))
y0 <- 245; y1 <- 682
labs <- image_crop(sh, geometry_area(86, y1 - y0, 82, y0))
c77  <- image_crop(sh, geometry_area(49, y1 - y0, 464, y0))
im <- image_append(c(labs, image_blank(10, y1 - y0, "white"), c77))
im <- image_scale(im, paste0("x", 2 * (y1 - y0)))
image_write(image_border(im, rule, "1x1"), file.path(out, "col-1877.png"))
# ==== END BLOCK ====


# ==== BLOCK: cells_1880s DEPS: setup ====
# Slide "The 1880s sheet handed to a coding agent": the two braced cells,
# June/July 1886 and January/February 1887, from the prep crops.
a <- image_scale(image_read(file.path(dat, "sheets/crops/1880s_1886_jun.png")), "x200")
b <- image_scale(image_read(file.path(dat, "sheets/crops/1880s_1887_jan.png")), "x200")
lab <- function(img, txt) {
  l <- image_blank(image_info(img)$width, 40, "white")
  l <- image_annotate(l, txt, size = 22, color = ink, gravity = "center")
  image_append(c(image_border(img, rule, "1x1"), l), stack = TRUE)
}
im <- image_append(c(lab(a, "Jun + Jul 1886: 2.82"), image_blank(30, 242, "white"), lab(b, "Jan + Feb 1887: 4.57")))
image_write(im, file.path(out, "cells-1880s.png"))
# ==== END BLOCK ====


# ==== BLOCK: paper_figures DEPS: setup ====
# Slides "Railroads and incomes in colonial India" and "London fog and deaths":
# figures lifted from the two papers. Donaldson (AER, 2018): Figure 1, four
# of its eight decade panels, from the open-access copy on MIT's DSpace.
# Hanlon (REStat, 2024): Figures 9 and 11 of the NBER working-paper version
# (the published PDF is paywalled). The PDFs go to a temp folder.
ua  <- c("User-Agent" = "Mozilla/5.0")
get <- function(url, name) {
  f <- file.path(tempdir(), name)
  if (!file.exists(f)) download.file(url, f, mode = "wb", quiet = TRUE, headers = ua)
  f
}
don <- get("https://dspace.mit.edu/server/api/core/bitstreams/8382702c-9903-4ff4-9303-5af04c6e3307/content", "donaldson_aer.pdf")
han <- get("https://www.nber.org/system/files/working_papers/w24488/w24488.pdf", "hanlon_nber.pdf")
k <- 200 / 72                                 # points to pixels at 200 dpi
box <- function(img, x0, y0, x1, y1)          # a box in PDF points, white trimmed
  image_trim(image_crop(img, geometry_area(round((x1 - x0) * k), round((y1 - y0) * k), round(x0 * k), round(y0 * k))))
pad <- function(img) image_border(img, "white", "12x12")
p10 <- image_read_pdf(don, pages = 10, density = 200)   # page 907 of the journal: Figure 1
# The PDF draws a blue link frame around each panel; keep the inside of the
# frame (its edges found as the first two runs of blue rows and columns).
inner <- function(img, x0, y0, x1, y1, label, pad = 8) {
  reg  <- image_crop(img, geometry_area(round((x1 - x0) * k), round((y1 - y0) * k), round(x0 * k), round(y0 * k)))
  a    <- as.integer(image_data(reg, "rgb"))            # height x width x 3
  blue <- a[, , 3] > 150 & a[, , 1] < 120 & a[, , 2] < 120
  runs <- function(v) { v <- which(v > 20); split(v, cumsum(c(1, diff(v) > 10))) }
  cx <- runs(colSums(blue)); cy <- runs(rowSums(blue))  # x runs, y runs
  x0 <- max(cx[[1]]) + pad; x1 <- min(cx[[2]]) - pad; y0 <- max(cy[[1]]) + pad; y1 <- min(cy[[2]]) - pad
  p <- image_crop(reg, geometry_area(x1 - x0, y1 - y0, x0, y0))
  image_annotate(p, label, size = 12, color = ink, gravity = "northwest", location = "+14+8")   # size in points at 200 dpi
}
pA <- inner(p10, 100,  75, 245, 190, "1860"); pC <- inner(p10, 100, 184, 245, 300, "1880")
pE <- inner(p10, 100, 292, 245, 410, "1900"); pH <- inner(p10, 240, 402, 380, 525, "1930")
grid <- image_append(c(image_append(c(pad(pA), pad(pC))), image_append(c(pad(pE), pad(pH)))), stack = TRUE)
image_write(image_background(grid, "white"), file.path(out, "donaldson-railroads.png"))
h49 <- image_read_pdf(han, pages = 49, density = 200)   # appendix page 47: Figure 9
h50 <- image_read_pdf(han, pages = 50, density = 200)   # appendix page 48: Figure 11
image_write(image_border(box(h49, 60, 210, 560, 540), "white", "10x10"), file.path(out, "hanlon-weather-note.png"))
image_write(image_border(box(h50, 60, 135, 560, 378), "white", "10x10"), file.path(out, "hanlon-fog-weeks.png"))
# ==== END BLOCK ====
