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
library(stringr)                     # text functions; every name starts with str_
fomc <- read.csv("fomc_statements.csv")
dim(fomc)
c(inflation = sum(str_detect(fomc$text, "inflation")),
  Inflation = sum(str_detect(fomc$text, "Inflation")),
  either    = sum(str_detect(fomc$text, regex("inflation", ignore_case = TRUE))))
fomc$n_infl <- str_count(fomc$text, regex("inflation", ignore_case = TRUE))
summary(fomc$n_infl)
fomc$date[which(fomc$n_infl == 0)]   # which(): the positions where the condition is TRUE


x <- "the Committee decided to raise the target range for the federal funds rate to 4-3/4 to 5 percent."
str_view(x, "\\d")
str_view(x, "[0-9/-]")
str_view(x, "[^a-z ]")      # ^ inside brackets: any character NOT in the set


str_view(x, "r.te")          # . : any one character
str_view(x, "\\.")           # \\. : a period
c(str_count(x, "."), str_count(x, "\\."))


str_extract_all(x, "[0-9/-]+")                   # + : one or more of the piece before
str_extract(x, "\\d+-\\d+/\\d+")
table(str_extract(fomc$text, "\\d+ basis points"), useNA = "ifany")
table(str_extract(fomc$text, "\\d+/\\d+ percentage points?"))   # ? : zero or one "s"


sum(str_detect(fomc$text, "^Information received"))      # ^ : at the start of the text
str_detect(c("5", "4-3/4", "4-3/4 to 5"), "^[0-9/-]+$")   # $ : at the end
sum(str_count(fomc$text, "rate"))
sum(str_count(fomc$text, "\\brate\\b"))                   # \\b : a word boundary
caught <- unlist(str_extract_all(fomc$text, "[a-z]*rate[a-z]*"))
head(sort(table(caught), decreasing = TRUE), 6)


should_match <- c("the federal funds rate", "longer-term interest rates")
should_skip  <- c("at a moderate pace", "to generate sustained improvement")
str_detect(should_match, "\\brate\\b")
str_detect(should_skip, "\\brate\\b")
str_detect(should_match, "\\brates?\\b")      # ? makes the "s" optional
str_detect(should_skip, "\\brates?\\b")
str_detect(should_skip, "rate")               # the literal catches both


r <- c("4-3/4", "1-1/2", "5")
m <- str_match(r, "(\\d+)-(\\d+)/(\\d+)")
m
is.na(m[, 1])                        # TRUE where the pattern found no match
p <- c("keep its target for the federal funds rate at 5-1/4 percent",
       "raise the target range for the federal funds rate to 4-3/4 to 5 percent",
       "establish a target range for the federal funds rate of 0 to 1/4 percent")
str_match(p, "(?:at|to|of) ([0-9/-]+) percent")


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Exercise 1 (5 minutes) ----
# Exercise 1 (5 minutes). R Console, in the 16-text-regex folder; needs
# stringr and fomc. The decision sentence says "decided to raise",
# "decided to lower", "decided to keep" or "decided to maintain", then the
# target. Test strings from the statements:
should_match <- c("decided to raise the target range",
                  "decided to keep the target range")
should_skip  <- c("preferred to lower the target range",
                  "decided to continue purchasing additional")
# 1. Write verb_pat, a pattern with one capture group for the verb, in the
#    form "decided to (...|...|...|...)".
# 2. Run str_detect(should_match, verb_pat) and
#    str_detect(should_skip, verb_pat). You want TRUE TRUE, then FALSE FALSE.
# 3. Pull the verb from every statement with v <- str_match(fomc$text, verb_pat)
#    and count column 2 with table(v[, 2], useNA = "ifany").
# 4. Find the first statement that returns NA with k <- which(is.na(v[, 2]))[1].
#    Print its date with fomc$date[k], and its decision sentence with
#    str_extract(fomc$text[k], "[^.]*decided[^.]*").
#
# Two answers to compare with the room: how many statements return NA, and
# why the first one fails.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




source("chat_reply.R")      # runs the reply's code, unchanged
str_view(c("5", "1/4", "4-3/4", "0.25"), num)
to_num(c("4-3/4", "1/4", "5", "0"))


i <- which(fomc$date == "2023-03-22")
greedy <- str_extract(fomc$text[i], regex("decided.*percent", dotall = TRUE))
lazy   <- str_extract(fomc$text[i], regex("decided.*?percent", dotall = TRUE))
c(nchar(greedy), nchar(lazy))       # nchar() counts characters
seg[i]                              # the reply's step 1 on this statement


str_match(seg[i], pat)              # the reply's step 2


sum(is.na(fomc$upper))                         # its first test prints these rows; here, a count
summary(fomc[, c("lower", "upper")])           # its second test
sum(fomc$lower > fomc$upper, na.rm = TRUE)     # its third: lower <= upper everywhere


fred <- read.csv("fred_target_range.csv")                # date, lower, upper: one row per day
k <- match(as.Date(fomc$date) + 1, as.Date(fred$date))    # + 1: the day after each statement
fomc$fred_lower <- fred$lower[k]
fomc$fred_upper <- fred$upper[k]
fomc$agree <- fomc$lower == fomc$fred_lower & fomc$upper == fomc$fred_upper
table(fomc$agree, useNA = "ifany")
fomc$date[which(!fomc$agree)]


