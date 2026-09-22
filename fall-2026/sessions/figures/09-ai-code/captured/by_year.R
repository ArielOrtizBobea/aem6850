# Reads data/placements.csv. Writes nothing; prints a table with one row
# per year giving the number of placements and the number of postdocs.

PLACEMENTS <- "data/placements.csv"

count_by_year <- function(placements) {
  n_placements <- tapply(placements$postdoc, placements$year, length)
  n_postdoc <- tapply(placements$postdoc, placements$year, sum)
  by_year <- data.frame(
    year = as.integer(names(n_placements)),
    n_placements = as.integer(n_placements),
    n_postdoc = as.integer(n_postdoc)
  )
  # Every placement belongs to exactly one year, so the counts must add up.
  stopifnot(sum(by_year$n_placements) == nrow(placements))
  by_year
}

placements <- read.csv(PLACEMENTS)
by_year <- count_by_year(placements)
print(by_year, row.names = FALSE)
