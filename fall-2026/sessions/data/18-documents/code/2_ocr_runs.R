# =============================================================
# AEM 6850 - Session 18: Documents & scans
# Script 2 of 8 - OCR: the Fed's page 8 and the 1899 bank table.
#
# Lecture part 3, a scan of a printed page. Two runs of tesseract:
#   - page 8 of the Fed's H.4.1 (born-digital) rendered at 300, 150, 100
#     and 72 dpi, read with tesseract and compared with the PDF's own text;
#   - one scanned page of the Comptroller of the Currency's 1899 report
#     (FRASER page 693 = printed page 646, Table XVII), read three ways:
#     the archive's own OCR layer, tesseract at 300 dpi and at 100 dpi,
#     each parsed into six columns and scored against the reference copy.
#
# Reads:  data/h41.pdf, data/comp1899_p.pdf, data_clean/comp1899_truth.csv
# Writes: data_clean/comp1899_p.png (the page at 300 dpi), and in
#         data_clean/ocr/ the page images tesseract read, its text, and
#         the three readings of the 1899 page aligned to the reference rows
#
# Open 18-documents.Rproj first. It sits at the project root, so the
# working directory is 18-documents/ and every path below is relative to it.
#
#   source("code/2_ocr_runs.R")
# =============================================================


# 1). Preliminary ----

  # Load or install the packages this script uses
  want <- c("pdftools", "tesseract", "magick", "stringr", "xml2")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only=TRUE))
  rm(want, need)

  # Parameters
  misc <- list()
  misc$h41    <- "data/h41.pdf"
  misc$page   <- "data/comp1899_p.pdf"              # page 693 of the 1899 volume
  misc$volume <- "https://fraser.stlouisfed.org/files/docs/publications/comp/1890s/1899/compcurr_1899_vol1.pdf"
  misc$png    <- "data_clean/comp1899_p.png"        # that page at 300 dpi
  misc$truth  <- "data_clean/comp1899_truth.csv"    # the reference copy, 58 rows
  misc$ocr    <- "data_clean/ocr"                   # everything tesseract reads and writes
  misc$cols   <- c("national", "state", "loan_trust", "savings", "private", "total")

  dir.create(misc$ocr, showWarnings = FALSE, recursive = TRUE)


# 2). The Fed's page 8 at four resolutions ----

  cat("================ The Fed's page 8, OCR at four resolutions ================\n")
  txt    <- pdf_text(misc$h41)
  lines8 <- strsplit(txt[8], "\n")[[1]]
  amt <- "(?<=\\s|^)(?:[-+]\\s*)?\\d{1,3}(?:,\\d{3})*(?=\\s|$)"     # from 1_fed_table6.R
  truth_fed <- str_extract_all(lines8[str_detect(lines8, "^Total assets")], amt)[[1]]
  cat("text layer, Total assets:", truth_fed, "\n")

  # OCR puts spaces next to commas ("186 ,283", "3,612, 792") and reads the
  # table rules as | ] } ) /. Clean those, then use the same amount pattern.
  ocr_amounts <- function(line) {
    line <- str_replace_all(line, "\\s*,\\s*", ",")
    line <- str_remove_all(line, "[|\\[\\]{}()/]")
    str_extract_all(line, amt)[[1]]
  }
  # words of the line that starts with "Total assets", from ocr_data()
  line_words <- function(d) {
    b <- str_split_fixed(d$bbox, ",", 4); storage.mode(b) <- "numeric"
    d$x1 <- b[, 1]; d$y1 <- b[, 2]; d$x2 <- b[, 3]; d$y2 <- b[, 4]
    i <- which(d$word == "Total" & c(d$word[-1], "") == "assets")
    if (length(i) == 0) return(d[0, ])
    h <- d$y2[i[1]] - d$y1[i[1]]
    d <- d[abs(d$y1 - d$y1[i[1]]) < h / 2, ]
    d[order(d$x1), ]
  }

  fed_res <- data.frame()
  for (dpi in c(300, 150, 100, 72)) {
    png <- file.path(misc$ocr, sprintf("h41_p8_%d.png", dpi))
    pdf_convert(misc$h41, pages = 8, dpi = dpi, filenames = png, verbose = FALSE)
    info <- image_info(image_read(png))
    t0 <- Sys.time(); text <- ocr(png)
    secs <- as.numeric(Sys.time() - t0, units = "secs")
    writeLines(text, file.path(misc$ocr, sprintf("h41_p8_%d.txt", dpi)))
    ll  <- strsplit(text, "\n")[[1]]
    hit <- ll[str_detect(ll, regex("^total\\s*assets", ignore_case = TRUE))]
    got <- if (length(hit)) ocr_amounts(hit[1]) else character(0)
    got13 <- c(got, rep(NA, 13))[1:13]
    right <- sum(got13 == truth_fed, na.rm = TRUE)
    cat(sprintf("\n-- %d dpi: %d x %d px, ocr %.1f s, %d lines of text, Total assets line found: %s\n",
                dpi, info$width, info$height, secs, length(ll), length(hit) > 0))
    if (length(hit)) cat("   raw: ", hit[1], "\n")
    cat(sprintf("   amounts found: %d, exactly right: %d of 13\n", length(got), right))
    if (right < 13) {
      w <- which(is.na(got13) | got13 != truth_fed)
      print(data.frame(col = w, truth = truth_fed[w], ocr = got13[w]))
    }
    fed_res <- rbind(fed_res, data.frame(dpi = dpi, width = info$width, height = info$height,
                                         ocr_secs = round(secs, 1), lines = length(ll),
                                         found = length(got), right = right))
  }
  cat("\nsummary:\n"); print(fed_res)

  cat("\n-- ocr_data() confidence, words on the Total assets line\n")
  for (dpi in c(300, 100)) {
    d <- line_words(ocr_data(file.path(misc$ocr, sprintf("h41_p8_%d.png", dpi))))
    cat(sprintf("%d dpi: %d words\n", dpi, nrow(d)))
    if (nrow(d)) {
      print(data.frame(word = d$word, confidence = round(d$confidence, 1)))
      cat(sprintf("   mean confidence %.1f, min %.1f\n", mean(d$confidence), min(d$confidence)))
    }
  }


