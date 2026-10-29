# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# AEM 6850 -- Empirical Methods for Applied Economists
# Prof. Ariel Ortiz-Bobea
# Session 18 -- Documents & scans
# Thursday, October 29, 2026
#
# Run it one line at a time: put the cursor on a line and press Cmd-Return
# (Mac) or Ctrl-Enter (Windows).
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# Preliminary ----
# Clean up workspace and load or install necessary packages if necessary
  rm(list=ls())
  want <- c("jsonlite","magick","pdftools","stringr","tesseract")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only=TRUE))
  rm(want, need)


library(pdftools)                               # reads the text and the pages of a PDF
pdf_info("data/h41.pdf")$keys$Creator           # h41.pdf, the H.4.1: which program made it
substr(pdf_text("data/h41.pdf")[1], 1, 120)     # the first 120 characters of its page 1 text
substr(pdf_text("data/comp1899_p.pdf")[1], 1, 140)   # the 1899 page, a scan: text too?
img <- magick::image_read("data/sheets/abbotsbury_1870s.jpg")   # a handwritten rainfall sheet, a JPEG
magick::image_info(img)[, 1:3]                  # an image has pixels, no text to ask for


library(pdftools)                              # reads the text stored in a PDF
txt <- pdf_text("data/h41.pdf")                # the H.4.1, the Fed's balance sheet: one string per page
length(txt)
lines <- strsplit(txt[6], "\n")[[1]]           # page 6 (Table 5), one element per printed line
length(lines)
line <- grep("Total assets", lines, value = TRUE)   # the line that holds the Total assets row
line


library(stringr)
m <- str_match(line, "Total assets\\s+\\(0\\)\\s+([0-9,]+)")   # ( ) captures the amount on the Total assets line
m
assets <- as.numeric(gsub(",", "", m[, 2]))    # drop the thousands commas
assets


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Exercise 1 (5 minutes) ----
# Exercise 1 (5 minutes). Page 7 holds Total liabilities and Total capital.
# 1. lines7 <- strsplit(txt[7], "\n")[[1]]; find the two lines with grep().
# 2. Pull each amount with str_match() and one capture group.
# 3. Test: liabilities + capital == assets.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Exercise 1, solution ----
lines7 <- strsplit(txt[7], "\n")[[1]]
grep("Total liabilities|Total capital", lines7, value = TRUE)
amount <- function(label, lines) {
  l <- grep(label, lines, value = TRUE)[1]
  as.numeric(gsub(",", "", str_match(l, paste0(label, "\\s+(?:\\([0-9]+\\)\\s+)?([0-9,]+)"))[, 2]))
}
liabilities <- amount("Total liabilities", lines7)
capital     <- amount("Total capital", lines7)
c(liabilities = liabilities, capital = capital, assets = assets)
liabilities + capital == assets
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




amt <- "[-+]?\\s*(?<![A-Za-z0-9()])(?:[0-9]{1,3}(?:,[0-9]{3})+|[0-9]+)(?![0-9)])"   # an amount, sign kept
rows_of <- function(page) {                     # page 8 or 9 of txt, the release as text
  ln <- strsplit(txt[page], "\n")[[1]]
  keep <- which(str_count(ln, amt) == 13)       # 13 matches of amt, the amount pattern: a table row
  label <- str_trim(str_replace(ln[keep], paste0("\\s*(\\([0-9]+\\)\\s+)?", amt, ".*$"), ""))
  above <- ln[keep - 1]                          # the line above: the start of a wrapped label
  wrapped <- str_count(above, amt) == 0 & str_count(str_trim(above), " ") >= 1
  label[wrapped] <- paste(str_trim(above[wrapped]), label[wrapped])
  nums <- t(sapply(str_extract_all(ln[keep], amt), function(a) as.numeric(gsub("[ ,]", "", a))))
  data.frame(item = str_replace(label, "[0-9]+$", ""), nums, check.names = FALSE) |> setNames(c("item", banks))
}


lines8 <- strsplit(txt[8], "\n")[[1]]           # page 8 of txt (the H.4.1, the Fed's balance sheet, as text)
n <- str_count(lines8, amt)                     # amt, a pattern for one printed amount: matches per line
table(n)
banks <- c("Total", "Boston", "New York", "Philadelphia", "Cleveland", "Richmond", "Atlanta",
           "Chicago", "St. Louis", "Minneapolis", "Kansas City", "Dallas", "San Francisco")
