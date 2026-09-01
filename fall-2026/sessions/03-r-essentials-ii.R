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
dim(m)

matrix(1:6, nrow = 2, byrow = TRUE)   # filled across instead of down


# Indexing a matrix ----
m[2, 3]     # row 2, column 3
m[2, ]      # all of row 2
m[, 3]      # all of column 3


# Names on the margins ----
temps <- matrix(c(12, 15, 19,
                  14, 17, 22), nrow = 2, byrow = TRUE)
rownames(temps) <- c("Compton", "Reseda")
colnames(temps) <- c("Jan", "Feb", "Mar")
temps

temps["Reseda", "Feb"]
rowMeans(temps)
colMeans(temps)


# Matrix arithmetic ----
temps * 9/5 + 32     # every cell at once, Celsius to Fahrenheit
t(temps)             # flip rows and columns


# Combining matrices ----
more <- matrix(c(9, 11, 16), nrow = 1,
               dimnames = list("Pasadena", c("Jan", "Feb", "Mar")))

rbind(temps, more)          # a new row: same columns
cbind(temps, Apr = c(21, 24))   # a new column: same rows


# One matrix, one type ----
rbind(c(1, 2, 3),
      c("a", "b", "c"))


# Sparse matrices ----
library(Matrix)

set.seed(1)
n <- 1000
d <- matrix(0, n, n)
d[sample(n * n, n * n * 0.01)] <- 1   # only 1% of cells are not zero

s <- Matrix(d, sparse = TRUE)

format(object.size(d), units = "MB")   # dense: every cell stored
format(object.size(s), units = "MB")   # sparse: only the non-zeros


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
fit <- lm(c(1, 3, 2, 5) ~ c(1, 2, 3, 4))

class(fit)
names(fit)          # a list underneath
fit$coefficients


# Combining list elements ----
pieces <- list(a = c(1, 2), b = c(3, 4), c = c(5, 6))

unlist(pieces)              # one flat vector, names kept
do.call(rbind, pieces)      # one matrix, one row per element


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Exercise 1 (5 minutes) ----
# 1. Build a 3 x 4 matrix of the numbers 1 to 12, filled ACROSS the rows.
#    Name the rows A, B, C. What is the mean of row B?
#
# 2. Build a list holding your name, the numbers 1 to 5, and TRUE.
#    Pull the numeric vector out two different ways, then take its mean.
#
# 3. What does l["readings"] give you that l[["readings"]] does not?
#    Answer with class(), not from memory.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




# apply(): once per row, once per column ----
temps
apply(temps, 1, mean)    # 1 = rows
apply(temps, 2, mean)    # 2 = columns


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
# Everything here uses temps and by_site, built earlier in this script.
#
# 1. One line: the highest reading for each city. One line: the highest
#    for each month. Which margin number did each one need, and why?
#
# 2. Build a list of three numeric vectors of DIFFERENT lengths.
#    One line for how long each one is; one line for the mean of each.
#    Why could a matrix not hold this?
#
# 3. sapply(by_site, range) came back as a matrix, not a vector.
#    Use dim() to explain why.
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
is.list(la)                             # a data frame IS a list
length(la)                              # of 22 columns

sapply(la, class)                       # so sapply walks the columns


# The identifier trap ----
la$Site.ID[1]        # what R holds


# Protect identifiers at read time ----
la <- read.csv("data/epa_pm25_la_county_2025.csv",
               colClasses = c("Site.ID" = "character"))

la$Site.ID[1]
length(unique(la$Site.ID))    # eleven monitors in the county


# Dates, one line deep ----
la$Date[1]
class(la$Date)

la$date <- as.Date(la$Date, format = "%m/%d/%Y")
class(la$date)
range(la$date)

la$month <- format(la$date, "%m")   # pull pieces back out of a date


# One instrument, one method ----
frm <- la[la$AQS.Parameter.Code == 88101 & la$POC == 1, ]

nrow(frm)
length(unique(frm$Local.Site.Name))


# Sites by months ----
tb <- tapply(frm$Daily.Mean.PM2.5.Concentration,
             list(frm$Local.Site.Name, frm$month),
             mean)

class(tb)
dim(tb)
round(tb[, 1:6], 1)


# Both margins at once ----
round(sort(apply(tb, 1, mean), decreasing = TRUE), 1)   # per site, all year
round(apply(tb, 2, mean), 1)                            # per month, all sites


# One line, every file ----
files <- list.files("data", pattern = "\\.csv$")
files

sapply(files, function(f) nrow(read.csv(file.path("data", f))))


# Writing your answer out ----
answers <- data.frame(
  site  = rownames(tb),
  mean  = round(apply(tb, 1, mean), 1)
)

write.csv(answers, "results.csv", row.names = FALSE)


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
