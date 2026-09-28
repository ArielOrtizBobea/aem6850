# savings.R: the life-cycle savings regression, 50 countries, 1960-1970
# Data: R's built-in LifeCycleSavings (see ?LifeCycleSavings)

# 1) Load and clean ----
d <- LifeCycleSavings
d <- d[complete.cases(d), ]      # drop incomplete rows
d <- d[d$ddpi < 10, ]            # drop implausible growth rates
stopifnot(nrow(d) > 40)          # enough countries remain

# 2) Estimate ----
fit <- lm(sr ~ pop15 + pop75 + dpi + ddpi, data = d)
summary(fit)

# 3) Figure ----
png("savings_growth.png", width = 800, height = 560, res = 120)
plot(d$ddpi, d$sr, pch = 19,
     xlab = "Growth of disposable income (% a year)",
     ylab = "Savings rate (% of disposable income)")
abline(lm(sr ~ ddpi, data = d), lwd = 2)
dev.off()
