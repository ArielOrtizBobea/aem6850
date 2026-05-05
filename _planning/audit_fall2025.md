# AEM 6850 — Fall 2025 audit

*Drafted 2026-05-05 as input to the Fall 2026 redesign memo.*

This is a structured read of the Fall 2025 offering: what was taught, in
what order, how students were assessed, and which assets already exist
that we can lean on, repurpose, or retire. The audit also surfaces gaps
that the AI-centric redesign needs to close.

---

## Snapshot of Fall 2025

- **Title:** *Empirical Methods for Applied Economists.*
- **Schedule:** Tuesdays/Thursdays, 1:25–2:40 pm, full Fall semester
  (28 sessions, Aug 26 – Dec 4), in-person.
- **Stated audience and prerequisites (as written in the Fall 2025
  syllabus):** "graduate course in econometrics (regression analysis
  and matrix algebra); basic programming skills."
- **Format:** Hands-on. Students work on personal computers in R +
  RStudio. Most sessions paired a lecture (`.Rmd` rendered to HTML)
  with live coding.
- **Course objectives (from syllabus):**
  1. Proficient in reproducible R programming.
  2. Capable of gathering, manipulating and visualizing various types
     of data effectively for research purposes.
  3. Capable of employing simulation and resampling methods in applied
     research.
- **Grading:** participation 10 %; weekly homework 40 % + peer review
  10 %; final reproducible project 30 % + peer review 10 %.
- **Homework cadence:** assigned at end of session, due one week
  later. Students peer-graded each other against a simple inline
  rubric (more on the rubric below).

## Topic sequence (28 sessions)

| Block | Sessions | Topic |
| ----- | -------- | ----- |
| Foundations | 1–2 | Getting started with R |
| Foundations | 3–4 | Loops, vectorization, parallel computing |
| Visualization | 5–6 | Basic data visualizations |
| Coding craft | 7 | Efficient coding practices |
| AI tools | 8 | Using LLMs for coding assistance |
| Data | 9 | Cleaning and manipulating tabular data |
| Data | 10 | Textual data |
| Spatial | 11 | Manipulating and visualizing spatial data |
| Spatial | 12–13 | Advanced spatial data manipulation |
| Workflow | 14 | Project workflow for complex projects |
| Data | 15 | Web scraping and APIs |
| Simulation | 16–17 | Monte Carlo simulations |
| Inference | 18–19 | Heteroscedasticity |
| Inference | 20 | Autocorrelation (time) |
| Inference | 21 | Autocorrelation (space) |
| Inference | 22–23 | Clustering |
| Resampling | 24–25 | Bootstrapping |
| Resampling | 26 | Cross-validation |
| Resampling | 27 | Permutation tests |
| Wrap | 28 | Summary |

Notes on the sequence:

1. The first eight sessions are about **becoming productive in R**;
   methods proper start at session ~14.
2. Visualization is treated as a core competency (two sessions plus
   three plotting homeworks).
3. The course already contains a single LLMs lecture (session 8,
   delivered Sept 18 2025 as a slide deck).
4. **Sessions 16–27 form a "robust inference + simulation" block**
   that occupies roughly 40 % of the course. Most of this block
   depends on Monte Carlo as its pedagogical engine.

## Homework architecture

Twelve homeworks, one per ~2 sessions. The folder layout follows a
pattern: `0_homework/hwN_topic/` with starter `.R`, often a
`_solution.R` or `_solutions.zip`, and any data needed.

Two examples set the range:

- **HW1 (week 1)** is a pure R-skills check. It is a single `.R`
  file with five comment-only questions and an inline points
  breakdown (15 + 25 + 20 + 25 + 15 = 100). No reproducibility
  scaffolding.
- **HW9 (clustering)** is a full Monte Carlo problem written as a
  research vignette: motivation paragraph, clear deliverable
  (one figure to disk in `../figures/`), and an **inline rubric with
  three 3-point dimensions**: Reproducibility (clean run + readme),
  Completeness (correct figure + annotation + location), and Coding
  (structure + parameter section + annotation + density). Total 9
  points. The descriptors are explicit enough to be machine-read.

The HW9 rubric pattern is essentially a contract for the AI grader
we want to build for Fall 2026 — it just needs to be lifted out of
the script header into a separate, structured (YAML/JSON) rubric file.

## Existing assets we can repurpose

These already exist on disk and should not be rebuilt from scratch:

- **`lecture 8 — using chatbots/`** — slide deck (Keynote + PDF, ~2.3 MB
  PDF) covering LLM background, using LLMs for writing, literature
  reviews, code generation/review, and disclosure/transparency. A
  starting point for a *threaded* AI track in Fall 2026.
- **`lecture 7 — coding practices/`** — `.Rmd` lecture on script
  structure, future-proofing, project management, master scripts,
  benchmarking, debugging.
- **`x_lecture x — reproducibility/`** — *parked, never delivered.*
  Contains a working `renv.lock`, a reproducibility `.Rmd`, and a
  rendered HTML. Was prepared but didn't run in Fall 2025. Needs a
  refresh but the bones are there.
