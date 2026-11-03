# Session 20 tables: build summary

Built 2026-11-02 by `code/run_everything.R` (five scripts, about 6 s; output in
`logs/run_everything.log`): `data_clean/` `words.csv` 207,189 rows, `segments.csv` 2,094,
`utterances.csv` 1,401, `tone.csv` 1,401, `meetings.csv` 24. Numbers below come from those files.

## Per conference

Words: kept after removing tags. Share: Powell's words over all labelled words. Scored:
utterances with a tone score (at least one 10-s window midpoint inside).

| Date | Words | Tags | Segments | Labels | Turns | Powell | Share | Answers | Scored |
|---|---|---|---|---|---|---|---|---|---|
| 2021-01-27 | 8,800 | 22 | 65 | 15 | 43 | SPK00 | 0.84 | 19 | 37 |
| 2021-03-17 | 9,590 | 34 | 81 | 24 | 67 | SPK00 | 0.80 | 25 | 49 |
| 2021-04-28 | 9,221 | 44 | 68 | 19 | 54 | SPK00 | 0.81 | 24 | 50 |
| 2021-06-16 | 10,297 | 27 | 77 | 18 | 59 | SPK00 | 0.81 | 23 | 48 |
| 2021-07-28 | 8,949 | 15 | 72 | 20 | 62 | SPK00 | 0.79 | 22 | 45 |
| 2021-09-22 | 8,818 | 27 | 82 | 22 | 66 | SPK00 | 0.79 | 26 | 52 |
| 2021-11-03 | 9,340 | 17 | 80 | 20 | 67 | SPK00 | 0.81 | 23 | 49 |
| 2021-12-15 | 10,231 | 31 | 82 | 19 | 68 | SPK00 | 0.82 | 26 | 52 |
| 2022-01-26 | 9,029 | 31 | 66 | 17 | 51 | SPK00 | 0.80 | 21 | 44 |
| 2022-03-16 | 8,531 | 35 | 81 | 22 | 67 | SPK00 | 0.78 | 24 | 52 |
| 2022-05-04 | 7,984 | 22 | 68 | 17 | 41 | SPK00 | 0.84 | 20 | 40 |
| 2022-06-15 | 9,211 | 13 | 120 | 21 | 52 | SPK00 | 0.82 | 25 | 49 |
| 2022-07-27 | 9,181 | 13 | 87 | 23 | 49 | SPK00 | 0.80 | 24 | 49 |
| 2022-09-21 | 7,139 | 16 | 74 | 15 | 45 | SPK00 | 0.81 | 22 | 43 |
| 2022-11-02 | 7,719 | 11 | 76 | 16 | 48 | SPK00 | 0.84 | 23 | 44 |
| 2022-12-14 | 7,603 | 5 | 77 | 25 | 48 | SPK00 | 0.82 | 22 | 43 |
| 2023-02-01 | 7,451 | 0 | 86 | 19 | 56 | SPK00 | 0.78 | 26 | 48 |
| 2023-03-22 | 7,248 | 17 | 92 | 21 | 68 | SPK00 | 0.75 | 31 | 61 |
| 2023-05-03 | 8,382 | 0 | 193 | 22 | 55 | SPK01 | 0.86 | 25 | 45 |
| 2023-06-14 | 8,634 | 0 | 107 | 26 | 80 | SPK00 | 0.74 | 36 | 71 |
| 2023-07-26 | 8,577 | 1 | 105 | 25 | 75 | SPK00 | 0.74 | 36 | 69 |
| 2023-09-20 | 9,260 | 3 | 95 | 20 | 66 | SPK00 | 0.76 | 31 | 59 |
| 2023-11-01 | 8,733 | 7 | 77 | 20 | 62 | SPK00 | 0.79 | 30 | 57 |
| 2023-12-13 | 7,261 | 9 | 83 | 20 | 52 | SPK00 | 0.82 | 24 | 46 |

Totals: 400 tags, 1,401 turns (24 statements, 608 answers, 769 other), 1,202 scored. The
statement, Powell's first turn of 2 min or more, lasts 349 to 549 s; no Powell turn precedes it.

## Powell's label

The label with the most words holds Powell throughout each conference, on four checks:

- None of the 608 answers opens with, or contains, a reporter's greeting ("Thank you, Chair
  Powell", "Hi, Mr. Chair", "Thanks, Michelle").
- The 12 other-label turns of 150 words or more are all reporters' questions (first 30 words read).
- Powell's share of words in each quarter of each conference runs from 0.64 to 0.97; no quarter
  shows another label taking over.
- Spot-check, first 40 words of three answers each. 2022-06-15: 15:37 "Sure. So the question
  really is, how high does the rate really need to go?", 35:17 "watching very, very carefully",
  49:30 "was your question on QT?". 2023-05-03: 12:38 "So the February 14th presentation",
  30:26 "sure so we we look at a range of wage um wage measures", 47:17 "I think we've moved a
  long way fairly quickly". All six are Powell. No conference shows a flip.

