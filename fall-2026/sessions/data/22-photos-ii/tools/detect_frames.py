# AEM 6850, session 22. Tool, run before class (in the Python environment of tools/requirements.txt).
# Students do not need to run it: its output ships as data_clean/boxes.csv and frames.csv.
#
# Runs an open pre-trained object detector (YOLO11 nano, 2.6 million weights, trained by its
# authors on the COCO photographs, 80 classes) on every saved camera frame, on this laptop.
# Nothing is trained here. Writes one row per detected object at confidence 0.10 or more
# (vehicles, people and bicycles), and one row per frame.
#
# The weights file (yolo11n.pt, 5.6 MB) downloads itself into tools/weights/ on the first run.
# The detector gives the same boxes on every run, so this reproduces data_clean/boxes.csv exactly.
#
#   python tools/detect_frames.py        from the 22-photos-ii folder
import csv, glob, os, time
from pathlib import Path
from ultralytics import YOLO

os.makedirs("tools/weights", exist_ok=True)
det = YOLO("tools/weights/yolo11n.pt")            # downloaded on the first run
keep = {"car", "truck", "bus", "motorcycle", "person", "bicycle"}
files = sorted(glob.glob("data/cameras/frames/*/*.jpg"))
t = time.time(); n = 0
with open("data_clean/boxes.csv", "w", newline="") as fb, open("data_clean/frames.csv", "w", newline="") as ff:
    wb = csv.writer(fb); wb.writerow(["cam", "stamp", "label", "conf", "x1", "y1", "x2", "y2"])
    wf = csv.writer(ff); wf.writerow(["cam", "stamp", "file"])
    for f in files:
        cam, stamp = Path(f).parent.name, Path(f).stem
        try:
            r = det.predict(f, conf=0.10, verbose=False)[0]
        except Exception as e:                      # a frame the feed returned half-written
            print("skipped", f, e); continue
        wf.writerow([cam, stamp, f]); n += 1
        for b in r.boxes:
            label = r.names[int(b.cls)]
            if label in keep:
                wb.writerow([cam, stamp, label, round(float(b.conf), 3)] + [round(v) for v in b.xyxy[0].tolist()])
secs = round(time.time() - t)
print(n, "frames in", secs, "s")
with open("logs/detect_frames.log", "a") as f:
    f.write(f"{time.strftime('%Y-%m-%d %H:%M')} {n} frames in {secs} s, yolo11n.pt, confidence 0.10 or more, device default\n")
