# For each continent, the country whose life expectancy rose the most
# between two years. Prints a named character vector (continent -> country).

FROM <- 1952
TO <- 2007

lifeexp_gain <- function(d, from, to) {
  start <- d[d$year == from, c("country", "continent", "lifeExp")]
  end <- d[d$year == to, c("country", "lifeExp")]
  # Merge on country so a country missing in either year drops out
  # instead of misaligning the subtraction.
  both <- merge(start, end, by = "country", suffixes = c("_from", "_to"))
  both$gain <- both$lifeExp_to - both$lifeExp_from
  tapply(seq_len(nrow(both)), both$continent, function(i) {
    both$country[i][which.max(both$gain[i])]
  })
}

d <- read.csv("data/gapminder.csv", stringsAsFactors = FALSE)
print(lifeexp_gain(d, FROM, TO))
