# make-figures.R: the charts for session 10. Run from this folder:
#   Rscript make-figures.R
# Every number is typed from the source named next to it; the savings
# figures come from R's built-in LifeCycleSavings.

RED  <- "#b31b1b"
GREY <- "grey55"
open_png <- function(file, w = 1600, h = 760) {
  png(file, width = w, height = h, res = 200)
  par(las = 1, mar = c(4, 4.5, 1.5, 1), cex = 1.35, cex.axis = 0.9, cex.lab = 1)
}

# 1) Reinhart and Rogoff: growth when public debt is above 90% of GDP ----
# Herndon, Ash & Pollin (2014), Cambridge Journal of Economics 38(2): 2.2%
# on average, "not -0.1% as published".
open_png("F1-debt-growth.png", w = 1400, h = 800)
v <- c(-0.1, 2.2)
b <- barplot(v, names.arg = c("Published", "Corrected"), col = c(GREY, RED),
             border = NA, ylim = c(-0.6, 2.8), width = 0.6, space = 0.6,
             ylab = "Average real GDP growth (%)", axes = FALSE)
axis(2, at = seq(0, 2.5, 0.5)); abline(h = 0)
text(b, v + ifelse(v < 0, -0.25, 0.25), sprintf("%.1f%%", v), cex = 1.2, font = 2)
mtext("Years with public debt above 90% of GDP, 20 advanced economies", side = 3,
      line = 0, cex = 0.9)
dev.off()

# 2) Institute for Replication experiment ----
# Brodeur et al. (2026), PNAS 123(22), abstract and Table 1.
open_png("F2-i4r.png", w = 1800, h = 780)
par(mfrow = c(1, 2), mar = c(3, 2, 3, 1), cex = 1.25)
lab <- c("No AI", "AI assisting", "AI in charge")
b <- barplot(c(94, 91, 37), names.arg = lab, col = c(GREY, GREY, RED), border = NA,
             ylim = c(0, 110), axes = FALSE, main = "Papers reproduced (%)",
             font.main = 1, cex.main = 1.1)
text(b, c(94, 91, 37) + 7, c("94", "91", "37"), font = 2)
b <- barplot(c(1.70, 0.74, 0.23), names.arg = lab, col = c(GREY, RED, RED),
             border = NA, ylim = c(0, 2), axes = FALSE,
             main = "Major coding errors found, per team", font.main = 1, cex.main = 1.1)
text(b, c(1.70, 0.74, 0.23) + 0.13, c("1.70", "0.74", "0.23"), font = 2)
dev.off()

# 3) Expected, felt, and measured speed ----
# Becker et al. (2025), METR: forecast 24% faster, felt 20% faster,
# measured 19% slower (completion time).
open_png("F3-speed.png", w = 1600, h = 800)
v <- c(24, 20, -19)
b <- barplot(v, names.arg = c("Expected, before", "Felt, after", "Measured"),
             col = c(GREY, GREY, RED), border = NA, ylim = c(-30, 32), axes = FALSE,
             ylab = "Faster (+) or slower (-) with AI, %")
axis(2, at = seq(-20, 30, 10)); abline(h = 0)
text(b, v + ifelse(v < 0, -4, 4), paste0(ifelse(v > 0, "+", ""), v, "%"), font = 2, cex = 1.1)
dev.off()

# 4) Recall of verifier agents on planted errors ----
# Willner & Yanagizawa-Drott (2026), "Verifying the Verifiers".
open_png("F4-recall.png", w = 1600, h = 760)
par(mar = c(4, 11, 1, 2), cex = 1.35)
v <- c(99, 80, 64, 48)
lab <- c("Code does not run", "Data errors", "Text vs. tables", "Paper vs. code")
b <- barplot(rev(v), names.arg = rev(lab), horiz = TRUE, col = c(RED, GREY, GREY, GREY),
             border = NA, xlim = c(0, 122), axes = FALSE,
             xlab = "Planted errors caught (%)")
text(rev(v) + 9, b, paste0(rev(v), "%"), font = 2)
dev.off()

# 5) The figure in the deliverable, and the same figure with all 50 ----
d <- LifeCycleSavings
k <- d[d$ddpi < 10, ]
open_png("F5-deliverable.png", w = 1400, h = 900)
par(mar = c(4.5, 4.5, 1, 1), cex = 1.2)
plot(k$ddpi, k$sr, pch = 19, col = "grey25",
     xlab = "Growth of disposable income (% a year)",
     ylab = "Savings rate (% of disposable income)")
abline(lm(sr ~ ddpi, data = k), lwd = 3, col = RED)
dev.off()

open_png("F6-reveal.png", w = 2000, h = 820)
par(mfrow = c(1, 2), mar = c(4.5, 4.5, 3, 1), cex = 1.1)
plot(k$ddpi, k$sr, pch = 19, col = "grey25", main = "In the deliverable",
     font.main = 1, xlab = "Growth of disposable income (% a year)",
     ylab = "Savings rate (%)")
abline(lm(sr ~ ddpi, data = k), lwd = 3, col = RED)
plot(d$ddpi, d$sr, pch = 19, col = "grey25", main = "All 50 countries",
     font.main = 1, xlab = "Growth of disposable income (% a year)",
     ylab = "Savings rate (%)")
out <- d$ddpi >= 10
points(d$ddpi[out], d$sr[out], pch = 21, bg = "gold", cex = 2)
text(d$ddpi[out], d$sr[out], rownames(d)[out], pos = 2, font = 2)
abline(lm(sr ~ ddpi, data = d), lwd = 3, col = RED)
dev.off()

# 7) Recruiters given a better or a weaker AI ----
# Dell'Acqua (working paper, 2022), "Falling Asleep at the Wheel", Tables 4
# and 5: seconds per resume = control mean 20.2 plus the estimated effect
# (+10.0 with the 75%-accurate AI, -1.4 with the 85%-accurate AI); accuracy
# gain over no AI on the paper's 1-10 scale, column 3 (+0.29, +0.08).
open_png("F7-recruiters.png", w = 1800, h = 780)
par(mfrow = c(1, 2), mar = c(3, 2, 3, 1), cex = 1.25)
lab <- c("No AI", "AI right 75%", "AI right 85%")
v <- c(20.2, 20.2 + 10.0, 20.2 - 1.4)
b <- barplot(v, names.arg = lab, col = c(GREY, GREY, RED), border = NA,
             ylim = c(0, 36), axes = FALSE, main = "Seconds spent per résumé",
             font.main = 1, cex.main = 1.1)
text(b, v + 2.2, round(v), font = 2)
v <- c(0.29, 0.08)
b <- barplot(v, names.arg = lab[2:3], col = c(GREY, RED), border = NA,
             ylim = c(0, 0.36), axes = FALSE, width = 0.6, space = 0.8,
             main = "Accuracy gain over no AI (1-10 scale)", font.main = 1, cex.main = 1.1)
text(b, v + 0.022, sprintf("+%.2f", v), font = 2)
dev.off()
