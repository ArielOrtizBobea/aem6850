# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# AEM 6850 -- Empirical Methods for Applied Economists
# Prof. Ariel Ortiz-Bobea
# Session 10 -- Verification
# Tuesday, September 29, 2026
#
# Run it one line at a time: put the cursor on a line and press Cmd-Return
# (Mac) or Ctrl-Enter (Windows).
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

# The data ----
nrow(LifeCycleSavings)
head(LifeCycleSavings)


?LifeCycleSavings      # the documentation: what each variable means


# A random sample to check by hand ----
set.seed(10)
sample(rownames(LifeCycleSavings), 5)


# The script as delivered ----
# savings.R: the life-cycle savings regression, 50 countries, 1960-1970
# Data: R's built-in LifeCycleSavings (see ?LifeCycleSavings)

# 1) Load and clean ----
d <- LifeCycleSavings
d <- d[complete.cases(d), ]      # drop incomplete rows
d <- d[d$ddpi < 10, ]            # drop implausible growth rates
stopifnot(nrow(d) > 40)          # enough countries remain

# 2) Estimate ----
fit <- lm(sr ~ pop15 + pop75 + dpi + ddpi, data = d)
summary(fit)

# 3) Figure ----
png("savings_growth.png", width = 800, height = 560, res = 120)
plot(d$ddpi, d$sr, pch = 19,
     xlab = "Growth of disposable income (% a year)",
     ylab = "Savings rate (% of disposable income)")
abline(lm(sr ~ ddpi, data = d), lwd = 2)
dev.off()


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Exercise (4 minutes) ----
# Run the delivered script first. Then:
# 1. How many countries does the model use? nobs(fit)
# 2. What is ddpi? Open the help page: ?LifeCycleSavings
# 3. Fit the same model on all 50 countries (data = LifeCycleSavings).
#    What is the coefficient on ddpi?
# Two answers to compare with the room: the number of countries in the
# model, and the coefficient on ddpi with all 50.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




# The checker: paste this into Claude Code, not into R ----
# In a folder holding only summary.md, run claude --permission-mode manual
# and paste:
#
# You have not seen how summary.md was made, and you cannot see the code
# that made it. Check it. Using R's built-in LifeCycleSavings data and its
# help page, recompute every number in summary.md with your own R code on
# the full data, and compare every description of a variable with the help
# page. Report a table with one row per claim: the claim, what summary.md
# says, what you found, and whether they match (numbers within 0.01). List
# any claim that data cannot check. Do not create or edit any file.


# The same model on all 50 countries ----
full <- lm(sr ~ pop15 + pop75 + dpi + ddpi, data = LifeCycleSavings)
nobs(full)
round(coef(full), 4)
round(summary(full)$r.squared, 2)


# The figure with all 50 countries ----
d <- LifeCycleSavings
dropped <- d$ddpi >= 10
plot(d$ddpi, d$sr, pch = 19,
     xlab = "Growth of disposable income (% a year)",
     ylab = "Savings rate (% of disposable income)")
points(d$ddpi[dropped], d$sr[dropped], pch = 21, bg = "gold", cex = 2)
text(d$ddpi[dropped], d$sr[dropped], rownames(d)[dropped], pos = 2)
abline(lm(sr ~ ddpi, data = d), lwd = 2)


# Practice ----
# Exact claims, one line of R each
#  1. Check each claim about LifeCycleSavings with one line: "Japan saves
#     the most"; "Zambia saves the least"; "the average savings rate is
#     9.7%". One of the three is false. Which one, and what is true?
#  2. The summary says the model explains 38% of the variation. Compute
#     the R-squared with all 50 countries and with the 48 the script
#     kept. Which one did the summary report?

# The checker
#  3. Make the savings-check folder and run the checker's prompt. Compare
#     its table with the one on this page. What differs, and what is the
#     same?
#  4. Copy savings.R into the checker's folder and run the prompt again,
#     changed to say it may read the script. Does it find line 7? What
#     does it lose by reading the worker's code?

# Planted errors
#  5. Copy a script of your own. Plant three errors that do not stop it
#     from running: a filter, a wrong variable, a number off by a factor
#     of ten. Ask a reviewer in a fresh session to find what is wrong,
#     read-only. How many of the three did it find? Did it report
#     anything that is not an error?

# Prose
#  6. Ask a chat assistant for a one-paragraph summary of a paper you
#     know well. Mark each claim exact, sourced or judgment. Check the
#     exact and sourced ones against the paper. How many hold?


# The end
