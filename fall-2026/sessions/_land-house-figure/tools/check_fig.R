# Measures a figure PDF against a journal spec and writes the pictures a
# reviewer looks at. Needs poppler's command-line tools (pdfinfo, pdffonts,
# pdftotext, pdftocairo, pdfimages, pdftoppm) and the magick package.
#
#   Rscript tools/check_fig.R figures/nature/figure1.pdf nature
#
# Prints one line per rule (PASS or FAIL, with what was measured) and writes
# check/<file>/report.txt, print.png (300 dpi), gray.png and deutan.png
# (how a reader with deuteranopia, the most common colour blindness, sees it).

library(yaml)
suppressPackageStartupMessages(library(magick))

args    <- commandArgs(trailingOnly = TRUE)
pdf     <- args[1]
journal <- args[2]
rules   <- read_yaml(file.path("specs", paste0(journal, ".yml")))
out     <- file.path("check", tools::file_path_sans_ext(basename(pdf)))
dir.create(out, showWarnings = FALSE, recursive = TRUE)

run <- function(cmd, ...) system2(cmd, c(...), stdout = TRUE, stderr = FALSE)
report <- character()
add <- function(rule, pass, measured) {
  report <<- c(report, sprintf("%-4s %-14s %s", if (pass) "PASS" else "FAIL",
                               rule, measured))
}

# 1). Page size ----
size_pt <- as.numeric(strsplit(sub(".*:\\s+([0-9.]+) x ([0-9.]+).*", "\\1 \\2",
                                   grep("Page size", run("pdfinfo", pdf),
                                        value = TRUE)), " ")[[1]])
size_mm <- size_pt * 25.4 / 72
widths  <- unlist(rules$width_mm$value)
add("width", any(abs(size_mm[1] - widths) < 1),
    sprintf("%.1f mm; allowed %s mm", size_mm[1], paste(widths, collapse = ", ")))
if (!is.null(rules$height_mm_max)) {
  add("height", size_mm[2] <= rules$height_mm_max$value,
      sprintf("%.1f mm; at most %s mm", size_mm[2], rules$height_mm_max$value))
}

# 2). Fonts ----
# One line per font: its name first, then type, encoding, emb, sub, uni.
fl <- run("pdffonts", pdf)[-(1:2)]
font_name <- sub("^[A-Z]{6}\\+", "", sub("^(\\S+).*", "\\1", fl))
font_emb  <- sub(".*\\s(yes|no)\\s+(yes|no)\\s+(yes|no)\\s+[0-9]+\\s+[0-9]+\\s*$", "\\1", fl)
add("font", all(grepl(rules$font$value, font_name, ignore.case = TRUE)),
    paste(unique(font_name), collapse = ", "))
add("fonts embedded", all(font_emb == "yes"),
    sprintf("%d of %d embedded", sum(font_emb == "yes"), length(fl)))

# 3). Text sizes ----
# pdftotext gives each word's box. For upright text the box height is the
# font size; for text drawn sideways it is the width. Which one applies
# comes from the word's length in Helvetica, from strwidth(): an upright
# word's box is that many times wider than tall, a sideways word's box that
# many times taller than wide. A word about as long as it is tall ("C.",
# "of", "16") has a square box either way, so it is left out of the sizes.
w <- regmatches(x <- run("pdftotext", "-bbox", pdf, "-"),
                regexpr("<word[^>]*>[^<]*", x))
num <- function(key) as.numeric(sub(paste0('.*', key, '="(-?[0-9.]+)".*'), "\\1", w))
unescape <- function(t) gsub("&amp;", "&", gsub("&gt;", ">", gsub("&lt;", "<", t)))
words <- data.frame(text = unescape(sub(".*>", "", w)),
                    x0 = num("xMin"), x1 = num("xMax"),
                    y0 = num("yMin"), y1 = num("yMax"))
words$h <- words$y1 - words$y0
words$w <- words$x1 - words$x0
pdf(NULL, pointsize = 10, family = "Helvetica")
len <- strwidth(words$text, units = "inches") * 72 / 10   # length per pt of size
invisible(dev.off())
upright  <- abs(log(words$w / words$h / len)) <= abs(log(words$h / words$w / len))
words$pt <- round(ifelse(upright, words$h, words$w), 1)
words$pt[len > 0.8 & len < 1.25] <- NA                # square box: direction unknown
words <- words[grepl("[[:alnum:]]", words$text), ]   # boxes of lone symbols such as "<" are unreliable

