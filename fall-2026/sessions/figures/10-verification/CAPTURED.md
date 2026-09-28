# Session 10: what is captured, and how

Everything in session 10 comes from R's built-in `LifeCycleSavings` data
(50 countries, 1960-1970; `?LifeCycleSavings`). R 4.6.1. Note: R versions
before 4.6.0 spell Guatemala's row name "Guatamala" in this dataset, so no
check on the page uses that row name.

## Charts and diagrams

- `F1`-`F7`: drawn by `make-figures.R` in this folder (base R). F1-F4 and F7 type
  numbers from the sources named in the script; F5-F6 come from the data.
- `D1`-`D6`: hand-written SVG in the style of session 9's diagrams.

## The planted deliverable (written for the session, not an agent run)

`captured/planted-savings.R` and `captured/planted-summary.txt` are the
deliverable on the page. Three problems were planted by hand: the "clean"
line `d[d$ddpi < 10, ]` drops Libya (ddpi 16.71) and Jamaica (10.23), so
the model uses 48 countries; the summary still says 50, reports the
subset's ddpi coefficient (0.84, p = 0.009; all 50: 0.41, p = 0.042) and
R-squared (0.38; all 50: 0.34), and describes `ddpi` (growth of income) as
income. `stopifnot(nrow(d) > 40)` passes with 48.

## Checker runs (2026-09-28, evening before class)

Three non-interactive runs of the checker prompt (`captured/checker-prompt.txt`)
in a folder holding only `summary.md`:
`env -u CLAUDECODE claude -p "<prompt>" --output-format stream-json --verbose
--no-chrome --strict-mcp-config --allowedTools "Read,Glob,Grep,Bash(Rscript:*)"`.
Transcripts `C1`-`C3`: 4-5 turns, about 33 seconds, about $0.20 each. All
three recomputed the full-data model, marked 0.32, 0.84, p < 0.01 and 38% as
mismatches, matched "50 countries" to the data, and listed the life-cycle
sentence and "checked against the script's output" as not checkable. C1 and
C3 guessed a subset of countries; C3 guessed income growth on a subset. The
table on the page condenses C3.

## Worker runs of the brief (2026-09-28)

Three non-interactive runs of `captured/brief.txt` in empty folders, with
`--allowedTools "Write,Edit,Read,Bash(Rscript:*)"`. Transcripts `W1`-`W3`,
scripts `W*-savings.R`, summaries `W*-summary.txt`. All three kept all 50
countries, described `ddpi` as income growth (0.41), and reported the
estimate without Libya separately (0.61). W1 also wrote a Makefile and a
block runner, following the instructor's global CLAUDE.md on this machine.
These runs are why the page says the deliverable was planted.
