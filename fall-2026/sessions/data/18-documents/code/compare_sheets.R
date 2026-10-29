# compare.R: model vs volunteers comparisons for the Abbotsbury sheets.
# Run from the session data folder:
#   Rscript <scratch>/compare.R <scratch>/compare_sections.md
# Writes markdown sections (read by the notes) and cell crops to sheets/crops/.
suppressPackageStartupMessages(library(magick))
OUT <- commandArgs(trailingOnly = TRUE)[1]
PRICE_IN  <- 3   / 1e6     # USD per input token  (assumption to be checked)
PRICE_OUT <- 15  / 1e6     # USD per output token (assumption to be checked)
TOL <- 0.005               # two numbers are "equal" if they differ by less than this

vol <- read.csv("rain_volunteers.csv", stringsAsFactors = FALSE)
mod <- read.csv("rain_model.csv", stringsAsFactors = FALSE)
log <- read.csv("cache/log.csv", stringsAsFactors = FALSE)
MONTHS <- c("jan","feb","mar","apr","may","jun","jul","aug","sep","oct","nov","dec")
SHEETS <- unique(vol$sheet)

key <- function(d) paste(d$sheet, d$year, d$month)
m1 <- mod[mod$run == 1, ]; m2 <- mod[mod$run == 2, ]
vol$model1 <- m1$inches[match(key(vol), key(m1))]
vol$model2 <- m2$inches[match(key(vol), key(m2))]
eq <- function(a, b) !is.na(a) & !is.na(b) & abs(a - b) < TOL

md <- character(0)
say <- function(...) md <<- c(md, sprintf(...))
tbl <- function(df, digits = 2) {
  f <- function(x) if (is.integer(x)) ifelse(is.na(x), "", as.character(x)) else if (is.numeric(x)) ifelse(is.na(x), "", formatC(x, format = "f", digits = digits)) else ifelse(is.na(x), "", as.character(x))
  cells <- as.data.frame(lapply(df, f), stringsAsFactors = FALSE)
  if (nrow(cells) == 0) return("(none)")
  c(paste0("| ", paste(names(df), collapse = " | "), " |"),
    paste0("|", paste(rep("---", ncol(df)), collapse = "|"), "|"),
    apply(cells, 1, function(r) paste0("| ", paste(r, collapse = " | "), " |")))
}
fmt <- function(x) ifelse(is.na(x), "NA", formatC(x, format = "f", digits = 2))

# ---- cell crops ------------------------------------------------------------
# Approximate pixel geometry of each sheet (x of each year column centre,
# y of each month row centre, read off the images); crops take one column
# and one row either side so a 10 px error still shows the cell.
geom <- list(
  "1860s" = list(years = 1860:1869, x = seq(180, 553, length.out = 10), y = seq(280, 586, length.out = 12), ytot = 619),
  "1870s" = list(years = 1870:1879, x = seq(185, 560, length.out = 10), y = seq(300, 613, length.out = 12), ytot = 652),
  "1880s" = list(years = 1880:1889, x = seq(170, 545, length.out = 10), y = seq(292, 600, length.out = 12), ytot = 638),
  "1890s" = list(years = 1890:1899, x = seq(182, 574, length.out = 10), y = seq(290, 597, length.out = 12), ytot = 638),
  "1910s" = list(years = 1910:1919, x = seq(160, 556, length.out = 10), y = seq(378, 686, length.out = 12), ytot = 730))
dir.create("sheets/crops", showWarnings = FALSE)
crop_cell <- function(sheet, year, month) {
  g <- geom[[sheet]]
  cx <- g$x[match(year, g$years)]
  cy <- if (month == "total") g$ytot else g$y[match(month, MONTHS)]
  w <- 130; h <- 90
  im <- image_read(sprintf("sheets/abbotsbury_%s.jpg", sheet))
  geo <- sprintf("%dx%d+%d+%d", w, h, max(0, round(cx - w / 2)), max(0, round(cy - h / 2)))
  f <- sprintf("sheets/crops/%s_%d_%s.png", sheet, year, month)
  image_write(image_scale(image_crop(im, geo), "300%"), f)
  f
}

