# Images for the session 12 page and slides, drawn from the session's
# project after its scripts have run. Called by _build-land-house-figure.sh:
#   Rscript _figures-12.R <project folder> <image folder>

suppressPackageStartupMessages(library(magick))
args <- commandArgs(trailingOnly = TRUE)
proj <- normalizePath(args[1])
img  <- normalizePath(args[2])
setwd(proj)
source("R/fig_style.R")
spec <- read_spec("nature")
d    <- readRDS("data_clean/counties.rds")
both <- d[!is.na(d$land_ratio) & !is.na(d$house_ratio), ]
png_of <- function(pdf, dpi, out) {
  system2("pdftoppm", c("-r", dpi, "-png", "-singlefile", pdf,
                        sub("\\.png$", "", out)))
}

# 1). Figure 1 for Nature, and the default version ----
png_of("figures/nature/figure1.pdf", 300, file.path(img, "F01-figure1-nature.png"))
png_of("figures/default/figure1.pdf", 150, file.path(img, "F02-figure1-default.png"))

# 2). One Nature column: R's cars data drawn with the Console code shown on
#     the slide "One Nature column, drawn in the R Console"
tmp <- file.path(tempdir(), "cars-nature.pdf")
cairo_pdf(tmp, width = 89 / 25.4, height = 70 / 25.4,
          pointsize = 7, family = "Helvetica")
par(mar = c(3, 3.2, 1.6, 0.6), mgp = c(1.8, 0.5, 0),
    cex.axis = 6 / 7, lwd = 0.5 / 0.75, las = 1)   # 0.5-pt box; axes stay 0.75 pt
plot(cars$speed, cars$dist, pch = 16, cex = 0.5,
     xlab = "Speed (mph)", ylab = "Stopping distance (ft)")
mtext("a", side = 3, line = 0.4, adj = 0, font = 2, cex = 8 / 7)
dev.off()
png_of(tmp, 300, file.path(img, "F03-cars-nature.png"))      # 89 mm at 300 dpi

# 3). Palettes as drawn and as a reader with deuteranopia sees them ----
deutan <- function(hex) {
  m <- matrix(c( 0.367322, 0.860646, -0.227968,
                 0.280085, 0.672501,  0.047413,
                -0.011820, 0.042940,  0.968881), nrow = 3, byrow = TRUE)
  v   <- t(col2rgb(hex)) / 255
  lin <- ifelse(v <= 0.04045, v / 12.92, ((v + 0.055) / 1.055)^2.4)
  s   <- pmin(pmax(lin %*% t(m), 0), 1)
  s   <- ifelse(s <= 0.0031308, 12.92 * s, 1.055 * s^(1 / 2.4) - 0.055)
  rgb(s[, 1], s[, 2], s[, 3])
}
gray_of <- function(hex) {
  v <- t(col2rgb(hex)) / 255
  g <- 0.2126 * v[, 1] + 0.7152 * v[, 2] + 0.0722 * v[, 3]
  rgb(g, g, g)
}
# Three kinds of scale, each with palettes to use and to avoid for readers
# with colour blindness, shown as R draws them, as a reader with
# deuteranopia sees them, and printed in grayscale. A tick or a cross after
# each of the last two strips: do the colours stay apart (categorical) or in
# order (sequential, diverging) in that column?
rows <- list(
  list(group = "Categorical: groups with no order"),
  list(verdict = "Use",   call = "palette.colors()",              col = palette.colors()[2:8],                    ok = c(TRUE,  FALSE)),
  list(verdict = "Avoid", call = 'palette.colors(palette = "R3")', col = palette.colors(palette = "R3")[2:7],      ok = c(FALSE, FALSE)),
  list(group = "Sequential: values that rise in one direction"),
  list(verdict = "Use",   call = 'hcl.colors(5, "Blues 3", rev = TRUE)', col = hcl.colors(5, "Blues 3", rev = TRUE), ok = c(TRUE, TRUE)),
  list(verdict = "Use",   call = 'hcl.colors(5, "viridis")',      col = hcl.colors(5, "viridis"),                 ok = c(TRUE,  TRUE)),
  list(verdict = "Avoid", call = "rainbow(5)",                    col = rainbow(5),                               ok = c(FALSE, FALSE)),
  list(group = "Diverging: values above and below a midpoint"),
  list(verdict = "Use",   call = 'hcl.colors(7, "Blue-Red 3")',   col = hcl.colors(7, "Blue-Red 3"),              ok = c(TRUE,  FALSE)),
  list(verdict = "Avoid", call = 'hcl.colors(7, "RdYlGn")',       col = hcl.colors(7, "RdYlGn"),                  ok = c(FALSE, FALSE))
)
png(file.path(img, "F04-colours.png"), width = 7.5, height = 5, units = "in",
    res = 200, pointsize = 13, family = "Helvetica")
