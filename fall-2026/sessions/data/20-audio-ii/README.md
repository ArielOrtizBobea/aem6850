# Session 20 data: FOMC press conferences, 2021-2023

The 24 press conferences that followed the scheduled FOMC meetings from January 2021 to
December 2023. Each conference was downloaded, transcribed with word timestamps, split into
speaker turns and scored for vocal emotion on 10-second windows. Built 2026-11-02 on an Apple
M2 Max (64 GB) with the scripts in `tools/`. Setup and versions are in `tools/SETUP.md`;
progress of the build is in `logs/STATUS.md`.

## Files

| Path | What it is |
|---|---|
| `data/meetings.csv` | one row per conference: `date`, Brightcove `video_id`, `duration_s` (WAV), `mp4_bytes`, `transcript_url` |
| `data/media/fomcYYYYMMDD_270p.mp4` | the Fed's video, 480x270 H.264 with AAC 48 kHz stereo audio (gitignored) |
| `data/media/fomcYYYYMMDD.wav` | the audio track as 16 kHz mono 16-bit PCM (gitignored) |
| `data/transcripts/FOMCpresconfYYYYMMDD.pdf` | the Fed's official transcript (edited: no "um" or "uh", few restarts) |
| `replies/words_YYYYMMDD.json` | mlx-whisper output as returned: `text`, `segments` with `start`, `end`, `text`, `avg_logprob`, `compression_ratio`, `no_speech_prob`, and `words` (`word`, `start`, `end`, `probability`) |
| `replies/words_YYYYMMDD_looped.json` | only for a conference the loop check flagged: the first transcription, kept for comparison |
| `replies/speakers_YYYYMMDD.rttm` | speaker turns, one line each: `SPEAKER fomcYYYYMMDD 1 <start> <duration> <NA> <NA> SPKnn <NA> <NA>` |
| `replies/emotion_YYYYMMDD.csv` | `window_start`, `window_end` (s), `arousal`, `dominance`, `valence` |
| `logs/steps.tsv` | one line per step per conference: `date`, `step`, `seconds`, `n`, `unit` (bytes, words, turns, windows), `detail`, `finished` |
| `logs/loopcheck.tsv` | the loop check for every transcription |
| `logs/failures.tsv` | steps that failed, with the reason |
| `logs/run_all.log` | console output of the background run |
| `logs/STATUS.md` | conferences finished per step, loops flagged, failures, how to resume |
| `code/1_words.R` ... `5_meetings.R`, `code/run_everything.R` | the R scripts that turn the replies into the tables in `data_clean/` (next section) |
| `data_clean/` | words, segments, utterances, tone and meetings tables, one CSV each |
| `logs/run_everything.log` | console output of `code/run_everything.R` |

Speaker labels are cluster numbers (`SPK00`, `SPK01`, ...) numbered by first appearance. They
are not names. The Chair is normally the cluster with the most speaking time.

## Sources

Dates. The Fed's calendar page, https://www.federalreserve.gov/monetarypolicy/fomccalendars.htm,
read 2026-11-02, lists eight scheduled meetings in each of 2021, 2022 and 2023, each with a
press-conference page `fomcpresconfYYYYMMDD.htm`, and no unscheduled meetings. The historical
pages `fomchistorical2021.htm` to `fomchistorical2023.htm` returned "Page not Found" that day,
because the main calendar still carries those years. The 24 dates match the expected list:

2021: Jan 27, Mar 17, Apr 28, Jun 16, Jul 28, Sep 22, Nov 3, Dec 15.
2022: Jan 26, Mar 16, May 4, Jun 15, Jul 27, Sep 21, Nov 2, Dec 14.
2023: Feb 1, Mar 22, May 3, Jun 14, Jul 26, Sep 20, Nov 1, Dec 13.

