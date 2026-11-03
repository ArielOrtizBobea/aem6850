# Setup

One Python environment runs every step. Built 2026-11-02 on an Apple M2 Max (64 GB), macOS 27.2,
Homebrew Python 3.11.11, ffmpeg 8.1.2 and pdftotext (poppler) 26.04.0. mlx-whisper needs Apple
silicon; the emotion model uses the Metal GPU through PyTorch's `mps` device.

## System tools

```bash
brew install python@3.11 ffmpeg poppler      # poppler provides pdftotext
```

## Python environment

```bash
/opt/homebrew/bin/python3.11 -m venv ~/.venvs/aem6850-audio
~/.venvs/aem6850-audio/bin/pip install --upgrade pip
~/.venvs/aem6850-audio/bin/pip install mlx-whisper==0.4.3 speechbrain==1.1.2 scikit-learn==1.9.1 \
  soundfile==0.14.0 torch==2.15.0 torchaudio==2.11.1 transformers==5.22.1 librosa==0.11.0 \
  numpy==2.4.6 huggingface_hub==2.4.0
```

The install took 43 s with a warm pip cache; the venv is 1.5 GB. These are the versions the
2026-11-02 feasibility runs used. Resolved dependencies of note: mlx 0.32.4, scipy 1.17.1,
tokenizers 0.23.3, safetensors 0.8.0, tiktoken 0.14.0, numba 0.68.1.

## Models

Downloaded on first use into the default Hugging Face cache (`~/.cache/huggingface/hub`). None is
gated and no account or token is needed.

| Model | Used by | Size | Licence |
|---|---|---|---|
| `mlx-community/whisper-large-v3-turbo` | `mlx_whisper` | 1.5 GB | none on the card; converted from `openai/whisper-large-v3-turbo` (MIT) |
| `speechbrain/spkrec-ecapa-voxceleb` | `diarize_ecapa.py` | 85 MB | Apache 2.0 |
| `audeering/wav2vec2-large-robust-12-ft-emotion-msp-dim` | `emotion_windows.py` | 661 MB | CC BY-NC-SA 4.0 (research only) |

SpeechBrain also writes a small folder of links at `~/.cache/huggingface/sb_ecapa`.

## Scripts

| File | What it does |
|---|---|
| `meetings.py` | `ids` reads the Fed calendar and each press-conference page into `data/meetings.csv`; `fill` adds durations and MP4 sizes |
| `bc_url.py` | resolves a Brightcove video id to its 270p MP4 URL (fresh token) |
| `run_all.sh` | the driver: download, WAV, PDF, transcription, loop check, speaker labels, emotion |
| `loop_check.py` | flags a transcript with a segment repeated 3+ times in a row or 20% more words than the PDF |
| `diarize_ecapa.py` | ECAPA embeddings on 3-s windows every 1.5 s, energy VAD, agglomerative clustering, RTTM |
| `emotion_windows.py` | arousal, dominance, valence on consecutive 10-s windows |
| `status.py` | writes `logs/STATUS.md` |

Run everything from the project folder:

```bash
cd ~/github/aem6850/fall-2026/sessions/data/20-audio-ii
~/.venvs/aem6850-audio/bin/python -I tools/meetings.py ids     # once
nohup caffeinate -i tools/run_all.sh >> logs/run_all.log 2>&1 &
```

`caffeinate -i` keeps the Mac awake while the run lasts and has no effect after it ends.
