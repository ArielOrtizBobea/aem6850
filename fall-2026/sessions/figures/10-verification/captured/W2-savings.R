# Life-cycle savings regression (Modigliani; Belsley, Kuh & Welsch 1980)
# using R's built-in LifeCycleSavings: 50 countries, averages over 1960-1970.
#   sr    aggregate personal savings / disposable income (%)
#   pop15 share of population under 15 (%)
#   pop75 share of population over 75 (%)
#   dpi   real per-capita disposable income (US$)
#   ddpi  growth rate of dpi (%)

# ==== BLOCK: setup DEPS: ====
library(ggplot2)
# ==== END BLOCK ====

# ==== BLOCK: data DEPS: setup ====
# The data ship with no missing values, so cleaning is limited to moving the
# country names out of the row names into a column and checking ranges.
savings <- LifeCycleSavings
savings$country <- rownames(savings)
rownames(savings) <- NULL
savings <- savings[, c("country", "sr", "pop15", "pop75", "dpi", "ddpi")]

stopifnot(
  !anyNA(savings),
  !anyDuplicated(savings$country),
  all(savings$sr >= 0), all(savings$dpi > 0),
  all(savings$pop15 > 0 & savings$pop15 < 100),
  all(savings$pop75 > 0 & savings$pop75 < 100)
)
# ==== END BLOCK ====

# ==== BLOCK: model DEPS: data ====
fit <- lm(sr ~ pop15 + pop75 + dpi + ddpi, data = savings)
print(summary(fit))

# Libya's income growth (16.7%) is far outside the rest of the sample
# (next highest 10.2%) and is the classic high-leverage point in this
# regression. Report the fit without it as a robustness check; the main
# estimate keeps all 50 countries.
infl <- data.frame(country = savings$country,
                   leverage = hatvalues(fit),
                   cooks_d  = cooks.distance(fit))
print(head(infl[order(-infl$cooks_d), ], 3), row.names = FALSE)

fit_nolibya <- update(fit, data = subset(savings, country != "Libya"))
print(round(cbind(all = coef(fit), no_Libya = coef(fit_nolibya)), 5))
# ==== END BLOCK ====

# ==== BLOCK: fig_growth DEPS: data ====
# Raw savings rate against income growth, with a simple bivariate OLS line
# and its 95% confidence band.
p <- ggplot(savings, aes(ddpi, sr)) +
  geom_smooth(method = "lm", formula = y ~ x, colour = "#2a6fdb",
              fill = "#2a6fdb", alpha = 0.12, linewidth = 0.7) +
  geom_point(size = 2.2, colour = "#2a6fdb", alpha = 0.85) +
  geom_text(data = subset(savings, ddpi > 8 | sr > 20 | sr < 2),
            aes(label = country), size = 3, colour = "grey30",
            hjust = 0, nudge_x = 0.25) +
  scale_x_continuous(expand = expansion(mult = c(0.02, 0.1))) +
  labs(x = "Growth rate of per-capita disposable income, 1960-70 (%)",
       y = "Personal savings rate (% of disposable income)",
       title = "Faster-growing countries saved more",
       subtitle = "50 countries, 1960-70 averages; line is OLS fit with 95% band") +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold"),
        plot.subtitle = element_text(colour = "grey35"))

ggsave("savings_growth.png", p, width = 7, height = 4.8, dpi = 200, bg = "white")
# ==== END BLOCK ====
