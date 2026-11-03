# How the replies were made

Everything in `replies/` except the two reference texts came from Python
models run on the instructor's laptop on 2 November 2026, between 00:20
and 00:55 EST. The R scripts in `code/` only read these files. This page
records the machine, the environment, the models and the exact command
behind each file, so the runs can be repeated.

## The machine

- Apple M2 Max, 64 GB of memory, macOS (Darwin 27.2), arm64.
- mlx-whisper runs on the Apple GPU. The speaker model ran on the CPU.
- ffmpeg 8.1.2 and poppler's pdftotext 26.04.0, both from Homebrew.

## The Python environment

One virtual environment on Homebrew Python 3.11.11, made in about three
minutes:

```bash
/opt/homebrew/bin/python3.11 -m venv venv
venv/bin/pip install mlx-whisper faster-whisper speechbrain scikit-learn soundfile
export HF_HOME=$PWD/hf HF_HUB_DISABLE_TELEMETRY=1    # models download here
```

Versions installed: mlx-whisper 0.4.3, mlx 0.32.4, faster-whisper 1.2.1,
ctranslate2 4.8.4, speechbrain 1.1.2, torch 2.15.0, torchaudio 2.11.1,
scikit-learn 1.9.1, soundfile 0.14.0, numpy 2.4.6, huggingface_hub 2.4.0.

mlx-whisper needs an Apple-silicon Mac. On Windows or Linux, faster-whisper
(`run_fw.py`) runs the same Whisper models on the CPU; on the 2-minute
opening it took 12.5 s with base and 129.2 s with large-v3-turbo, and the
turbo run came out in lower case, without punctuation, and looped over the
last 2 seconds.

## The models

All are public on Hugging Face and need no account or token. Revision is
the commit that was downloaded.

| Model | Hugging Face repo | Revision | Download |
|:--|:--|:--|:--|
| Whisper large-v3-turbo | `mlx-community/whisper-large-v3-turbo` | `a4aaeec` | 1,539 MB, 110 s |
| Whisper base | `mlx-community/whisper-base-mlx` | `1e3e249` | 137 MB, 14 s |
| ECAPA speaker embeddings | `speechbrain/spkrec-ecapa-voxceleb` | `0f99f2d` | 85 MB |

## The scripts in this folder

Copied unchanged from the working folder they ran in. They expect that
folder's layout: `scripts/` (this folder), `venv/`, `hf/`, `audio/`
(the WAV files and every reply) and `out/` (timings). To run them again,
make such a folder and copy `tools/` into it as `scripts/`.

- `run_mlx.sh`: one mlx-whisper run with word timestamps; writes
  `audio/<clip>_mlx-<model>[_prompt].json` and adds a line to
  `out/timings.tsv`.
- `diarize_ecapa.py`: speaker labels without a token. ECAPA embeddings on
  3-second windows every 1.5 s, a simple energy filter for silence,
  agglomerative clustering (average linkage, cosine distance threshold
  0.7), and an RTTM file out.
- `wc_json.py`: words, segments, um and uh in a reply.
- `run_fw.py`, `batch_fw.sh`: the faster-whisper runs on the two clips
  (their replies are not shipped here).

## The media

```bash
# the Fed's page embeds a Brightcove player (account 66043936001, video
# 6319614734112); its public config holds the key for the Playback API
PK=$(curl -s https://players.brightcove.net/66043936001/default_default/config.json |
     python3 -c 'import json,sys;print(json.load(sys.stdin)["video_cloud"]["policy_key"])')
curl -s -H "Accept: application/json;pk=$PK" -o dl/bc_video.json \
  https://edge.api.brightcove.com/playback/v1/accounts/66043936001/videos/6319614734112
URL=$(python3 -c 'import json;print([s["src"] for s in json.load(open("dl/bc_video.json"))["sources"] if s.get("height")==270 and s["src"].startswith("https")][0])')
curl -s -o dl/fomc20230201_270p.mp4 "$URL"      # 172.5 MB, 28 s

ffmpeg -i dl/fomc20230201_270p.mp4 -vn -ac 1 -ar 16000 -c:a pcm_s16le audio/fomc20230201.wav   # 8.5 s
ffmpeg -i audio/fomc20230201.wav -t 120 -c copy audio/open2min.wav
ffmpeg -ss 969.6 -t 30 -i audio/fomc20230201.wav -c copy audio/schneider30.wav
```

