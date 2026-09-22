# Session 9 media, captured 2026-09-14

All captures are REAL runs of Claude Code v2.1.258 (model Opus 5, plan Max)
in `~/github/gapminder-practice`, launched from a terminal as
`claude --permission-mode manual` (so every edit asks), rendered from the
terminal screen as a light terminal tab (RStudio's Terminal look). Lines
that belong to the instructor's machine (remote-control tips, /status,
/effort) were blanked; nothing else was altered. Replies vary between
runs: the page must say so. The repository state before the first prompt:
one commit ("Add the Gapminder table"), `data/gapminder.csv`, `.gitignore`,
`gapminder-practice.Rproj`, no `code/` folder.

## Screenshots (PNG, 1648 px wide, white background)

| File | What it shows | Use |
|:--|:--|:--|
| `S01-trust-folder.png` | First launch in a folder: "Accessing workspace ... Quick safety check ... ❯ No, exit / Yes, I trust this folder ... Enter to confirm · Esc to cancel" | the first screen after typing `claude` |
| `S02-welcome.png` | The welcome screen: logo, "Claude Code v2.1.258", "Opus 5 (1M context) · Claude Max", "~/github/gapminder-practice", the prompt box `❯ Try "write a test for <filepath>"`, status bar "⏸ manual mode on · ? for shortcuts" | what a ready session looks like; where the mode shows |
| `S03-create-file-dialog.png` | After the vague prompt (run A): "⏺ Write(code/lifeexp_by_continent.R)", "Create file", the 9-line script, "Do you want to create lifeexp_by_continent.R? ❯ 1. Yes / 2. Yes, and switch to accept edits (auto-approve file edits and common file commands) for this session (shift+tab) / 3. No", "Esc to cancel · Tab to amend" | the approval prompt; the script uses `tapply(sub$lifeExp, sub$continent, mean)` (countries averaged, not people) |
| `S04-written-summary.png` | After accepting: "Wrote 9 lines to code/lifeexp_by_continent.R", the file, the model's summary paragraph, "Brewed for 27s" | "the transcript says what it did" |
| `S05-edit-dialog-diff.png` | After the patch request (run B, same conversation): "⏺ Update(code/lifeexp_by_continent.R)", "Edit file", a red/green diff (line 1 comment changed; line 5 `mean` replaced by `sum(lifeExp*pop)/sum(pop)` via two `tapply` calls), "Do you want to make this edit to lifeexp_by_continent.R? ❯ 1. Yes / 2. Yes, and switch to accept edits ... / 3. No" | reading a diff before accepting; note the model also rewrote the comment although asked to change nothing else |
| `S06-gain-create-dialog.png` | Run C (with CLAUDE.md in the repo, a 3-line prompt): the create dialog for `code/lifeexp_gain.R`, 18 lines: header comment, `FROM <- 1952`, `TO <- 2007`, `merge()`, a why-comment, `which.max` per continent | CLAUDE.md conventions applied without being repeated in the prompt |
| `S07-gain-written-summary.png` | After accepting run C: "Wrote 20 lines", the summary ending "Not run, per the project rules." | the standing rules were read |

## Prompts (verbatim, as typed)

Run A (vague on purpose; produced the unweighted mean):

    Write code/lifeexp_by_continent.R. It defines a function
    lifeexp_by_continent(d, yr) that takes the Gapminder data frame d and a
    year yr and returns the mean life expectancy of each continent in that
    year, as a named vector with one number per continent. Base R only, no
    packages. At the bottom of the script, read data/gapminder.csv into d and
    print lifeexp_by_continent(d, 2007). Do not run the script; I will run it
    myself. Do not create any other file and do not use git.

Run B (the patch request, same conversation):

    I ran the script. Oceania prints 80.72. I predicted 81.06 by hand:
    Australia, 81.235, has 20,434,176 people and New Zealand, 80.204, has
    4,115,771, so the mean of the people is 81.06. Your function averages
    countries, not people. Change lifeexp_by_continent() so each country's
    life expectancy is weighted by its population, the pop column. Change
    nothing else. Do not run the script.

Run C (new conversation, CLAUDE.md present):

    Write code/lifeexp_gain.R: a function lifeexp_gain(d, from, to) that
    returns, for each continent, the name of the country whose life
    expectancy rose the most between the years from and to. At the bottom,
    read the data and print the result for 1952 to 2007.

## Text captures (in `captured/`)

- `A-script.R`: the script run A wrote. `T05-run-A.txt`: `Rscript` output
  (Oceania 80.71950). `T05b-git-status.txt`: `git status` (code/ untracked).
  `T05c-git-diff-staged.txt`: after `git add code/lifeexp_by_continent.R`,
  `git diff --staged` shows the whole new file as `+` lines.
- `B-script.R`: after the patch. `T09-git-diff.txt`: `git diff` of the
  patch (comment line and the two tapply lines). `T10-run-B.txt`: output
  (Oceania 81.06215).
