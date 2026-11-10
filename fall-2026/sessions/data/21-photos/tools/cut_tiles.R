# =============================================================
# AEM 6850 - Session 21: Photographs I
# Tool, run before class. Students do not run it: the tiles it writes ship in
# data_clean/tiles/.
#
# Cuts the 365 daily photographs out of Zou Yi's 2014 composite
# (data/composite/beijing-smog.jpg, 4999 by 3108 px, a 30 by 14 grid). The top
# two grid rows hold the title; the five photos of Jan 1-5 sit at the right end
# of the second row, and Jan 6 to Dec 31 fill rows 3 to 14 left to right.
# Writes data_clean/tiles/<date>.jpg and data_clean/tiles.csv.
#
#   Rscript tools/cut_tiles.R        from the project folder
# =============================================================

  want <- c("magick")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only=TRUE))
  rm(want, need)

# 1). The grid ----

  im   <- image_read("data/composite/beijing-smog.jpg")
  info <- image_info(im)
  nc <- 30; nr <- 14
  tw <- info$width / nc; th <- info$height / nr          # 166.6 by 222 px

  dates <- seq(as.Date("2014-01-01"), as.Date("2014-12-31"), by = "day")
  stopifnot(length(dates) == 365)
  slot <- c(seq(1 * nc + 25, 1 * nc + 29), seq(2 * nc, nr * nc - 1))   # 0-based, row-major
  stopifnot(length(slot) == 365)
  tiles <- data.frame(date = dates, row = slot %/% nc, col = slot %% nc)
  tiles$file <- sprintf("data_clean/tiles/%s.jpg", tiles$date)

# 2). Cut ----

  dir.create("data_clean/tiles", showWarnings = FALSE, recursive = TRUE)
  for (i in seq_len(nrow(tiles))) {
    x <- round(tiles$col[i] * tw); y <- round(tiles$row[i] * th)
    geom <- sprintf("%dx%d+%d+%d", round(tw), round(th), x, y)
    image_write(image_crop(im, geom), tiles$file[i], format = "jpeg", quality = 92)
  }
  write.csv(tiles, "data_clean/tiles.csv", row.names = FALSE)
  cat(nrow(tiles), "tiles written;", sum(file.exists(tiles$file)), "exist\n")