Video. Each press-conference page embeds one Brightcove video (account 66043936001, player
`default_default`; the id is in `data-video-id`). `tools/bc_url.py` reads the policy key from the
player's public `config.json`, asks the Playback API
(`edge.api.brightcove.com/playback/v1/accounts/66043936001/videos/<id>`) for the sources and
takes the HTTPS 270p MP4. The URL carries a short-lived token, so it is looked up again before
every download, and the file size is checked against the API's `size`. No account is needed.

Transcripts. `https://www.federalreserve.gov/mediacenter/files/FOMCpresconfYYYYMMDD.pdf`, the
link on each press-conference page.

## How each file was made

`tools/run_all.sh` runs these steps for each date in `data/meetings.csv` and skips any step whose
output already exists:

1. Download: `curl` of the 270p MP4 from the URL `bc_url.py` returns.
2. WAV: `ffmpeg -i fomcYYYYMMDD_270p.mp4 -vn -ac 1 -ar 16000 -c:a pcm_s16le fomcYYYYMMDD.wav`.
3. Transcript PDF: `curl` of `transcript_url`.
4. Transcription: `mlx_whisper fomcYYYYMMDD.wav --model mlx-community/whisper-large-v3-turbo
   --language en --word-timestamps True --output-format json --verbose False`. All other settings
   are the defaults: temperature 0 with fallback, conditioning on previous text, no initial prompt.
