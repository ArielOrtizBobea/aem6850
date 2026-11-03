"""Write figures/19-audio/sync-loop90.js: the words each model wrote for the
clip data/clips/loop90.mp3 (2070 to 2160 s of the recording), in clip seconds.
Run: python3 -I make_sync.py /Users/ao332/github/aem6850/fall-2026/sessions"""
import json, sys
from pathlib import Path

sessions = Path(sys.argv[1])
replies = sessions / "data/19-audio/replies"
T0, T1 = 2070.0, 2160.0

def words(name):
    segs = json.loads((replies / name).read_text())["segments"]
    out = [{"w": x["word"].strip(), "s": round(x["start"] - T0, 2), "e": round(x["end"] - T0, 2)}
           for s in segs for x in s["words"] if T0 <= x["start"] < T1]
    assert all(a["s"] <= b["s"] for a, b in zip(out, out[1:])), name + ": times not monotone"
    return out

def js_array(ws, per_line=8):
    items = ["{w:%s,s:%s,e:%s}" % (json.dumps(x["w"]), x["s"], x["e"]) for x in ws]
    rows = [",".join(items[i:i + per_line]) for i in range(0, len(items), per_line)]
    return "[\n" + ",\n".join(rows) + "\n]"

large, small = words("words.json"), words("words_base.json")
out = sessions / "figures/19-audio/sync-loop90.js"
out.write_text(
    "// Words each model wrote for data/clips/loop90.mp3 (34:30 to 36:00 of the Fed's\n"
    "// press conference of 1 Feb 2023), in seconds from the start of the clip.\n"
    "// From replies/words.json (large) and replies/words_base.json (small).\n"
    "var sync19 = {\nlarge: " + js_array(large) + ",\nsmall: " + js_array(small) + "\n};\n")
print(out, len(large), len(small))
