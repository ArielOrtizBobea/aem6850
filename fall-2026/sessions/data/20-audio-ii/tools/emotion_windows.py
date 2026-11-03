# Speech emotion (arousal, dominance, valence) on consecutive 10-s windows of a 16 kHz mono WAV.
# Model: audeering/wav2vec2-large-robust-12-ft-emotion-msp-dim (CC BY-NC-SA 4.0, research only).
# The two classes are the model card's code, with init_weights() replaced by post_init()
# (needed on transformers 5.x), as in the 2026-11-02 feasibility run (modelcard_fixed.py).
#
# Usage: python -I emotion_windows.py audio.wav out.csv [--win 10] [--device mps]
# Output columns: window_start, window_end, arousal, dominance, valence (seconds; scores ~0 to 1).
# Windows start at 0, 10, 20, ... s; the last one ends at the end of the file and is kept if it
# is at least --min seconds long (default 1 s).
import argparse, csv, os, time
import numpy as np, soundfile as sf, torch
import torch.nn as nn
from transformers import Wav2Vec2Processor
from transformers.models.wav2vec2.modeling_wav2vec2 import (
    Wav2Vec2Model,
    Wav2Vec2PreTrainedModel,
)


class RegressionHead(nn.Module):
    r"""Classification head."""

    def __init__(self, config):

        super().__init__()

        self.dense = nn.Linear(config.hidden_size, config.hidden_size)
        self.dropout = nn.Dropout(config.final_dropout)
        self.out_proj = nn.Linear(config.hidden_size, config.num_labels)

    def forward(self, features, **kwargs):

        x = features
        x = self.dropout(x)
        x = self.dense(x)
        x = torch.tanh(x)
        x = self.dropout(x)
        x = self.out_proj(x)

        return x


class EmotionModel(Wav2Vec2PreTrainedModel):
    r"""Speech emotion classifier."""

    def __init__(self, config):

        super().__init__(config)

        self.config = config
        self.wav2vec2 = Wav2Vec2Model(config)
        self.classifier = RegressionHead(config)
        self.post_init()

    def forward(
            self,
            input_values,
    ):

        outputs = self.wav2vec2(input_values)
        hidden_states = outputs[0]
        hidden_states = torch.mean(hidden_states, dim=1)
        logits = self.classifier(hidden_states)

        return hidden_states, logits


p = argparse.ArgumentParser()
p.add_argument("wav"); p.add_argument("csv")
p.add_argument("--win", type=float, default=10.0)
p.add_argument("--min", type=float, default=1.0, help="drop a final window shorter than this (s)")
p.add_argument("--device", default="mps" if torch.backends.mps.is_available() else "cpu")
a = p.parse_args()

t0 = time.time()
model_name = "audeering/wav2vec2-large-robust-12-ft-emotion-msp-dim"
processor = Wav2Vec2Processor.from_pretrained(model_name)
model = EmotionModel.from_pretrained(model_name).to(a.device).eval()
labels = [model.config.id2label[i] for i in range(model.config.num_labels)]
assert labels == ["arousal", "dominance", "valence"], labels
x, sr = sf.read(a.wav, dtype="float32")
assert sr == 16000 and x.ndim == 1, (sr, x.shape)
t1 = time.time()

W = int(a.win * sr)
rows = []
with torch.no_grad():
    for s in range(0, len(x), W):
        seg = x[s:s + W]
        if len(seg) < a.min * sr:
            break
        y = processor(seg, sampling_rate=sr)["input_values"][0].reshape(1, -1)
        out = model(torch.from_numpy(y).to(a.device))[1][0].detach().cpu().numpy()
        rows.append((s / sr, (s + len(seg)) / sr, *out.tolist()))
t2 = time.time()

tmp = a.csv + ".part"
with open(tmp, "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["window_start", "window_end", "arousal", "dominance", "valence"])
    for r in rows:
        w.writerow([f"{r[0]:.2f}", f"{r[1]:.2f}"] + [f"{v:.6f}" for v in r[2:]])
os.replace(tmp, a.csv)
print(f"windows={len(rows)} device={a.device} load_s={t1 - t0:.1f} score_s={t2 - t1:.1f} "
      f"per_window_s={(t2 - t1) / max(1, len(rows)):.3f} total_s={time.time() - t0:.1f}")
