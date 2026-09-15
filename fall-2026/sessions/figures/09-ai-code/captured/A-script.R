# Mean life expectancy by continent for a given year (base R only)

lifeexp_by_continent <- function(d, yr) {
  sub <- d[d$year == yr, ]
  tapply(sub$lifeExp, sub$continent, mean)
}

d <- read.csv("data/gapminder.csv", stringsAsFactors = FALSE)
print(lifeexp_by_continent(d, 2007))
