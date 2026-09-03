# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# AEM 6850 -- Empirical Methods for Applied Economists
# Prof. Ariel Ortiz-Bobea
# Session 2 -- R essentials I
# Thursday, August 27, 2026
#
# Run it one line at a time: put the cursor on a line and press Cmd-Return
# (Mac) or Ctrl-Enter (Windows).
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# Objects and calls ----
x <- c(1, 2, 3)
f <- function(v) v * 2

class(f)        # a function is an object, exactly like a vector
class(`+`)      # so is the plus sign
`+`(x, 1)       # so x + 1 is a call to that object


# One function, many classes ----
summary(c(1, 2, 3, 100))
summary(c("a", "b", "a"))


# Objects and assignment ----
x <- c(1, 2, 3, 4, 5)   # the arrow points from the value into the name
x = c(1, 2, 3, 4, 5)    # also assigns; you will meet it in other code
c(1, 2, 3, 4, 5) -> x   # legal, and points the other way

x
class(x)
length(x)


# Your environment ----
ls()            # everything you have named, right now

5 + 3           # this prints, and is gone
ls()            # nothing new: it was never given a name


# Asking R for help ----
?seq             # the help page for seq()
help(seq)        # the same thing
??regression     # search the help system when you do not know the name


# Building vectors ----
1:10
seq(0, 100, by = 25)
seq(0, 1, length.out = 5)
rep(c("a", "b"), times = 3)
rep(c("a", "b"), each = 3)


# Vector arithmetic ----
x * 2
x + c(10, 20, 30, 40, 50)
x + c(0, 100)      # lengths do not match -- R recycles, and warns


# Summaries ----
sum(x)
mean(x)
min(x)
max(x)
range(x)         # both ends at once
round(mean(x), 2)   # trim the decimals before you report a number


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Exercise 1 ----
# One line, two commands: what is the mean of 0, 25, 50, 75, 100?
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




# Types ----
class(1)
class("a")
class(TRUE)
class(as.Date("2025-01-07"))


# Silent conversion ----
c(1, 2, 3)
c(1, 2, "three")          # one text value converts the whole vector
class(c(1, 2, "three"))


# TRUE is 1 ----
sum(c(TRUE, FALSE, TRUE))   # TRUE becomes 1, FALSE becomes 0
mean(c(TRUE, FALSE, TRUE))  # so the mean of a logical is a proportion


# Text sorts like text ----
sort(c(10, 9, 100))
sort(c("10", "9", "100"))   # character by character


# What silent conversion costs you ----
readings <- c(12.4, 18.1, 9.7, "n/a", 22.3)
class(readings)
mean(readings)


# The repair ----
readings <- as.numeric(readings)   # "n/a" cannot convert -- it becomes NA
readings
mean(readings, na.rm = TRUE)


# Missing values ----
temps <- c(21.0, NA, 19.4, 23.8)
mean(temps)
mean(temps, na.rm = TRUE)

is.na(temps)
sum(is.na(temps))
temps == NA        # == tests for equality; this is not how you test for NA


# Indexing ----
x <- c(10, 20, 30, 40, 50)
x[1]
x[c(1, 3)]
x[-1]              # everything except the first
x[length(x)]       # the last, however long it is


# Logical subsetting ----
x > 25             # a TRUE/FALSE for every element
x[x > 25]          # keep the elements where it is TRUE
sum(x > 25)        # count them -- TRUE is 1
x[x > 25 & x < 45] # & is and, | is or


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Exercise 2 ----
# w <- c(12, 45, 7, 33, 88, 21)
#
# One line each: how many values are above 20?
#                what is the mean of just those?
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




# Data frames ----
d <- data.frame(
  site = c("Compton", "Compton", "Reseda"),
  date = c("2025-01-01", "2025-01-02", "2025-01-01"),
  pm25 = c(53.2, 33.6, 47.0)
)
d
str(d)


# Stacking two frames ----
e <- data.frame(site = "Reseda", date = "2025-01-02", pm25 = 41.5)

identical(names(d), names(e))   # same columns, same order?
both <- rbind(d, e)             # stack the rows
nrow(both)


# Getting at rows and columns ----
d$pm25            # one column, by name
d[1, ]            # first row, all columns
d[, "pm25"]       # all rows, one column
d[d$pm25 > 40, ]  # the rows where a condition is TRUE


# Sorting by position ----
v <- c(10, 50, 30)
order(v)              # positions, not values
v[order(v)]           # which is what sort() does
d[order(d$pm25), ]    # so this sorts the whole frame by one column


# Factors ----
site <- factor(c("Compton", "Reseda", "Compton", "Compton"))
site
levels(site)
table(site)


# The factor trap ----
f <- factor(c("10", "9", "100"))   # numbers, stored as categories
as.numeric(f)                      # NOT the numbers -- the level codes
as.numeric(as.character(f))        # the repair: text first, then number


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Practice: 19 exercises (solutions on the session page) ----
# Vectors and sequences
#  1. Build the whole numbers 1 to 20.
#  2. Build the even numbers from 2 to 20.
#  3. Repeat "yes" and "no", alternating, four times each.
#  4. How many odd numbers are there between 1 and 99? Two commands, one line.
#
# Classes and conversion
#  5. Predict first, then check: what class is c(1, 2, "3")?
#  6. x <- c("4.5", "2.1", "8.8") arrived as text. Get its mean.
#  7. Sort c("5", "10", "9") into true numeric order, in one line.
#  8. y <- c(3, NA, 7, NA, 12). How many values are missing?
#  9. Same y: what is its mean, ignoring the gaps?
#
# Subsetting
# 10. z <- c(10, 25, 3, 47, 18, 60). Keep only the values above 20.
# 11. Same z: how many values are above 20?
# 12. Same z: what is the mean of the values above 20?
# 13. Same z: drop the first and the last value, however long z is.
# 14. Same z: put it in order without using sort().
#
# Data frames and factors
# 15. Build a data frame: city = Ithaca, Buffalo; pop = 30, 275.
# 16. From it, print the row where pop is above 100.
# 17. f <- factor(c("2019", "2007", "2013")). Put the years in order,
#     as numbers.
# 18. Same f: what does as.numeric(f) give instead, and why?
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =


# The end
