# 21-photos

The project for AEM 6850, session 21, Photographs I (Tuesday, November 10,
2026): 365 photographs of the Beijing skyline, one each morning of 2014, scored
for haze by a general vision model and judged against the US Embassy's PM2.5
monitor on days the model never saw.

Open `21-photos.Rproj` first. R then starts in this folder, and every path in
the slides, the live script and the scripts below is relative to it. The scripts
install what they need. Nobody needs Python, an account or the network: every
model reply is saved in `replies/`.

## What is where

```
21-photos/
  21-photos.Rproj
  README.md          this file
  code/              the scripts, numbered in the order the lecture uses them
  data/composite/    Zou Yi's 2014 composite, 4999 by 3108 px (the raw photographs)
  data/pollution/    the Embassy's hourly PM2.5 file for 2014, as downloaded
  data/street/       one CC0 street photograph (Porlamar, Venezuela) and its source note
  data_clean/tiles/  the 365 daily photographs cut from the composite, <date>.jpg, 167 by 222 px
  data_clean/        tiles.csv, pm25_daily.csv, haze.csv, haze_pm25.csv, street/,
                     tile_embeddings.csv (512 numbers per photograph, from an open embedding model)
  replies/haze/      the model's reply for each day, exactly as returned (365 JSON files)
  replies/street/    the model's four replies on the street photograph
  replies/local/     an open model on a laptop: its haze reply for each day, its direct answer in
                     micrograms for the 110 held-out days, both as returned and as two tables
  replies/*.txt      the questions that were asked, and the model
  logs/              run records
  tools/             what made data_clean/ and replies/ (needs a key or Python)
```

| Script | What it does |
|---|---|
| `code/1_one_photo.R` | one photograph read as an array, its numbers, two mornings side by side |
| `code/2_replies.R` | the hourly file into a daily mean, one reply as it came back, three replies into a table joined to the daily mean, the score against the monitor, all 365 replies into one table joined to the monitor |
| `code/3_judge.R` | seeded split, the score calibrated to micrograms on the fitting days, mean absolute error on the held-out days, Exercise 1 (the ten worst held-out days), the monitor's mean at each score in place of the line, a model trained on the monitor (a regression on each photograph's 512 embedding numbers) beside the other routes, Exercise 2 (the trained model with fewer and more numbers), the weather tiles, two comparisons answered by the monitor and by the photograph (the APEC week, the heating season) |
| `code/4_local_model.R` | optional, not run by `run_everything.R`: the same haze question put to an open vision model running on this computer (needs Ollama and one downloaded vision model; no key, no network) |
| `code/run_everything.R` | all three, in a few seconds |

## Where the data come from

- **Photographs.** Zou Yi (邹毅), "北京·一目了然" season 2: one photograph of the
  same view each morning of 2014, published as one composite of 365 tiles. The
  capture time is burned into every caption: 05:55 (17 June) to 08:33 (7 October),
  one morning (6 October) at 10:19; summer about 06:00 to 06:45, winter about
  07:00 to 08:05. The caption on the 21 December tile reads 2012, a typo in the
  original. The composite was used in this course in 2025. The tiles are for
  teaching in this course; they are not redistributed on the public site, so
  `data/composite/` and `data_clean/tiles/` are in the class zip (Box, Cornell
  NetID) and not in the zip on the public page. `code/1_one_photo.R`,
  the photographs drawn in `code/3_judge.R` (Exercise 1, the end of section 7, section 9) need the tiles.
  `tools/cut_tiles.R` cuts them; the grid is 30 by 14, the top two rows hold
  the title and the five photographs of Jan 1-5.
- **Monitor.** US Department of State, Mission China air quality monitoring
  program, Beijing, hourly PM2.5 for 2014 (`Beijing_2014_HourlyPM25_created20150203.csv`;
  -999 marks a missing hour, 99 of 8,760). `tools/monitor_daily.R` averages the
  valid hours of each day: 333 days have all 24, 32 days have 13 to 23 (9 December
  has 13, none before 11:00), so no day is lost.
- **Street photograph.** `data/street/SOURCE.md`.

## What the model was asked, and what came back

`tools/score_photos.R` sent each tile to a general vision model with one
question (the text is in `replies/haze_prompt.txt`): a haze score from 0 to 10,
a sky condition from a fixed list, one short reason, returned as JSON against a
schema. 365 calls, 195,640 input and 27,305 output tokens, about 1.3 USD, run
2026-11-09. `tools/describe_street.R` asked four questions about the street
photograph (label, busyness, counts, caption). `tools/detect_street.py` ran an
open detector, an open segmenter and an open embedding model on it
(`data_clean/street/`).

Numbers the slides show (from the scripts, 2026-11-09): correlation of the haze
score with the monitor's daily mean across the 365 days, 0.68; with
`set.seed(6850)`, 255 fitting days and 110 held-out days; the fitted line is
5.7 + 19.5 micrograms per point of haze; mean absolute error on the held-out
days 44.2 micrograms per cubic metre, against 66.0 for guessing the fitting
days' mean. All ten of the largest held-out misses read too low: nine scored
8 or 9 (the line gives at most 161 or 181) on days the monitor read 271 to
450; the tenth, 28 December, was a clear morning after a night of smog.
