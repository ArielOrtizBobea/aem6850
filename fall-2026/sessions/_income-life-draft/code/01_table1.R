# Table 1: countries, life expectancy and income by continent, 2007

d <- read.csv("data/gapminder.csv")
d <- d[d$year == 2007, ]

table1 <- data.frame(
  continent = sort(unique(d$continent)),
  countries = as.vector(table(d$continent)),
  life_exp  = round(tapply(d$lifeExp, d$continent, mean), 1),
  gdp_pc    = round(tapply(d$gdpPercap, d$continent, median))
)

write.csv(table1, "output/table1.csv", row.names = FALSE)
