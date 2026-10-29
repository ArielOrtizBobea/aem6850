# =============================================================
# AEM 6850 - Session 18: Documents & scans
# Script 1 of 8 - Table 6 of the Fed's H.4.1, from its text layer.
#
# Lecture part 2, a born-digital PDF. Reads the H.4.1 release of
# 3 October 2024 from the text stored inside the PDF, checks the headline
# totals of Table 5, and rebuilds Table 6 (each Reserve Bank) as a data
# frame whose twelve banks add to the Total column.
#
# Reads:  data/h41.pdf
# Writes: data_clean/table6.csv
#
# Open 18-documents.Rproj first. It sits at the project root, so the
# working directory is 18-documents/ and every path below is relative to it.
#
#   source("code/1_fed_table6.R")
# =============================================================


# 1). Preliminary ----

  # Load or install the packages this script uses
  want <- c("pdftools", "stringr")
  need <- want[!(want %in% installed.packages()[,"Package"])]
  if (length(need)) install.packages(need)
  lapply(want, function(i) require(i, character.only=TRUE))
  rm(want, need)

  # Parameters
  misc <- list()
  misc$pdf <- "data/h41.pdf"
  misc$out <- "data_clean/table6.csv"
  misc$banks <- c("Boston", "New York", "Philadelphia", "Cleveland", "Richmond",
                  "Atlanta", "Chicago", "St. Louis", "Minneapolis", "Kansas City",
                  "Dallas", "San Francisco")


# 2). Headline totals of Table 5 (pages 6 and 7) ----

  txt <- pdf_text(misc$pdf)
  cat("pages:", length(txt), "\n")
  stopifnot(length(txt) == 11)

  lines6 <- strsplit(txt[6], "\n")[[1]]
  lines7 <- strsplit(txt[7], "\n")[[1]]

  show_line <- function(lines, what) {
    l <- lines[str_detect(lines, what)]
    cat("\n--", what, "-- (", length(l), "line(s) )\n")
    cat(l, sep = "\n"); dput(l)
    l
  }
  # the "(0)" between the label and the amount is the "eliminations from
  # consolidation" column; the pattern allows it (optional) and captures the
  # first amount after it
  pat_total <- function(what) paste0(what, "\\s+(?:\\(\\d+\\)\\s+)?([\\d,]+)")

  la <- show_line(lines6, "Total assets")
  assets <- str_match(la, pat_total("Total assets"))[, 2]
  cat("pattern:", pat_total("Total assets"), " -> ", assets, "\n")

  ll <- show_line(lines7, "Total liabilities")
  liab <- str_match(ll, pat_total("Total liabilities"))[, 2]
  cat("pattern:", pat_total("Total liabilities"), " -> ", liab, "\n")

  lc <- show_line(lines7, "Total capital")
  cap <- str_match(lc, pat_total("Total capital"))[, 2]
  cat("pattern:", pat_total("Total capital"), " -> ", cap, "\n")

  to_num <- function(x) as.numeric(str_remove_all(x, "[,\\s]"))
  cat("\n7,003,485 + 43,440 == 7,046,925 ?",
      to_num(liab) + to_num(cap) == to_num(assets), "\n")


