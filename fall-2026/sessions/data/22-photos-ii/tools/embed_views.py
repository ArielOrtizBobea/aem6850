# AEM 6850, session 22. Tool, run before class (in the Python environment of tools/requirements.txt)
# (open_clip_torch). Students do not run it.
#
# An open embedding model, already trained (CLIP ViT-B/32, by OpenAI), on this laptop. Nothing is
# trained here. Two outputs for the Ithaca views in data_clean/views/:
#   data_clean/view_embeddings.csv   512 numbers per view, e1 to e512
#   data_clean/typed_labels.csv      for each set of typed labels, the share the model gives each
#                                    label: the model embeds the photograph and each sentence, and
#                                    the closest sentence gets the largest share
#
#   python tools/embed_views.py      from the 22-photos-ii folder, after python tools/cut_views.py
import csv, json, time
import torch
from PIL import Image
import open_clip

sets = {
    "shows": ["a photo of a house", "a photo of an apartment building", "a photo of a store or an office building",
              "a photo of a parking lot", "a photo of trees or an empty lot", "a photo of a road with no buildings"],
    "porch": ["a photo of a house with a front porch", "a photo of a house with no porch"],
    "upkeep": ["a photo of a well-kept house", "a photo of a run-down house"],
}
json.dump(sets, open("replies/typed_labels.json", "w"), indent=1)
views = list(csv.DictReader(open("data_clean/views.csv")))
t0 = time.time()
model, _, preprocess = open_clip.create_model_and_transforms("ViT-B-32", pretrained="openai"); model.eval()
tok = open_clip.get_tokenizer("ViT-B-32")
with torch.no_grad():
    T = {k: torch.nn.functional.normalize(model.encode_text(tok(v)), dim=-1) for k, v in sets.items()}
    E = []
    for i in range(0, len(views), 32):
        x = torch.stack([preprocess(Image.open(v["file"]).convert("RGB")) for v in views[i:i + 32]])
        E.append(torch.nn.functional.normalize(model.encode_image(x), dim=-1))
    E = torch.cat(E)
    P = {k: (100 * E @ t.T).softmax(dim=-1).numpy() for k, t in T.items()}
with open("data_clean/view_embeddings.csv", "w", newline="") as f:
    w = csv.writer(f); w.writerow(["view"] + ["e%d" % k for k in range(1, 513)])
    for v, e in zip(views, E.numpy()): w.writerow([v["view"]] + ["%.5f" % a for a in e])
with open("data_clean/typed_labels.csv", "w", newline="") as f:
    w = csv.writer(f); w.writerow(["view", "set", "label", "share"])
    for k, labels in sets.items():
        for v, p in zip(views, P[k]):
            for lab, s in zip(labels, p): w.writerow([v["view"], k, lab.replace("a photo of ", ""), "%.4f" % s])
secs = round(time.time() - t0)
print(len(views), "views embedded in", secs, "s")
with open("logs/embed_views.log", "a") as f:
    f.write(f"{time.strftime('%Y-%m-%d %H:%M')} {len(views)} views, embeddings and shares for three sets of descriptions, in {secs} s; CLIP ViT-B-32 (openai)\n")