The MP4 link carries a short-lived token, so ask the API afresh each time.
The Playback API also lists 360p (334 MB) and 540p (612 MB) files.

The MP3 copies in `data/clips/` were made on 2 November 2026 at 14:53 EST,
for the web page's audio player:

```bash
ffmpeg -i open2min.wav    -c:a libmp3lame -b:a 64k open2min.mp3
ffmpeg -i schneider30.wav -c:a libmp3lame -b:a 64k schneider30.mp3
```

The three short MP3s played in class were cut straight from the full WAV
on 2 November 2026 at 16:05 EST, from `data/media/` into `data/clips/`:

```bash
ffmpeg -ss 1370 -t 10 -i fomc20230201.wav -ac 1 -c:a libmp3lame -b:a 64k pause_2258.mp3   # 22:50 to 23:00
ffmpeg -ss 2610 -t 14 -i fomc20230201.wav -ac 1 -c:a libmp3lame -b:a 64k pause_4338.mp3   # 43:30 to 43:44
ffmpeg -ss 919  -t 10 -i fomc20230201.wav -ac 1 -c:a libmp3lame -b:a 64k howard10.mp3     # 15:19 to 15:29
ffmpeg -ss 1294 -t 6.4 -i fomc20230201.wav -ac 1 -c:a libmp3lame -b:a 64k yes6.mp3      # 21:34 to 21:40
```

## Each reply

Times are when the file was written, 2 November 2026, EST. Wall time
includes starting Python and loading a model already on disk.

**`words.json`**: the full conference (2,677 s), large-v3-turbo. Written
at 00:39:56, wall time 306.8 s, 8.7 times faster than the audio plays.
7,451 words in 1,711 segments; no loop (the largest compression ratio of
any segment is 1.86). Settings are mlx-whisper's defaults apart from those
on the command line. The working notes record this command for the clips
and the output name for the full file; the redirect is read off the log.

```bash
time -p venv/bin/mlx_whisper audio/fomc20230201.wav \
  --model mlx-community/whisper-large-v3-turbo --language en \
  --word-timestamps True --output-format json --output-dir audio \
  --output-name full_mlx-turbo --verbose False 2> out/full_turbo.log
```

**`words_base.json`**: the full conference, base model, the same command
with `--model mlx-community/whisper-base-mlx --output-name full_mlx-base`.
Written at 00:28:06, wall time 169.4 s. 10,302 words, but at 34:57 the
model fell into a loop and wrote "we are going to be cautious about the
fact that..." to the end: 4,414 words and 9.6 minutes of audio lost.

**`words_base_nocond.json`**: the same as `words_base.json` plus
`--condition-on-previous-text False`, so that each window is decoded
without the text before it. Written at 00:53:15, wall time 95.9 s. 7,264
words, no loop.

**`speakers.rttm`**: speaker labels for the full conference. Written at
00:48:02, wall time 57.8 s (0.4 s to load the model, 57.1 s to embed
1,566 windows). 19 labels, 86 segments.

```bash
venv/bin/python -I scripts/diarize_ecapa.py audio/fomc20230201.wav \
  audio/full_ecapa.rttm audio/full_mlx-turbo.json > out/full_ecapa.txt
# defaults: --win 3.0 --hop 1.5 --thr 0.7
```

Two things learned the hard way, noted in the script: on the CPU, batches
of 16 or more windows ran about 70 times slower than batches of 8, and
importing scikit-learn before the torch work slowed it about 50 times.

**`clip30_*.json`**: the 30-second clip `schneider30.wav` (969.6 to
999.6 s of the full file), four runs.