# 3). An amount on page 8 ----

  # An amount is a run of digits in groups of three with commas, optionally
  # signed, standing alone between spaces (or at the start or end of the line).
  # Footnote markers ("loans1", "Program)2") are glued to a word or ")", so the
  # look-behind rejects them; "(0)" is glued to parentheses; "October 2, 2024"
  # fails because "2" is followed by a comma and "2024" has four digits.
  # The Interdistrict settlement account row prints its sign as a separate
  # token ("+     23,560"), so the sign may be followed by spaces.
  amt <- "(?<=\\s|^)(?:[-+]\\s*)?\\d{1,3}(?:,\\d{3})*(?=\\s|$)"
  cat("\namount pattern:", amt, "\n")

  lines8 <- strsplit(txt[8], "\n")[[1]]
  found8 <- str_extract_all(lines8, amt)
  n8 <- lengths(found8)
  cat("\npage 8: amounts per line\n"); print(table(n8))
  for (i in seq_along(lines8))
    cat(sprintf("%3d n=%2d | %s\n", i, n8[i], str_trunc(lines8[i], 60)))
  cat("\nTotal assets line, 13 amounts:\n")
  print(found8[[which(str_detect(lines8, "^Total assets"))]])
  cat("\nInterdistrict settlement account line (signed, sign is its own token):\n")
  print(found8[[which(str_detect(lines8, "Interdistrict"))]])
  cat("\nzeros are printed as 0 (no dashes, no blank cells in Table 6):",
      sum(unlist(found8) == "0"), "zeros on page 8\n")


# 4). Table 6 as a data frame ----

  # Long item names wrap: the lines above a data row that hold no amount and
  # are indented are the start of its label ("Gold certificates and special
  # drawing" / "rights certificates"). label_full glues them back on.
  parse_page <- function(lines) {
    found <- str_extract_all(lines, amt)
    keep  <- lengths(found) == 13
    label <- str_extract(lines[keep], "^.*?(?=\\s(?:[-+]\\s*)?\\d{1,3}(?:,\\d{3})*(?:\\s|$))")
    label <- str_trim(label)
    label <- str_remove(label, "\\d+$")        # footnote marker glued to the label
    full <- label
    for (k in seq_along(which(keep))) {
      i <- which(keep)[k]; parts <- character(0)
      while (i > 1 && lengths(found)[i - 1] == 0 && str_detect(lines[i - 1], "^\\s+\\S")) {
        i <- i - 1; parts <- c(str_trim(lines[i]), parts)
      }
      full[k] <- str_squish(paste(c(parts, label[k]), collapse = " "))
    }
    m <- t(sapply(found[keep], to_num))
    out <- data.frame(label = label, label_full = full, m, check.names = FALSE)
    names(out)[-(1:2)] <- c("Total", misc$banks)
    out
  }
  lines9 <- strsplit(txt[9], "\n")[[1]]
  n9 <- lengths(str_extract_all(lines9, amt))
  cat("\npage 9: amounts per line\n"); print(table(n9))

  tab <- rbind(parse_page(lines8), parse_page(lines9))
  rownames(tab) <- NULL
  cat("\ndim(tab):", dim(tab), "\n")
  print(head(tab))
  cat("\nrow labels (text before the first amount):\n"); print(tab$label)
  cat("\nrow labels with the wrapped lines glued back on:\n"); print(tab$label_full)


# 5). Do the twelve banks add to the Total? ----

  diff <- rowSums(tab[, misc$banks]) - tab$Total
  names(diff) <- tab$label
  cat("\nbanks - Total, nonzero rows:\n"); print(diff[diff != 0])
  cat("exact:", sum(diff == 0), " off by 1:", sum(abs(diff) == 1),
      " off by 2:", sum(abs(diff) == 2), " larger:", sum(abs(diff) > 2),
      " largest |diff|:", max(abs(diff)), "\n")

  # the headline rows
  hl <- tab[tab$label %in% c("Total assets", "Total liabilities",
                             "Total liabilities and capital"), c("label", "Total")]
  print(hl)
  stopifnot(hl$Total[hl$label == "Total assets"] == 7046925,
            hl$Total[hl$label == "Total liabilities"] == 7003485,
            hl$Total[hl$label == "Total liabilities and capital"] == 7046925)
  cap_rows <- c("Capital paid in", "Surplus", "Other capital")
  cat("Total liabilities + capital rows =",
      sum(tab$Total[tab$label %in% c("Total liabilities", cap_rows)]), "\n")


# 6). Save ----

  write.csv(tab, misc$out, row.names = FALSE)
  cat("wrote", misc$out, "\n")


# the end ----
