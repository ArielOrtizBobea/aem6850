# AEM 6850 - Session 21: Photographs I
# Tool, run before class in the Python environment ~/.venvs/vision
# (ultralytics, open_clip_torch). Students do not run it.
#
# On the one street photo data/street/porlamar.jpg: the boxes an open object
# detector draws (with its confidence for each), the masks an open segmenter
# draws, and the embedding an open image model returns. Writes data_clean/street/.
#
#   ~/.venvs/vision/bin/python tools/detect_street.py      from the project folder
import csv, json
from pathlib import Path
import numpy as np, torch
from PIL import Image
from ultralytics import YOLO
import open_clip

img = Path("data/street/porlamar.jpg")
out = Path("data_clean/street"); out.mkdir(parents=True, exist_ok=True)

# 1. boxes, at a low cutoff so the cutoff can be chosen afterwards
det = YOLO(str(Path.home() / ".venvs/vision/weights/yolo11n.pt"))
r = det.predict(str(img), conf=0.10, verbose=False)[0]
rows = []
for b in r.boxes:
    x1, y1, x2, y2 = b.xyxy[0].tolist()
    rows.append(dict(label=r.names[int(b.cls)], conf=round(float(b.conf), 3),
                     x1=round(x1), y1=round(y1), x2=round(x2), y2=round(y2)))
with open(out / "boxes.csv", "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=list(rows[0].keys())); w.writeheader(); w.writerows(rows)
Image.fromarray(r.plot(line_width=4, font_size=28)[:, :, ::-1]).save(out / "boxes_010.jpg", quality=90)
r50 = det.predict(str(img), conf=0.50, verbose=False)[0]
Image.fromarray(r50.plot(line_width=4, font_size=28)[:, :, ::-1]).save(out / "boxes_050.jpg", quality=90)

# 2. masks
seg = YOLO(str(Path.home() / ".venvs/vision/weights/yolo11n-seg.pt"))
s = seg.predict(str(img), conf=0.25, verbose=False)[0]
Image.fromarray(s.plot(boxes=False, labels=False, line_width=1)[:, :, ::-1]).save(out / "masks.jpg", quality=90)

# 3. embedding
model, _, preprocess = open_clip.create_model_and_transforms("ViT-B-32", pretrained="openai")
with torch.no_grad():
    e = model.encode_image(preprocess(Image.open(img).convert("RGB")).unsqueeze(0))[0]
e = (e / e.norm()).numpy()
np.savetxt(out / "embedding.csv", e[None, :], delimiter=",", fmt="%.5f")

labels = sorted(set(x["label"] for x in rows))
print(len(rows), "boxes at conf>=0.10;", len(r50.boxes), "at conf>=0.50;",
      0 if s.masks is None else len(s.masks), "masks;", e.shape[0], "embedding numbers")
print(json.dumps({"labels": labels, "cars_010": sum(x["label"]=="car" for x in rows),
                  "cars_050": sum(r50.names[int(b.cls)]=="car" for b in r50.boxes),
                  "persons_050": sum(r50.names[int(b.cls)]=="person" for b in r50.boxes)}))
