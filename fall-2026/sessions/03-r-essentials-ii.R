# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# AEM 6850 -- Empirical Methods for Applied Economists
# Prof. Ariel Ortiz-Bobea
# Session 3 -- R essentials II
# Tuesday, September 1, 2026
#
# Run it one line at a time: put the cursor on a line and press Cmd-Return
# (Mac) or Ctrl-Enter (Windows).
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# Matrices ----
m <- matrix(1:6, nrow = 2)
m
c(dim(m), nrow(m), ncol(m))

matrix(1:6, nrow = 2, byrow = TRUE)   # filled across, not down
matrix(1:2, nrow = 2, ncol = 3)       # too few values: R recycles them


# Indexing a matrix ----
m[2, 3]     # row 2, column 3
m[2, ]      # all of row 2
m[, 3]      # all of column 3

class(m[, 3])                # a plain vector: the dimension was dropped
class(m[, 3, drop = FALSE])  # still a matrix

head(m, 1)                   # first rows; tail() for the last


# Three ways to pick: position, name, logical ----
temps <- matrix(c(12, 15, 19,
                  14, 17, 22), nrow = 2, byrow = TRUE)
rownames(temps) <- c("Compton", "Reseda")
colnames(temps) <- c("Jan", "Feb", "Mar")
temps

temps["Reseda", "Feb"]     # by name, not position
temps[, c("Jan", "Feb")]   # several at once
temps[temps > 15]          # by logical: returns a vector


# The diagonal ----
sq <- matrix(1:9, nrow = 3)
sq

diag(sq)          # pull the diagonal out
diag(3)           # build a 3 x 3 identity matrix
diag(c(4, 5, 6))  # build a diagonal matrix from a vector


# Matrix arithmetic ----
temps * 9/5 + 32     # every cell at once, Celsius to Fahrenheit
t(temps)             # flip rows and columns


# Combining matrices ----
more <- matrix(c(9, 11, 16), nrow = 1,
               dimnames = list("Pasadena", c("Jan", "Feb", "Mar")))

rbind(temps, more)              # a new row: same columns
cbind(temps, Apr = c(21, 24))   # a new column: same rows

Matrix::bdiag(diag(2), matrix(1, 2, 2))   # blocks down the diagonal


# One matrix, one type ----
rbind(c(1, 2, 3),
      c("a", "b", "c"))


# Sparse matrices ----
library(Matrix)
set.seed(1); n <- 2000
d <- matrix(0, n, n); d[sample(n * n, n * n * 0.01)] <- 1   # 1% non-zero
s <- Matrix(d, sparse = TRUE); v <- rnorm(n)

c(dense = format(object.size(d), units = "MB"),
  sparse = format(object.size(s), units = "MB"))

c(dense  = system.time(for (i in 1:20) d %*% v)[["elapsed"]],
  sparse = system.time(for (i in 1:20) s %*% v)[["elapsed"]])


# Lists ----
l <- list(site = "Compton", readings = c(53.2, 33.6, 47.0), clean = TRUE)
str(l)
length(l)      # three elements...
lengths(l)     # ...of these lengths


# One bracket or two ----
l["readings"]     # a LIST of length one
l[["readings"]]   # the vector itself
l$readings        # the same thing, less typing

class(l["readings"])
class(l[["readings"]])


# Lists inside lists ----
monitor <- list(
  id   = "060371302",
  site = list(name = "Compton", lat = 33.90, lon = -118.21),
  pm   = c(53.2, 33.6, 47.0)
)

monitor$site$name
monitor[["site"]][["lat"]]
str(monitor)


# Where lists come from ----
x <- c(1, 2, 3, 4)
y <- c(1, 3, 2, 5)
fit <- lm(y ~ x)

class(fit)
names(fit)          # a list underneath
fit$coefficients


