# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# AEM 6850 -- Empirical Methods for Applied Economists
# Prof. Ariel Ortiz-Bobea
# Session 16 -- Text I: regex
# Thursday, October 22, 2026
#
# Run it one line at a time: put the cursor on a line and press Cmd-Return
# (Mac) or Ctrl-Enter (Windows).
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# install.packages(c("stringr", "stopwords"))   # once
library(stringr)               # text functions; every name starts with str_
words <- c("color", "colour", "colr", "Colour")
str_detect(words, "colou?r")   # TRUE if the string contains a match; ? makes the u optional
str_view(words, "colou?r")     # the strings that match, each match in < >
str_detect(words, regex("colou?r", ignore_case = TRUE))   # upper and lower case match alike


# a sentence from the Fed's policy statement of 22 March 2023
x <- "the Committee decided to raise the target range for the federal funds rate to 4-3/4 to 5 percent."
str_view(x, "\\d")
str_view(x, "[0-9/-]")
str_view(x, "[^a-z ]")      # ^ inside brackets: any character NOT in the set


str_view(c("rate", "rite", "r8te", "rte"), "r.te")   # . : any one character
str_view(x, "\\.")           # \\. : a period
c(str_count(x, "."), str_count(x, "\\."))


str_extract_all(x, "[0-9/-]+")            # + : one or more of the piece before
str_extract(x, "\\d+-\\d+/\\d+")           # a whole number, a hyphen, a fraction
str_detect(c("1/4 percentage point", "1/2 percentage points"), "percentage points?")
str_extract(c("year 2026", "26"), "\\d{4}")   # {4} : exactly four digits


s <- c("rate", "the rate rose", "moderate", "rates")
str_detect(s, "rate")             # the literal also matches inside other words
str_detect(s, "\\brate\\b")       # \\b : the edge of a word
str_detect(s, "^rate$")           # ^ : start of the text; $ : end of the text


rates <- c("4-3/4", "1-1/2", "5")             # rates as the Fed writes them
m <- str_match(rates, "(\\d+)-(\\d+)/(\\d+)")  # whole number, numerator, denominator
m
as.numeric(m[, 2]) + as.numeric(m[, 3]) / as.numeric(m[, 4])   # 4 + 3/4 = 4.75


# phrases from the Fed statements of 8 Aug 2006, 22 Mar 2023 and 16 Dec 2008
phrases <- c("keep its target for the federal funds rate at 5-1/4 percent",
             "raise the target range for the federal funds rate to 4-3/4 to 5 percent",
             "establish a target range for the federal funds rate of 0 to 1/4 percent")
str_match(phrases, "(?:at|to|of) ([0-9/-]+) percent")


fips <- c("06037", "6037", "36109", "3610A", " 36109")   # US county codes
str_detect(fips, "^\\d{5}$")         # exactly five digits, nothing before or after
str_detect(fips, "\\d{5}")           # without the anchors, " 36109" passes
fips[!str_detect(fips, "^\\d{5}$")]  # the values that fail
dates <- c("2026-10-22", "10/22/2026", "2026-1-5")
str_detect(dates, "^\\d{4}-\\d{2}-\\d{2}$")   # year-month-day, two digits each


prices <- c("$1,250", "price: $99.99", "free", "$52,000")
str_extract(prices, "[0-9,.]+")             # digits, commas and periods
ages <- c("<1", "1-5", "5-10", "15+")        # age groups in a mortality table
str_match(ages, "(\\d+)(?:-(\\d+))?")         # group 1: the first number; group 2: the second


amount <- str_extract(prices, "[0-9,.]+")       # "free" has no digits, so NA
as.numeric(str_replace_all(amount, ",", ""))    # drop the commas, then convert
str_squish("  Federal   Reserve \n Board ")     # \n: a line break; result: one space between words
# month/day/year becomes year-month-day
str_replace(c("10/22/2026", "01/05/2026"), "(\\d{2})/(\\d{2})/(\\d{4})", "\\3-\\1-\\2")


