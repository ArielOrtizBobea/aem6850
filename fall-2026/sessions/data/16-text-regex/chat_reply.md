```r
library(stringr)

# A number as it appears in statements: "5", "1/4", "4-3/4", or a decimal like "0.25"
num <- "\\d+(?:\\.\\d+)?(?:-\\d+/\\d+|/\\d+)?"

# Convert strings like "4-3/4", "1/4", "5" to numeric
to_num <- function(x) {
  m <- str_match(x, "^(?:(\\d+)-)?(\\d+(?:\\.\\d+)?)(?:/(\\d+))?$")
  whole <- as.numeric(m[, 2])   # part before the hyphen (if any)
  a     <- as.numeric(m[, 3])   # whole number, decimal, or numerator
  b     <- as.numeric(m[, 4])   # denominator (if any)
  ifelse(is.na(b), a, a / b) + ifelse(is.na(whole), 0, whole)
}

# 1. Isolate the part of the statement describing the decision on the funds rate
seg <- str_extract(
  fomc$text,
  regex("decided.*?federal funds rate.*?percent\\b", ignore_case = TRUE, dotall = TRUE)
)

# 2. Pull out "to/at/of X [to Y] percent"
pat <- str_c("\\b(?:to|at|of)\\s+(", num, ")(?:\\s+to\\s+(", num, "))?\\s+percent\\b")
m   <- str_match(seg, pat)

# 3. Convert to numeric
first  <- to_num(m[, 2])
second <- to_num(m[, 3])

fomc$lower <- first
fomc$upper <- ifelse(is.na(second), first, second)
```

For your example, `"...to 4-3/4 to 5 percent."` gives `lower = 4.75` and `upper = 5`.

**How it works**
- The first step grabs the text from "decided" through the first "percent" that follows "federal funds rate". This keeps it from picking up other numbers in the statement, such as the 2 percent inflation goal, "25 basis points", or the discount rate.
- `percent\\b` means "percentage point" in phrases like "by 1/2 percentage point, to 1 to 1-1/4 percent" doesn't end the match early.
- `to_num()` handles whole numbers (`5`), fractions (`1/4`), and mixed numbers (`4-3/4`).

**Cases to know about**
- **Pre-December 2008 statements** set a single target, such as "...to 5-1/4 percent", not a range. The code sets `lower` and `upper` both to that value. If you'd rather have `lower` be `NA` there, use:
  ```r
  fomc$lower <- ifelse(is.na(second), NA_real_, first)
  ```
- **Statements with no rate decision** (a few unscheduled statements about liquidity facilities, for example) return `NA`.
- **Quick check:** run these to see what failed and to look at the extremes:
  ```r
  fomc[is.na(fomc$upper), "text"]
  summary(fomc[, c("lower", "upper")])
  ```
  Also check that `lower <= upper` everywhere.