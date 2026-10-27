# Label each text with a fresh chat and save every raw reply to disk, one JSON
# file per item. Items already saved are skipped: no call, no cost.
# Needs ellmer, jsonlite and MODEL (from model_setup.R); a key only for items
# not yet saved.
save_replies <- function(texts, ids, folder, prompt, type) {
  dir.create(folder, recursive = TRUE, showWarnings = FALSE)    # make the folder if it is missing
  for (j in seq_along(texts)) {
    f <- file.path(folder, paste0(ids[j], ".json"))            # one file per item
    if (file.exists(f)) next                                   # saved already: no call, no cost
    chat <- chat_anthropic(system_prompt = prompt, model = MODEL, cache = "none")   # a fresh conversation
    ans <- chat$chat_structured(texts[j], type = type)
    rec <- list(id = ids[j], answer = ans, model = MODEL,
                reply = chat$last_turn()@json)                 # the reply as the provider sent it
    writeLines(jsonlite::toJSON(rec, auto_unbox = TRUE, null = "null"), f)
  }
}