should_match <- c("the federal funds rate", "longer-term interest rates")
should_skip  <- c("at a moderate pace", "to generate sustained improvement")
str_detect(should_match, "\\brate\\b")
str_detect(should_skip, "\\brate\\b")
str_detect(should_match, "\\brates?\\b")      # ? makes the "s" optional
str_detect(should_skip, "\\brates?\\b")
str_detect(should_skip, "rate")               # without \\b, "moderate" and "generate" match


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Exercise 1 (5 minutes) ----
# Exercise 1 (5 minutes). R Console; needs stringr. Answers to a survey
# question on yearly income:
income <- c("$52,000", "48500", "Income: $61,250.00", "N/A", "about 40k",
            "$1,000,000")
# 1. Validation: write ok_pat, a pattern for an answer that is only an
#    amount: an optional $, then digits and commas, then optional cents
#    (.00). Run str_detect(income, ok_pat). Alone, $ means the end of the
#    text, so write \\$ for a dollar sign.
# 2. Extraction: pull the number out of every answer with str_extract().
# 3. Replacement: drop the commas with str_replace_all(), then as.numeric().
# 4. Read the result next to income. Which answers give NA or a wrong number?
#
# Two answers to compare with the room: how many answers pass step 1, and
# what "about 40k" becomes.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




fomc <- read.csv("fomc_statements.csv")
dim(fomc)
c(inflation = sum(str_detect(fomc$text, "inflation")),
  Inflation = sum(str_detect(fomc$text, "Inflation")),
  either    = sum(str_detect(fomc$text, regex("inflation", ignore_case = TRUE))))
fomc$n_infl <- str_count(fomc$text, regex("inflation", ignore_case = TRUE))
summary(fomc$n_infl)
fomc$date[which(fomc$n_infl == 0)]   # which(): the positions where the condition is TRUE


sum(str_count(fomc$text, "rate"))
sum(str_count(fomc$text, "\\brate\\b"))
caught <- unlist(str_extract_all(fomc$text, "[a-z]*rate[a-z]*"))   # every word containing "rate"
head(sort(table(caught), decreasing = TRUE), 6)


i <- which(fomc$date == "2023-03-22")                         # the row of the 22 Mar 2023 statement
fomc$year <- as.numeric(str_sub(fomc$date, 1, 4))             # the year, used in Exercise 2
tokens <- str_extract_all(str_to_lower(fomc$text), "[a-z]+")  # every run of letters
head(tokens[[i]], 12)
length(tokens[[i]])


all_words <- unlist(tokens)
length(all_words)
head(sort(table(all_words), decreasing = TRUE), 8)
stop_words <- stopwords::stopwords("en")     # pkg::fun(): a package's function without library()
kept <- all_words[!all_words %in% stop_words & nchar(all_words) > 1]   # !x %in% y: x is not in y
head(sort(table(kept), decreasing = TRUE), 8)


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Exercise 2 (5 minutes) ----
# Exercise 2 (5 minutes). R Console; needs fomc (with its year column) and
# tokens from the previous slides.
# Which words appear in the statements for the first time in 2022?
#
# 1. Put the words of the 2022 statements in one vector:
#      w22 <- unlist(tokens[fomc$year == 2022])
# 2. Put the words of every statement before 2022 in a second vector
#    called before.
# 3. Keep the 2022 words that are not in the vector before (use %in% and !).
# 4. Count them with table() and sort them, largest first.
#
# Two answers to compare with the room: the most frequent new word, and the
# new words that are people's names.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




lm_words <- read.csv("lm_words.csv")         # word, list: "positive" or "negative"; lower case
table(lm_words$list)
pos <- lm_words$word[lm_words$list == "positive"]
neg <- lm_words$word[lm_words$list == "negative"]
c("liability", "tax", "cost") %in% neg      # three words a general-purpose list calls negative


