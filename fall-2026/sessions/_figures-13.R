# Figures for the session 13 page and slides, drawn from the files in
# _figures-13-data/ (see its SOURCE.txt). Run from fall-2026/sessions:
#   Rscript _figures-13.R
# Writes figures/13-data/F02-admin-data-journals.png,
# F03-opportunity-atlas-county.png and F04-card-spending-quartiles.png.

suppressPackageStartupMessages(library(maps))
dat <- "_figures-13-data"
out <- "figures/13-data"
dir.create(out, showWarnings = FALSE, recursive = TRUE)
pal <- unname(palette.colors(8, "Okabe-Ito"))   # colour-blind safe

png_open <- function(file, w = 1800, h = 1100) {
  png(file, width = w, height = h, res = 150)
  par(family = "Helvetica", las = 1, lwd = 2, cex = 1.25)
}

# F2). Administrative data in four journals, 1980-2010 (Chetty 2012) ----
ch <- read.csv(file.path(dat, "chetty1_increase_admin.csv"))
png_open(file.path(out, "F02-admin-data-journals.png"))
par(mar = c(4.2, 5.2, 1, 7.5), mgp = c(3.2, 0.7, 0))
plot(ch$Year, ch$AER, type = "n", ylim = c(0, 80), xlim = c(1980, 2010),
     xlab = "Year", ylab = "Papers using administrative data (%)",
     axes = FALSE, xaxs = "i")
axis(1, at = c(1980, 1990, 2000, 2010)); axis(2, at = seq(0, 80, 20)); box(bty = "l")
j <- c("AER", "JPE", "QJE", "ECMA"); lab <- c("AER", "JPE", "QJE", "Econometrica")
jcol <- pal[c(2, 3, 4, 8)]   # orange, sky blue, green, purple
for (i in seq_along(j)) {
  lines(ch$Year, ch[[j[i]]], col = jcol[i], lwd = 3)
  points(ch$Year, ch[[j[i]]], col = jcol[i], pch = 16, cex = 1.3)
}
par(xpd = NA)
yend <- ch[ch$Year == 2010, j]
ypos <- as.numeric(yend); ypos <- ypos + c(0, 0, 0, 0)  # 75, 60, 69, 38: no overlap
text(2010.6, ypos, lab, col = jcol, adj = 0, font = 2)
dev.off()

# F3). Opportunity Atlas: adult income rank of children from 25th-percentile
#      families, by county ----
oa <- read.csv(file.path(dat, "county_outcomes_simple.csv"))
oa$fips <- oa$state * 1000 + oa$county
v <- oa$kfr_pooled_pooled_p25
data(county.fips)
cf <- county.fips; cf$polyname <- sub(":.*$", "", cf$polyname)
m <- map("county", plot = FALSE, fill = TRUE)
nm <- sub(":.*$", "", m$names)
fips <- cf$fips[match(nm, cf$polyname)]
val <- v[match(fips, oa$fips)]
br <- quantile(v, c(0, .2, .4, .6, .8, 1), na.rm = TRUE)
cls <- cut(val, br, include.lowest = TRUE)
cols5 <- hcl.colors(5, "Blue-Red", rev = TRUE)   # red for low, blue for high
png(file.path(out, "F03-opportunity-atlas-county.png"), width = 1800, height = 1150, res = 150)
layout(matrix(1:2, nrow = 2), heights = c(10, 1.4))
par(mar = c(0, 0, 0, 0), family = "Helvetica")
map("county", fill = TRUE, col = ifelse(is.na(cls), "white", cols5[cls]), border = NA,
    projection = "albers", parameters = c(29.5, 45.5), resolution = 0)
map("state", add = TRUE, col = "white", lwd = 0.6,
    projection = "albers", parameters = c(29.5, 45.5), resolution = 0)
labs <- paste0(round(100 * br[-6]), " to ", round(100 * br[-1]))
par(mar = c(0, 0, 0, 0))
plot.new()
legend("center", horiz = TRUE, fill = cols5, border = NA, bty = "n", cex = 1.25,
       legend = labs, title = "Average adult income rank (percentile) of children from 25th-percentile families",
       x.intersp = 0.6, text.width = NA)
dev.off()
cat("F3: counties", nrow(oa), "mapped", sum(!is.na(val)), "\n")

# F4). Card spending relative to January 2020, by ZIP-code income quartile ----
af <- read.csv(file.path(dat, "affinity_daily.csv"), na.strings = ".")
af <- af[af$freq == "d" & af$year == 2020, ]
af$date <- as.Date(sprintf("%d-%02d-%02d", af$year, af$month, af$day))
af <- af[order(af$date), ]
ma7 <- function(x) stats::filter(x, rep(1 / 7, 7), sides = 2)
q <- paste0("spend_all_q", 1:4)
qlab <- c("Lowest-income quarter of ZIP codes", "Second", "Third", "Highest-income quarter")
png_open(file.path(out, "F04-card-spending-quartiles.png"))
par(mar = c(4.2, 5.2, 1, 12.5), mgp = c(3.2, 0.7, 0))
plot(af$date, 100 * af$spend_all_q4, type = "n", ylim = c(-45, 20),
     xlab = "2020", ylab = "Card spending, change from January 2020 (%)",
     axes = FALSE)
axis.Date(1, af$date, format = "%b"); axis(2, at = seq(-40, 20, 20)); box(bty = "l")
abline(h = 0, col = "grey70", lwd = 1.5)
qcol <- pal[c(3, 7, 2, 6)]
for (i in 1:4) lines(af$date, 100 * ma7(af[[q[i]]]), col = qcol[i], lwd = 3)
par(xpd = NA)
yend <- sapply(q, function(k) { s <- 100 * ma7(af[[k]]); tail(s[!is.na(s)], 1) })
text(max(af$date) + 6, yend, qlab, col = qcol, adj = 0, font = 2, cex = 0.9)
dev.off()
cat("F4: days", nrow(af), "\n")
mid_apr <- af[af$date == as.Date("2020-04-15"), q]
cat("F4 mid-April values:", round(100 * as.numeric(mid_apr), 1), "\n")