# 3). The 1899 page: the PDF, its archive text and two images ----

  cat("\n================ The 1899 scan ================\n")
  # The page ships in data/. Only if it is missing: download the whole
  # volume (907 pages) from FRASER and cut out page 693.
  if (!file.exists(misc$page)) {
    vol <- tempfile(fileext = ".pdf")
    download.file(misc$volume, vol, mode = "wb")
    pdf_subset(vol, pages = 693, output = misc$page)
  }
  info <- pdf_info(misc$page)
  cat(basename(misc$page), ": pages", info$pages, " version", info$version,
      " page size (pt)", unlist(pdf_pagesize(misc$page)[c("width", "height")]), "\n")
  arch <- pdf_text(misc$page)
  cat("archive text layer:", nchar(arch), "characters\n")
  stopifnot(nchar(arch) > 0)
  png100 <- file.path(misc$ocr, "comp1899_100.png")
  if (!file.exists(misc$png))
    pdf_convert(misc$page, dpi = 300, filenames = misc$png, verbose = FALSE)
  if (!file.exists(png100))
    pdf_convert(misc$page, dpi = 100, filenames = png100, verbose = FALSE)
  for (f in c(misc$png, png100)) {
    i <- image_info(image_read(f)); cat(basename(f), ":", i$width, "x", i$height, "px\n")
  }

  truth <- read.csv(misc$truth, stringsAsFactors = FALSE)
  COLS  <- misc$cols
  cat("reference copy:", nrow(truth), "rows,", sum(!is.na(truth$total)), "with a Total\n")