- `final-lifeexp_by_continent.R`: the script after the student adds the
  check by hand (`res <- ...; stopifnot(abs(res["Oceania"] - 81.06) < 0.01)`).
  `T11-git-diff-check.txt`: the diff of that edit. `T12-run-check.txt`: it
  runs, no error. `T13-git-log.txt`: the log after the commit.
- `claude-md-seed.txt`: the CLAUDE.md seed the page ships (28 lines; named .txt here so no tool mistakes it for instructions).
- `C-script.R`: run C's script. `T17-run-gain.txt`: output (Africa Libya,
  Americas Nicaragua, Asia Oman, Europe Turkey, Oceania Australia).
  `T18-git-log.txt`: four commits.

## Hand-check numbers (verified with base R on the shipped CSV)

Oceania 2007: Australia lifeExp 81.235, pop 20,434,176; New Zealand
80.204, pop 4,115,771. Unweighted mean 80.72; population-weighted 81.06.
All five continents 2007, unweighted: Africa 54.81, Americas 73.61, Asia
70.73, Europe 77.65, Oceania 80.72; weighted: 54.56, 75.36, 69.44, 77.89,
81.06. Gain 1952 to 2007: Australia 69.120 to 81.235 (+12.115), New
Zealand 69.390 to 80.204 (+10.814), so Oceania's answer is Australia.

## Run G (2026-09-14, 23:30): version control from inside the agent

New conversation in the same repository (five commits at the start, clean
tree, CLAUDE.md present with its "Do not use git. I commit." rule).

Prompt G1 (an edit):

    In code/lifeexp_gain.R, store the printed result in a variable and add a
    check after it: stopifnot(result["Oceania"] == "Australia"), with a
    one-line comment saying it is the hand-checked case. Change nothing
    else. Do not run it and do not commit.

| File | What it shows | Use |
|:--|:--|:--|
| `S08-edit-dialog-check.png` | "⏺ Update(code/lifeexp_gain.R)", "Edit file", the diff: line 20 `print(lifeexp_gain(d, FROM, TO))` removed; lines 20-23 added (`result <- ...`, `print(result)`, the comment, `stopifnot(result["Oceania"] == "Australia")`), then "Do you want to make this edit to lifeexp_gain.R? ❯ 1. Yes / 2. Yes, and switch to accept edits ... / 3. No" | the diff is shown in the interface before the file changes |
| `S09-slash-diff.png` | after accepting, the `/diff` command: a panel "Uncommitted changes (git diff HEAD)", "1 file changed +4 -1", "❯ code/lifeexp_gain.R +4 -1", "←/→ to switch source · ↑/↓ to select · Enter to view · Esc to close" | the same diff, from git, inside the tool |

Prompt G2 (a commit, explicitly asked for):

    Commit code/lifeexp_gain.R with the message: Add the Oceania check to
    lifeexp_gain

| File | What it shows | Use |
|:--|:--|:--|
| `S10-git-commit-dialog.png` | the model's line "Your CLAUDE.md says not to use git, but since you're asking explicitly, I'll go ahead with this one commit."; then "Bash command" with the exact command `git -C ~/github/gapminder-practice add code/lifeexp_gain.R && git ... commit -m "Add the Oceania check to lifeexp_gain" && git ... status --short`, "This command requires approval", "Do you want to proceed? ❯ 1. Yes / 2. Yes, and don't ask again for: git * / 3. Yes, and switch to auto mode / 4. No" | the agent runs git for you when asked; in manual mode every git command is shown and approved first; a standing rule in CLAUDE.md yields to an explicit ask |
| `S11-after-commit.png` | "Committed f0f9a04"; "Committed as f0f9a04 on main — 'Add the Oceania check to lifeexp_gain', one file changed. Working tree is clean." | the result, to be checked with `git log --oneline` |

`captured/T19-git-log-after-agent-commit.txt`: the log (six commits, the
newest made by the agent). `captured/T20-git-show-stat.txt`: `git show
--stat HEAD`.

## Run I (2026-09-15, 00:40): `/init`

In the repository at the commit before CLAUDE.md existed, a new
conversation, `/init` at the prompt. Claude Code first asked to run a
read-only inspection command (a "Bash command ... Do you want to proceed?"
box: cat .gitignore, head of the CSV, wc -l), then proposed the file.

| File | What it shows | Use |
|:--|:--|:--|
| `S14-init-create-box.png` | The draft CLAUDE.md scrolled to lines 4-24 ("What this is", "Running", "Conventions": 1704 rows, base R only, run from the root, `stopifnot()` self-checks) and the box "Do you want to create CLAUDE.md? ❯ 1. Yes / 2. Yes, and switch to accept edits ... / 3. No" | slide "/init: a first draft of CLAUDE.md". Two draft lines that mentioned the instructor's own global configuration were blanked; nothing else changed. The draft is Esc-declined; the page's seed replaces it. |

## RStudio (2026-09-15, 10:20)