# What the fitted list is describing ----
plot(x, y, pch = 16, xlab = "x", ylab = "y")
abline(fit, col = "#b31b1b", lwd = 2)
segments(x, y, x, fitted(fit), lty = 2, col = "grey55")   # the residuals


# Combining list elements ----
pieces <- list(a = c(1, 2), b = c(3, 4), c = c(5, 6))

unlist(pieces)              # one flat vector, names kept
do.call(rbind, pieces)      # one matrix, one row per element


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Exercise 1 (5 minutes) ----
# 1. Build a diagonal matrix with the numbers 1 to 5 down the middle.
#
# 2. From m (the 2 x 3 matrix), pull the second column two ways: once
#    as a vector, once still a matrix.
#
# 3. l["readings"] and l[["readings"]]: which one can you take a mean of?
#    Find out with class(), not from memory.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




# apply(): once per row, once per column ----
apply(temps, 1, mean)              # 1 = rows
apply(temps, 2, mean)              # 2 = columns

rowMeans(temps); colMeans(temps)   # same answers, named and faster
rowSums(temps)


# Any function, not just mean ----
apply(temps, 2, max)
apply(temps, 2, range)                       # two numbers per column
apply(temps, 2, function(x) max(x) - min(x)) # write your own, inline


# split(): one group per element ----
x <- c(12, 15, 19, 14, 17, 22)
g <- c("Compton", "Compton", "Compton", "Reseda", "Reseda", "Reseda")

split(x, g)


# lapply(): a list in, a list out ----
by_site <- split(x, g)

lapply(by_site, mean)


# sapply(): the same, simplified ----
sapply(by_site, mean)      # a named vector, not a list
sapply(by_site, length)
sapply(by_site, range)     # two numbers each, so a matrix comes back

apply(temps, 1, mean)      # same answers, from the matrix


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Exercise 2 (5 minutes) ----
# 1. One line: the highest reading in each city. One line: the highest
#    in each month.
#
# 2. One line: the range of each site in by_site. Why does that come
#    back as a matrix?
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




# Read the file ----
la <- read.csv("data/epa_pm25_la_county_2025.csv")
dim(la)


# If you do not have the file yet ----
# Uncomment and run once. Same file, fetched instead of clicked.
# dir.create("data", showWarnings = FALSE)
# download.file(paste0("https://arielortizbobea.github.io/aem6850/",
#                      "fall-2026/sessions/data/epa_pm25_la_county_2025.csv"),
#               "data/epa_pm25_la_county_2025.csv")


# A data frame is a list of columns ----
is.list(la)             # a data frame IS a list
length(la)              # of 22 columns
head(sapply(la, class)) # so sapply walks the columns


# The identifier trap ----
la$Site.ID[1]        # what R holds


# Protect identifiers at read time ----
la <- read.csv("data/epa_pm25_la_county_2025.csv",
               colClasses = c("Site.ID" = "character"))

la$Site.ID[1]

unique(la$Site.ID)            # unique() drops repeats
length(unique(la$Site.ID))    # ...so this counts monitors: eleven


# Dates, one line deep ----
la$Date[1]
class(la$Date)

la$date <- as.Date(la$Date, format = "%m/%d/%Y")
class(la$date)
range(la$date)


# Pulling pieces back out of a date ----
d <- as.Date("2025-01-07")

c(month = format(d, "%m"), name = format(d, "%b"),
  year = format(d, "%Y"), doy = format(d, "%j"),
  day = weekdays(d))

la$month <- format(la$date, "%m")


# Dates are numbers, so they do arithmetic ----
d + 30                                # thirty days later
as.Date("2025-03-01") - d             # how far apart
seq(d, by = "week", length.out = 4)   # a sequence of dates
seq(as.Date("2025-01-01"), as.Date("2025-12-01"), by = "month")


# One row per what? ----
key <- la[, c("Site.ID", "date")]

anyDuplicated(key)     # 0 means none; otherwise the first repeated row
sum(duplicated(key))   # how many rows repeat a site-day


