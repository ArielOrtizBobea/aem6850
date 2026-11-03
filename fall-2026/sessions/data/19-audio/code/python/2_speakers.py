# =============================================================
# AEM 6850 - Session 19: Audio
# Python, before class: the speaker-label reply, replies/speakers.rttm.
#
# Cuts the recording into 3-second windows, one every 1.5 s, keeps those at
# least half speech, turns each into a voice embedding (numbers that sit
# close for the same voice) and clusters them; windows in one cluster share
# a label. Writes one line per labelled stretch, in RTTM format. Not run in
# class: about a minute on the instructor's laptop. code/2_speakers.R reads
# the file it writes.
#
# Needs the Python environment of tools/SETUP.md and
# data/media/fomc20230201.wav, which is not in the zip. No account: the
# voice model downloads from the model-hosting site on the first run.
#
#   python code/python/2_speakers.py         from the 19-audio folder
# =============================================================
import os, sys
import numpy as np, soundfile as sf, torch
from huggingface_hub import snapshot_download
from speechbrain.inference.speaker import EncoderClassifier

wav = sys.argv[1] if len(sys.argv) > 1 else "data/media/fomc20230201.wav"
out = sys.argv[2] if len(sys.argv) > 2 else "replies/speakers.rttm"
WIN, HOP, THR = 3.0, 1.5, 0.7          # window, step (seconds); cosine distance threshold

x, sr = sf.read(wav, dtype="float32"); assert sr == 16000 and x.ndim == 1
enc = EncoderClassifier.from_hparams(source=snapshot_download("speechbrain/spkrec-ecapa-voxceleb"),
                                     savedir=os.path.expanduser("~/.cache/sb_ecapa"),
                                     run_opts={"device": "cpu"})

# 1. Speech or not: 30-ms frames, speech if their energy is over 4 times the 20th percentile
f = int(0.03 * sr); n = len(x) // f
e = (x[: n * f].reshape(n, f) ** 2).mean(1)
speech = e > max(np.percentile(e, 20) * 4, 1e-6)
W, H = int(WIN * sr), int(HOP * sr)
starts = [s for s in range(0, max(1, len(x) - W + 1), H) if speech[s // f:(s + W) // f].mean() > 0.5]

# 2. One voice embedding per kept window (batches of 8: 16 or more ran ~70 times slower on CPU)
with torch.no_grad():
    E = np.concatenate([enc.encode_batch(torch.from_numpy(np.stack([x[s:s + W] for s in starts[i:i + 8]])))
                        .squeeze(1).numpy() for i in range(0, len(starts), 8)])
E /= np.linalg.norm(E, axis=1, keepdims=True)

# 3. Cluster the embeddings (scikit-learn imported only now: loaded before torch, it slowed it ~50 times)
from sklearn.cluster import AgglomerativeClustering
lab = AgglomerativeClustering(n_clusters=None, metric="cosine", linkage="average",
                              distance_threshold=THR).fit_predict(E)
order = {}; lab = [order.setdefault(l, len(order)) for l in lab]   # labels in order of first appearance

# 4. Each window labels its middle 1.5 s; neighbours with the same label merge into one stretch
turns = []
for s, l in zip(starts, lab):
    st, en = (s + (W - H) / 2) / sr, (s + (W + H) / 2) / sr
    if turns and turns[-1][2] == l and st - turns[-1][1] < 0.01 + HOP:
        turns[-1][1] = en
    else:
        turns.append([st, en, l])
name = os.path.splitext(os.path.basename(wav))[0]
with open(out, "w") as o:
    for st, en, l in turns:
        o.write(f"SPEAKER {name} 1 {st:.2f} {en - st:.2f} <NA> <NA> SPK{l:02d} <NA> <NA>\n")
print(len(starts), "windows,", len(order), "labels,", len(turns), "stretches ->", out)
