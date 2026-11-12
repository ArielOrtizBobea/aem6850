# AEM 6850, session 22. Expression labels on the Fed chair's face.
# Run in the 22-photos-ii folder (open 22-photos-ii.Rproj first). Base R only.
# Reads data_clean/fed_frames.csv, fed_expressions.csv and fed_hand_labels.csv.
# No model runs here: the face detector and the typed-label classifier ran before
# class (tools/fed_faces.py).

# ---- 1. The frames: one every 30 seconds of 24 press conferences ----------------
fr <- read.csv("data_clean/fed_frames.csv")
nrow(fr); length(unique(fr$date))
table(fr$shows)                                   # what the typed-label classifier says each frame shows
sum(fr$face_found, na.rm = TRUE)                                # frames with the speaker and a face found

# ---- 2. The expression the typed labels give each face ----------------------------
ex <- read.csv("data_clean/fed_expressions.csv")  # one row per face: a share for each of four typed labels
head(ex[, c("date", "seconds", "happy", "neutral", "angry", "worried", "top")], 3)
round(prop.table(table(ex$top)), 3)

# ---- 3. Against 80 faces labelled by looking ---------------------------------------
fh <- read.csv("data_clean/fed_hand_labels.csv")
f  <- merge(fh, ex[, c("file", "top")], by = "file")
table(by_looking = f$label, pretrained = f$top)
mean(f$label == f$top)                            # the share of faces where the two agree

# ---- 4. The same faces against other sets of descriptions ----------------------------
sets <- read.csv("data_clean/fed_expressions_sets.csv")   # made by tools/fed_descriptions.py
sets[, c("set", "description", "share")]