```bash
P="Um, uh, so, you know, I mean, like, I- I think, uh, we- we're"
scripts/run_mlx.sh audio/schneider30.wav base  mlx-community/whisper-base-mlx              # clip30_base.json
scripts/run_mlx.sh audio/schneider30.wav base  mlx-community/whisper-base-mlx "$P"         # clip30_base_prompt.json
scripts/run_mlx.sh audio/schneider30.wav turbo mlx-community/whisper-large-v3-turbo        # clip30_turbo.json
scripts/run_mlx.sh audio/schneider30.wav turbo mlx-community/whisper-large-v3-turbo "$P"   # clip30_turbo_prompt.json
```

| Reply | Written | Wall s | Words |
|:--|:--|--:|--:|
| `clip30_base.json` | 00:29:39 | 4.7 | 99 |
| `clip30_base_prompt.json` | 00:29:43 | 3.4 | 39, stops at 12.7 s |
| `clip30_turbo.json` | 00:30:29 | 8.5 | 104 |
| `clip30_turbo_prompt.json` | 00:30:38 | 8.6 | 112 |

The Words column counts word rows, the words that carry a time. For
`clip30_turbo_prompt.json` the `text` field holds 109 words: the word rows
give each of its three restart dashes ("would-", "We-", "we've-") a row of
its own, and the word-error rate in `code/7_wer.R` splits the `text` field.

## The two reference texts

`fed_transcript.txt` is the PDF's text layer, written at 00:57:23:

```bash
pdftotext data/fomc20230201_transcript.pdf replies/fed_transcript.txt
```

`clip30_fed.txt` is the stretch of it that the 30-second clip covers, cut
in R at 01:00:04 (the lines below, with this project's paths, rebuild it
byte for byte). It ends where the turbo run's clip ends ("a quarter of
the time." at 29.52 to 29.98 s), and the PDF's curly apostrophes are
straightened, since the models write straight ones:

```r
fed  <- paste(readLines("replies/fed_transcript.txt", encoding = "UTF-8", warn = FALSE), collapse = " ")
rest <- substring(fed, regexpr("So I guess I would say it this way", fed, fixed = TRUE))
to   <- regexpr("a quarter of the", rest, fixed = TRUE) + nchar("a quarter of the") - 1
writeLines(gsub("’", "'", substr(rest, 1, to)), "replies/clip30_fed.txt")
```

## Logs

- `logs/timings.tsv`: one line per clip run, as `run_mlx.sh` and
  `batch_fw.sh` wrote it. The line `fomc20230201_mlx-turbo wall_s=222.2`
  is a first attempt at the full file through `run_mlx.sh` that left no
  reply; `words.json` comes from the run in `full_turbo.log`.
- `logs/full_turbo.log`, `logs/full_base_nocond.log`: mlx-whisper's
  progress bar and the `time -p` lines of those two runs. No log was kept
  for the looped base run.
- `logs/full_ecapa.txt`: the speaker run's summary line and each Whisper
  segment with the label it got.

## Speaker labels with pyannote

pyannote, the usual speaker model, was not used: its models are gated and
need a Hugging Face account and token. To use it, create an account at
huggingface.co, accept the conditions on
`huggingface.co/pyannote/speaker-diarization-3.1` and
`huggingface.co/pyannote/segmentation-3.0` (pyannote.audio 4 uses
`pyannote/speaker-diarization-community-1`, also gated), make a read token
under Settings > Access Tokens, and store it with `hf auth login` or as
`HF_TOKEN` in `~/.zshrc` (or `~/.Renviron` for R).

## The R route

The live run in class uses R, not Python: the audio.whisper package runs
the same open Whisper models through whisper.cpp, a C++ version of them,
on the laptop. It made none of the shipped replies. Everything below was
done on the instructor's laptop on 2 and 3 November 2026.

