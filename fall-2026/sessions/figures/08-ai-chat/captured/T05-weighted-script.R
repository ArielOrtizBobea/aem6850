# 2_lifeexp_weighted_2007.R
# Population-weighted mean of life expectancy by continent, 2007.
# Base R only. Run from the RStudio project root.
# Input: data/gapminder.csv
# Output: output/lifeexp_weighted_2007.csv

# Read data -----------------------------------------------------------------
gm <- read.csv("data/gapminder.csv", stringsAsFactors = FALSE)

# Check structure against expectations
expected_cols <- c("country", "continent", "year", "lifeExp", "pop", "gdpPercap")
stopifnot(identical(names(gm), expected_cols))
stopifnot(nrow(gm) == 1704)
stopifnot(length(unique(gm$country)) == 142)
stopifnot(identical(sort(unique(gm$year)), seq(1952L, 2007L, by = 5L)))

# Keep 2007 -----------------------------------------------------------------
gm07 <- gm[gm$year == 2007, ]
stopifnot(nrow(gm07) == 142)
stopifnot(!anyNA(gm07[, c("continent", "lifeExp", "pop")]))

# read.csv stores pop as integer. Continental sums exceed the integer
# maximum (about 2.1 billion), which would return NA. Convert to double.
gm07$pop <- as.numeric(gm07$pop)

# Weighted mean by continent ------------------------------------------------
gm07$lifeExp_x_pop <- gm07$lifeExp * gm07$pop
num <- tapply(gm07$lifeExp_x_pop, gm07$continent, sum)
den <- tapply(gm07$pop, gm07$continent, sum)

res <- data.frame(
  continent = names(num),
  weighted_lifeExp = as.numeric(num / den[names(num)]),
  stringsAsFactors = FALSE
)
stopifnot(nrow(res) == 5)

# Write output --------------------------------------------------------------
dir.create("output", showWarnings = FALSE)
write.csv(res, "output/lifeexp_weighted_2007.csv", row.names = FALSE)

# Print results -------------------------------------------------------------
for (i in seq_len(nrow(res))) {
  cat(sprintf("%-10s %.2f\n", res$continent[i], res$weighted_lifeExp[i]))
}
