# =============================================================
# AEM 6850 - Session 18: Documents & scans
# Script 8 of 8 - cells right by model size.
#
# Lecture part 5, reading thousands of pages. Scores each model size's
# readings with the rules the slides use for the medium model. The 1899
# page: rows returned, rows whose five columns add to their Total (within
# 0.15), and cells matching the reference copy (348 cells). The rainfall
# sheets: cells where the model and the volunteers both hold a number and
# agree (within 0.005), numbers the model wrote where the volunteers have
# none, and years whose twelve months add to the written total.
#
# Reads:  replies/ (the medium model), replies/sizes/ (small and large),
#         data_clean/comp1899_truth.csv, data_clean/rain_volunteers.csv
# Writes: data_clean/scores_by_size.csv
#
# Open 18-documents.Rproj first. It sits at the project root, so the
# working directory is 18-documents/ and every path below is relative to it.
#
#   source("code/8_compare_sizes.R")
# =============================================================


# 1). Preliminary ----

  # Load or install the packages this script uses
  want <- c("jsonlite")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only=TRUE))
  rm(want, need)

  # Parameters
  misc <- list()
  misc$truth  <- "data_clean/comp1899_truth.csv"
  misc$vol    <- "data_clean/rain_volunteers.csv"
  misc$out    <- "data_clean/scores_by_size.csv"
  misc$cols   <- c("national", "state", "loan_trust", "savings", "private", "total")
  misc$months <- c("jan","feb","mar","apr","may","jun","jul","aug","sep","oct","nov","dec")
  misc$sheets <- c("1860s", "1870s", "1880s", "1890s", "1910s")
  # where each size's replies are
  misc$files  <- list(
    medium = list(p1899 = "replies/comp1899_run1.json",
                  sheet = function(s, r) sprintf("replies/abbotsbury_%s_run%d.json", s, r)),
    small  = list(p1899 = "replies/sizes/comp1899_small.json",
                  sheet = function(s, r) sprintf("replies/sizes/abbotsbury_%s_small_run%d.json", s, r)),
    large  = list(p1899 = "replies/sizes/comp1899_large.json",
                  sheet = function(s, r) sprintf("replies/sizes/abbotsbury_%s_large_run%d.json", s, r)))


# 2). The 1899 page against the reference copy ----

  COLS  <- misc$cols
  truth <- read.csv(misc$truth, stringsAsFactors = FALSE)
  norm  <- function(s) tolower(gsub("[^A-Za-z]", "", s))
  score_1899 <- function(path) {
    m <- fromJSON(path)
    for (cc in COLS) if (!cc %in% names(m)) m[[cc]] <- NA_real_
    m[COLS] <- lapply(m[COLS], as.numeric)
    pass <- !is.na(m$total) & abs(rowSums(m[, COLS[1:5]], na.rm = TRUE) - m$total) <= 0.15
    # align with the reference by label, as in code/3_model_1899.R
    tn <- norm(truth$row_label); mn <- norm(m$row_label)
    read <- truth; read[, COLS] <- NA_real_; p <- 1L
    for (i in seq_len(nrow(m))) {
      if (p > nrow(truth)) break
      cand <- p:min(p + 3L, nrow(truth))
      d <- sapply(cand, function(j) adist(substr(mn[i], 1, nchar(tn[j])), tn[j]))
      ok <- which(d <= ifelse(nchar(tn[cand]) >= 7, 3, 2))
      if (length(ok)) { j <- cand[ok[which.min(d[ok])]]; read[j, COLS] <- m[i, COLS]; p <- j + 1L }
    }
    T <- as.matrix(truth[, COLS]); M <- as.matrix(read[, COLS])
    same <- (is.na(M) & is.na(T)) | (!is.na(M) & !is.na(T) & abs(M - T) < 0.05)
    wrong <- which(!same, arr.ind = TRUE)
    list(rows = nrow(m), rows_pass = sum(pass), cells_right = sum(same), cells = length(T),
         wrong = if (nrow(wrong)) data.frame(row = truth$row_label[wrong[, 1]], col = COLS[wrong[, 2]],
                                             truth = T[wrong], model = M[wrong]) else NULL)
  }


