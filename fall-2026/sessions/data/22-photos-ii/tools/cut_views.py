# AEM 6850, session 22. Tool, run before class in a Python environment with numpy and Pillow
# (tools/requirements.txt). Students do not need to run it: its output ships as data_clean/views/.
#
# Each street panorama is a full circle around the car, 4096 by 2048 pixels, with the direction
# of travel in the middle. This cuts two ordinary photographs from it, 800 by 600 pixels and 80
# degrees wide: one looking left of the car and one looking right, which face the houses on
# either side of the street. Writes data_clean/views.csv, one row per view.
#
#   python tools/cut_views.py        from the 22-photos-ii folder, after Rscript tools/pull_ithaca.R
import csv, os
import numpy as np
from PIL import Image

def view(pano, yaw_deg, fov=80, W=800, H=600, pitch_deg=5):
    h, w = pano.shape[:2]; f = (W / 2) / np.tan(np.radians(fov) / 2)
    x, y = np.meshgrid(np.arange(W) - W / 2, np.arange(H) - H / 2)
    d = np.stack([x, -y, np.full_like(x, f, dtype=float)], -1); d /= np.linalg.norm(d, axis=-1, keepdims=True)
    p, yw = np.radians(pitch_deg), np.radians(yaw_deg)
    Rx = np.array([[1, 0, 0], [0, np.cos(p), np.sin(p)], [0, -np.sin(p), np.cos(p)]])
    Ry = np.array([[np.cos(yw), 0, np.sin(yw)], [0, 1, 0], [-np.sin(yw), 0, np.cos(yw)]])
    d = d @ Rx.T @ Ry.T
    lon = np.arctan2(d[..., 0], d[..., 2]); lat = np.arcsin(np.clip(d[..., 1], -1, 1))
    return pano[np.clip(((0.5 - lat / np.pi) * h).astype(int), 0, h - 1), ((lon / (2 * np.pi) + 0.5) * w).astype(int) % w]

os.makedirs("data_clean/views", exist_ok=True); rows = []
for r in csv.DictReader(open("data/ithaca/panoramas.csv")):
    pano = np.asarray(Image.open(os.path.join("data/ithaca/panoramas", r["file"])).convert("RGB"))
    for side, yaw in (("L", -90), ("R", 90)):
        name = f'{r["id"]}_{side}.jpg'
        Image.fromarray(view(pano, yaw)).save(os.path.join("data_clean/views", name), quality=85)
        rows.append(dict(view=name[:-4], panorama=r["id"], side=side, date=r["date"], time=r["time"], lon=r["lon"], lat=r["lat"],
                         heading=r["heading"], drive=r["sequence"], file="data_clean/views/" + name))
with open("data_clean/views.csv", "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=list(rows[0].keys())); w.writeheader(); w.writerows(rows)
print(len(rows), "views from", len(rows) // 2, "panoramas")
