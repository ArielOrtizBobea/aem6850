MODEL <- "claude-opus-5-5"   # the model's id, from the provider's list of models
# model_call.R: builds a request that asks a language model to label each of
# the 266 names in the World Bank table as a single economy or a group of
# economies. Run it in the 14-apis folder. Needs httr2 and jsonlite; it reads
# the saved replies in saved/ and sends nothing (model_send.R sends it).
source("wb_functions.R")   # loads httr2, jsonlite, fetch() and flat()

replies <- lapply(paste0("saved/wb_2023_p", 1:3, ".json"), fromJSON)
wb <- do.call(rbind, lapply(replies, flat))
# sort by name, the same way on every computer
wb <- wb[order(tolower(wb$country), method = "radix"), ]
wb$id <- 1:nrow(wb)

prompt <- paste0(
  "Below are ", nrow(wb), " names from a World Bank table. Some are single ",
  "economies (a country or a territory). Others are groups of economies ",
  "(a region, an income group, a lending group, or the world). Label each ",
  "name. Reply with CSV only: a header line id,label, then one line per ",
  "name with its number and either economy or group.\n\n",
  paste0(wb$id, ". ", wb$country, collapse = "\n"))
writeLines(prompt, "raw/model_prompt.txt")

req <- request("https://api.anthropic.com/v1/messages")
req <- req_headers(req, "x-api-key" = Sys.getenv("ANTHROPIC_API_KEY"),
                   "anthropic-version" = "2023-06-01", .redact = "x-api-key")
req <- req_body_json(req, list(model = MODEL, max_tokens = 4000,
  messages = list(list(role = "user", content = prompt))))
