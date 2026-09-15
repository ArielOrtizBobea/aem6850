# Population-weighted mean life expectancy by continent for a given year (base R only)

lifeexp_by_continent <- function(d, yr) {
  sub <- d[d$year == yr, ]
  tapply(sub$lifeExp * sub$pop, sub$continent, sum) /
    tapply(sub$pop, sub$continent, sum)
}

d <- read.csv("data/gapminder.csv", stringsAsFactors = FALSE)
res <- lifeexp_by_continent(d, 2007)
print(res)

# Check: Oceania 2007 by hand. Australia 81.235 (20,434,176 people) and
# New Zealand 80.204 (4,115,771 people) give 81.06.
stopifnot(abs(res["Oceania"] - 81.06) < 0.01)
