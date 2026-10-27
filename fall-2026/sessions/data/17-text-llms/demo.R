# The live demo: the five sentences the class labelled, labelled twice.
# Instructor's computer; needs ellmer, an API key in ~/.Renviron and
# model_setup.R. Ten calls, under a cent.
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
