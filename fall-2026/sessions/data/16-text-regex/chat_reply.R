# The code in a chatbot's reply to chat_prompt.txt, unchanged.
# Full reply: chat_reply.md.
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