tab6 <- rbind(rows_of(8), rows_of(9))           # rows_of(): the lines with 13 amounts, as label + numbers
dim(tab6)
head(tab6[, 1:3], 2)                             # one row per item: its label, the Total, then the banks


diff <- rowSums(tab6[, banks[-1]]) - tab6$Total      # the twelve bank columns minus the Total column
table(diff)
tab6$item[diff != 0]


theirs <- read.csv("agent/table6_agent.csv", check.names = FALSE)   # the agent's CSV, made before class
dim(theirs)                                       # 24 rows; it added a Section column (which part of the table)
ours <- do.call(paste, tab6[, banks])             # each row of our tab6 as one string of 13 amounts
setequal(ours, do.call(paste, theirs[, banks]))   # the same 24 rows in the agent's table? (banks: the 13 columns)


arch <- strsplit(pdf_text("data/comp1899_p.pdf"), "\n")[[1]]   # the text FRASER's OCR stored in the 1899 page's PDF, by line
grep("Total United States|Total New England", arch, value = TRUE)   # two of the table's 58 rows
a <- read.csv("data_clean/ocr/comp1899_archive.csv")    # that text parsed into 58 rows before class (code/2_ocr_runs.R)
sum(abs(rowSums(a[, 2:6], na.rm = TRUE) - a$total) > 0.05)   # rows whose five bank columns (2:6) miss the Total


library(tesseract)                                        # the OCR program, with English training data
ocr_txt <- ocr("data_clean/comp1899_p.png")               # the 1899 bank table as a 300-dpi image
tes <- strsplit(ocr_txt, "\n")[[1]]
grep("Total United States", tes, value = TRUE)            # the table's last row, all US banks
words <- ocr_data("data_clean/comp1899_p.png")            # every word with a confidence, 0 to 100
head(words[grepl("^[0-9,.]+$", words$word) & words$confidence < 80, c("word", "confidence")])   # doubted numbers


ta <- lines8[grep("Total assets", lines8)]   # the Total assets line of page 8, from the PDF's text
truth <- as.numeric(gsub("[ ,]", "", str_extract_all(ta, amt)[[1]]))   # its 13 amounts, pulled by amt
right <- sapply(c(300, 100), function(d) {
  png <- pdf_convert("data/h41.pdf", pages = 8, dpi = d, filenames = sprintf("data_clean/ocr/h41_p8_%d.png", d), verbose = FALSE)
  l <- grep("Total assets", strsplit(ocr(png), "\n")[[1]], value = TRUE)[1]
  if (is.na(l)) return(0)                                 # OCR found no such line
  l <- gsub("\\s*,\\s*", ",", gsub("[]|})]", "", l))     # OCR's stray spaces around commas, and its rules
  got <- as.numeric(gsub("[ ,]", "", str_extract_all(l, amt)[[1]]))
  sum(got[seq_along(truth)] == truth, na.rm = TRUE)
})


setNames(right, c("300 dpi", "100 dpi"))                  # of the 13 amounts in the Total assets row, read right


library(jsonlite)                                           # reads JSON, the text format model replies arrive in
m1899 <- fromJSON("replies/comp1899_run1.json")             # the model's saved reading of the 1899 page, one row each
nrow(m1899)


cat(substr(ocr("data/sheets/abbotsbury_1870s.jpg"), 1, 400))


f <- "data/volunteers/TYRain_1870-1879_04_pt1-page-064.csv"     # the 1870s Abbotsbury sheet as the volunteers typed it
vol <- read.csv(f, skip = 4, check.names = FALSE)[1:13, 1:11]  # skip 4 metadata lines; rows 1:13 = Jan..Dec + Total
names(vol)[1] <- "month"
vol[vol == -999] <- NA                                     # -999: the volunteers could not read the cell
head(vol, 4)                                               # inches of rain; 1871 is empty on the sheet


# type the 12 months of 1877 on one line, January first, spaces between
mine <- scan(text = readline("1877, January to December: "))
# the months where your typing and the volunteers' differ
month.abb[which(mine != vol[1:12, "1877"])]


library(jsonlite)                                           # reads JSON, the format of the saved reply
mod_y <- fromJSON("replies/abbotsbury_1870s_run1.json")     # the saved reply for the 1870s sheet: one row per year
mod <- data.frame(month = vol$month, t(as.matrix(mod_y[, -1])), check.names = FALSE)   # months as rows, as in vol
names(mod)[-1] <- mod_y$year
head(mod, 2)