- **`x_lecture x — version control/`** — *parked, never delivered.*
  An older (2021) `.Rmd` lecture on git. Concept is right; the
  delivery needs a 2026 rewrite that integrates GitHub Classroom.
- **`x_lecture x — Resampling/`** — parked resampling module
  (relevant since bootstrapping/cross-validation/permutation tests
  did make it into Fall 2025).

## What is missing or thin relative to the AI-centric goal

1. **No version control thread.** Git/GitHub did not appear in the
   delivered Fall 2025 sequence. Required for the GitHub Classroom +
   AI-grader workflow we want.
2. **No reproducibility thread.** Despite the stated objective
   ("proficient in reproducible R programming"), reproducibility was
   parked. `renv`, project structure, README conventions did not get
   a dedicated session.
3. **AI is a single session, not a thread.** A 2025-vintage chatbot
   lecture is a fine starting point, but if the redesign is "AI-
   centric" the assumption needs to flip: AI tools are scaffolded
   from week 1 and tied to coding craft, debugging, code review,
   and reproducibility verification across the whole semester.
4. **No project workflow → project deliverable bridge.** Session 14
   covered "project workflow for complex projects" but the final
   project deliverable does not have a structured scaffold (e.g., a
   template repo with README, `renv`, build script, structured
   write-up).
5. **Prerequisite mismatch with Fall 2026 audience.** The Fall 2025
   syllabus assumes prior econometrics and basic programming. Fall
   2026 must drop both assumptions. Several method-heavy sessions
   (heteroscedasticity, clustering, autocorrelation) currently lean
   on those prereqs.
6. **Monte Carlo carries too much weight.** Sessions 16–17 plus
   Monte-Carlo-driven HWs (e.g., HW9) make MC a load-bearing
   pedagogical device. Since MC is being moved to AEM 6851, the
   robust-inference block needs to be re-engineered around different
   demonstrations.

## Inspiration syllabi already in the folder

Two PDFs in `/2025_Spring/syllabus/inspiration/`. Ariel notes both
have a different scope from AEM 6850 — useful as inspiration, not
templates.

- **Goldsmith-Pinkham, MGMT 737 — Applied Empirical Methods (Yale, Spring 2021).** PhD course, methods-heavy
  (RD, IV, DiD, etc.). Problem-set-driven, "code from scratch"
  philosophy (no `lm()`; build the regression by matrix). Course
  page lives in a public GitHub repo. *Relevance to AEM 6850:* the
  GitHub-public-course pattern and the from-scratch coding ethos.
  *Not relevant:* the methods focus, which is downstream of where
  AEM 6850 sits.
- **McDermott, EC 607 — Data Science for Economists (Oregon, Winter 2021).** PhD course, hands-on practical
  toolkit: version control, project management, programming, data
  acquisition, GIS/remote sensing, big data. *Highly relevant:* this
  is the closest existing course to the Fall 2026 vision (minus AI).
  Public on GitHub. Worth deep reading in Phase 2 of the peer scan
  to see the *shape* of a "skills-first" course before AI was central.

## Implications for the Fall 2026 redesign

These are the carry-overs into Phase 2/3, not final design choices:

- **Drop the prerequisite floor.** Fall 2026 cannot assume prior
  econometrics or programming. Foundations block likely needs to
  expand from 4 sessions to 6–8.
- **Drop Monte Carlo.** Move MC to AEM 6851. Replace the inference
  block's MC-based demonstrations with simulations expressed as
  pre-built reproducible scripts students *run and inspect* rather
  than build.
- **Promote reproducibility and version control from "parked" to
  weeks 1–2.** They are infrastructure for everything else and for
  the GitHub Classroom homework flow.
- **Thread AI throughout.** Keep one anchor lecture on AI principles
  (the chatbot deck, modernized), but every coding-heavy session
  should include a 10-minute "how AI changes this task" segment and
  a homework prompt that requires explicit AI-assisted workflow +
  disclosure.
- **Keep the visualization weight.** Three plotting HWs in 2025 was
  a deliberate choice; visualization remains a high-leverage
  competency in an AI era and can absorb AI-assisted iteration well.
- **Re-engineer the homework rubric for AI grading.** HW9 already
  encodes a 3 × 3-point rubric inline; lift this into a YAML/JSON
  file in each assignment template and make the AI grader's contract
  explicit. Peer review can shrink (reduce from 20 % combined to
  ~10 %) since the AI grader does the rubric pass.
- **Add an R → Python translation thread for the second half.**
  Per Ariel's design choice: teach the concept in R first, then in
  the *same* session or an immediate follow-up show the Python
  equivalent. This doubles as a research-life skill.
- **Plan for ~20–25 students and the no-TA constraint.** Every
  artifact (lecture, homework, rubric) should be designed assuming
  no TA support — clean automation, structured outputs, machine-
  readable rubrics.

---

*Next: Phase 2 (peer-institution scan) and Phase 3 (AI-era skills
survey) run in parallel. Findings from all three phases feed the
research memo (`_planning/research_memo.md`) before we touch the
syllabus.*
