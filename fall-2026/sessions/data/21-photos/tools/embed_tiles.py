# AEM 6850 - Session 21: Photographs I
# Tool, run before class in the Python environment ~/.venvs/vision (open_clip_torch).
# Students do not run it.
#
# One embedding per Beijing photograph: an open embedding model, already trained,
# turns each tile in data_clean/tiles/ into 512 numbers that describe the whole
# photograph. Writes data_clean/tile_embeddings.csv: one row per day, the date and
# e1 to e512. code/3_judge.R fits a regression on these numbers.
#
#   ~/.venvs/vision/bin/python tools/embed_tiles.py      from the project folder
import csv, glob, os
import torch
from PIL import Image
import open_clip

tiles = sorted(glob.glob("data_clean/tiles/*.jpg"))
model, _, preprocess = open_clip.create_model_and_transforms("ViT-B-32", pretrained="openai")
model.eval()
rows = []
with torch.no_grad():
    for i in range(0, len(tiles), 32):
        x = torch.stack([preprocess(Image.open(f).convert("RGB")) for f in tiles[i:i + 32]])
        e = model.encode_image(x)
        e = e / e.norm(dim=-1, keepdim=True)          # every list scaled to length 1
        for f, v in zip(tiles[i:i + 32], e.numpy()):
            rows.append([os.path.basename(f)[:-4]] + ["%.5f" % a for a in v])
with open("data_clean/tile_embeddings.csv", "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["date"] + ["e%d" % k for k in range(1, 513)])
    w.writerows(rows)
print(len(rows), "photographs,", len(rows[0]) - 1, "numbers each")
