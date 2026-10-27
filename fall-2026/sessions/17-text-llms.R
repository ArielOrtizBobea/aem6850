# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# AEM 6850 -- Empirical Methods for Applied Economists
# Prof. Ariel Ortiz-Bobea
# Session 17 -- Text II: LLMs
# Tuesday, October 27, 2026
#
# Run it one line at a time: put the cursor on a line and press Cmd-Return
# (Mac) or Ctrl-Enter (Windows).
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

fomc <- read.csv("fomc_statements.csv")   # 171 statements
i <- which(fomc$date == "2023-03-22")


rng <- read.csv("replies/range_model.csv")   # the model's target range: date, lower, upper, tokens
head(rng, 3)
k <- match(fomc$date, rng$date)              # rng's row for each statement, matched by date
fomc$mod_lower <- rng$lower[k]
fomc$mod_upper <- rng$upper[k]


txt <- gsub("\u2011", "-", fomc$text)    # the non-breaking hyphen becomes "-"
m <- regmatches(txt, regexec("([0-9/-]+) to ([0-9/-]+) percent", txt))
m[[i]]
to_number <- function(x) sapply(parse(text = sub("-", "+", x)), eval)   # "4-3/4" becomes 4+3/4
fomc$pat_lower <- to_number(sapply(m, function(x) x[2]))   # group 1; NA where nothing matched
fomc$pat_upper <- to_number(sapply(m, function(x) x[3]))   # group 2
sum(is.na(fomc$pat_lower))


fred <- read.csv("fred_target_range.csv")  # 7,578 days: date, lower, upper
fred[fred$date >= "2023-03-21" & fred$date <= "2023-03-23", ]
k <- match(as.Date(fomc$date) + 1, as.Date(fred$date))   # FRED's row for the day after
fomc$fred_lower <- fred$lower[k]
fomc$fred_upper <- fred$upper[k]


fomc$pat_ok <- fomc$pat_lower == fomc$fred_lower & fomc$pat_upper == fomc$fred_upper
fomc$mod_ok <- fomc$mod_lower == fomc$fred_lower & fomc$mod_upper == fomc$fred_upper
table(pattern = fomc$pat_ok, model = fomc$mod_ok, useNA = "ifany")   # useNA: count the NA too
show <- c("date", "mod_lower", "mod_upper", "fred_lower", "fred_upper")
fomc[which(!fomc$mod_ok | is.na(fomc$mod_ok)), show]


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Exercise 1 (4 minutes) ----
# Exercise 1 (4 minutes). A discussion with your neighbour; no code to run.
# For each task, decide whether it calls for a pattern ("regex"), a language
# model ("model") or a person ("person").
tasks <- c(
  "1. the date of each FOMC meeting, from the statement's first line",
  "2. every five-digit US ZIP code in 100,000 addresses",
  "3. how often 'inflation' appears in each statement",
  "4. 50,000 product reviews: positive or negative",
  "5. 3,000 answers to 'Why did you move?', sorted into reasons",
  "6. 20,000 firm names in loan records, matched to a list of listed firms",
  "7. the amount in 10,000 contracts: 'USD 1.2 million', '$1,200,000' or in words",
  "8. 2 million job ads, coded into occupations",
  "9. whether one 40-page court ruling supports a claim in your paper",
  "10. 200 Fed sentences, labelled to judge a model's labels")
# 1. Compare with your neighbour. Where do you differ, and why?
# 2. For each "model" answer: what would you check it against?
#
# Two answers to compare with the room: the tasks where you and your
# neighbour differ, and what you would check task 6 against.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




a <- c("dovish", "neutral", "neutral")    # person A's labels for three sentences
b <- c("dovish", "hawkish", "neutral")    # person B, the same three
a == b
mean(a == b)                              # mean() of TRUE and FALSE is the share TRUE


tdw <- read.csv("tdw_sentences.csv")   # tdw: Trillion Dollar Words, the dataset's name
dim(tdw)
tdw$annotators <- c("dovish", "hawkish", "neutral")[tdw$label + 1]   # the release codes 0, 1, 2
table(tdw$annotators)


library(jsonlite)                        # reads JSON, the text format replies arrive in
r <- fromJSON("replies/run1/904.json")   # one of the 2,480 saved files
r$answer$stance                          # the label the model gave
r$reply$model                            # the model id the provider reports
r$reply$content$text                     # the reply's text, as the model wrote it
r$reply$stop_reason                      # why the model stopped writing
unlist(r$reply$usage[c("input_tokens", "output_tokens")])   # tokens billed: sent, written back


d1 <- read.csv("demo/demo_run1.csv")   # id, sentence, annotators, stance
d2 <- read.csv("demo/demo_run2.csv")
data.frame(sentence = substr(d1$sentence, 1, 50), annotators = d1$annotators,
           run1 = d1$stance, run2 = d2$stance)


