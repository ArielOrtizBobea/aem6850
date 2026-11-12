# AEM 6850, session 22. Tool, run before class (in the Python environment of tools/requirements.txt)
# (open_clip_torch and opencv). Students do not run it: its outputs ship in data_clean/.
#
# Three steps on the frames tools/fed_frames.sh saved (one every 30 s of the Fed's 24 press
# conferences of 2021 to 2023), all on this laptop. Nothing is trained here: both models are
# used as their authors released them.
#   1. What the frame shows. An open embedding model (CLIP ViT-B/32, by OpenAI) embeds the
#      frame and four typed sentences; the closest sentence gets the largest share.
#   2. Where the face is. On frames whose top sentence is the speaker at the podium, an open
#      face detector (YuNet, from OpenCV's model zoo, a 230 KB file) returns a box per face;
#      the largest box at least 30 pixels wide is cut out with a margin and enlarged to
#      224 by 224 pixels into data_clean/fed_faces/<date>_<seconds>.jpg.
#      (OpenCV 5 no longer ships the older Haar-cascade face finder, so YuNet is used.)
#   3. What expression the face shows. The same embedding model scores each face crop
#      against four typed sentences.
# Writes data_clean/fed_frames.csv (one row per frame), data_clean/fed_expressions.csv (one
# row per face crop), replies/fed_typed_labels.json (the sentences) and a line in logs/.
#
#   python tools/fed_faces.py        from the 22-photos-ii folder, after bash tools/fed_frames.sh
import urllib.request
import csv, glob, json, os, time
from pathlib import Path
import cv2, torch, open_clip
from PIL import Image

sets = {
    "frame": ["a photo of a man in a suit speaking at a podium in front of flags",
              "a photo of a chart or a slide with text",
              "a photo of a reporter asking a question",
              "a screenshot of a video call with many people"],
    "expression": ["a photo of a happy, smiling face", "a photo of a neutral face",
                   "a photo of an angry face", "a photo of a worried or sad face"],
}
short = {"frame": ["speaker at the podium", "chart or slide", "reporter", "video call"],
         "expression": ["happy", "neutral", "angry", "worried"]}
os.makedirs("replies", exist_ok=True); os.makedirs("data_clean/fed_faces", exist_ok=True); os.makedirs("logs", exist_ok=True)
json.dump({"sentences": sets, "short_names": short}, open("replies/fed_typed_labels.json", "w"), indent=1)

t0 = time.time()
model, _, preprocess = open_clip.create_model_and_transforms("ViT-B-32", pretrained="openai"); model.eval()
tok = open_clip.get_tokenizer("ViT-B-32")
norm = torch.nn.functional.normalize
with torch.no_grad():
    T = {k: norm(model.encode_text(tok(v)), dim=-1) for k, v in sets.items()}

def shares(files, key):                       # one row of shares per image, for one set of sentences
    out = []
    with torch.no_grad():
        for i in range(0, len(files), 32):
            x = torch.stack([preprocess(Image.open(f).convert("RGB")) for f in files[i:i + 32]])
            out.append((100 * norm(model.encode_image(x), dim=-1) @ T[key].T).softmax(dim=-1))
    return torch.cat(out).numpy()

frames = sorted(glob.glob("data/fed/frames/fomc*/*.jpg"))
P = shares(frames, "frame")
yunet = Path("tools/weights/face_detection_yunet_2023mar.onnx")      # 230 KB, downloaded on the first run
if not yunet.exists():
    yunet.parent.mkdir(parents=True, exist_ok=True)
    urllib.request.urlretrieve("https://github.com/opencv/opencv_zoo/raw/main/models/face_detection_yunet/" + yunet.name, yunet)
det = cv2.FaceDetectorYN.create(str(yunet), "", (480, 270), 0.6)
rows, crops = [], []
for f, p in zip(frames, P):
    date, secs = Path(f).parent.name[4:], int(Path(f).stem)
    top = int(p.argmax()); r = dict(date=date, seconds=secs, shows=short["frame"][top], share=round(float(p[top]), 3),
                                    face_found="", x="", y="", w="", h="", face_score="", file="")
    if top == 0:
        im = cv2.imread(f); H, W = im.shape[:2]; det.setInputSize((W, H)); _, faces = det.detect(im)
        big = None if faces is None else max(faces, key=lambda a: a[2] * a[3])
        if big is not None and big[2] >= 30:
            x, y, w, h = [float(v) for v in big[:4]]; m = 0.25 * max(w, h)          # a margin around the box
            x1, y1, x2, y2 = int(max(0, x - m)), int(max(0, y - m)), int(min(W, x + w + m)), int(min(H, y + h + m))
            out = f"data_clean/fed_faces/{date}_{secs:05d}.jpg"
            cv2.imwrite(out, cv2.resize(im[y1:y2, x1:x2], (224, 224), interpolation=cv2.INTER_CUBIC), [cv2.IMWRITE_JPEG_QUALITY, 90])
            r.update(face_found=1, x=round(x), y=round(y), w=round(w), h=round(h), face_score=round(float(big[-1]), 3), file=out); crops.append((date, secs, out))
        else:
            r.update(face_found=0)
    rows.append(r)
with open("data_clean/fed_frames.csv", "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=list(rows[0].keys())); w.writeheader(); w.writerows(rows)
E = shares([c[2] for c in crops], "expression")
with open("data_clean/fed_expressions.csv", "w", newline="") as f:
    w = csv.writer(f); w.writerow(["date", "seconds", "file"] + short["expression"] + ["top"])
    for (date, secs, out), e in zip(crops, E):
        w.writerow([date, secs, out] + ["%.4f" % v for v in e] + [short["expression"][int(e.argmax())]])
secs = round(time.time() - t0)
chair = sum(r["shows"] == short["frame"][0] for r in rows)
print(len(rows), "frames |", chair, "show the speaker at the podium |", len(crops), "faces cut |", secs, "s")
with open("logs/fed_faces.log", "a") as f:
    f.write(f"{time.strftime('%Y-%m-%d %H:%M')} {len(rows)} frames, {chair} speaker frames, {len(crops)} face crops in {secs} s; "
            "CLIP ViT-B-32 (openai) typed labels, YuNet 2023mar face detector at score 0.6, largest face 30 px or wider\n")