# ---- 1. run1 vs volunteers ---------------------------------------------------
say("### Run 1 model vs volunteers, per sheet (months and Total, cells where both have a number)\n")
agree <- do.call(rbind, lapply(SHEETS, function(s) {
  d <- vol[vol$sheet == s, ]
  both <- !is.na(d$inches) & !is.na(d$model1)
  data.frame(sheet = s, compared = sum(both), equal = sum(eq(d$inches, d$model1)),
             share_equal = round(sum(eq(d$inches, d$model1)) / sum(both), 3),
             of_which_totals_compared = sum(both & d$month == "total"))
}))
md <- c(md, tbl(agree, 3), "")
say("All sheets: %d compared, %d equal, share %.3f.\n", sum(agree$compared), sum(agree$equal), sum(agree$equal) / sum(agree$compared))
dis <- vol[!is.na(vol$inches) & !is.na(vol$model1) & !eq(vol$inches, vol$model1), c("sheet","year","month","inches","model1")]
names(dis) <- c("sheet","year","month","volunteers","model_run1")
say("Disagreeing cells, run 1 (%d):\n", nrow(dis))
if (nrow(dis)) dis$crop <- mapply(crop_cell, dis$sheet, dis$year, dis$month)
md <- c(md, tbl(dis), "")

# ---- 1b. run2 vs volunteers (same measure, for reference) ----------------------
say("### Run 2 model vs volunteers, per sheet (same measure)\n")
agree2 <- do.call(rbind, lapply(SHEETS, function(s) {
  d <- vol[vol$sheet == s, ]
  both <- !is.na(d$inches) & !is.na(d$model2)
  data.frame(sheet = s, compared = sum(both), equal = sum(eq(d$inches, d$model2)),
             share_equal = round(sum(eq(d$inches, d$model2)) / sum(both), 3))
}))
md <- c(md, tbl(agree2, 3), "")
say("All sheets, run 2: %d compared, %d equal, share %.3f.\n", sum(agree2$compared), sum(agree2$equal), sum(agree2$equal) / sum(agree2$compared))
dis2 <- vol[!is.na(vol$inches) & !is.na(vol$model2) & !eq(vol$inches, vol$model2), c("sheet","year","month","inches","model2")]
names(dis2) <- c("sheet","year","month","volunteers","model_run2")
say("Disagreeing cells, run 2 (%d):\n", nrow(dis2))
md <- c(md, tbl(dis2), "")
na_vol2 <- vol[!is.na(vol$model2) & is.na(vol$inches), c("sheet","year","month","unread","model2")]
say("Run 2 cells with a model number where the volunteers have NA (%d):\n", nrow(na_vol2))
if (nrow(na_vol2)) na_vol2$crop <- mapply(crop_cell, na_vol2$sheet, na_vol2$year, na_vol2$month)
md <- c(md, tbl(na_vol2), "")

# ---- 2. NA on one side -------------------------------------------------------
say("### Cells with a number on one side only, run 1\n")
na_model <- vol[is.na(vol$model1) & !is.na(vol$inches), c("sheet","year","month","inches")]
na_vol   <- vol[!is.na(vol$model1) & is.na(vol$inches), c("sheet","year","month","unread","model1")]
cnt <- do.call(rbind, lapply(SHEETS, function(s) data.frame(
  sheet = s,
  model_NA_volunteers_number = sum(na_model$sheet == s),
  model_number_volunteers_NA = sum(na_vol$sheet == s),
  model_number_volunteers_NA_unread = sum(na_vol$sheet == s & na_vol$unread))))
md <- c(md, tbl(cnt, 0), "")
say("Model NA where the volunteers have a number (%d):\n", nrow(na_model))
if (nrow(na_model)) na_model$crop <- mapply(crop_cell, na_model$sheet, na_model$year, na_model$month)
md <- c(md, tbl(na_model), "")
say("Model number where the volunteers have NA (%d; unread = the volunteers wrote -999 there). Candidate invented numbers unless the crop shows a value:\n", nrow(na_vol))
if (nrow(na_vol)) na_vol$crop <- mapply(crop_cell, na_vol$sheet, na_vol$year, na_vol$month)
md <- c(md, tbl(na_vol), "")

# ---- 3. sums per sheet-year, run 1 -------------------------------------------
say("### Sum of the 12 model months (run 1) against the model's total field and the volunteers' transcribed Total\n")
say("Only years where the model returned at least one month. months_NA = months the model left null (the sum is over the others). Flag = |difference| > 0.01.\n")
sums <- do.call(rbind, lapply(split(vol, list(vol$sheet, vol$year), drop = TRUE), function(d) {
  mo <- d[d$month != "total", ]
  if (all(is.na(mo$model1))) return(NULL)
  s <- sum(mo$model1, na.rm = TRUE)
  mt <- d$model1[d$month == "total"]; vt <- d$inches[d$month == "total"]
  data.frame(sheet = d$sheet[1], year = d$year[1], months_NA = sum(is.na(mo$model1)),
             model_month_sum = s, model_total = mt, diff_vs_model_total = s - mt,
             volunteers_total = vt, diff_vs_volunteers_total = s - vt,
             flag = ifelse((!is.na(mt) & abs(s - mt) > 0.01) | (!is.na(vt) & abs(s - vt) > 0.01), "FLAG", ""))
}))
sums <- sums[order(sums$sheet, sums$year), ]
md <- c(md, tbl(sums), "")
say("Flagged years: %d of %d.\n", sum(sums$flag == "FLAG"), nrow(sums))

