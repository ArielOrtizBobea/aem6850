#!/bin/bash
# Orchestrates the billed runs before class. Run from the 17-text-llms folder.
set -u
export ELLMER_LIB="$1"
N=8
echo "== range $(date)"
Rscript prep/run_range.R 2>&1 | tail -4
for what in "labels replies/run1" "labels replies/run2" "statements replies/statements"; do
  set -- $what
  echo "== $1 $2 $(date)"
  for k in $(seq 1 $N); do Rscript prep/run_shard.R $1 $2 $k $N 2>&1 | grep -v "^$" & done
  wait
  echo "files: $(ls $2 | wc -l)"
done
echo "== csv $(date)"
Rscript prep/build_csv.R
echo "== done $(date)"