# 4). Parsing a reading into six columns ----

  # Every value on this page is printed with one decimal. A number token is
  # digits (with thousands commas), a point, one digit  or  point, digit ,
  # allowing the OCR habits of a space after a comma or a point ("1,169. 7",
  # "4, 708. 6") and a space in place of the point ("117 9"). Tokens with
  # letters, double points or no decimal ("i.'i)", "6.Y", "2156", "29") are
  # not numbers, so the cell is NA. Numbers are right-aligned in their column,
  # so a token's right edge says which column it is in: the right edges of
  # all number tokens fall into six clusters (k-means), one per column. For
  # the archive layer the positions are character columns of the layout text
  # that pdf_text() returns; for tesseract they are the word boxes of its
  # hOCR output, which also gives the lines. The row label is the text left
  # of the first number. Digits inside the label area (left 35% of the line)
  # are ignored.
  NUM <- "(?<![\\w.])(?:\\d{1,3}(?:, ?\\d{3})*(?:\\. ?| )\\d|\\. ?\\d)(?![\\w.])"
  to_num <- function(s) {
    s <- str_replace_all(s, "([,.]) ", "\\1")       # "1, 169. 7" -> "1,169.7"
    s <- str_replace_all(s, "(\\d) (\\d)", "\\1.\\2") # "117 9"     -> "117.9"
    as.numeric(str_remove_all(s, ","))
  }

  # tokens: data frame(row, text, right, is_num, label_part) -> six-column table
  assign_columns <- function(tok) {
    num <- tok[tok$is_num, ]
    num <- num[num$right > 0.35 * max(num$right), ]
    if (nrow(num) < 6 || length(unique(num$right)) < 6) {
      cat("   fewer than six distinct number positions: nothing parsed\n")
      out <- data.frame(row = integer(0), row_label = character(0))
      for (cc in COLS) out[[cc]] <- numeric(0)
      return(out)
    }
    km  <- kmeans(num$right, centers = 6, nstart = 25)
    ord <- order(km$centers); num$col <- match(km$cluster, ord)    # 1 = leftmost
    cat("   column right-edge centers:", round(sort(km$centers)), "\n")
    rows <- sort(unique(num$row))
    out <- data.frame(row = rows, row_label = NA_character_, stringsAsFactors = FALSE)
    for (cc in COLS) out[[cc]] <- NA_real_
    for (i in seq_along(rows)) {
      r <- rows[i]
      lab <- tok$text[tok$row == r & tok$label_part]
      out$row_label[i] <- str_squish(str_remove_all(paste(lab, collapse = " "), "[.:;'\"]"))
      nr <- num[num$row == r, ]
      for (k in seq_len(nrow(nr))) {
        cc <- COLS[nr$col[k]]
        if (is.na(out[i, cc])) out[i, cc] <- to_num(nr$text[k])
      }
    }
    out
  }

  # archive layer: lines of the layout text; positions are character columns
  parse_layout <- function(text) {
    ll <- strsplit(text, "\n")[[1]]
    tok <- data.frame()
    for (i in seq_along(ll)) {
      m <- str_locate_all(ll[i], NUM)[[1]]
      if (nrow(m) == 0) next
      tok <- rbind(tok,
        data.frame(row = i, text = str_sub(ll[i], 1, m[1, 1] - 1), right = 0,
                   is_num = FALSE, label_part = TRUE),
        data.frame(row = i, text = str_sub(ll[i], m[, 1], m[, 2]), right = m[, 2],
                   is_num = TRUE, label_part = FALSE))
    }
    assign_columns(tok)
  }

  # tesseract: hOCR gives word boxes and its own lines. Its line boxes are
  # stretched by the dot leaders, so words are regrouped into rows from the
  # number-like words, whose boxes sit on the baseline: their vertical
  # centres closer than row_tol (12 px at 300 dpi) form one row, and every
  # other word joins the row with the nearest centre (within 1.5 row_tol,
  # else it is dropped).
  # A word ending in "," or "." followed by a word of digits, or a number
  # followed by a single digit, is one number that tesseract split at a space.
  hocr_words <- function(png) {
    doc <- xml2::read_html(ocr(png, HOCR = TRUE))
    lines <- xml2::xml_find_all(doc, "//span[span[@class='ocrx_word']]")
    out <- data.frame()
    for (i in seq_along(lines)) {
      lb <- as.numeric(str_match(xml2::xml_attr(lines[[i]], "title"), "bbox \\d+ (\\d+) \\d+ (\\d+)")[, 2:3])
      w <- xml2::xml_find_all(lines[[i]], "./span[@class='ocrx_word']")
      b <- str_match(xml2::xml_attr(w, "title"), "bbox (\\d+) (\\d+) (\\d+) (\\d+); x_wconf (\\d+)")
      out <- rbind(out, data.frame(line = i, word = str_trim(xml2::xml_text(w)),
                                   x1 = as.numeric(b[, 2]), x2 = as.numeric(b[, 4]),
                                   yc = (as.numeric(b[, 3]) + as.numeric(b[, 5])) / 2,
                                   conf = as.numeric(b[, 6])))
    }
    out
  }
  parse_boxes <- function(d, row_tol) {
    anchor <- str_detect(d$word, "^\\W*\\d[\\d,]*\\.?\\d?\\W*$")
    if (sum(anchor) < 6) anchor <- rep(TRUE, nrow(d))
    yc <- sort(unique(d$yc[anchor]))
    grp <- cumsum(c(TRUE, diff(yc) > row_tol))
    centre <- tapply(yc, grp, mean)
    near <- sapply(d$yc, function(y) which.min(abs(centre - y)))
    d$row <- ifelse(abs(centre[near] - d$yc) <= 1.5 * row_tol, near, NA)
    d <- d[!is.na(d$row), ]
    cat(sprintf("   %d hOCR lines regrouped into %d rows\n", length(unique(d$line)), length(centre)))
    tok <- data.frame()
    for (r in sort(unique(d$row))) {
      w <- d[d$row == r, ]; w <- w[order(w$x1), ]
      # table rules and quotes read as | ] ) " ; stuck to the words, and a
      # comma after a complete number ("8.9,")
      words <- str_remove_all(w$word, "[|\\[\\]{}()'\"‘’;:]"); x2 <- w$x2
      words <- str_replace(words, "^(\\d{1,3}(,\\d{3})*\\.\\d),$", "\\1")
      k <- 1
      while (k < length(words)) {
        glue <- (str_detect(words[k], "^\\d{1,3}(,\\d{3})*,$") && str_detect(words[k + 1], "^\\d{3}")) ||
                (str_detect(words[k], "^\\d{1,3}(,\\d{3})*\\.$") && str_detect(words[k + 1], "^\\d$")) ||
                (str_detect(words[k], "^\\d{1,3}(,\\d{3})*$") && str_detect(words[k + 1], "^\\d$"))
        if (glue) {
          words[k] <- paste(words[k], words[k + 1]); x2[k] <- x2[k + 1]
          words <- words[-(k + 1)]; x2 <- x2[-(k + 1)]
        } else k <- k + 1
      }
      is_num <- str_detect(words, paste0("^", NUM, "$"))
      if (!any(is_num)) next
      first <- which(is_num)[1]
      # label words: letters before the dot leader ("Jersey.......220" -> "Jersey")
      words[seq_len(first - 1)] <- str_remove(words[seq_len(first - 1)], "[.\\d].*$")
      label_part <- seq_along(words) < first & str_detect(words, "^[A-Za-z]+$")
      tok <- rbind(tok, data.frame(row = r, text = words, right = x2,
                                   is_num = is_num, label_part = label_part))
    }
    assign_columns(tok)
  }


