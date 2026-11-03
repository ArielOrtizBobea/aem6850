# Usage: python -I wc_json.py file1.json [file2.json ...]
# Prints words (from word timestamps), segments, um/uh counts, first/last word time.
import json, re, sys
for f in sys.argv[1:]:
    j = json.load(open(f))
    segs = j["segments"]
    words = [w for s in segs for w in s.get("words", [])]
    toks = [re.sub(r"[^\w']", "", w["word"].lower()) for w in words]
    um = sum(t in ("um", "umm", "uhm") for t in toks)
    uh = sum(t in ("uh", "uhh", "er", "ah") for t in toks)
    txt_words = len(j["text"].split())
    span = f'{words[0]["start"]:.2f}-{words[-1]["end"]:.2f}' if words else "-"
    print(f'{f.split("/")[-1]}\twords={len(words)}\ttext_words={txt_words}\tsegments={len(segs)}\tum={um}\tuh={uh}\tspan={span}')
