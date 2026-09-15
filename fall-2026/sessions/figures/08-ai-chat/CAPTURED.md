# Session 8 media, captured 2026-09-14/15

Real captures from claude.ai (web), signed in on the instructor's account
(model picker reads "Opus 5 · High", plan Max; a free account shows a
different picker), light theme, sidebar collapsed, window 1500 px wide.
Captured through a same-origin popup window and `screencapture`, so the
pixels are the page as rendered; only the browser chrome was cropped off.
Replies vary between runs: the page must say so.

## Files that replace placeholders (same names the qmd already uses)

| File | What it shows | Notes for the page |
|:--|:--|:--|
| `S01-claude-new-chat.png` | A new, empty chat: "How can I help you today?", the **+** button, the **Chat / Cowork** toggle in the composer, the model picker "Opus 5 · High", the microphone and voice icons | claude.ai now shows Cowork as a toggle inside the web composer too (the desktop app is still the way to grant a folder). The sidebar is collapsed in this capture (the "Show sidebar" icon, top left), so "New chat" is not visible: circle the + and the picker instead. |
| `S02-explain-reply.png` | The reply to the explain prompt (P1), scrolled to lines 6 to 8: each line quoted in a code box, its explanation under it | Exercise 1 solution. The `tapply()` sentence reads "So R computes the average life expectancy for each continent" and never says that every country counts once. That is the thing to question. Full reply: `captured/T01-explain.txt`. |
| `S03-attach-menu.png` | The **+** menu open: **Add files or photos ⌘U**, Take a screenshot, Add to project, Add from GitHub, Skills, Connectors, Add plugins, Research, **Web search ✓**, **Memory ✓** | The upload item's label is "Add files or photos". The web-search toggle lives in this same menu (needed for the references demo). |
| `S04-csv-chip.png` | The composer with the `gapminder.csv` chip ("gapminder.csv · CSV") above the message box, nothing typed | Exercise 2 step 1. |
| `S04b-chip-and-prompt.png` | The same composer with the chip and the full Exercise 2 prompt typed, before sending | Optional page figure. |
| `S05-code-block-copy-icon.png` | The reply to P5 with the artifact panel open on the right: "2 lifeexp weighted 2007 · R", **Copy** button top right, the script with line numbers | THE REPLY CAME AS AN ARTIFACT, NOT AN INLINE CODE BLOCK: the script sits in a side panel opened by clicking the card "2 lifeexp weighted 2007 · Code · R" (which also has a **Download** button). Reword the page/slide: "click the card, then Copy". The old placeholder name is kept so the qmd renders. |
| `S05c-artifact-card.png` | The reply text and the artifact card with its Download button, panel closed | Alternative to S05. |
| `S10-doi-not-found.png` | doi.org: "DOI NOT FOUND · 10.1016/S0954-349X(02)00049-7 · This DOI cannot be found in the DOI System" | The check that catches the wrong DOI (see T04). |
| `S14-references-reply.png` | The reply to the references prompt with web search off: the refusal to invent, the three hedged references with DOIs | Optional slide/page figure beside S10. |

## Still placeholders (grey PNGs; see SHOPPING-LIST.md)

S06 (desktop app, Cowork), S07 (Cowork with the folder connected), S11
(Settings > Capabilities), S12 (free account: Chat only), S13 (chore
prompt in chat). S06/S07/S12 need the Claude desktop app, which this
build cannot drive; S11 and S13 are page-only and two-minute captures.

## Transcripts (in `captured/`)

- `P1-explain-prompt.txt`, `T01-explain.txt`: the explain prompt and the
  full reply (eleven lines, each quoted then explained). Precise
  throughout; the one sentence to question is line 7's.
- `P4-references-prompt.txt`, `T04-references.txt`, `T04-doi-check.txt`:
  web search OFF. The model declined to claim Gapminder-based papers,
  said it might hallucinate details, and gave three references flagged
  as unverified. The check: Wilson 2001 VERIFIED (doi.org and Crossref
  match); Neumayer 2003 exists but the DOI given
  (10.1016/S0954-349X(02)00049-7) does not resolve, the real one is
  10.1016/S0954-349X(02)00047-4, MISMATCH; Becker, Philipson and Soares
  2005 VERIFIED. One wrong DOI in three, from a model that hedged
  honestly. Under the reply the page showed a banner "Web search is off.
  Turn it on so Claude can check current sources for this."
- `P5-weighted-prompt.txt`, `T05-reply.txt`, `T05-weighted-script.R`,
  `T05-run.txt`: Exercise 2. With the CSV attached and code execution
  on, the model first ran checks on the file ("Ran 2 commands, read a
  file, and 2 more tools"), reported 1704 rows, 142 countries, 12 years,
  no missing values, then delivered the script as an artifact. The
  script runs from the project root and prints Africa 54.56, Americas
  75.36, Asia 69.44, Europe 77.89, Oceania 81.06 (matches the hand
  check). One claim in the reply is out of date: it says summing the
  integer `pop` column "would return NA with an overflow warning"; in
  R 4.3 `sum()` of an integer vector returns a double when the total
  exceeds the integer range (Asia 2007: 3,811,953,827, no NA, no
  warning). Harmless conversion, wrong reason: a good example of
  checking an explanation against what R does.

## Numbers (base R on the shipped CSV, 2026-09-14)

2007 unweighted means: Africa 54.81, Americas 73.61, Asia 70.73, Europe
77.65, Oceania 80.72. Population-weighted: 54.56, 75.36, 69.44, 77.89,
81.06.