net_tone <- function(w) 100 * (sum(w %in% pos) - sum(w %in% neg)) / length(w)
j <- which(fomc$date == "2008-12-16")
w <- tokens[[j]]
w[w %in% neg]
w[w %in% pos]
net_tone(w)
fomc$tone <- sapply(tokens, net_tone)        # sapply(): the function on each statement's words
fomc[c(which.min(fomc$tone), which.max(fomc$tone)), c("date", "tone")]   # lowest, highest


# Fig tone time ----
par(mar = c(2.5, 4.5, 0.8, 0.5))               # margins in lines: bottom, left, top, right
plot(as.Date(fomc$date), fomc$tone, type = "h", ylim = c(-3.4, 2.8),
     xlab = "", ylab = "Net tone per 100 tokens", las = 1)    # "h": one bar per statement
abline(h = 0, col = "grey60")
lab <- which(fomc$date %in% c("2008-09-16", "2020-03-03", "2021-07-28"))
text(as.Date(fomc$date[lab]), fomc$tone[lab], c("16 Sep 2008", "3 Mar 2020", "28 Jul 2021"),
     pos = c(1, 3, 3), cex = 1, xpd = NA)


source("chat_reply.R")      # runs the reply's code, unchanged
str_view(c("5", "1/4", "4-3/4", "0.25"), num)
to_num(c("4-3/4", "1/4", "5", "0"))


i <- which(fomc$date == "2023-03-22")
greedy <- str_extract(fomc$text[i], regex("decided.*percent", dotall = TRUE))
lazy   <- str_extract(fomc$text[i], regex("decided.*?percent", dotall = TRUE))
c(nchar(greedy), nchar(lazy))       # nchar() counts characters
lazy
identical(lazy, seg[i])             # the reply's step 1 gives the same text


str_match(seg[i], pat)              # the reply's step 2


sum(is.na(fomc$upper))                         # the reply's test 1 prints these rows; here we count them
summary(fomc[, c("lower", "upper")])           # the reply's test 2
sum(fomc$lower > fomc$upper, na.rm = TRUE)     # the reply's test 3: lower <= upper


fred <- read.csv("fred_target_range.csv")                # date, lower, upper: one row per day
k <- match(as.Date(fomc$date) + 1, as.Date(fred$date))    # + 1: the day after each statement
fomc$fred_lower <- fred$lower[k]
fomc$fred_upper <- fred$upper[k]
fomc$agree <- fomc$lower == fomc$fred_lower & fomc$upper == fomc$fred_upper
table(fomc$agree, useNA = "ifany")
fomc$date[which(!fomc$agree)]


# Fig fred range ----
d <- as.Date(fomc$date) + 1                    # the day after each statement
ok <- fomc$agree %in% TRUE                     # %in% TRUE: NA counts as not TRUE
bad <- fomc$agree %in% FALSE
par(mar = c(2.5, 4.5, 0.5, 0.5))               # margins in lines: bottom, left, top, right
plot(as.Date(fred$date), fred$upper, type = "s", col = "grey60", ylim = c(0, 6),
     xlab = "", ylab = "Target, percent", las = 1)    # "s": steps, flat between decisions
lines(as.Date(fred$date), fred$lower, type = "s", col = "grey60")
points(d[ok], fomc$upper[ok], pch = 16, cex = 0.7)
points(d[bad], fomc$lower[bad], pch = 4, cex = 1.4, lwd = 2, col = "firebrick")
segments(d[bad], fomc$fred_lower[bad], d[bad], fomc$lower[bad], col = "firebrick", lwd = 2)
rug(d[is.na(fomc$agree)], col = "darkorange", lwd = 2, ticksize = 0.04)   # a tick for each NA
label_x <- as.Date(c("2010-07-01", "2013-06-01", "2015-08-01", "2021-03-01", "2018-10-01", "2025-10-01"))
label_y <- c(0.8, 1.05, 1.65, 1.0, 0.55, 1.0)  # labels placed by hand at (date, percent)
text(label_x, label_y, cex = 0.9,
     c("\"will maintain\"", "2014: the match\nruns too far", "\"reaffirmed\"",
       "look-alike\nhyphen", "look-alike\nhyphen", "look-alike\nhyphen"),
     col = c("darkorange", "firebrick", "darkorange", "firebrick", "darkorange", "darkorange"))
