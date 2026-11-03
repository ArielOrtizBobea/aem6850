# Write logs/STATUS.md from the files on disk and the logs. run_all.sh calls it after each conference.
# Usage: python -I tools/status.py
import csv, datetime, json, os, re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
J = lambda *p: os.path.join(ROOT, *p)


def tsv(name):
    path = J("logs", name)
    if not os.path.exists(path):
        return []
    with open(path, newline="") as f:
        return list(csv.DictReader(f, delimiter="\t"))


dates = [r["date"] for r in csv.DictReader(open(J("data", "meetings.csv")))]
outputs = [
    ("MP4 (data/media)", "data/media/fomc{d}_270p.mp4"),
    ("WAV (data/media)", "data/media/fomc{d}.wav"),
    ("transcript PDF", "data/transcripts/FOMCpresconf{d}.pdf"),
    ("words (replies)", "replies/words_{d}.json"),
    ("speakers (replies)", "replies/speakers_{d}.rttm"),
    ("emotion (replies)", "replies/emotion_{d}.csv"),
]
have = {lab: [d for d in dates if os.path.exists(J(pat.format(d=d)))] for lab, pat in outputs}

pid, running = None, False
if os.path.exists(J("logs", "run_all.pid")):
    pid = open(J("logs", "run_all.pid")).read().strip()
    try:
        os.kill(int(pid), 0)
        running = True
    except (OSError, ValueError):
        running = False

steps, loops, fails = tsv("steps.tsv"), tsv("loopcheck.tsv"), tsv("failures.tsv")
L = [f"# Session 20 data build: status", "",
     f"Updated {datetime.datetime.now():%Y-%m-%d %H:%M:%S}. "
     + (f"`run_all.sh` is running in the background (PID {pid})." if running
        else "`run_all.sh` is not running."), "",
     "## Conferences finished, by step", "", "| Step | Done (of 24) |", "|---|---|"]
L += [f"| {lab} | {len(v)} |" for lab, v in have.items()]
complete = [d for d in dates if all(d in v for v in have.values())]
L += ["", f"All steps complete: {len(complete)} of {len(dates)}.", ""]

L += ["## Loop check", "",
      "A conference is flagged when a segment's text repeats three or more times in a row (empty segments skipped), or when "
      "Whisper's word count is more than 20% above the transcript PDF's `pdftotext` count. Flagged "
      "ones are rerun with `--condition-on-previous-text False`; the first output is kept as "
      "`replies/words_YYYYMMDD_looped.json`.", ""]
flagged = [r for r in loops if r["attempt"] == "cond" and r["flag"] == "1"]
L += [f"Checked: {len({r['date'] for r in loops})}. Flagged: {len(flagged)}"
      + (": " + ", ".join(f"{r['date']} (repeat {r['max_repeat']}, ratio {r['ratio']}, at {r['repeat_at']})"
                          for r in flagged) if flagged else ".")]
reruns = [r for r in loops if r["attempt"] == "nocond"]
if reruns:
    L += ["", "Reruns without conditioning: " + ", ".join(
        f"{r['date']} ({r['words']} words, ratio {r['ratio']}, max repeat {r['max_repeat']}, "
        + (f"STILL FLAGGED at {r['repeat_at']})" if r["flag"] == "1" else "clean)")
        for r in reruns)]
final = {}
for r in loops:
    final[r["date"]] = r
hi = [r for r in final.values() if r["flag"] == "0" and float(r["max_compression"] or 0) > 2.4]
L += ["", "Final transcripts not flagged but with a segment whose compression ratio is above 2.4 "
      "(Whisper's own threshold; a sign of repetition or skipped speech inside one segment): "
      + (", ".join(f"{r['date']} ({r['max_compression']})" for r in hi) if hi else "none.")]
TAG = re.compile(r"\b[A-Z][A-Z'\u2019-]+(?: [A-Z][A-Z'\u2019-]+)+\.")
tags = {}
for d in dates:
    f = J("replies", f"words_{d}.json")
    if os.path.exists(f):
        tags[d] = len(TAG.findall(json.load(open(f))["text"]))
L += ["", "Speaker tags in capitals (\"CHAIR POWELL.\", \"MICHELLE SMITH.\") that Whisper writes in the "
      "style of the Fed's transcripts, counted in each final transcript: "
      + ", ".join(f"{d} {n}" for d, n in tags.items() if n) + "." if any(tags.values()) else ""]
L += ["", "## Failures", ""]
L += ([f"- {r['date']} {r['step']}: {r['reason']} ({r['when']})" for r in fails] or ["None."])

by = {}
for r in steps:
    by.setdefault(r["date"], {})[r["step"]] = r
cols = ["download", "wav", "transcript_pdf", "transcribe_cond", "transcribe_nocond", "labels", "emotion"]
L += ["", "## Seconds per step", "",
      "| Date | " + " | ".join(cols) + " | words | windows |", "|---" * (len(cols) + 3) + "|"]
for d in dates:
    if d not in by:
        continue
    s = by[d]
    w = s.get("transcribe_nocond", s.get("transcribe_cond", {})).get("n", "")
    L.append(f"| {d} | " + " | ".join(s.get(c, {}).get("seconds", "") for c in cols)
             + f" | {w} | {s.get('emotion', {}).get('n', '')} |")
L += ["", "Blank download/wav cells for 20230201: its MP4 and WAV were copied from the feasibility run.", "",
      "## Resume", "", "Every step skips outputs that already exist, so resuming is the same command:", "",
      "```bash", "cd ~/github/aem6850/fall-2026/sessions/data/20-audio-ii",
      "nohup caffeinate -i tools/run_all.sh >> logs/run_all.log 2>&1 &", "```", "",
      "Progress: `tail -f logs/run_all.log`. One conference only: `tools/run_all.sh 20210127`.", ""]
open(J("logs", "STATUS.md"), "w").write("\n".join(L))
print("\n".join(L))
