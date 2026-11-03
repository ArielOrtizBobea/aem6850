# Flag a Whisper transcript that may have fallen into a repetition loop.
# Usage: python -I loop_check.py words_YYYYMMDD.json FOMCpresconfYYYYMMDD.pdf
# Prints one key=value line. flag=1 when either
#   - some segment text (stripped, lower case) repeats 3 or more times in a row, empty
#     segments skipped, or
#   - Whisper's word count is more than 20% above the PDF's pdftotext word count.
# The PDF count includes page headers and speaker names, so it runs a little above the spoken words.
import json, re, subprocess, sys

j = json.load(open(sys.argv[1]))
segs = j["segments"]
words = sum(len(s.get("words", [])) for s in segs)
pdf_text = subprocess.run(["pdftotext", sys.argv[2], "-"], capture_output=True, text=True, check=True).stdout
pdf_words = len(pdf_text.split())

run, best, best_at, prev = 0, 0, None, None
for s in segs:
    t = re.sub(r"\s+", " ", s["text"].strip().lower())
    if not t:  # empty segments sit between the copies of a loop; they do not break the run
        continue
    run = run + 1 if t == prev else 1
    prev = t
    if run > best:
        best, best_at = run, (s["start"], t[:60])
ratio = words / pdf_words if pdf_words else float("nan")
# highest compression ratio among segments with text (Whisper can end a file with empty ones)
max_cr = max((s.get("compression_ratio", 0) for s in segs if s["text"].strip()), default=0)
flag = int(best >= 3 or ratio > 1.2)
where = f"{best_at[0]:.1f}s:{best_at[1]!r}" if best >= 3 else "-"
print(f"words={words} pdf_words={pdf_words} ratio={ratio:.3f} segments={len(segs)} "
      f"max_repeat={best} max_compression={max_cr:.2f} flag={flag} repeat_at={where}")