# 5). Aligning a reading with the reference rows, and scoring it ----

  # Labels are matched in order: a parsed label matches the nearest of the
  # next four reference labels whose letters differ in at most 2 places (3
  # for labels of 7 letters or more; prefix of the same length, case and
  # punctuation ignored); a row with no usable label takes the next
  # reference row in sequence; a garbage label that matches nothing is skipped.
  norm <- function(s) str_to_lower(str_remove_all(s, "[^A-Za-z]"))
  align_rows <- function(parsed, truth_labels) {
    parsed$truth_row <- rep(NA_integer_, nrow(parsed))
    p <- 1L; n <- length(truth_labels); tn <- norm(truth_labels)
    for (i in seq_len(nrow(parsed))) {
      if (p > n) break
      lab <- norm(parsed$row_label[i])
      cand <- p:min(p + 3L, n)
      d <- sapply(cand, function(j) adist(str_sub(lab, 1, nchar(tn[j])), tn[j]))
      lim <- ifelse(nchar(tn[cand]) >= 7, 3, 2)
      ok <- which(d <= lim)
      if (length(ok) && nchar(lab) >= 3) {
        j <- cand[ok[which.min(d[ok])]]; parsed$truth_row[i] <- j; p <- j + 1L
      } else if (nchar(lab) < 3) { parsed$truth_row[i] <- p; p <- p + 1L }
    }
    parsed
  }

  # does each row's five columns add to its printed Total?
  components_check <- function(tab) {
    has_total <- !is.na(tab$total)
    comp <- rowSums(tab[, COLS[1:5]], na.rm = TRUE)
    pass <- has_total & abs(comp - tab$total) <= 0.15
    list(rows = nrow(tab), with_total = sum(has_total), pass = sum(pass), pass_rows = pass)
  }
  # cells right/wrong over all reference rows (6 cells each); an unaligned
  # reference row counts as 6 wrong cells; NA matches NA
  score_cells <- function(aligned, truth) {
    read <- truth; read[, COLS] <- NA_real_
    ok <- !is.na(aligned$truth_row)
    read[aligned$truth_row[ok], COLS] <- aligned[ok, COLS]
    same <- (is.na(read[, COLS]) & is.na(truth[, COLS])) |
            (!is.na(read[, COLS]) & !is.na(truth[, COLS]) & abs(read[, COLS] - truth[, COLS]) < 0.05)
    wrong <- which(!same, arr.ind = TRUE)
    wl <- data.frame(row_label = truth$row_label[wrong[, 1]], col = COLS[wrong[, 2]],
                     truth = truth[, COLS][wrong], read = read[, COLS][wrong])
    wl <- wl[order(wrong[, 1], wrong[, 2]), ]
    list(right = sum(same), wrong = sum(!same), rows_aligned = sum(ok),
         wrong_list = wl, read = read)
  }
  report <- function(name, tab, truth) {
    cat(sprintf("\n-- %s: %d parsed rows\n", name, nrow(tab)))
    cc <- components_check(tab)
    cat(sprintf("   components vs Total (|diff| <= 0.15): %d of %d rows with a Total pass\n",
                cc$pass, cc$with_total))
    al <- align_rows(tab, truth$row_label)
    sc <- score_cells(al, truth)
    cat(sprintf("   aligned to %d of %d truth rows; cells right %d, wrong %d (of %d)\n",
                sc$rows_aligned, nrow(truth), sc$right, sc$wrong, 6 * nrow(truth)))
    if (nrow(sc$wrong_list) <= 40) { cat("   wrong cells:\n"); print(sc$wrong_list, row.names = FALSE) }
    else { cat("   first 40 wrong cells:\n"); print(head(sc$wrong_list, 40), row.names = FALSE) }
    invisible(list(aligned = al, score = sc, comp = cc))
  }