5. Loop check (`tools/loop_check.py`): the transcript is flagged when one segment's text repeats
   three or more times in a row, or when its word count is more than 20% above the `pdftotext`
   word count of the PDF (that count includes page headers and speaker names). Empty segments
   are skipped when counting repeats, because Whisper writes them between the copies of a loop.
   A flagged conference is transcribed again with `--condition-on-previous-text False`; the first
   output is renamed `words_YYYYMMDD_looped.json`. The check also logs the highest compression
   ratio among segments with text; above 2.4 (Whisper's own threshold) suggests repetition inside
   a single segment, which the two rules would miss. `logs/STATUS.md` lists any such transcript.
   Both refinements (skipping empty segments, ignoring them in the compression ratio) were added
   after the first conferences ran; the rows for 2021-01-27 and 2021-06-16 in
   `logs/loopcheck.tsv` were recomputed and say so. Neither change altered a flag.
6. Speaker labels (`tools/diarize_ecapa.py`, defaults): SpeechBrain ECAPA embeddings on 3-s
   windows every 1.5 s, CPU, batches of 8 windows; an energy rule keeps windows that are more than
   half speech (30-ms frames above 4 times the 20th percentile of energy); agglomerative
   clustering, average linkage, cosine distance threshold 0.7; runs of the same cluster merged
   into turns.
7. Emotion (`tools/emotion_windows.py`): the audeering model's regression head on consecutive
   10-s windows starting at 0 s, run on the Metal GPU (`mps`). Each window is normalised by the
   model's processor. The last window ends at the end of the file and is dropped only if shorter
   than 1 s.

The MP4 and WAV for 2023-02-01 were copied from the feasibility run of 2026-11-02 00:21, which
used the same download and `ffmpeg` commands; every other file was made by `run_all.sh`.

## data_clean/

Five CSV files made from `data/meetings.csv` and `replies/` by the R scripts in `code/` (base R
and `jsonlite`). Open `20-audio-ii.Rproj` and run `source("code/run_everything.R")`, or
`Rscript code/run_everything.R` from the project folder; the five scripts take about 6 s and
print what they did (`logs/run_everything.log`). Built 2026-11-02. The number in brackets is the
script that writes the file. Dates are written `2021-01-27`; times are seconds from the start of
the recording, the same clock as the video.

- `words.csv` (1): one row per word of the final transcript (the rerun where the loop check
  flagged the first pass): `date`, `word`, `start`, `end`, `probability`; 207,189 rows. The
  leading space Whisper puts on each word is trimmed. The speaker tags Whisper wrote as speech are
  removed: a tag is two or three words in capitals, the last ending in a period, standing after
  the end of a sentence or a dash, or at the start of the file. That drops 400 tags (800 words),
  from 0 (2023-02-01, 2023-05-03, 2023-06-14) to 44 (2021-04-28, 14 of them the "GREG ROBB."
  loop), and keeps "we bought MBS II." (2021-04-28) and three sentences of speech written in
  capitals (2022-06-15), which the count in `logs/STATUS.md` includes. Five of the JSON files hold
  a `NaN`, which is not valid JSON; script 1 reads it as missing.
- `segments.csv` (2): the speaker segments of the RTTM files: `date`, `start`, `end`,
  `speaker`; 2,094 rows, 65 to 193 per conference, 15 to 26 labels.
- `utterances.csv` (3): one row per turn: `date`, `turn` (1, 2, ... within each conference),
  `speaker`, `type`, `start`, `end`, `words`, `text`; 1,401 rows. Each word takes the label of
  the segment its midpoint falls in (`findInterval()`); a word in a gap between segments gets no
  label and is in no turn (2.0 to 5.4 percent of the words, 25 percent on 2023-05-03). A turn is
  a run of words with one label. Powell is the label with the most words in each conference
  (`SPK00`, except `SPK01` on 2023-05-03). `type` is `statement` for his first turn of two
  minutes or more, the prepared opening (349 to 549 s; 24 rows), `answer` for his later turns
  (608) and `other` for every other label (769), the moderator and the reporters. No Powell turn
  comes before the statement. The "Good afternoon." that opens most conferences comes before the
  first segment and has no label.
- `tone.csv` (4): `date`, `turn`, `speaker`, `type`, `start`, `end`, `words` as in
  `utterances.csv`, and `arousal`, `dominance`, `valence`: the mean of the 10-s emotion windows
  whose midpoints fall inside the utterance, rounded to 4 decimals; 1,401 rows. An utterance with
  no window midpoint inside it gets NA: 199 rows, 15 of them answers (median 2.6 s long). Windows
  that straddle a change of speaker count for the utterance that holds their midpoint. Pitch and
  energy are not here; the lecture computes them in R from the recordings.
- `meetings.csv` (5): one row per conference: `date`, `duration_s`, `n_turns`, `powell_label`,
  `powell_turns`, `powell_words`, `powell_answers` (answers in `tone.csv`), `arousal_answers` and
  `valence_answers` (the plain mean over his scored answers, each answer counting once),
  `decision`, `size_bp` and `upper`. `decision` is `hike` for the 11 meetings that raised the
  federal funds target range and `hold` for the other 13. The hikes, with their sizes, are typed
  in the script from the Fed's table of target-range changes,
  https://www.federalreserve.gov/monetarypolicy/openmarket.htm (read 2026-11-02), which dates
  each change the day after the announcement: 2022-03-16 (25 bp), 05-04 (50), 06-15 (75), 07-27
  (75), 09-21 (75), 11-02 (75), 12-14 (50), 2023-02-01 (25), 03-22 (25), 05-03 (25), 07-26 (25);
  none in 2021. `upper` is the top of the range after the decision, in percent, counted up from
  0.25 by those sizes.

The column names follow the build brief (`date`, `turn`). The session outline calls them
`conf_date` and `utt_id`, and names the speakers (Powell, Reporter, Moderator); the tables here
keep the cluster labels.

## Models

| Model | Revision | Licence |
|---|---|---|
| `mlx-community/whisper-large-v3-turbo` | `a4aaeec0` | none on the card; converted from OpenAI's MIT-licensed `whisper-large-v3-turbo` |
| `speechbrain/spkrec-ecapa-voxceleb` | `0f99f2d0` | Apache 2.0 |
| `audeering/wav2vec2-large-robust-12-ft-emotion-msp-dim` | `6eba34a2` | CC BY-NC-SA 4.0, research use only |

The audeering model was fine-tuned on the MSP-Podcast corpus. Its outputs are in the order
arousal, dominance, valence (`config.id2label`), roughly on a 0 to 1 scale. The model card's code
needs one change on transformers 5.x: `self.init_weights()` becomes `self.post_init()`. With it,
one second of silence gives the card's numbers (0.546, 0.606, 0.404).

## Run times

Every step's wall time is in `logs/steps.tsv`, one line per step per conference, and the table in
`logs/STATUS.md` is rebuilt after each conference. Medians over the first ten conferences
(2021-01-27 to 2022-01-26 and 2023-02-01), wall time including process start and model load:

| Step | Median s | Range s |
|---|---|---|
| download (213-236 MB) | 9.5 | 8.5-10.6 |
| WAV | 3.6 | 3.5-4.0 |
| transcript PDF | 0.3 | 0.3-0.6 |
| transcription, default conditioning | 197 | 180-236 |
| transcription, rerun without conditioning | 177 | 162-199 |
| speaker labels | 42 | 40-45 |
| emotion | 33 | 30-37 |

A conference takes about 4.7 minutes when the first transcription passes the loop check and
about 7.7 minutes when it is rerun. The first run on 2023-02-01 also downloaded the three models
(about 2.2 GB in the Hugging Face cache) inside its transcription and emotion steps. The full
background run started 2026-11-02 at 15:01.

## Caveats

- Whisper loops. With default conditioning, 8 of the first 10 conferences were flagged; every
  2021 conference except 2021-06-16 was. The worst first passes repeated one segment 358 times
  (2021-07-28, "Michael McKee at Bloomberg TV.") and 225 times (2021-09-22). The reruns without
  conditioning were clean except 2021-04-28, which still repeats "GREG ROBB." from 3037 to
  3052 s, where the reporter's opening sentences (about 18 s) are lost.
- Whisper also drops speech without looping. In the 2021-11-03 rerun one segment runs from
  450.5 to 471.2 s with nine words; about 20 s of the opening statement ("does not imply any
  direct signal ... We at the Fed will") is missing. Its compression ratio of 3.95 is what
  `logs/STATUS.md` lists. A word lasting several seconds ("everything", 451.7-466.8 s) is the
  sign to look for.
- Speaker tags in the transcript. In 21 of the 24 conferences Whisper writes the Fed
  transcript's speaker tags as if they were speech: "CHAIR POWELL.", "MICHELLE SMITH.", and
  sometimes a wrong name such as "CHAIR YELLEN." or "CHAIRMAN BERNANKE." They carry word
  timestamps and count as words (1 to 45 per conference; 15 to 45 in 2021). 2023-02-01,
  2023-05-03 and 2023-06-14 have none. `logs/STATUS.md` counts them per conference;
  `code/1_words.R` removes them before anything is counted.
- Last seconds. Several first passes end with "Thank you." repeated within the last half second
  of the file, which is what flagged 2021-03-17.
- Speaker clusters were not checked against the transcripts. The number of clusters is close to
  the number of speakers named in the PDF (for example 15 and 15 on 2021-01-27, 24 and 21 on
  2021-03-17), and the largest cluster holds 79 to 83% of the labelled time, which fits the
  Chair. In the feasibility run a 0.4-s "Howard." by the moderator was merged into the
  reporter who followed.
- The emotion scores come from a model trained on podcast speech, and every 10-s window is
  scored whoever is speaking. Windows that straddle a change of speaker mix two voices. On
  2023-02-01 the first window is mostly room noise; the Chair starts at 6.6 s.
- Whisper writes few "um" or "uh" with these settings, and the Fed's PDFs edit them out. In
  `data_clean/words.csv` they number 0 in 17 conferences, 1 to 11 in five, 53 on 2023-09-20 and
  95 on 2023-05-03, whose rerun also writes long stretches in lower case without punctuation.
