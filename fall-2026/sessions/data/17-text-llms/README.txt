17-text-llms: how the saved model replies were made
====================================================

Closed model: claude-sonnet-5-5 (the provider's mid-size model), written once
as MODEL in model_setup.R. Prompts: range_prompt.txt and codebook.txt, written
before any reply was seen. Schemas: range_type and stance_type in
model_setup.R. Every call used the model's default settings (the model
rejects a temperature setting) with ellmer's prompt cache off
(cache = "none"), one fresh conversation per item.
Runs made on 25 October 2026 on the instructor's key, ellmer 0.5.0, R version 4.6.1 (2026-06-24).

Target range, 171 statements              171 calls     218,166 input     3,014 output
Stance labels, run 1                    2,480 calls   1,723,541 input    50,003 output
Stance labels, run 2                    2,480 calls   1,723,541 input    51,308 output
Statement sentences (distinct)          1,195 calls     819,454 input    20,635 output

The label runs used save_replies() (save_replies.R), split across 8 R
sessions (prep/run_shard.R) that call it on parts of the ids. The range run
used parallel_chat_structured() (prep/run_range.R). replies/*.csv are built
from the JSON files by prep/build_csv.R. demo/ holds the sentences of
the five-sentence task labelled twice before class, as demo.R does live.

Open models, run on the instructor's laptop (Apple M2 Max, 64 GB) through a
local Ollama server, the same codebook and schema, temperature 0, seed 6850,
thinking off, by run_local.R (a copy is in prep/):
  qwen3.5:4b-q4_K_M (3.3 GB): 2480 sentences, replies/local_4b.csv
  qwen3.5:9b-q4_K_M (6.6 GB): 2480 sentences, replies/local_9b.csv
  qwen3.5:27b-q4_K_M (17 GB): 2480 sentences, replies/local_27b.csv
Each row holds the id, the label and the seconds the call took.
