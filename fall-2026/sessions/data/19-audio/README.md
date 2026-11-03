# 19-audio

The project for AEM 6850, session 19, Audio I: speech to text (Tuesday,
November 3, 2026): the Federal Reserve chair's press conference of
1 February 2023, turned into a table of who said what and when, and
checked against the Fed's own transcript.

Open `19-audio.Rproj` first. R then starts in this folder, and every
path in the slides, the live script and the scripts below is relative to it.

## What is where

```
19-audio/
  19-audio.Rproj
  README.md      this file
  code/          the scripts, numbered in the order the lecture uses them
  data/          the raw files, exactly as downloaded, and the clips cut from them
  data_clean/    everything the scripts compute
  replies/       every model reply, exactly as returned, and the Fed's text
  logs/          run times, the speaker model's log, what the scripts print
  tools/         the Python scripts that made the replies, and SETUP.md
```

**`data/`, raw.**

- `fomc20230201_transcript.pdf`: the Fed's transcript of the conference,
  23 pages.
- `clips/open2min.wav`: the first two minutes, Powell's opening statement.
- `clips/schneider30.wav`: 30 seconds of Powell's answer to Howard
  Schneider of Reuters, 16:09.6 to 16:39.6 in the video.
- `clips/open2min.mp3`, `clips/schneider30.mp3`: the same two clips at
  64 kb/s, for the web page's audio player.
- `clips/pause_2258.mp3`: 1370 to 1380 s (22:50 to 23:00), the longest
  pause in the utterance table, before Powell's answer at 22:58; the
  unlabelled words "shared on the committee. So, the committee,
  obviously," sit inside it.
- `clips/pause_4338.mp3`: 2610 to 2624 s (43:30 to 43:44), the longest
  silence between words before an answer, 4.58 s after "this summer?",
  then "Look, it's very hard to think about".
- `clips/howard10.mp3`: 919 to 929 s (15:19 to 15:29), the moderator's
  "Howard." (923.79 to 924.23 s) between Powell's "a lot of work left to
  do." and "Howard Schneider with Reuters"; the call gets no speaker label.
- `media/`: the whole conference, `fomc20230201_270p.mp4` (the video,
  172.5 MB) and `fomc20230201.wav` (its sound, 85.7 MB). They are kept out
  of the course's git repository for their size; `tools/SETUP.md` shows
  how to fetch the video and make the WAV.

**`data_clean/`, computed.** The number is the script that writes the file.

- `words.rds` (1): one row per word Whisper heard, with its start, end and
  probability; 7,451 rows.
- `seg.rds` (2): the speaker segments, with start, duration, end and
  label; 86 rows.
- `w.rds` (3): the 7,184 words that got a speaker label, with their turn.
- `utterances.csv` (4): one row per turn, with speaker, start, end and
  text; 56 rows.
- `wer_table.csv` (6): the four runs on the 30-second clip, scored against
  the Fed's text.

**`replies/`, the models' replies.** Exactly as returned, renamed plainly.
Made on 2 November 2026 on an Apple M2 Max laptop. Each line gives the
model and settings, the time the file was written (EST) and how long the
run took.

- `words.json`: the full conference, Whisper large-v3-turbo through
  mlx-whisper, English, a time on every word; 00:40, 307 s; 7,451 words.
- `words_base.json`: the full conference, Whisper base, the same
  settings; 00:28, 169 s. At 34:57 it falls into a loop and repeats one
  phrase to the end.
- `words_base_nocond.json`: Whisper base again, each 30-second window
  decoded without the text before it (`--condition-on-previous-text
  False`); 00:53, 96 s; 7,264 words, no loop.
- `speakers.rttm`: who spoke when in the full conference, from SpeechBrain
  ECAPA voice embeddings on 3-second windows every 1.5 s, clustered at a
  cosine distance of 0.7; 00:48, 58 s; 19 labels, 86 segments, no names.
- `clip30_turbo.json`, `clip30_base.json`: the 30-second clip, each model
  with the settings of `words.json`; 00:30 and 00:29, 8.5 s and 4.7 s.
- `clip30_turbo_prompt.json`, `clip30_base_prompt.json`: the same, with a
  prompt written full of fillers ("Um, uh, so, you know, ..."); 00:30 and
  00:29, 8.6 s and 3.4 s. The base run stops at 12.7 s.
