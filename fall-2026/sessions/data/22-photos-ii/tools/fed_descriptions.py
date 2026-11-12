# AEM 6850, session 22. Tool, run before class (in the Python environment of tools/requirements.txt).
#
# The pre-trained model (CLIP ViT-B/32) has no fixed list of answers: it picks among whatever
# descriptions it is given. This runs the saved face crops (data_clean/fed_faces/) against three
# different sets of descriptions and writes, for each set, the share of faces given each answer.
# Nothing is trained. Output: data_clean/fed_expressions_sets.csv.
#
#   python tools/fed_descriptions.py        from the 22-photos-ii folder, after python tools/fed_faces.py
import csv, glob, time
import torch, open_clip
from PIL import Image

sets = {
    "four, as on the slides": ["a happy, smiling face", "a neutral face", "an angry face", "a worried or sad face"],
    "five, adding serious": ["a happy, smiling face", "a neutral face", "an angry face", "a worried or sad face", "a serious, focused face"],
    "two, smiling or not": ["a smiling face", "a face that is not smiling"],
}
files = sorted(glob.glob("data_clean/fed_faces/*.jpg")); t0 = time.time()
model, _, preprocess = open_clip.create_model_and_transforms("ViT-B-32", pretrained="openai"); model.eval()
tok = open_clip.get_tokenizer("ViT-B-32"); norm = torch.nn.functional.normalize
with torch.no_grad():
    E = torch.cat([norm(model.encode_image(torch.stack([preprocess(Image.open(f).convert("RGB")) for f in files[i:i + 32]])), dim=-1)
                   for i in range(0, len(files), 32)])
    rows = []
    for name, labels in sets.items():
        T = norm(model.encode_text(tok(["a photo of " + l for l in labels])), dim=-1)
        top = (100 * E @ T.T).softmax(dim=-1).argmax(dim=-1)
        for k, l in enumerate(labels):
            rows.append([name, l, int((top == k).sum()), round(float((top == k).float().mean()), 3)])
with open("data_clean/fed_expressions_sets.csv", "w", newline="") as f:
    w = csv.writer(f); w.writerow(["set", "description", "faces", "share"]); w.writerows(rows)
secs = round(time.time() - t0)
for r in rows: print(r)
with open("logs/fed_descriptions.log", "a") as f:
    f.write(f"{time.strftime('%Y-%m-%d %H:%M')} {len(files)} faces, {len(sets)} sets of descriptions, in {secs} s; CLIP ViT-B-32 (openai)\n")
