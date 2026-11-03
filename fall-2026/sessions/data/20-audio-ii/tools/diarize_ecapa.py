# Token-free speaker labelling: SpeechBrain ECAPA embeddings on sliding windows
# + agglomerative clustering (cosine). Writes RTTM; optionally labels Whisper words.
# Usage: python -I diarize_ecapa.py audio.wav out.rttm [whisper.json] [--win 3.0 --hop 1.5 --thr 0.7]
# Copied from the 2026-11-02 feasibility run; one change: savedir falls back to the default
# Hugging Face cache (~/.cache/huggingface) when HF_HOME is unset.
import sys, argparse, time, json, os
import numpy as np, soundfile as sf, torch
from huggingface_hub import snapshot_download
from speechbrain.inference.speaker import EncoderClassifier

p = argparse.ArgumentParser()
p.add_argument("wav"); p.add_argument("rttm"); p.add_argument("whisper", nargs="?")
p.add_argument("--win", type=float, default=3.0); p.add_argument("--hop", type=float, default=1.5)
p.add_argument("--thr", type=float, default=0.7, help="cosine distance threshold")
a = p.parse_args()
t0 = time.time()
x, sr = sf.read(a.wav, dtype="float32"); assert sr == 16000 and x.ndim == 1
local = snapshot_download("speechbrain/spkrec-ecapa-voxceleb")
enc = EncoderClassifier.from_hparams(source=local, savedir=os.path.join(os.environ.get("HF_HOME", os.path.expanduser("~/.cache/huggingface")), "sb_ecapa"),
                                     run_opts={"device": "cpu"})
t1 = time.time()
# crude energy VAD: 30 ms frames, speech if energy above 20th percentile * 4
f = int(0.03 * sr); n = len(x) // f
e = (x[: n * f].reshape(n, f) ** 2).mean(1)
speech = e > max(np.percentile(e, 20) * 4, 1e-6)
W, H = int(a.win * sr), int(a.hop * sr)
starts = [s for s in range(0, max(1, len(x) - W + 1), H)
          if speech[s // f:(s + W) // f].mean() > 0.5]
with torch.no_grad():
    embs = []
    for i in range(0, len(starts), 8):  # batches >=16 ran ~70x slower on CPU (torch 2.15, M2)
        b = torch.from_numpy(np.stack([x[s:s + W] for s in starts[i:i + 8]]))
        embs.append(enc.encode_batch(b).squeeze(1).numpy())
# sklearn imported only after torch work: loading both OpenMP runtimes first slowed embedding ~50x
from sklearn.cluster import AgglomerativeClustering
t_emb = time.time() - t1
E = np.concatenate(embs); E /= np.linalg.norm(E, axis=1, keepdims=True)
if len(E) > 1:
    lab = AgglomerativeClustering(n_clusters=None, metric="cosine", linkage="average",
                                  distance_threshold=a.thr).fit_predict(E)
else:
    lab = np.zeros(1, int)
# relabel by first appearance, assign each window centre region, merge runs
order = {}; lab = np.array([order.setdefault(l, len(order)) for l in lab])
turns = []
for s, l in zip(starts, lab):
    st, en = (s + (W - H) / 2) / sr, (s + (W + H) / 2) / sr
    if turns and turns[-1][2] == l and st - turns[-1][1] < 0.01 + a.hop:
        turns[-1][1] = en
    else:
        turns.append([st, en, l])
name = os.path.splitext(os.path.basename(a.wav))[0]
with open(a.rttm, "w") as out:
    for st, en, l in turns:
        out.write(f"SPEAKER {name} 1 {st:.2f} {en - st:.2f} <NA> <NA> SPK{l:02d} <NA> <NA>\n")
t2 = time.time()
print(f"windows={len(starts)} speakers={len(order)} turns={len(turns)} "
      f"load_s={t1 - t0:.1f} embed_s={t_emb:.1f} embed_cluster_s={t2 - t1:.1f} total_s={t2 - t0:.1f}")
if a.whisper:  # label each Whisper segment by majority of its words' midpoints
    j = json.load(open(a.whisper))
    centres = np.array([(s0 + W / 2) / sr for s0 in starts])
    def spk(t):  # label of the window whose centre is nearest
        return f"SPK{lab[np.abs(centres - t).argmin()]:02d}"
    for sg in j["segments"]:
        ws = [spk((w["start"] + w["end"]) / 2) for w in sg.get("words", [])]
        sg["speaker"] = max(set(ws), key=ws.count) if ws else "SPK??"
        print(f'[{sg["start"]:7.2f}-{sg["end"]:7.2f}] {sg["speaker"]}: {sg["text"].strip()[:90]}')
    json.dump(j, open(a.rttm.replace(".rttm", "_labelled.json"), "w"))
