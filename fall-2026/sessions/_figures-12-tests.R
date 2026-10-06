# Session 12 images drawn from test runs of the live demos, saved in
# _planning/session12_tests/ (not in git: the runs print data summaries).
#   Rscript _figures-12-tests.R <tests folder> <image folder>

suppressPackageStartupMessages(library(magick))
args  <- commandArgs(trailingOnly = TRUE)
tests <- normalizePath(args[1])
img   <- normalizePath(args[2])

# 1). The target and Claude Code's figure from the matching demo, stacked ----
png_of <- function(pdf, dpi) {
  out <- tempfile()
  system2("pdftoppm", c("-r", dpi, "-png", "-singlefile", pdf, out))
  image_read(paste0(out, ".png"))
}
label <- function(im, text) {
  strip <- image_annotate(image_blank(image_info(im)$width, 110, "white"),
                          text, size = 58, font = "Helvetica",
                          gravity = "west", location = "+20+0")
  image_append(c(strip, im), stack = TRUE)
}
target <- image_read(file.path(img, "F01-figure1-nature.png"))
agent  <- png_of(file.path(tests, "brute", "figure1_brute.pdf"), 300)
both <- image_append(c(
  label(target, "Target: the picture Claude Code was given"),
  image_blank(image_info(target)$width, 50, "white"),
  label(agent, "Claude Code's figure, after 12 rounds of drawing and comparing")),
  stack = TRUE)
image_write(image_border(both, "white", "10x10"),
            file.path(img, "F07-match-result.png"))

# 2). The three versions in a row, for the slide that measures them ----
thumb <- function(im, h, text) {
  im <- image_border(image_scale(im, paste0("x", h)), "grey70", "3x3")
  strip <- image_annotate(image_blank(image_info(im)$width, 90, "white"),
                          text, size = 56, font = "Helvetica",
                          gravity = "center")
  image_append(c(im, strip), stack = TRUE)
}
gap <- image_blank(70, 10, "white")
default <- image_read(file.path(img, "F02-figure1-default.png"))
row <- image_append(c(thumb(default, 450, "Default code"), gap,
                      thumb(agent, 450, "Claude Code's figure"), gap,
                      thumb(target, 450, "Target")))
image_write(image_background(row, "white"), file.path(img, "F08-three-versions.png"))

# 3). Claude Code's figure and the target, side by side ----
pair <- image_append(c(thumb(agent, 520, "Claude Code's figure"), gap,
                       thumb(target, 520, "Target")))
image_write(image_background(pair, "white"), file.path(img, "F09-matched-and-target.png"))