| File | What it shows | Notes |
|:--|:--|:--|
| `S12-rstudio-terminal-claude.png` | RStudio (dark theme) with the `gapminder-practice` project open: the Terminal tab active, "Terminal 1 (busy)", Claude Code's welcome screen in the pane (v2.1.258, `~/github/gapminder-practice`, the `❯` prompt, "⏸ manual mode on"), the Environment pane and the Files pane (`.gitignore`, `CLAUDE.md`, `code`, `data`, `gapminder-practice.Rproj`) | Real capture. Claude Code was started in the Terminal tab by an RStudio startup hook because this build cannot type in RStudio; one warning line that only appears when RStudio is launched from inside another Claude Code session was painted over in the terminal's background colour. Nothing else changed. Students on the default light theme see the same layout in light colours. |

`S13-terminal-dropdown.png` (the terminal dropdown with two terminals) stays a placeholder: it needs a click in RStudio on a regular desktop Space.

## Runs L and S (2026-09-21): a loop, and a subagent review

Both non-interactive (`claude -p ... --output-format stream-json`) in a
scratch clone of the repository at commit f0f9a04, with the tools the
prompt needs allowed in advance (`Write,Edit,Bash(Rscript *)` for L,
`Agent` for S), which is what pressing `1. Yes` on each box does in
manual mode. Same version as the September 14 captures.

- Run L, prompt in the page's loop section (ambiguous "mean gdpPercap",
  the hand check in the script, "run until the check passes"): 7 turns,
  50 s. It wrote a plain mean, ran it (Oceania 29810.188, the check
  failed), edited to the population-weighted mean, ran again (32884.555),
  and replied with the output and two flags (the check only passes for
  the weighted mean; CLAUDE.md says not to run scripts but the prompt
  asked). `T21-loop-run.txt` is the transcript, `D-gdp_by_continent.R`
  the final file.
- Run S: `.claude/agents/hand-check-reviewer.md` (here as
  `hand-check-reviewer.md.txt`) in place, prompt "Use the
  hand-check-reviewer subagent to review code/lifeexp_by_continent.R
  against this rule: ...". Run twice, the second time with the description
  shortened to one line so the slide shows the whole file; the report on the
  page is the second run's. The subagent read the file and returned rule,
  line, verdict; nothing edited. `T22-subagent-review.txt`.

## The placements project (2026-09-21, 23:30): the session's spine from this date

The lecture was rebuilt around a project that starts from an empty
folder (`placements.Rproj` only). All runs non-interactive
(`env -u CLAUDECODE claude -p ... --output-format stream-json --verbose
--no-chrome --strict-mcp-config --allowedTools ...`), one resumed
conversation for M0-M3 and M6 (`--continue`), separate conversations for
M4 (on a copy at the M2 state) and M5 (with the reviewer agent file in
place). Same Claude Code version as the September 14 captures. The page
snapshot is `phd-placements-page-2026-09-21.html` (109 rows, 2015-2026).

| File | Prompt | What happened |
|:--|:--|:--|
| `M0-git-init.txt` | initialize git, .gitignore, commit "New project" | Write .gitignore; one Bash command `git init && git add -A && git commit ...`; the commit message carries a Co-Authored-By line |
| `M1-scraper.txt` | write and run code/placements.R (rvest) | two `Rscript -e` looks at the page's two tables; Write; `Rscript`: 109 rows first try |
| `M2-postdoc.txt` | add a postdoc column, run, count TRUE | listed 11 spellings; one line `grepl("post[- ]?doc", ..., ignore.case = TRUE)`; 25 of 109 |
| `M3-country.txt`, `M3-country-block.R` | add a country column, run, counts | listed 107 organizations; typed a 16-pattern table plus default "United States" (77 rows); DTUM read as TUM, Germany. An earlier run the same evening (scratch repo `placements`, not shipped) read DTUM as DTU Management, Denmark |
| `M4-plan-first.txt` | "Describe your approach before writing any code" (on the M2 state) | proposes a hand-curated lookup it would populate "from knowledge of the institutions" |
| `M5-reviewer.txt` | hand-check-reviewer subagent, rule: country values only from the page or a data file | verdict breaks; lines 44-67 quoted; nothing edited |
| `M6-fix-lookup.txt` | replace the table with data/countries.csv filled by hand, NA otherwise | 107-row file written once; three-line match; 109 of 109 NA |
| `M7-by-year-under-claude-md.txt`, `by_year.R` | one sentence under `claude-md-placements-seed.txt` | header, constant, function, stopifnot on counts, "Not run, per the project rules." |
| `placements-final.R`, `countries-head.csv` | the script after M6; the first rows of the lookup file | |

Hand counts on the page snapshot: 109 rows; 16 for 2026; postdoc
spellings 25 (find: "postdoc" 15, "post-doc" 9, "post doc" 1); 14
organization strings name a place.

Screens S01, S02, S03, S05, S10, S12, S14 stay in the deck as anatomy of
the boxes, captioned as from another project.