# 3). The rainfall sheets against the volunteers ----

  vol <- read.csv(misc$vol, stringsAsFactors = FALSE)
  read_sheet <- function(path, sheet) {
    m <- fromJSON(path)
    if (length(m) == 0 || !is.data.frame(m)) m <- data.frame(year = integer(0))
    for (col in c(misc$months, "total")) if (is.null(m[[col]])) m[[col]] <- NA_real_
    m$year <- as.integer(m$year); m <- m[!duplicated(m$year), ]
    years <- sort(unique(vol$year[vol$sheet == sheet]))
    m <- m[match(years, m$year), c(misc$months, "total")]
    data.frame(sheet = sheet, year = rep(years, each = 13),
               month = rep(c(misc$months, "total"), times = length(years)),
               inches = as.numeric(as.vector(t(as.matrix(m)))))
  }
  score_sheet <- function(path, sheet) {
    v <- vol[vol$sheet == sheet, ]; m <- read_sheet(path, sheet)
    both <- !is.na(v$inches) & !is.na(m$inches)
    agree <- both & abs(v$inches - m$inches) < 0.005
    # a number where the volunteers have none; the braced months (one figure
    # written across two months: June 1870, June-July 1886, January-February
    # 1887) hold a real figure, so they are left out
    braced <- paste(v$year, v$month) %in% c("1870 jun", "1886 jun", "1886 jul", "1887 jan", "1887 feb")
    extra <- !is.na(m$inches) & is.na(v$inches) & !v$unread & !braced
    sums <- sapply(split(m, m$year), function(d) {
      mo <- d$inches[d$month != "total"]; tt <- d$inches[d$month == "total"]
      if (all(is.na(mo)) || is.na(tt) || any(is.na(mo))) NA else abs(sum(mo) - tt) <= 0.01
    })
    c(both = sum(both), agree = sum(agree), extra = sum(extra),
      years_checked = sum(!is.na(sums)), years_pass = sum(sums, na.rm = TRUE))
  }


# 4). Score every size ----

  out <- list()
  for (size in names(misc$files)) {
    f <- misc$files[[size]]
    if (!file.exists(f$p1899)) next
    s99 <- score_1899(f$p1899)
    cat(sprintf("\n== %s: 1899 page: %d rows returned, %d pass, %d of %d cells right\n",
                size, s99$rows, s99$rows_pass, s99$cells_right, s99$cells))
    if (!is.null(s99$wrong)) print(head(s99$wrong, 12), row.names = FALSE)
    sh <- do.call(rbind, lapply(misc$sheets, function(s) do.call(rbind, lapply(1:2, function(r) {
      p <- f$sheet(s, r); if (!file.exists(p)) return(NULL)
      data.frame(sheet = s, run = r, t(score_sheet(p, s)))
    }))))
    print(sh, row.names = FALSE)
    tot <- colSums(sh[, -(1:2)])
    cat(sprintf("   sheets, all runs: agree %d of %d cells both hold (%.3f); %d numbers where the volunteers have none; %d of %d complete years add to the written total\n",
                tot["agree"], tot["both"], tot["agree"] / tot["both"], tot["extra"],
                tot["years_pass"], tot["years_checked"]))
    out[[size]] <- data.frame(size = size, rows_1899 = s99$rows, rows_pass_1899 = s99$rows_pass,
                              cells_right_1899 = s99$cells_right, cells_1899 = s99$cells,
                              t(tot))
  }


# 5). Save ----

  scores <- do.call(rbind, out)
  write.csv(scores, misc$out, row.names = FALSE)
  print(scores, row.names = FALSE)
  cat("wrote", misc$out, "\n")


# the end ----