months <- 1:12                                              # the twelve month rows of mod
round(colSums(mod[months, -1]) - unlist(mod[13, -1]), 2)   # months minus the written Total, row 13, per year


m <- as.matrix(mod[months, -1])                             # the model's twelve month rows of the 1870s sheet
v <- as.matrix(vol[months, -1])                             # the volunteers' typing of the same cells
mean(m == v, na.rm = TRUE)                                  # share of cells where the two readings agree
which(m != v, arr.ind = TRUE)                               # where they differ: row 9 September, column 8 = 1877


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Exercise 2 (6 minutes) ----
# Exercise 2 (6 minutes). The 1910s sheet, two readings.
# 1. vol2 from data/volunteers/TYRain_1910-1919_11_pt1-page-034.csv (skip = 4, rows 1:13).
# 2. mod2 from replies/abbotsbury_1910s_run1.json, transposed to months as rows.
# 3. mean(m2 == v2, na.rm = TRUE) on all 13 rows; then the cells where
#    is.na(m2) != is.na(v2): a number on one side only.
# 4. Open data/sheets/abbotsbury_1910s.jpg and read those cells yourself.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Exercise 2, solution ----
vol2 <- read.csv("data/volunteers/TYRain_1910-1919_11_pt1-page-034.csv", skip = 4, check.names = FALSE)[1:13, 1:11]
names(vol2)[1] <- "month"; vol2[vol2 == -999] <- NA
mod2_y <- fromJSON("replies/abbotsbury_1910s_run1.json")
mod2 <- data.frame(month = vol2$month, t(as.matrix(mod2_y[, -1])), check.names = FALSE); names(mod2)[-1] <- mod2_y$year
m2 <- as.matrix(mod2[, -1]); v2 <- as.matrix(vol2[, -1])     # all 13 rows: the months and the Total
mean(m2 == v2, na.rm = TRUE)                                   # on the cells both readings hold
which(is.na(m2) != is.na(v2), arr.ind = TRUE)                  # a number on one side only
m2[is.na(v2) & !is.na(m2)]
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




log <- read.csv("logs/model_calls.csv")  # each call before class; three sizes of one model
# $ per million tokens read, written (provider's list, 29 Oct 2026); / 1e4 below gives cents
PRICE <- rbind(small = c(0.10, 0.50), medium = c(2, 10), large = c(4, 20))
log$cents <- (log$input_tokens * PRICE[log$size, 1] + log$output_tokens * PRICE[log$size, 2]) / 1e4
log$page <- ifelse(log$page == "1899", "1899 page", "rainfall sheet")
round(tapply(log$cents, list(log$size, log$page), mean), 2)   # cents per page, mean of the calls


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Practice ----
# Practice. Run in the 18-documents folder after the slides' code has built
# txt, amt, tab6, vol, mod and months. No task needs a key.

# The text layer
#  1. Table 1 of data/h41.pdf ("Factors Affecting Reserve Balances", pages 1-2)
#     prints a total row for reserve bank credit. Build the table as a data
#     frame with the rows_of() approach and test the printed total.

# OCR
#  2. pdf_convert("data/comp1899_p.pdf", dpi = 200, ...) then ocr(); pull the
#     "Total United States" row and count the cells that match the printed
#     values (4,708.6 1,636.0 1,071.4 2,400.7 87.8 9,904.5). Compare with
#     300 dpi (data_clean/ocr/comp1899_300.txt).

# The model
#  3. The 1890s sheet: replies/abbotsbury_1890s_run1.json against
#     data/volunteers/TYRain_1890-1899_09_pt1-page-113.csv. Agreement share, the
#     differing cells, and your own reading of each on
#     data/sheets/abbotsbury_1890s.jpg.

# The checks
#  4. The 1860s sheet: for the volunteers' file and the model's reply,
#     colSums of the months minus the written Total, by year. Which years
#     miss, in which reading, and why (look at the sheet)?

# Cost
#  5. On FRASER, find the Comptroller's annual report for 1900 and its page
#     count. With the seconds and tokens of the 1899 page in
#     logs/model_calls.csv, how long and how much would a run over the whole
#     volume take with each model size?
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =


# The end