# Keep one instrument per site ----
frm <- la[la$AQS.Parameter.Code == 88101 & la$POC == 1, ]

anyDuplicated(frm[, c("Site.ID", "date")])   # 0: one row per site-day now


# Sites by months ----
tb <- tapply(frm$Daily.Mean.PM2.5.Concentration,
             list(frm$Local.Site.Name, frm$month), mean)

dim(tb)
round(tb[, 1:6], 1)


# reshape(): long to wide and back ----
long <- data.frame(site  = c("A", "A", "B", "B"),
                   month = c("01", "02", "01", "02"),
                   pm25  = c(21.3, 13.4, 11.6, 7.2))
long

wide <- reshape(long, direction = "wide",
                idvar = "site", timevar = "month", v.names = "pm25")
wide


# reshape(): wide back to long ----
reshape(wide, direction = "long", idvar = "site",
        varying = list(2:3), v.names = "pm25", times = c("01", "02"))


# Both margins at once ----
round(sort(apply(tb, 1, mean), decreasing = TRUE), 1)   # per site, all year
round(apply(tb, 2, mean), 1)                            # per month, all sites


# Two tables, one key ----
means <- data.frame(site = rownames(tb),
                    pm25 = round(apply(tb, 1, mean), 1))
coords <- unique(frm[, c("Local.Site.Name", "Site.Latitude", "Site.Longitude")])
names(coords) <- c("site", "lat", "lon")


# Merge setup shown ----
means  <- data.frame(site = rownames(tb), pm25 = round(apply(tb, 1, mean), 1))
coords <- unique(frm[, c("Local.Site.Name", "Site.Latitude", "Site.Longitude")])
names(coords) <- c("site", "lat", "lon")


# Merge, counting rows before and after ----
nrow(means); nrow(coords)                    # count BEFORE
sites <- merge(means, coords, by = "site")
nrow(sites)                                  # and after


# What a join does silently ----
partial <- coords[coords$site != "Compton", ]   # pretend one site is missing

nrow(merge(means, partial, by = "site"))                # dropped
nrow(merge(means, partial, by = "site", all.x = TRUE))  # kept, with NA


# One line, every file ----
files <- list.files("data", pattern = "\\.csv$")
files

sapply(files, function(f) nrow(read.csv(file.path("data", f))))


# Writing files to disk ----
answers <- data.frame(site = rownames(tb),
                      mean = round(apply(tb, 1, mean), 1))

write.csv(answers, "results.csv", row.names = FALSE)   # text, anything reads it
saveRDS(answers, "results.rds")                        # R's own format
readRDS("results.rds")


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Practice ----
# Everything below uses la, frm and tb, built earlier in this script.

# Matrices
#  1. Build a 3 x 4 matrix of the numbers 1 to 12, filled across the rows.
#  2. Same matrix: what is the sum of each row? Of each column?
#  3. Same matrix: divide every cell by its own column's total.
#  4. Add a fourth row of zeros with rbind(). Then add a fifth column.
#  5. Run rbind(c(1, 2), c("a", "b")). What class is the result, and why?

# Lists
#  6. Build a list holding your name, the numbers 1 to 5, and TRUE.
#  7. Same list: pull the numeric vector out two different ways.
#  8. What class does l["readings"] return? Check with class().
#  9. Split "2025-01-07" on the dash and get back a vector of three pieces.
# 10. unlist() the list from question 6. What happened to the numbers?

# apply and friends
# 11. Which column of la came in as character? (One line, all 22 at once.)
# 12. How many rows does each site have in la? (One line.)
# 13. Which month had the highest county-wide mean, and what was it?
# 14. Which site had the single dirtiest month of 2025?
# 15. Rebuild tb with median instead of mean. Where do the two disagree
#     most, and what does that tell you about those days?
# 16. One line: the number of rows in every CSV in your data folder.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =


# The end
