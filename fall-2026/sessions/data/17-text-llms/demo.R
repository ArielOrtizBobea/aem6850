# The live demo, in two parts.
# Part 1: the five sentences the class labelled, sent twice to the closed
# model. Needs ellmer, an API key in ~/.Renviron and model_setup.R. Ten
# calls, under a cent.
# Part 2: the same five through the open model on this computer. Needs the
# model server running (ollama serve) and the model file pulled. No key.

# ---- Part 1: the closed model ----
source("model_setup.R")                    # loads ellmer; MODEL, CODEBOOK, stance_type
tdw <- read.csv("tdw_sentences.csv")
set.seed(6850)
pick <- sample(nrow(tdw), 5)               # the five sentences you labelled
chat <- chat_anthropic(system_prompt = CODEBOOK, model = MODEL, cache = "none")
five <- as.list(tdw$sentence[pick])
live1 <- parallel_chat_structured(chat, five, type = stance_type, on_error = "stop")   # stop at the first error
live2 <- parallel_chat_structured(chat, five, type = stance_type, on_error = "stop")
data.frame(annotators = c("dovish", "hawkish", "neutral")[tdw$label[pick] + 1],   # the file codes labels 0, 1, 2
           live1 = live1$stance, live2 = live2$stance)
identical(live1$stance, live2$stance)

# ---- Part 2: the open model on this computer ----
LOCAL_MODEL <- "qwen3.5:4b-q4_K_M"         # the open model's file, pulled once
chat_local <- chat_ollama(model = LOCAL_MODEL, system_prompt = CODEBOOK,
                          params = params(temperature = 0, seed = 6850,
                                          reasoning_effort = "none"))   # thinking off
open_live <- sapply(tdw$sentence[pick], USE.NAMES = FALSE,
                    function(s) chat_local$clone()$chat_structured(s, type = stance_type)$stance)
data.frame(annotators = c("dovish", "hawkish", "neutral")[tdw$label[pick] + 1],
           closed = live1$stance, open = open_live)
