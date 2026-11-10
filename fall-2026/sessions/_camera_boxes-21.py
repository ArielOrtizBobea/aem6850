# AEM 6850 - Session 21: the four city camera frames on the slide "Cameras that cover a place over time".
# Tool, run before class in the Python environment ~/.venvs/vision (ultralytics). Students do not run it.
#
# Takes one saved frame from each of four New York City DOT traffic cameras
# (https://webcams.nyctmc.org/api/cameras, no key; frames saved from the feed on
# 2026-11-09, with a cameras.csv beside the frames folder), copies them to figures/21-photos/camera_src/
# and writes the boxes an open object detector draws on each, at confidence 0.25 or more.
# _figures-21.R, block camera_frames, draws the figure from these files.
#
#   ~/.venvs/vision/bin/python _camera_boxes-21.py <frames folder> <cam>=<stamp> ...     from fall-2026/sessions
import csv, shutil, sys
from pathlib import Path
from ultralytics import YOLO

frames = Path(sys.argv[1]); picks = [a.split("=") for a in sys.argv[2:]]
out = Path("figures/21-photos/camera_src"); out.mkdir(parents=True, exist_ok=True)
names = {r["cam"]: r["name"] for r in csv.DictReader(open(frames.parent / "cameras.csv"))}
det = YOLO(str(Path.home() / ".venvs/vision/weights/yolo11n.pt"))
vehicles = {"car", "truck", "bus", "motorcycle"}
rows = []
for cam, stamp in picks:
    src = frames / cam / f"{stamp}.jpg"; dst = out / f"{cam}.jpg"; shutil.copy(src, dst)
    r = det.predict(str(dst), conf=0.25, verbose=False)[0]
    n = 0
    for b in r.boxes:
        label = r.names[int(b.cls)]
        if label not in vehicles: continue
        x1, y1, x2, y2 = (round(v) for v in b.xyxy[0].tolist()); n += 1
        rows.append(dict(cam=cam, name=names[cam], stamp=stamp, label=label, conf=round(float(b.conf), 3), x1=x1, y1=y1, x2=x2, y2=y2))
    if n == 0: rows.append(dict(cam=cam, name=names[cam], stamp=stamp, label="", conf="", x1="", y1="", x2="", y2=""))
    print(cam, names[cam], stamp, n, "vehicles at 0.25 or more")
with open(out / "boxes.csv", "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=list(rows[0].keys())); w.writeheader(); w.writerows(rows)