# Words reaching past the page edge are cut off in print.
off <- words[words$x0 < -0.5 | words$y0 < -0.5 |
             words$x1 > size_pt[1] + 0.5 | words$y1 > size_pt[2] + 0.5, ]
add("text on page", nrow(off) == 0,
    if (nrow(off)) paste("cut off at the edge:", paste(unique(off$text), collapse = " "))
    else "every word inside the page")

label <- rules$panel_label$value
is_letter <- grepl("^[a-z]$", words$text) & !is.na(words$pt) &
             words$pt > rules$text_pt$value$max
other <- words[!is_letter & !is.na(words$pt), ]
lo <- rules$text_pt$value$min
hi <- rules$text_pt$value$max
bad <- other[other$pt < lo - 0.05 | other$pt > hi + 0.05, ]
add("text size", nrow(bad) == 0,
    sprintf("%s to %s pt; allowed %s to %s pt%s", min(other$pt), max(other$pt),
            lo, hi, if (nrow(bad)) paste0("; outside: ",
            paste(sprintf("'%s' %.1f", bad$text, bad$pt), collapse = ", ")) else ""))
if (!is.null(label$pt)) {
  letters_pt <- words$pt[is_letter]
  asked <- sprintf("asked %s pt bold %s", label$pt, label$case)
  add("panel letters", length(letters_pt) > 0 && all(abs(letters_pt - label$pt) < 0.1),
      if (length(letters_pt) == 0) paste("none found;", asked) else
        sprintf("%s at %s pt; %s", paste(sort(words$text[is_letter]), collapse = " "),
                paste(unique(letters_pt), collapse = "/"), asked))
}

# 4). Line weights ----
# pdftocairo writes the figure as SVG, where every stroke has its width in pt.
svg <- tempfile(fileext = ".svg")
invisible(run("pdftocairo", "-svg", pdf, svg))
s <- readLines(svg, warn = FALSE)
lw <- as.numeric(unlist(regmatches(s, gregexpr('(?<=stroke-width=")[0-9.]+', s, perl = TRUE))))
add("line weight", min(lw) >= rules$line_pt$value$min - 1e-6 &&
                   max(lw) <= rules$line_pt$value$max + 1e-6,
    sprintf("%s to %s pt over %d strokes; allowed %s to %s pt", min(lw), max(lw),
            length(lw), rules$line_pt$value$min, rules$line_pt$value$max))

# 5). Vector file ----
images <- length(run("pdfimages", "-list", pdf)) - 2
add("vector only", images == 0, sprintf("%d raster images inside", images))

# 6). Pictures for a reviewer ----
invisible(run("pdftoppm", "-r", "300", "-png", "-singlefile", pdf, file.path(out, "print")))
invisible(run("pdftoppm", "-r", "300", "-png", "-gray", "-singlefile", pdf, file.path(out, "gray")))

# Deuteranopia, full severity, from Machado, Oliveira and Fernandes (IEEE
# TVCG, 2009), applied to linear RGB.
m <- matrix(c( 0.367322, 0.860646, -0.227968,
               0.280085, 0.672501,  0.047413,
              -0.011820, 0.042940,  0.968881), nrow = 3, byrow = TRUE)
a  <- as.integer(image_read(file.path(out, "print.png"))[[1]]) / 255
a  <- a[, , 1:3]
lin <- ifelse(a <= 0.04045, a / 12.92, ((a + 0.055) / 1.055)^2.4)
px  <- matrix(lin, ncol = 3) %*% t(m)
px  <- pmin(pmax(px, 0), 1)
srgb <- ifelse(px <= 0.0031308, 12.92 * px, 1.055 * px^(1 / 2.4) - 0.055)
image_write(image_read(array(srgb, dim = dim(a))), file.path(out, "deutan.png"))

# 7). Report ----
report <- c(sprintf("%s against specs/%s.yml", pdf, journal), report)
writeLines(report)
writeLines(report, file.path(out, "report.txt"))