labels <- read.csv("replies/labels_run1.csv")         # the 2,480 saved replies, collected: id, stance, tokens
tdw$model <- labels$stance[match(tdw$id, labels$id)]  # the model's label next to the people's
set.seed(6850); pick <- sample(nrow(tdw), 5)          # the five you labelled: a seed fixes a random draw
data.frame(annotators = tdw$annotators[pick], model = tdw$model[pick])
mean(tdw$model == tdw$annotators)                     # agreement rate on all 2,480


tab_m <- table(annotators = tdw$annotators, model = tdw$model)   # hand labels in rows, the model's in columns
round(prop.table(tab_m, 1), 2)        # shares within each row
diag(tab_m)                           # counts where both agree: the diagonal
sum(diag(tab_m)) / sum(tab_m)         # over all 2,480: the agreement rate


round(prop.table(table(tdw$annotators)), 3)   # prop.table(): counts as shares
mean(tdw$annotators == "neutral")             # a rule that always answers "neutral"


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Exercise 2 (4 minutes) ----
dict <- read.csv("lm_words.csv")              # Loughran-McDonald word lists
pos <- dict$word[dict$list == "positive"]
neg <- dict$word[dict$list == "negative"]
w <- strsplit(tolower(tdw$sentence), "[^a-z]+")   # the words of each sentence
tdw$tone <- sapply(w, function(x) 100 * (sum(x %in% pos) - sum(x %in% neg)) / length(x))
tdw$rule <- ifelse(tdw$tone < 0, "dovish", ifelse(tdw$tone > 0, "hawkish", "neutral"))
# 1. agreement rate: mean(tdw$rule == tdw$annotators)
# 2. confusion table: tab_r <- table(annotators = tdw$annotators, word_rule = tdw$rule)
#    then round(prop.table(tab_r, 1), 2)
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




PRICE <- c(input = 2, output = 10)   # dollars per million tokens; provider's list, 25 Oct 2026
tok <- colSums(labels[, c("input_tokens", "output_tokens")])
tok                                   # tokens billed for 2,480 labels
sum(tok * PRICE) / 1e6                # dollars; 1e6 is one million
hours <- 2 * 2480 * 15 / 3600         # two people, 15 seconds a sentence (an assumption)
WAGE <- 20; c(hours = hours, dollars = hours * WAGE)   # $20 an hour for a person labelling (an assumption)


library(jsonlite)
files <- list.files("replies/run1", full.names = TRUE)
length(files)
r <- fromJSON(files[1])
r$reply$usage$input_tokens                    # tokens billed for this one call
replies <- lapply(files, fromJSON)            # under a second
ids <- sapply(replies, function(x) x$id)
stance <- sapply(replies, function(x) x$answer$stance)
identical(stance[match(tdw$id, ids)], tdw$model)


open4 <- read.csv("replies/local_4b.csv")   # id, stance, seconds; the small open model, before class
data.frame(annotators = tdw$annotators[pick], closed = tdw$model[pick],
           open = open4$stance[match(tdw$id[pick], open4$id)])


score <- function(stance, seconds, dollars)
  c(agreement = mean(stance == tdw$annotators, na.rm = TRUE),
    sec_each = median(seconds, na.rm = TRUE),
    hours_all = sum(seconds, na.rm = TRUE) / 3600, dollars = dollars)
open <- sapply(c("4b", "9b", "27b"), function(s) {          # billions of weights
  d <- read.csv(paste0("replies/local_", s, ".csv"))         # id, stance, seconds
  d <- d[match(tdw$id, d$id), ]
  score(d$stance, d$seconds, 0)
})
closed <- c(agreement = mean(tdw$model == tdw$annotators),
            sec_each = 2.0, hours_all = 10.5 / 60,     # 2 s a call, 8 at a time (run log)
            dollars = sum(tok * PRICE) / 1e6)          # tok: the tokens billed, cost slide
round(cbind(open, closed), 3)


# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
# Practice ----
# Practice. Run in the 17-text-llms folder after the slides' code has built
# fomc (with the pattern, model and FRED columns), tdw (with annotators,
# model, tone and rule), labels, pos and neg. Tasks 1-9 need no key; task 10
# needs ellmer and your own API key; task 11 an open model on your computer.

