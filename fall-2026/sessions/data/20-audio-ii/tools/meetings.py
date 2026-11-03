# Build and update data/meetings.csv for the 24 FOMC press conferences of 2021-2023.
#
#   python -I tools/meetings.py ids    # read the Fed calendar, check the 24 dates, read each
#                                      # press-conference page for its Brightcove video id and PDF
#   python -I tools/meetings.py fill   # fill duration_s and mp4_bytes from the files in data/media/
#
# Columns: date, video_id, duration_s, mp4_bytes, transcript_url
import csv, html, os, re, subprocess, sys, urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CSV = os.path.join(ROOT, "data", "meetings.csv")
MEDIA = os.path.join(ROOT, "data", "media")
FED = "https://www.federalreserve.gov"
CAL = FED + "/monetarypolicy/fomccalendars.htm"
EXPECTED = ("20210127 20210317 20210428 20210616 20210728 20210922 20211103 20211215 "
            "20220126 20220316 20220504 20220615 20220727 20220921 20221102 20221214 "
            "20230201 20230322 20230503 20230614 20230726 20230920 20231101 20231213").split()
COLS = ["date", "video_id", "duration_s", "mp4_bytes", "transcript_url"]


def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 (AEM 6850 course data)"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read().decode("utf-8", "replace")


def read_csv():
    if not os.path.exists(CSV):
        return {}
    with open(CSV, newline="") as f:
        return {r["date"]: r for r in csv.DictReader(f)}


def write_csv(rows):
    with open(CSV, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=COLS, lineterminator="\n")
        w.writeheader()
        for d in sorted(rows):
            w.writerow({c: rows[d].get(c, "") for c in COLS})


def ids():
    t = get(CAL)
    found = []
    for y in ("2021", "2022", "2023"):
        i = t.index(f"{y} FOMC Meetings")
        j = t.find("FOMC Meetings", i + 20)
        entries = re.split(r"fomc-meeting__month", t[i:j])[1:]
        pcs = [d for e in entries for d in re.findall(r"fomcpresconf(\d{8})\.htm", e)]
        print(f"{y}: {len(entries)} meetings on the calendar, {len(pcs)} press conferences")
        found += pcs
    assert found == EXPECTED, f"calendar dates differ from the expected 24: {found}"
    rows = read_csv()
    for d in EXPECTED:
        page = get(f"{FED}/monetarypolicy/fomcpresconf{d}.htm")
        vids = sorted(set(re.findall(r'data-video-id="(\d+)"', page)))
        acct = set(re.findall(r'data-account="(\d+)"', page))
        pdfs = sorted(set(re.findall(r'href="([^"]*FOMCpresconf%s\.pdf)"' % d, page, re.I)))
        assert len(vids) == 1 and acct == {"66043936001"} and len(pdfs) == 1, (d, vids, acct, pdfs)
        r = rows.get(d, {"date": d})
        r["video_id"] = vids[0]
        r["transcript_url"] = FED + html.unescape(pdfs[0]) if pdfs[0].startswith("/") else pdfs[0]
        rows[d] = r
        print(d, vids[0], r["transcript_url"])
    write_csv(rows)


def fill():
    rows = read_csv()
    for d, r in rows.items():
        mp4 = os.path.join(MEDIA, f"fomc{d}_270p.mp4")
        wav = os.path.join(MEDIA, f"fomc{d}.wav")
        if os.path.exists(mp4):
            r["mp4_bytes"] = str(os.path.getsize(mp4))
        if os.path.exists(wav):
            out = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
                                  "-of", "default=nw=1:nk=1", wav], capture_output=True, text=True)
            r["duration_s"] = f"{float(out.stdout.strip()):.2f}"
    write_csv(rows)


if __name__ == "__main__":
    {"ids": ids, "fill": fill}[sys.argv[1]]()
