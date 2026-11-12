# 22-photos-ii

The project for AEM 6850, session 22, Photographs II (Thursday, November 12,
2026): the objects in photographs turned into counts and labels, and each judged
against what a look at the same photograph says. Three applications: vehicles in
New York City traffic-camera frames, houses in street views of Ithaca, and the
expression on the Fed chair's face at his press conferences.

Open `22-photos-ii.Rproj` first. R then starts in this folder, and every path in
the slides, the live script and the scripts below is relative to it. Every script
uses base R, so there is nothing to install. Nobody needs Python, an account or
the network: the models ran before class and what they returned is in
`data_clean/`.

## What is where

```
22-photos-ii/
  22-photos-ii.Rproj
  22-photos-ii.R          the live script: every code slide in order, the two exercises, the practice tasks (in the zips)
  README.md               this file
  code/                   the scripts, numbered in the order the lecture uses them
  data/cameras/           cameras.csv (33 cameras) and frames/<camera>/<moment>.jpg, the frames as saved
  data/ithaca/mapillary/  the photo listings for Ithaca, as the API returned them (60 JSON files)
  data/ithaca/            panoramas.csv, the 815 panoramas kept; panoramas/ holds them (not in the zips)
  data/fed/frames/        one frame every 30 seconds of 24 press conferences (not in the zips)
  data_clean/             boxes.csv, frames.csv: the detector's objects, one row each, and the frames searched
                          handcount_frames.csv, handcount.csv: 30 frames, a person's count and a model's count of each
                          views.csv, views/: 1,630 street views cut from the panoramas
                          label_sample.csv, hand_labels.csv: 200 views, a person's label and a model's label of each
                          typed_labels.csv, view_embeddings.csv: what the embedding model returned per view
                          fed_expressions_sets.csv: the same faces against three sets of descriptions
                          fed_frames.csv, fed_faces/, fed_expressions.csv, fed_hand_labels.csv: the Fed frames,
                          the faces cut from them, the typed expression labels, 80 labels by looking
  replies/                the sentences typed as labels (typed_labels.json, fed_typed_labels.json)
  logs/                   run records
  tools/                  what made data/ and data_clean/ before class (needs Python or a free account)
```

| Script | What it does |
|---|---|
| `code/1_count.R` | the box table, a count per frame at a confidence cutoff, the detector against 30 reference counts, Exercise 1 (the cutoff), daylight against dark, counts by hour |
| `code/2_houses.R` | 200 labelled views, a pre-trained model given six descriptions, a logistic regression trained on the labels and judged on 69 held-out views, Exercise 2 (fewer and more labels), every view on a map |
| `code/3_faces.R` | the Fed frames, the typed expression label for each face, against 80 labels by looking |
| `code/run_everything.R` | runs the three in order |

## Who made the reference counts and labels

`handcount.csv` holds two counts of each of the 30 frames. `count` is Ariel
Ortiz-Bobea's, made on November 11, 2026 from the enlarged frames, and is the
reference in every script. `count_model` is a general vision model's (Claude),
made the same day from the same frames; `sure_model` is `FALSE` where that
counter could not separate every vehicle. The two agree on 12 of 30 frames and
differ by 1.6 vehicles on average.

`hand_labels.csv` holds two sets of labels for the 200 sampled views. `house` is
Ariel Ortiz-Bobea's, made on November 11, 2026 by looking at each view: 1 house,
0 no house, and no label (NA) where a house was barely visible or he was in real
doubt (41, 148 and 11 views). It is the reference in every script. `house_model`
is a general vision model's (Claude) label for the same views, under a stricter
rule (front at least half visible, the main thing in the view); the two agree on
178 of the 189 views he decided.

`fed_hand_labels.csv` carries a `labeller` column. As of November 11, 2026 its 80
labels were made by a general vision model (Claude) looking at each face crop,
and no person had checked them.