# ---- 4. run1 vs run2 ---------------------------------------------------------
say("### Run 1 vs run 2, per sheet (all 130 cells per sheet; NA on both sides counts as equal)\n")
rr <- do.call(rbind, lapply(SHEETS, function(s) {
  d <- vol[vol$sheet == s, ]
  same <- (is.na(d$model1) & is.na(d$model2)) | eq(d$model1, d$model2)
  data.frame(sheet = s, cells = nrow(d), equal = sum(same), share_equal = round(mean(same), 3),
             both_numbers_equal = sum(eq(d$model1, d$model2)), both_NA = sum(is.na(d$model1) & is.na(d$model2)),
             changed = sum(!same))
}))
md <- c(md, tbl(rr, 3), "")
ch <- vol[!((is.na(vol$model1) & is.na(vol$model2)) | eq(vol$model1, vol$model2)), c("sheet","year","month","inches","model1","model2")]
names(ch) <- c("sheet","year","month","volunteers","run1","run2")
say("Cells that changed between runs (%d):\n", nrow(ch))
md <- c(md, tbl(ch), "")

# ---- 5. time, tokens, cost ---------------------------------------------------
say("### Seconds, tokens and cost per call\n")
say("Prices assumed: USD %g per million input tokens, USD %g per million output tokens (to be checked against the current price list; ellmer's own cost column is also shown).\n", PRICE_IN * 1e6, PRICE_OUT * 1e6)
log$cost_at_3_15 <- log$input_tokens * PRICE_IN + log$output_tokens * PRICE_OUT
lg <- log[order(log$sheet, log$run), c("sheet","run","seconds","input_tokens","output_tokens","cached_input_tokens","cost_at_3_15","cost_usd")]
names(lg)[8] <- "ellmer_cost_usd"
lg$cost_at_3_15 <- round(lg$cost_at_3_15, 4)
md <- c(md, tbl(lg, 4), "")
say("Per sheet (both runs):\n")
ps <- aggregate(cbind(seconds, input_tokens, output_tokens, cost_at_3_15) ~ sheet, log, sum)
ps$cost_at_3_15 <- round(ps$cost_at_3_15, 4)
md <- c(md, tbl(ps, 4), "")
say("All ten calls: %.1f s, %d input tokens, %d output tokens, USD %.4f at 3/15 (ellmer: USD %.4f). Mean per call: %.1f s, USD %.4f.\n",
    sum(log$seconds), sum(log$input_tokens), sum(log$output_tokens), sum(log$cost_at_3_15), sum(log$cost_usd),
    mean(log$seconds), mean(log$cost_at_3_15))

# ---- 6. the 1880s braces -----------------------------------------------------
say("### The 1880s sheet: the braced months\n")
say("On the sheet June and July 1886 share one braced figure (2.82) and January and February 1887 share one (4.57). The volunteers left them blank or -999.\n")
b <- vol[vol$sheet == "1880s" & ((vol$year == 1886 & vol$month %in% c("jun","jul")) | (vol$year == 1887 & vol$month %in% c("jan","feb"))), c("year","month","inches","unread","model1","model2")]
names(b) <- c("year","month","volunteers","unread","run1","run2")
md <- c(md, tbl(b), "")
for (r in 1:2) for (y in c(1886, 1887)) {
  d <- mod[mod$sheet == "1880s" & mod$run == r & mod$year == y, ]
  s <- sum(d$inches[d$month != "total"], na.rm = TRUE); nna <- sum(is.na(d$inches[d$month != "total"]))
  written <- c("1886" = 32.51, "1887" = 25.14)[as.character(y)]
  say("- Run %d, %d: model months sum to %.2f (%d null), written total %.2f, model total field %s, difference %+.2f.",
      r, y, s, nna, written, fmt(d$inches[d$month == "total"]), s - written)
}
say("")
writeLines(md, OUT)
cat("wrote", OUT, "\n")