- `clip30_live.json`: the rehearsal of the live run in class, the
  command of `clip30_turbo.json` with `--output-name clip30_live`; 16:09,
  8.0 s; byte for byte the same file as `clip30_turbo.json`. The run in
  class writes this name again.
- `fed_transcript.txt`: the text layer of the Fed's PDF, by pdftotext
  (poppler 26.04.0); 00:57.
- `clip30_fed.txt`: the stretch of `fed_transcript.txt` the clip covers,
  cut in R, with the PDF's curly apostrophes made straight; 01:00. Every
  clip run is scored against it.

**`logs/`.**

- `timings.tsv`: one line per clip run, with wall time and word counts.
- `full_turbo.log`, `full_base_nocond.log`: mlx-whisper's progress bar
  and the run time of those two full runs.
- `full_ecapa.txt`: the speaker run's windows, labels and seconds, then
  each Whisper segment with the label it got.
- `run_everything.log`: what each script prints, from the run of
  2 November 2026.
- `live_run.txt`: the terminal after the rehearsal of the live run
  (`replies/clip30_live.json`): the command, the segments as printed, the
  run time and the first lines of the reply.

**`tools/`.** The Python scripts behind the replies, copied unchanged,
and `SETUP.md`: the environment, the models and the exact command behind
each reply.

## The scripts, in lecture order

| Script | What it does |
|:--|:--|
| `1_words.R` | Whisper's reply as a table, one row per word; words and "you know" beside the Fed's transcript |
| `2_speakers.R` | the speaker segments, read from the RTTM file |
| `3_join_turns.R` | each word takes the label of the segment its midpoint falls in; turns; turns against the transcript |
| `4_utterances.R` | one row per turn: speaker, start, end, text |
| `5_pauses.R` | the pause before each of Powell's answers, the silence between words before each, speaking rate, "you know" in each answer |
| `6_wer.R` | word-error rate of the four runs on the 30-second clip |
| `align.R` | `align()`: where a run's words differ from the reference, one row per edit; sourced by `6_wer.R` |

`code/run_everything.R` runs them all, in order, in about two seconds,
and prints a `==== code/N_name.R ====` line before each script's output.
Each script reads `replies/` and what the scripts before it saved in
`data_clean/`, so any one of them runs on its own in a fresh R session.
They use base R and the jsonlite package, which each script loads and
installs if it is missing.

## What needs Python

Two replies cannot be rebuilt in R: `words.json`, the transcript with a
time on every word, and `speakers.rttm`, the speaker segments. Both came
from Python models run before class, as did the clip replies.
`tools/SETUP.md` gives the environment, the model versions and the
command line behind each one. With the replies saved here, the R scripts
need neither Python nor the audio.

## Where the raw data came from

- `fomc20230201_transcript.pdf`: Board of Governors of the Federal Reserve
  System, "Transcript of Chair Powell's Press Conference, February 1,
  2023", final version (23 pages, made 14 February 2023, 208,952 bytes),
  https://www.federalreserve.gov/mediacenter/files/FOMCpresconf20230201.pdf,
  linked from the conference's page,
  https://www.federalreserve.gov/monetarypolicy/fomcpresconf20230201.htm.
  US federal work, public domain. Downloaded 2 November 2026.
- `media/fomc20230201_270p.mp4`: the Fed's video of the conference, 44:37,
  the 270p MP4 (480 by 270, sound AAC 48 kHz stereo at 64 kb/s,
  172,509,888 bytes) served by the Brightcove player on the same page
  (account 66043936001, video 6319614734112). Downloaded 2 November 2026,
  in 28 s.
- `media/fomc20230201.wav`: the video's sound as 16 kHz mono 16-bit WAV,
  the form Whisper reads; ffmpeg 8.1.2, 8.5 s.
- `clips/`: the WAV clips cut from `fomc20230201.wav` with ffmpeg, without
  re-encoding (`open2min.wav` 0 to 120 s, `schneider30.wav` 969.6 to
  999.6 s); the MP3s made from them with ffmpeg's LAME encoder at 64 kb/s
  on 2 November 2026. `pause_2258.mp3`, `pause_4338.mp3` and `howard10.mp3`
  were cut straight from `fomc20230201.wav` to 64 kb/s mono MP3 the same
  day (no WAV kept); the commands are in `tools/SETUP.md`.
