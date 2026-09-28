# Life-cycle savings regression (Modigliani / Belsley, Kuh & Welsch data)
# sr = aggregate personal savings / disposable income, 1960-1970 averages
# pop15, pop75 = % of population under 15 / over 75
# dpi = real per-capita disposable income (US$), ddpi = its growth rate (%)

# ==== BLOCK: setup ====
library(ggplot2)
# ==== END BLOCK ====

# ==== BLOCK: data DEPS: setup ====
d <- LifeCycleSavings
d$country <- rownames(d)
rownames(d) <- NULL

# Checks: 50 countries, no missing values, no duplicated countries,
# all values within plausible ranges. Nothing needs to be dropped.
stopifnot(nrow(d) == 50, !anyNA(d), !anyDuplicated(d$country))
stopifnot(all(d$sr >= 0 & d$sr <= 100),
          all(d$pop15 + d$pop75 <= 100),
          all(d$dpi > 0))

# Libya's income growth (16.7%) is far outside the rest (next: Jamaica 10.2).
# It stays in the main sample; the fit without it is reported as a check.
d$libya <- d$country == "Libya"
# ==== END BLOCK ====

# ==== BLOCK: regression DEPS: data ====
fit      <- lm(sr ~ pop15 + pop75 + dpi + ddpi, data = d)
fit_nolb <- update(fit, subset = !libya)

print(summary(fit))
cat("\nWithout Libya:\n")
print(round(coef(summary(fit_nolb)), 4))

b    <- coef(fit)
b_nl <- coef(fit_nolb)
# ==== END BLOCK ====

# ==== BLOCK: figure DEPS: regression ====
fit_biv <- lm(sr ~ ddpi, data = d)

p <- ggplot(d, aes(ddpi, sr)) +
  geom_smooth(method = "lm", formula = y ~ x, se = TRUE,
              colour = "#2A6FDB", fill = "#2A6FDB", alpha = 0.12,
              linewidth = 0.8) +
  geom_point(size = 2.4, colour = "#2A6FDB", alpha = 0.85,
             stroke = 0.5, shape = 21, fill = "#2A6FDB") +
  geom_text(data = subset(d, libya | country %in% c("Japan", "Jamaica")),
            aes(label = country), hjust = 1.15, vjust = -0.5,
            size = 3.2, colour = "grey25") +
  scale_x_continuous(breaks = seq(0, 16, 2)) +
  labs(x = "Growth rate of per-capita disposable income (%)",
       y = "Personal savings rate (% of disposable income)",
       title = "Savings rate and income growth, 50 countries, 1960-1970",
       subtitle = sprintf(paste0(
         "Line: simple OLS fit, slope %.2f. ",
         "Holding age structure and income level fixed, the slope is %.2f."),
         coef(fit_biv)[2], b["ddpi"])) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(),
        panel.grid.major = element_line(colour = "grey90", linewidth = 0.3),
        plot.title = element_text(face = "bold"),
        plot.subtitle = element_text(colour = "grey35", size = 9.5),
        axis.title = element_text(colour = "grey25"),
        plot.background = element_rect(fill = "white", colour = NA))

ggsave("savings_growth.png", p, width = 7.5, height = 5, dpi = 200)
# ==== END BLOCK ====

# ==== BLOCK: summary DEPS: regression ====
txt <- sprintf(paste0(
  "In %d countries over 1960-1970, households saved more where incomes were growing ",
  "faster: each extra percentage point of annual income growth went with a savings ",
  "rate about %.1f points higher, comparing countries with similar age profiles and ",
  "income levels (%.1f points if Libya, an extreme case of fast growth, is left out). ",
  "Countries with more children saved less: 10 more percentage points of the ",
  "population under 15 went with a savings rate about %.1f points lower, as the ",
  "life-cycle theory predicts, while the share over 75 and the level of income ",
  "had no clear effect. ",
  "These factors explain about a third (%.0f%%) of the differences in savings rates, ",
  "which averaged %.1f%% of disposable income.\n"),
  nobs(fit), b["ddpi"], b_nl["ddpi"], -10 * b["pop15"],
  100 * summary(fit)$r.squared, mean(d$sr))

writeLines(c("# Life-cycle savings regression", "", txt), "summary.md")
# ==== END BLOCK ====