legend("top", ncol = 2, bty = "n", cex = 0.85,
       legend = c("FRED: lower and upper", paste0("equal (", sum(ok), ")"),
                  paste0("wrong (", sum(bad), "): lower = upper"),
                  paste0("NA (", sum(is.na(fomc$agree)), ")")),
       col = c("grey60", "black", "firebrick", "darkorange"),
       lty = c(1, NA, 1, 1), lwd = c(1, NA, 2, 2), pch = c(NA, 16, 4, NA))


j <- which(fomc$date == "2025-12-10")
str_view(seg[j], num)
utf8ToInt(str_extract(seg[j], "3.3/4"))     # . matches either hyphen; utf8ToInt(): each code point
utf8ToInt("3-3/4")                           # typed with the hyphen key
sum(str_detect(fomc$text, "\u2011"))         # statements with character 8209


# 1. the look-alike hyphen (character 8209) becomes "-"
fomc$text <- str_replace_all(fomc$text, "\u2011", "-")
# 2. stop at the period; 3. three verbs, no "federal funds rate"
seg <- str_extract(fomc$text, regex("(?:decided|maintain|reaffirmed)[^.]*?percent\\b",
                                    ignore_case = TRUE))
# 3. no "to/at/of" before the number
m <- str_match(seg, str_c("(", num, ")(?:\\s+to\\s+(", num, "))?\\s+percent\\b"))
fomc$lower <- to_num(m[, 2])
fomc$upper <- ifelse(is.na(m[, 3]), fomc$lower, to_num(m[, 3]))
fomc$agree <- fomc$lower == fomc$fred_lower & fomc$upper == fomc$fred_upper
table(fomc$agree, useNA = "ifany")


s <- str_extract(fomc$text[fomc$date == "2012-09-13"], "economic growth might not[^.]*")
str_view(s, "\\b(not|strong|improvement)\\b")


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Practice ----
# Practice. Run in the 16-text-regex folder with stringr loaded, after the
# slides' code has built fomc (with the three changes), tokens, pos, neg
# and the FRED columns.

# Patterns and numbers
#  1. Label each statement by its opening with ^: "Information received",
#     "Recent indicators", or "other". Count them by year with table().
#  2. Run str_match(fomc$text, "(\\d+) basis points") and table() column 2.
#     Read each matching sentence. Which matches are not the committee's
#     decision? Change the pattern so only decisions match.
#  3. The 2026 statements give the vote ("by a 12 – 0 vote"). Extract the
#     two numbers as numeric columns. Why does "by a (\\d+) - (\\d+) vote"
#     fail? Use utf8ToInt() on the character between the numbers.
#  4. Validate the url column: every address should look like
#     https://www.federalreserve.gov/newsevents/pressreleases/monetaryYYYYMMDDa.htm
#     Write the pattern with ^, \d{8} and $. Which addresses fail, and why?
# Base R
#  5. Rewrite the three changes with gsub(), regmatches() with regexpr(),
#     and regexec(). Do the same 170 statements equal FRED?
# Word counts
#  6. For each statement, compute the share of its tokens that are
#     "inflation". Average it by year with tapply(share, fomc$year, mean),
#     which applies mean() within each year, and plot it. Which year is
#     highest, which lowest?
#  7. Apply the core words of the three lists of Baker, Bloom & Davis
#     (QJE, 2016) to the statements with \\b and |. How many statements
#     match each list, and all three, and in which years?
# Tone
#  8. Recompute net tone after removing "unemployment" and "against" from
#     neg, and "stability" and "exceptionally" from pos. Which statements
#     are now lowest and highest? Where does 3 Mar 2020 land?
#  9. List the word after every "not" with str_match_all(), which returns
#     str_match()'s matrix for every match in each statement. How many are
#     on the positive list, and how many on the negative list?
# Characters
# 10. List every character with a code point above 127, with its code
#     point, its count, and the statements it appears in. Which would you
#     replace before matching?
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =


# The end
