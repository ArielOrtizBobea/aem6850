# Population-weighted mean GDP per capita by continent for a given year
# (base R only). Prints a named vector with one number per continent.

YEAR <- 2007

gdp_by_continent <- function(d, yr) {
  sub <- d[d$year == yr, ]
  # Weight by population so large countries count for more, as in the
  # hand-computed Oceania check below.
  tapply(sub$gdpPercap * sub$pop, sub$continent, sum) /
    tapply(sub$pop, sub$continent, sum)
}

d <- read.csv("data/gapminder.csv", stringsAsFactors = FALSE)
res <- gdp_by_continent(d, YEAR)
print(res)

# Check: Oceania 2007 by hand. Australia 34,435.37 (20,434,176 people) and
# New Zealand 25,185.01 (4,115,771 people) give 32,883.
stopifnot(abs(res["Oceania"] - 32883) < 50)
