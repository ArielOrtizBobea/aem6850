# Wineglass Marathon finishers, net times, from Leone Timing results pages.
# Keeps only place, sex, age group and net time; names, ages and towns are dropped.

# ==== BLOCK: setup ====
suppressPackageStartupMessages({
  library(rvest)
  library(dplyr)
  library(ggplot2)
})
source("fetch.R")
# ==== END BLOCK ====

# ==== BLOCK: data DEPS: setup ====
years <- 2018:2025
row_re <- paste0("^\\s*(\\d+)\\s+.*?\\s(\\d{1,3})\\s+([MFX])#?\\s*(\\d+)\\s+",
                 "(\\d+)/(\\d+)\\s+(\\S+)\\s+(\\d{1,2}:\\d\\d:\\d\\d)\\s")

parse_page <- function(body, year) {
  ln <- strsplit(body, "\r?\n")[[1]]
  # main table only: from the header rule after "PLACE NAME" to the next section
  start <- grep("^PLACE NAME", ln)[1] + 2
  stop_at <- grep("WHEELCHAIR|</PRE>", ln)
  stop_at <- min(stop_at[stop_at > start]) - 1
  ln <- ln[start:stop_at]
  ln <- ln[grepl("^\\s*\\d+\\s", ln)]
  full <- regmatches(ln, regexec(row_re, ln, perl = TRUE))
  ok <- lengths(full) > 0
  data.frame(
    year = year,
    place = as.integer(sub("^\\s*(\\d+).*", "\\1", ln)),
    sex = ifelse(ok, vapply(full, function(m) if (length(m)) m[4] else NA_character_, ""), NA),
    age_group = ifelse(ok, vapply(full, function(m) if (length(m)) m[8] else NA_character_, ""), NA),
    # net time is the first h:mm:ss on the row (before pace and splits)
    net_time = regmatches(ln, regexpr("\\d{1,2}:\\d\\d:\\d\\d", ln))
  )
}

res <- list(); last_place <- c()
for (y in years) {
  base <- sprintf("https://www.leonetiming.com/%d/Roads/Wineglass/", y)
  idx <- fetch(base)
  if (idx$status != 200) next
  a <- html_elements(read_html(idx$body), "a")
  txt <- html_text(a); href <- html_attr(a, "href")
  i <- which(grepl("Net", txt) & grepl("Marathon", href) &
             !grepl("Half|Relay", href, ignore.case = TRUE))
  stopifnot(length(i) == 1)
  pg <- fetch(paste0(base, href[i]))
  d <- parse_page(pg$body, y)
  res[[as.character(y)]] <- d
  last_place[as.character(y)] <- max(d$place)
}
wg <- bind_rows(res)
hms <- as.integer(strsplit(paste(wg$net_time), ":") |> unlist()) |> matrix(ncol = 3, byrow = TRUE)
wg$net_minutes <- hms[, 1] * 60 + hms[, 2] + hms[, 3] / 60
write.csv(wg, "wineglass.csv", row.names = FALSE)
# ==== END BLOCK ====

# ==== BLOCK: fig_hist DEPS: data ====
p <- ggplot(filter(wg, net_minutes >= 150, net_minutes < 390), aes(net_minutes)) +
  geom_histogram(breaks = seq(150, 390, 1), fill = "grey35", colour = NA) +
  geom_vline(xintercept = c(180, 210, 240, 270), colour = "firebrick", linewidth = 0.4) +
  scale_x_continuous(breaks = seq(150, 390, 30),
                     labels = function(x) sprintf("%d:%02d", x %/% 60, x %% 60)) +
  labs(x = "Net time (one-minute bins)", y = "Finishers",
       title = sprintf("Wineglass Marathon finishers, %s",
                       paste(range(wg$year), collapse = "–")),
       subtitle = "All years pooled; lines at 3:00, 3:30, 4:00 and 4:30") +
  theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank())
ggsave("wineglass.png", p, width = 9, height = 5, dpi = 150, bg = "white")
# ==== END BLOCK ====

# ==== BLOCK: fig_years DEPS: data ====
by_year <- wg |> group_by(year) |>
  summarise(finishers = n(), median_min = median(net_minutes), .groups = "drop")
long <- bind_rows(
  transmute(by_year, year, value = finishers, panel = "Finishers"),
  transmute(by_year, year, value = median_min, panel = "Median net time")
)
fmt_hm <- function(x) sprintf("%d:%02d", as.integer(x %/% 60), as.integer(round(x %% 60)))
p2 <- ggplot(long, aes(year, value)) +
  geom_line(colour = "grey50") + geom_point(size = 2.5, colour = "grey15") +
  facet_wrap(~panel, ncol = 1, scales = "free_y") +
  scale_x_continuous(breaks = by_year$year) +
  # panels share one scale spec: limits below 400 mean the median-minutes panel
  scale_y_continuous(
    breaks = function(l) if (l[2] < 400) seq(ceiling(l[1] / 3) * 3, l[2], 3)
                         else scales::extended_breaks()(l),
    labels = function(v) if (max(v, na.rm = TRUE) < 400) fmt_hm(v)
                         else format(v, big.mark = ",")) +
  labs(x = NULL, y = NULL, title = "Wineglass Marathon by year",
       subtitle = "No race in 2020") +
  theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank(), strip.text = element_text(face = "bold", hjust = 0))
ggsave("wineglass_years.png", p2, width = 7, height = 6, dpi = 150, bg = "white")
# ==== END BLOCK ====

# ==== BLOCK: report DEPS: data ====
cat("Rows kept and last place on page, by year\n")
for (y in names(last_place))
  cat(sprintf("  %s  rows %5d  last place %5d\n", y, sum(wg$year == y), last_place[y]))
cat("\nFinishers by whole net minute (all years)\n")
for (m in 237:242)
  cat(sprintf("  %d:%02d  %d\n", m %/% 60, m %% 60, sum(floor(wg$net_minutes) == m)))
cat("\nMedian net time by year\n")
med <- tapply(wg$net_minutes, wg$year, median)
for (y in names(med)) {
  s <- round(med[y] * 60)
  cat(sprintf("  %s  %d:%02d:%02d\n", y, s %/% 3600, (s %% 3600) %/% 60, s %% 60))
}
# ==== END BLOCK ====