## Tone of Powell's answers

Medians over answers with a score (one value per answer, 593 of 608).

| Group | n | Arousal | Valence |
|---|---|---|---|
| 2021 | 182 | 0.432 | 0.500 |
| 2022 | 178 | 0.402 | 0.509 |
| 2023 | 233 | 0.396 | 0.515 |
| Hike (11 conferences) | 273 | 0.401 | 0.512 |
| Hold (13 conferences) | 320 | 0.416 | 0.505 |
| Hold, 2022-2023 only (5) | 138 | 0.392 | 0.512 |

The hold group holds all of 2021, when arousal ran highest; within 2022-2023 the hold median is
below the hike median. Answers of 15 s or more (571) give the same medians to within 0.001. The
statements' median arousal is 0.401; the other labels' (reporters, moderator) 0.504.

## Answers to listen to

Answers of 15 s or more; time from the start of the recording (same clock as the video).

| Date | Start | Length | Arousal | First 15 words |
|---|---|---|---|---|
| 2023-07-26 | 08:57 | 26 s | 0.509 | i'm just going to go back to what i said you know that's the question |
| 2021-11-03 | 25:14 | 35 s | 0.507 | That's a decision for the Committee. I would -I would put it to you this |
| 2021-11-03 | 26:09 | 51 s | 0.505 | I'm really saying is that question is not before us right now. We're -we're -you |
| 2022-07-27 | 35:02 | 114 s | 0.314 | doesn't seem that the U .S. economy is in recession right now. And I think |
| 2022-07-27 | 48:55 | 57 s | 0.302 | No, all I've really said is I don't think it's likely that the U .S. |
| 2022-09-21 | 40:35 | 20 s | 0.294 | that shelter inflation is going to remain high for some time. You know, we're looking |

The two 2021-11-03 answers are consecutive. With no 15-s floor the top one is 9 s (2021-11-03,
13:36, 0.539: Powell asks a reporter to repeat the question).

## Odd things

- 2023-05-03. The speaker labels cover 69% of the recording (88 to 93% elsewhere; the energy rule
  kept 1,291 of about 1,970 windows), in 193 segments, so 25% of its words have no label (2.0 to
  5.4% elsewhere) and its statement has 689 labelled words. Powell is SPK01 there. The rerun opens
  with "SECRETARY KERRY, President of the United States of America", which Whisper made up; the
  tag rule keeps it, and "United States of America" is a 4-word turn of SPK00. It also writes 95
  "um" or "uh" and long stretches in lower case without punctuation.
- The four conferences still flagged. 2021-04-28: the 15 copies of "GREG ROBB." are tags and are
  removed; the reporter's first 18 s (50:37 to 50:52) are missing, between turns 47 and 48.
  2022-03-16: "I'm sorry." four times at 23:15 inside a reporter's turn, at most 6 extra words.
  2022-06-15: 11 copies of "and the growth of the economy," from 1:26 to 1:49 of the statement;
  about 23 s of speech lost, 66 loop words counted in its 1,261. 2022-12-14: "I think that's a
  good thing to do with the Fed." repeated at about 35:45; six copies end Powell's answer at
  34:46-35:53 (turn 33, 219 words, about 66 of them the loop).
- Dropped speech. Words lasting over 5 s, the sign `README.md` names: 2021-04-28 18:52,
  2021-11-03 7:31 (15 s), 2022-05-04 7:39 and 37:08, 2022-07-27 8:14, 2022-12-14 42:11. The
  high-compression segments of 2022-09-21 and 2023-12-13 were not traced.
- Emotion windows. None missing (2022-05-04 drops its last 0.23 s by the 1-s rule). 15 answers
  get no score (median 2.6 s long).
- Tags. STATUS counts "MBS II." (2021-04-28) and three capital sentences (2022-06-15) as tags;
  the script keeps them (44 and 13, not 45 and 16). Tags run through 2023-12-13 (README corrected).
- Fillers. "um" or "uh" appear 95 times on 2023-05-03, 53 on 2023-09-20, 1 to 11 in five others;
  the README said none (corrected). This touches Part 1's filler-word count.
- Decision list. The 11 hike dates match the Fed's table of target-range changes (openmarket.htm,
  read 2026-11-02, each change dated the next day); no [fact-check] tag needed. `meetings.csv`
  also carries `size_bp`, `upper` and `powell_answers`.
- Columns follow the brief (`date`, `turn`, cluster labels, arousal/dominance/valence on 0-1).
  The outline's tables use `conf_date`, `utt_id`, named speakers, one `emotion` score on -1 to 1,
  pitch, energy and `net_tone`; the slides will need one or the other.
