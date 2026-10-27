#!/bin/bash
# The three sizes of the open model, one after the other. Free; about 5 hours.
export ELLMER_LIB="$1"
for m in "qwen3.5:4b-q4_K_M local_4b" "qwen3.5:9b-q4_K_M local_9b" "qwen3.5:27b-q4_K_M local_27b"; do
  set -- $m
  echo "== $1 $(date)"; Rscript prep/run_local.R $1 replies/$2.csv 2>&1 | tail -2
done
echo "== done $(date)"