The counting rule, as he applied it: every car, truck, bus and motorcycle that is
entirely below the camera's line (`line_y`, pixels from the top of the 352 by 240
frame), parked ones included. The scripts count the detector's boxes the same
way (the box's top edge below the line). The vision model's count also included
vehicles that cross the line, which is most of why it runs higher in daylight.
## Where the data came from

**Camera frames.** New York City DOT traffic cameras,
https://webcams.nyctmc.org/api/cameras (no key; 964 cameras listed; 352 by 240
JPEG; no archive). The 33 cameras in `data/cameras/cameras.csv` are those at the
crossings into Manhattan's Congestion Relief Zone. One frame per camera about
every ten minutes from 2026-11-09 22:22 to 2026-11-11 20:25, New York time, with
gaps while the collecting laptop slept (Tuesday 11:25 to Wednesday 11:14 has
five passes; Wednesday 14:00 to 16:00 has one). The file name is the moment the
pass started, `yyyymmdd_hhmmss`. Wednesday, November 11 was Veterans Day.

**Ithaca panoramas.** Mapillary, https://www.mapillary.com, through its API
(`tools/pull_ithaca.R`, a free client token in `~/.Renviron` as
`MAPILLARY_TOKEN`), requested 2026-11-11 over longitude -76.52 to -76.47 and
latitude 42.43 to 42.46 in 60 small boxes. 25,683 photographs listed; 5,523 are
panoramas, all taken on 10 and 11 April 2024 by one contributor (quickness805);
one was kept every 20 m or more along each drive, 815 in all. Licence CC BY-SA
4.0. Mapillary blurs faces and licence plates.

**Fed video.** The Board of Governors' own recordings of the 24 press conferences
after scheduled FOMC meetings, January 2021 to December 2023, 480 by 270, already
downloaded for sessions 19 and 20 (their README gives the source pages).

## Reproducing what the models returned

Nothing below is needed to follow the lecture. It is here so that every table in
`data_clean/` can be made again from the pictures.

```
python3 -m venv .venv && source .venv/bin/activate      # once: a Python environment for this project
pip install -r tools/requirements.txt                   # the packages and versions the tools ran with
python tools/detect_frames.py                           # camera frames  -> data_clean/boxes.csv, frames.csv
Rscript tools/pull_ithaca.R                             # Mapillary      -> data/ithaca/ (needs a free token)
python tools/cut_views.py                               # panoramas      -> data_clean/views/, views.csv
python tools/embed_views.py                             # views          -> view_embeddings.csv, typed_labels.csv
bash tools/fed_frames.sh                                # Fed videos     -> data/fed/frames/ (needs ffmpeg)
python tools/fed_faces.py                               # video frames   -> fed_frames.csv, fed_faces/, fed_expressions.csv
python tools/fed_descriptions.py                        # face crops     -> fed_expressions_sets.csv
```

- The model weights download themselves on the first run into `tools/weights/`
  (the detector 5.6 MB, the face detector 230 KB) and the embedding model into
  the package's own cache (about 350 MB).
- The camera frames cannot be fetched again: the city keeps no archive. They are
  in the class zip, and `detect_frames.py` run on them gives `boxes.csv` exactly
  as shipped (checked on November 11, 2026: the two files are identical).
- The panoramas need a free Mapillary token; the Fed videos come from the Fed's
  press-conference pages, as the README of the audio sessions describes.
- The counts and labels made by looking (`handcount.csv`, `hand_labels.csv`,
  `fed_hand_labels.csv`) are typed in, not computed.

## How data_clean/ was made

1. `tools/detect_frames.py`: an open pre-trained detector (YOLO11 nano, trained by
   its authors on the COCO photographs, 80 classes) on every frame, on a laptop;
   objects at confidence 0.10 or more. 4,037 frames in 169 s.
2. `tools/pick_handcount.R`: ten cameras at three moments; the counts were then
   typed into `handcount.csv`.
3. `tools/cut_views.py`: a left and a right view, 800 by 600 and 80 degrees wide,
   from each panorama.
4. `tools/embed_views.py`: an open embedding model (CLIP ViT-B/32) on every view:
   512 numbers per view, and its share for each typed label.
5. `tools/fed_frames.sh`, `tools/fed_faces.py`: one frame every 30 seconds; the
   same embedding model with typed labels for what the frame shows; an open face
   detector (YuNet) on the speaker's frames; typed labels for the expression.

Nothing was trained by any tool. The only models fitted in this project are the
logistic regressions in `code/2_houses.R`.
