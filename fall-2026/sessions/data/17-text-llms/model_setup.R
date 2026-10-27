# The model, the two prompts and the two schemas, written once.
# Needs ellmer; creates no chat and sends nothing.
library(ellmer)   # install.packages("ellmer") once; calls language models from R

MODEL <- "claude-sonnet-5-5"   # the full model id from the provider's list, written once
RANGE_PROMPT <- paste(readLines("range_prompt.txt"), collapse = "\n")
CODEBOOK <- paste(readLines("codebook.txt"), collapse = "\n")

range_type <- type_object(
  lower = type_number("Lower limit, in percent, such as 4.75", required = FALSE),
  upper = type_number("Upper limit, in percent, such as 5", required = FALSE))
stance_type <- type_object(stance = type_enum(c("dovish", "hawkish", "neutral")))