**The package.** audio.whisper 0.5.0 is on neither CRAN nor r-universe, so
R compiles it from source once. The build calls cmake, which this Mac
lacked, and needs the Xcode command line tools. cmake came from pip in a
throwaway environment (Homebrew's `brew install cmake` does the same), and
the 0.5.0 release tarball from GitHub went through `R CMD INSTALL`, in 66 s
with ten parallel jobs. Metal and Accelerate are built in by default on a
Mac: the build log says "Including METAL backend" and "Including BLAS
backend".

```bash
python3 -m venv ~/cmake-env && ~/cmake-env/bin/pip install cmake
export PATH=~/cmake-env/bin:$PATH
curl -L -o audio.whisper_0.5.0.tar.gz \
  https://github.com/bnosac/audio.whisper/archive/refs/tags/0.5.0.tar.gz
MAKEFLAGS=-j10 R CMD INSTALL audio.whisper_0.5.0.tar.gz      # 66 s
```

The same from R, with cmake on the PATH; it compiles only when the package
is missing:

```r
want <- c("remotes")
need <- want[!(want %in% installed.packages()[,"Package"])]
if (length(need)) install.packages(need)
if (!requireNamespace("audio.whisper", quietly = TRUE))
  remotes::install_github("bnosac/audio.whisper", ref = "0.5.0")
library(audio.whisper)
```

**The models.** One line per model file, from the project folder, into
`data/media/models/` (kept out of git and out of the zip). Download times
here: base 5.5 s, small 16.9 s, large-v3-turbo 54.4 s, large-v3 93.5 s.

```r
whisper_download_model("large-v3-turbo", model_dir = "data/media/models", overwrite = FALSE)
whisper_download_model("base",           model_dir = "data/media/models", overwrite = FALSE)
```

**The live run.** From the project folder, in a fresh R session:

```r
library(audio.whisper)
m   <- whisper("data/media/models/ggml-large-v3-turbo.bin", use_gpu = TRUE)
out <- predict(m, "data/clips/schneider30.wav", token_timestamps = TRUE)
out$data[1:3, c("from", "text")]
```

`use_gpu = TRUE` runs the model on the Apple GPU through Metal; the default,
`FALSE`, runs it on the CPU. Rehearsed 3 November 2026 at 00:03 EST:
`predict()` took 1.6 to 2.2 s and `whisper()` 0.9 to 1.1 s, and a fresh R
session doing everything took 3.2 to 3.8 s wall (mlx-whisper: 8.5 s). The
first Metal load on this Mac once took 10.9 s. The console is in
`logs/live_run_r.txt`. `out$data` has one row per segment (`segment`,
`segment_offset`, `from`, `to`, `text`); `out$tokens` one row per token
(`segment`, `token_id`, `token`, `token_prob`, `token_from`, `token_to`).
A token is a piece of a word (126 tokens for the clip's 101 words); a
token that starts with a space starts a word.

The run writes 101 words in 10 segments. Against `clip30_turbo.json` (104
words) it drops one "you know" and does not guess "time." at the cut;
against `clip30_fed.txt` it makes 4 deletions, a word-error rate of 0.038.

**Run times.** `predict()` alone with `language = "en"`, `n_threads = 8`,
the model already loaded; word-error rate on the 30-second clip against
`clip30_fed.txt`, scored with `to_words()` and `word_edits()` from
`code/7_wer.R`.

| Model file | Size | Clip, Metal | Clip, CPU | The 44:37 conference | Words | Word-error rate |
|:--|--:|--:|--:|:--|--:|--:|
| `ggml-base.bin` | 148 MB | 1.1 s | 1.2 s | 33.7 s, Metal | 101 | 0.067 |
| `ggml-small.bin` | 488 MB | 1.1 s | 4.1 s | 3 min 48 s, CPU | 102 | 0.067 |
| `ggml-large-v3-turbo.bin` | 1,625 MB | 2.3 s | 13.2 s | 2 min 5 s, Metal; 13 min 3 s, CPU | 101 | 0.038 |
| `ggml-large-v3.bin` | 3,095 MB | 3.7 s | not run | not run | 100 | 0.048 |

On the full file large-v3-turbo looped once, on Metal and on the CPU alike:
"I don't think there's a much more information on the market." eight times
from 32:34 to 32:39 (on the CPU, another sentence 14 times to 32:45). Base
on Metal and small on the CPU had no loop.

**No speaker labels.** `predict(..., diarize = TRUE)` only splits a stereo
file by the energy in each channel, and the WAV is mono. The tinydiarize
model is not in `whisper_download_model()`'s list. `speakers.rttm` needs
the Python speaker model above.
