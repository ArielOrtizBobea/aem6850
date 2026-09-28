# Life-cycle savings regression (Modigliani 1966 / Belsley, Kuh & Welsch 1980)
# sr ~ pop15 + pop75 + dpi + ddpi, 50 countries, averages over 1960-1970.
# Run whole: Rscript savings.R    One block: make block name=<block>

# ==== BLOCK: setup DEPS: ====
suppressPackageStartupMessages(library(ggplot2))
# ==== END BLOCK ====

# ==== BLOCK: data DEPS: setup ====
d <- datasets::LifeCycleSavings
d$country <- rownames(d)
rownames(d) <- NULL

# Checks: no missing values, no duplicate rows, all values in plausible ranges.
stopifnot(!anyNA(d), !anyDuplicated(d$country), nrow(d) == 50,
          all(d$sr >= 0 & d$sr <= 100),
          all(d$pop15 >= 0 & d$pop15 <= 100),
          all(d$pop75 >= 0 & d$pop75 <= 100),
          all(d$dpi > 0))
# Nothing needs dropping or recoding. Libya's income growth (16.7%/yr) is far
# above every other country and is a known high-leverage point; it is kept in
# the main estimate and dropped only in the sensitivity check below.
# ==== END BLOCK ====

# ==== BLOCK: model DEPS: data ====
fit <- lm(sr ~ pop15 + pop75 + dpi + ddpi, data = d)
print(summary(fit))

fit_nolibya <- update(fit, data = subset(d, country != "Libya"))
cat("\nSensitivity: dropping Libya\n")
print(round(cbind(all = coef(fit), no_libya = coef(fit_nolibya)), 4))

h <- hatvalues(fit)
cat("\nHighest-leverage countries (cutoff 2p/n =", 2 * 5 / 50, ")\n")
print(round(head(sort(setNames(h, d$country), decreasing = TRUE), 3), 3))
# ==== END BLOCK ====

# ==== BLOCK: fig_growth DEPS: data ====
biv <- lm(sr ~ ddpi, data = d)
p <- ggplot(d, aes(ddpi, sr)) +
  geom_smooth(method = "lm", formula = y ~ x, se = TRUE,
              colour = "#2a6fdb", fill = "#2a6fdb", alpha = 0.12, linewidth = 0.8) +
  geom_point(size = 2.2, colour = "#3d3d3d", alpha = 0.85) +
  geom_text(data = subset(d, country %in% c("Libya", "Japan")),
            aes(label = country), hjust = 1.2, vjust = 0.4, size = 3.4,
            colour = "#555555") +
  labs(x = "Growth rate of per-capita disposable income (% per year)",
       y = "Savings rate (% of disposable income)",
       title = "Savings rate and income growth, 50 countries, 1960-1970",
       subtitle = sprintf(
         "Line: simple OLS fit with 95%% band, slope %.2f points per point of growth",
         coef(biv)[["ddpi"]]),
       caption = "Data: R datasets::LifeCycleSavings (Belsley, Kuh & Welsch 1980)") +
  theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold"),
        plot.subtitle = element_text(colour = "#555555"),
        plot.caption = element_text(colour = "#777777", size = 9))
ggsave("savings_growth.png", p, width = 7.5, height = 5, dpi = 200, bg = "white")
# ==== END BLOCK ====
