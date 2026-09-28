# Figure 1: life expectancy against GDP per capita, 2007

d <- read.csv("data/gapminder.csv")
d <- d[d$year == 2007, ]

pdf("output/figure1.pdf", width = 6.5, height = 4, pointsize = 10)
par(mar = c(4.5, 4.5, 1, 1))
plot(d$gdpPercap, d$lifeExp, log = "x", pch = 19, col = "grey30",
     xlab = "GDP per capita (US dollars, inflation-adjusted, log scale)",
     ylab = "Life expectancy at birth (years)")
dev.off()