# The target range
#  1. Before December 2008 the FOMC set a single number ("keep its target for
#     the federal funds rate at 5-1/4 percent", "raise its target for the
#     federal funds rate by 25 basis points to 4-1/2 percent"; a basis point
#     is 0.01 percentage point). Write a second pattern for these, fill in
#     the 26 NA, and compare with FRED. Which statement is still NA, and why
#     is NA the right answer there?
#  2. Print every statement where the model's range differs from FRED's or
#     from the pattern's. Read the decision sentence of each: which is right?
# Hand labels
#  3. Find the sentences that appear more than once in tdw with duplicated().
#     How many different sentences is that, and how many carry two labels?
#     What did the model give each of those?
#  4. Draw 20 sentences with set.seed(17) and sample(), and label them before
#     you look. Your agreement with the annotators and with the model, and
#     your confusion table against the annotators.
#  5. Count the sentences that end with a comma (pieces of split sentences)
#     with grepl(). The model's agreement with the annotators on them and on
#     the rest.
# Agreement
#  6. Build the confusion table with
#     tab_m <- table(annotators = tdw$annotators, model = tdw$model), then read
#     it by column with round(prop.table(tab_m, 2), 2): of the sentences the
#     model called hawkish, what share did the annotators call hawkish?
#  7. Split the sentences by whether they contain "inflation", in any case
#     (grepl() with ignore.case = TRUE). The base rate and the model's
#     agreement in each group.
#  8. On the sentences where the word-count rule and the model disagree,
#     which one agrees with the annotators more often?
# Runs and cost
#  9. Read replies/labels_run2.csv into run2 and add its stance column to tdw
#     as model2. List the sentences whose label changed between the two runs,
#     with their annotators' labels, and compare their length with the rest.
#     Then the cost of each saved run from its tokens and PRICE, and the cost
#     of 100,000 sentences.
# With your own key (optional)
# 10. Run source("model_setup.R") and source("save_replies.R") first, with
#     MODEL set to a model your key can call. Add three labelled sentences
#     from split == "train", one per label, to the codebook (few-shot). Label
#     20 sentences of split == "test" drawn with set.seed(6850), save each raw
#     reply with save_replies(), and compare agreement with the zero-shot
#     labels of the same 20.
# With an open model on your own computer (optional)
# 11. Install a local model server and one open model file (steps below).
#     Label the same 20 sentences with chat_ollama(), LOCAL_MODEL and
#     reasoning_effort = "none". Compare its agreement and its seconds per
#     sentence with the closed model's labels of the same 20.
# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =




s <- tdw$sentence[c(1028, 172, 1054)]
w3 <- strsplit(tolower(s), "[^a-z]+")
round(sapply(w3, function(x) 100 * (sum(x %in% pos) - sum(x %in% neg)) / length(x)), 1)


st <- read.csv("statement_sentences.csv")          # id, sid, date, sentence
lab <- read.csv("replies/statement_labels.csv")    # id (the sentence's sid), stance
st$stance <- lab$stance[match(st$sid, lab$id)]
score <- c(dovish = -1, neutral = 0, hawkish = 1)[st$stance]   # each label picks its score
stance_by_date <- tapply(score, st$date, mean)     # (hawkish - dovish) / sentences
fomc$stance <- as.numeric(stance_by_date[fomc$date])
w2 <- strsplit(tolower(fomc$text), "[^a-z]+")
fomc$tone <- sapply(w2, function(x) 100 * (sum(x %in% pos) - sum(x %in% neg)) / length(x))
ev <- as.Date(c("2008-09-16", "2020-03-15", "2022-03-16"))   # three statements, marked
par(mfrow = c(2, 1), mar = c(2, 4.5, 1, 4.5))
xr <- range(as.Date(fomc$date))
plot(as.Date(fomc$date), fomc$stance, type = "h", xlab = "", ylab = "Model's stance", xlim = xr)
abline(h = 0, v = ev, col = "grey")
par(new = TRUE)                                    # the target rate on the same panel, right axis
fr <- fred[as.Date(fred$date) >= xr[1] & as.Date(fred$date) <= xr[2], ]
plot(as.Date(fr$date), fr$upper, type = "l", col = "#B31B1B", lwd = 1.5, axes = FALSE,
     xlab = "", ylab = "", xlim = xr)
axis(4, col = "#B31B1B", col.axis = "#B31B1B")
mtext("Target rate, %", side = 4, line = 2.5, col = "#B31B1B", cex = 0.9)
plot(as.Date(fomc$date), fomc$tone, type = "h", xlab = "", ylab = "Net tone per 100 words")
abline(h = 0, v = ev, col = "grey")


save_replies <- function(texts, ids, folder, prompt, type) {
  dir.create(folder, recursive = TRUE, showWarnings = FALSE)    # make the folder if it is missing
  for (j in seq_along(texts)) {
    f <- file.path(folder, paste0(ids[j], ".json"))            # one file per item
    if (file.exists(f)) next                                   # saved already: no call, no cost
    chat <- chat_anthropic(system_prompt = prompt, model = MODEL, cache = "none")
    ans <- chat$chat_structured(texts[j], type = type)
    rec <- list(id = ids[j], answer = ans, model = MODEL,
                reply = chat$last_turn()@json)                 # the reply as the provider sent it
    writeLines(jsonlite::toJSON(rec, auto_unbox = TRUE, null = "null"), f)
  }
}


# The end