par(mar = c(0.2, 0.2, 0.2, 0.2))
centre <- c(3.3, 4.65, 6.0)                       # column centres
half   <- 0.42                                    # half the width of a strip
step   <- c(group = 0.52, palette = 0.5)
H <- 0.95 + sum(ifelse(sapply(rows, function(r) is.null(r$col)), step["group"], step["palette"]))
plot.new(); plot.window(c(0, 6.65), c(0, H), xaxs = "i", yaxs = "i")
top <- H - 0.42
heads <- c("As R\ndraws it", "Seen with\ndeuteranopia", "Printed in\ngrayscale")
text(centre, top, heads, font = 2, cex = 0.85)
hw <- strwidth(c("draws it", "deuteranopia", "grayscale"), font = 2, cex = 0.85) / 2
arrows(centre[1:2] + hw[1:2] + 0.06, top, centre[2:3] - hw[2:3] - 0.06, top,
       length = 0.07, lwd = 1.6, col = "grey35")
# Key, in the empty corner beside the headers
tick  <- function(xm, ym) lines(xm + c(-0.07, -0.025, 0.07), ym + c(0, -0.1, 0.12), lwd = 2.2)
cross <- function(xm, ym) segments(xm - 0.055, ym + c(-0.1, 0.1), xm + 0.055, ym + c(0.1, -0.1), lwd = 2.2)
text(0.05, H - 0.2, "Use or Avoid: for colour-blind readers", adj = c(0, 0.5), cex = 0.78)
tick(0.12, H - 0.47);  cross(0.32, H - 0.47)
text(0.47, H - 0.47, "the colours stay apart or in order, or not", adj = c(0, 0.5), cex = 0.78)
text(0.05, H - 0.74, "Only sequential scales also pass in gray", adj = c(0, 0.5), cex = 0.78)
y <- H - 0.95
for (r in rows) {
  if (is.null(r$col)) {
    y <- y - step["group"]
    text(0.05, y + 0.16, r$group, adj = c(0, 0.5), font = 2, cex = 0.95)
    next
  }
  y <- y - step["palette"]
  text(0.12, y + 0.2, r$verdict, adj = c(0, 0.5), cex = 0.85)
  text(0.6, y + 0.2, r$call, adj = c(0, 0.5), cex = 0.62, family = "mono")
  for (k in 1:3) {
    cols <- list(r$col, deutan(r$col), gray_of(r$col))[[k]]
    w  <- 2 * half / length(cols)
    x0 <- centre[k] - half
    rect(x0 + (seq_along(cols) - 1) * w, y + 0.04, x0 + seq_along(cols) * w,
         y + 0.38, col = cols, border = "grey85", lwd = 0.6)
    if (k > 1) {                                  # a tick or a cross, drawn
      xm <- centre[k] + half + 0.13
      if (r$ok[k - 1]) {
        lines(xm + c(-0.07, -0.025, 0.07), y + c(0.21, 0.11, 0.33), lwd = 2.4)
      } else {
        segments(xm - 0.055, y + c(0.11, 0.31), xm + 0.055, y + c(0.31, 0.11), lwd = 2.4)
      }
    }
  }
}
dev.off()

# 4). The colour check of map a: as printed, deuteranopia, grayscale ----
system2("Rscript", c("tools/check_fig.R", "figures/nature/figure1.pdf", "nature"),
        stdout = FALSE)
crop <- "1300x690+0+60"
three <- lapply(c("print", "deutan", "gray"), function(f)
  image_crop(image_read(file.path("check/figure1", paste0(f, ".png"))), crop))
image_write(image_append(do.call(c, three)), file.path(img, "F05-colour-check.png"))

# 5). The three AER files side by side ----
aer <- lapply(c("a", "b", "c"), function(p) {
  f <- sprintf("figures/aer/Figure1%s.pdf", p)
  png_of(f, 200, file.path(tempdir(), paste0("aer", p, ".png")))
  image_border(image_read(file.path(tempdir(), paste0("aer", p, ".png"))),
               "grey80", "2x2")
})
image_write(image_append(do.call(c, aer)), file.path(img, "F06-figure1-aer.png"))