# 6). The archive's OCR layer ----

  cat("\n-- archive OCR layer: raw lines\n")
  al <- strsplit(arch, "\n")[[1]]
  for (w in c("Total United States", "Total New England States")) {
    l <- al[str_detect(al, w)]; cat(w, ":\n"); cat(l, "\n"); dput(l)
  }
  arch_tab <- parse_layout(arch)
  arch_res <- report("archive layer", arch_tab, truth)


# 7). tesseract at 300 and 100 dpi ----

  tess <- list()
  for (dpi in c(300, 100)) {
    png <- if (dpi == 300) misc$png else png100
    t0 <- Sys.time(); text <- ocr(png)
    secs <- as.numeric(Sys.time() - t0, units = "secs")
    writeLines(text, file.path(misc$ocr, sprintf("comp1899_%d.txt", dpi)))
    d <- ocr_data(png)
    h <- hocr_words(png)
    cat(sprintf("\n-- tesseract %d dpi: ocr %.1f s, %d words on %d hOCR lines\n",
                dpi, secs, nrow(h), length(unique(h$line))))
    tab <- parse_boxes(h, row_tol = 12 * dpi / 300)
    tess[[as.character(dpi)]] <- report(sprintf("tesseract %d dpi", dpi), tab, truth)
    # confidence of the words on the Total United States row
    b <- str_split_fixed(d$bbox, ",", 4); storage.mode(b) <- "numeric"
    yc <- (b[, 2] + b[, 4]) / 2
    i <- which(str_detect(d$word, "otal$") & str_detect(c(d$word[-1], ""), "^United$"))
    if (length(i)) {
      w <- d[abs(yc - yc[i[1]]) < 0.6 * median(b[, 4] - b[, 2]), ]
      cat("   Total United States row, words and confidence:\n")
      print(data.frame(word = w$word, confidence = round(w$confidence, 1)), row.names = FALSE)
    } else cat("   Total United States row not found by ocr_data()\n")
  }


# 8). Where the archive layer and tesseract (300 dpi) disagree ----

  cat("\n-- cells where the archive layer and tesseract 300 dpi disagree (truth rows)\n")
  A <- arch_res$score$read; B <- tess[["300"]]$score$read
  dis <- which(!((is.na(A[, COLS]) & is.na(B[, COLS])) |
                 (!is.na(A[, COLS]) & !is.na(B[, COLS]) & abs(A[, COLS] - B[, COLS]) < 0.05)),
               arr.ind = TRUE)
  dl <- data.frame(row_label = truth$row_label[dis[, 1]], col = COLS[dis[, 2]],
                   truth = truth[, COLS][dis], archive = A[, COLS][dis], tesseract = B[, COLS][dis])
  dl <- dl[order(dis[, 1], dis[, 2]), ]
  cat("  ", nrow(dl), "cells\n"); print(dl, row.names = FALSE)


# 9). Save the readings, aligned to the reference rows ----

  save_read <- function(read, file) write.csv(read, file, row.names = FALSE)
  save_read(arch_res$score$read,     file.path(misc$ocr, "comp1899_archive.csv"))
  save_read(tess[["300"]]$score$read, file.path(misc$ocr, "comp1899_tess300.csv"))
  save_read(tess[["100"]]$score$read, file.path(misc$ocr, "comp1899_tess100.csv"))
  cat("\nwrote comp1899_archive.csv, comp1899_tess300.csv and comp1899_tess100.csv in", misc$ocr, "\n")


# the end ----
