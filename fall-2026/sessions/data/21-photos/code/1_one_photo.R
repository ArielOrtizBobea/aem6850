# =============================================================
# AEM 6850 - Session 21: Photographs I
# Script 1 of 3 - one photograph as numbers.
#
# Reads two of the 365 daily photographs of the Beijing skyline (Zou Yi, 2014)
# into R, looks at the array of numbers a photograph is, and draws them.
#
# Reads:  data_clean/tiles/2014-01-06.jpg, data_clean/tiles/2014-01-03.jpg
# Writes: nothing
#
# Open 21-photos.Rproj first. It sits at the project root, so the working
# directory is 21-photos/ and every path below is relative to it.
#
#   source("code/1_one_photo.R")
# =============================================================

# 1). Preliminary ----

  # Load or install the packages this script uses
  want <- c("jpeg")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only=TRUE))
  rm(want, need)

  if (!dir.exists("data_clean/tiles"))
    stop("The 365 photographs are in the class zip on Box (Cornell NetID), not in the zip on the\n",
         "  course page. Unzip the class zip and open its 21-photos.Rproj to run this script.")

# 2). One photograph as an array ----

  img <- readJPEG("data_clean/tiles/2014-01-06.jpg")
  dim(img)                        # 222 rows, 167 columns, 3 colour bands
  round(img[1:3, 1:3, 1], 2)      # top-left corner of the red band: numbers from 0 to 1
  img[150, 80, ]                  # one pixel: its red, green and blue
  plot(as.raster(img))            # the same numbers drawn as a picture

# 3). Two mornings, as numbers ----

  clear <- readJPEG("data_clean/tiles/2014-01-03.jpg")
  par(mfrow = c(1, 2), mar = c(0, 0, 2, 0))
  plot(as.raster(clear)); title("2014-01-03")
  plot(as.raster(img));   title("2014-01-06")
  round(apply(clear[1:55, , ], 3, mean), 2)   # mean red, green, blue in the top quarter (sky)
  round(apply(img[1:55, , ], 3, mean), 2)