# Fig fred range ----
d <- as.Date(fomc$date) + 1                                   # the day after
ok <- fomc$agree %in% TRUE
bad <- fomc$agree %in% FALSE
plot(as.Date(fred$date), fred$upper, type = "s", col = "grey60", ylim = c(0, 6),
     xlab = "", ylab = "Percent", las = 1)
lines(as.Date(fred$date), fred$lower, type = "s", col = "grey60")
points(d[ok], fomc$upper[ok], pch = 16, cex = 0.7)
points(d[bad], fomc$lower[bad], pch = 4, cex = 1.4, lwd = 2, col = "firebrick")
rug(d[is.na(fomc$agree)], col = "darkorange", lwd = 2, ticksize = 0.04)
text(as.Date(c("2010-04-01", "2012-11-01", "2015-08-01", "2021-03-01")), c(0.8, 1.05, 1.65, 1.0),
     c("\"will maintain\"", "2014: the match\nruns too far", "\"reaffirmed\"", "the Fed's\nhyphen"),
     col = c("darkorange", "firebrick", "darkorange", "firebrick"), cex = 0.9)
legend("top", ncol = 4, bty = "n", cex = 0.85,
       legend = c("FRED: lower and upper", "equal (130)", "wrong (9)", "NA (32)"),
       col = c("grey60", "black", "firebrick", "darkorange"),
       lty = c(1, NA, NA, 1), lwd = c(1, NA, 2, 2), pch = c(NA, 16, 4, NA))


j <- which(fomc$date == "2025-12-10")
str_view(seg[j], num)
utf8ToInt(str_extract(seg[j], "3.3/4"))     # the number that identifies each character
utf8ToInt("3-3/4")                           # typed with the hyphen key
sum(str_detect(fomc$text, "\u2011"))         # statements with character 8209


fomc$text <- str_replace_all(fomc$text, "\u2011", "-")       # 1. the Fed's hyphen becomes "-"
seg <- str_extract(fomc$text, regex("(?:decided|maintain|reaffirmed)[^.]*?percent\\b",
                                    ignore_case = TRUE))      # 2. one sentence; 3. three verbs
m <- str_match(seg, str_c("(", num, ")(?:\\s+to\\s+(", num, "))?\\s+percent\\b"))   # 3. the range anywhere in it
fomc$lower <- to_num(m[, 2])
fomc$upper <- ifelse(is.na(m[, 3]), fomc$lower, to_num(m[, 3]))
fomc$agree <- fomc$lower == fomc$fred_lower & fomc$upper == fomc$fred_upper
table(fomc$agree, useNA = "ifany")


i <- which(fomc$date == "2023-03-22")
fomc$year <- as.numeric(str_sub(fomc$date, 1, 4))               # characters 1 to 4 of "2023-03-22"
tokens <- str_extract_all(str_to_lower(fomc$text), "[a-z]+")     # every run of letters
head(tokens[[i]], 12)                                             # 22 Mar 2023
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
#
# 1. Put the words of the 2022 statements in one vector:
#      w22 <- unlist(tokens[fomc$year == 2022])
# 2. Put the words of every statement before 2022 in a second vector, before.
# 3. Keep the 2022 words that never appear in before (use %in% and !).
# 4. Count them with table() and sort them, largest first.
#
# Two answers to compare with the room: the most frequent new word, and the
# new words that are people's names.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




lm_words <- read.csv("lm_words.csv")         # word, list: "positive" or "negative"; lower case
table(lm_words$list)
pos <- lm_words$word[lm_words$list == "positive"]
neg <- lm_words$word[lm_words$list == "negative"]
c("liability", "tax", "cost") %in% neg


net_tone <- function(w) 100 * (sum(w %in% pos) - sum(w %in% neg)) / length(w)
j <- which(fomc$date == "2008-12-16")
w <- tokens[[j]]
w[w %in% neg]
w[w %in% pos]
net_tone(w)
fomc$tone <- sapply(tokens, net_tone)        # sapply(): the function on each statement's words
fomc[which.min(fomc$tone), c("date", "tone")]
fomc[which.max(fomc$tone), c("date", "tone")]


# Fig range tone ----
par(mfrow = c(2, 1), mar = c(2, 5, 0.5, 1))
plot(as.Date(fred$date), fred$upper, type = "s", col = "grey60", ylim = c(0, 6),
     xlab = "", ylab = "Target, percent", las = 1)
points(as.Date(fomc$date) + 1, fomc$upper, pch = 16, cex = 0.5)
plot(as.Date(fomc$date), fomc$tone, type = "h", ylim = c(-3.4, 2.8),
     xlab = "", ylab = "Net tone", las = 1)
abline(h = 0, col = "grey60")
lab <- which(fomc$date %in% c("2008-09-16", "2020-03-03", "2021-07-28"))
text(as.Date(fomc$date[lab]), fomc$tone[lab], c("16 Sep 2008", "3 Mar 2020", "28 Jul 2021"),
     pos = c(1, 3, 3), cex = 0.8, xpd = NA)


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
#  4. Split c("<1", "1-5", "5-10", "15+") into numeric low and high columns,
#     once with gsub() and strsplit() and once with str_match().
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
