"""Wineglass Marathon net-time finishers, 2018-2025, from Leone Timing.

Keeps only place, sex, age group and net time; names, ages and towns are
never stored or printed. Fetching goes through fetch.get (cached, 1 req/s).
"""
import re

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd
from bs4 import BeautifulSoup

from explore_results import marathon_net_url
from fetch import get

# place, name..., age, sex#, overall-sex place, div place/total, age group, net time
ROW = re.compile(
    r"^\s*(?P<place>\d+)\s.*?\s(?:\d{1,3})?\s+(?P<sex>[MFX])#\s*\d+\s+\d+/\d+\s+"
    r"(?P<group>\S+)\s+(?P<net>\d+:\d\d:\d\d)\s"
)
# a few finishers have no sex or age group recorded: keep them with those blank
NO_SEX = re.compile(r"^\s*(?P<place>\d+)\s.*?\s(?:\d{1,3})?\s+#\s+(?P<net>\d+:\d\d:\d\d)\s")
START_DATA = re.compile(r"^\s*\d+\s+\S")

rows, last_place, unparsed = [], {}, {}
for year in range(2018, 2026):
    url = marathon_net_url(year)
    if url is None:
        continue
    lines = BeautifulSoup(get(url)[1], "html.parser").get_text().splitlines()
    places, bad = [], 0
    in_main = False
    for line in lines:
        if START_DATA.match(line):
            in_main = True
            m = ROW.match(line) or NO_SEX.match(line)
            if m is None:
                bad += 1
                continue
            d = m.groupdict()
            places.append(int(d["place"]))
            rows.append({"year": year, "place": int(d["place"]), "sex": d.get("sex"),
                         "age_group": d.get("group"), "net_time": d["net"]})
        elif in_main and line.strip() and "WHEELCHAIR" in line.upper():
            break  # 2019: separate wheelchair table follows the main list
    last_place[year] = max(places) if places else None
    unparsed[year] = bad

df = pd.DataFrame(rows)
hms = df["net_time"].str.split(":", expand=True).astype(int)
df["net_minutes"] = (hms[0] * 60 + hms[1] + hms[2] / 60).round(4)
df.to_csv("wineglass.csv", index=False)

# ---- histogram, all years, 1-minute bins 2:30-6:30
fig, ax = plt.subplots(figsize=(10, 5))
ax.hist(df["net_minutes"], bins=range(150, 391), color="#4C72B0", edgecolor="white", linewidth=0.3)
for t in (180, 210, 240, 270):
    ax.axvline(t, color="#C44E52", lw=1, ls="--")
ticks = range(150, 391, 30)
ax.set_xticks(ticks, [f"{t // 60}:{t % 60:02d}" for t in ticks])
ax.set_xlim(150, 390)
ax.set_xlabel("Net time (h:mm), one-minute bins")
ax.set_ylabel("Finishers")
ax.set_title(f"Wineglass Marathon finishers by net time, {', '.join(map(str, sorted(df.year.unique())))}")
ax.spines[["top", "right"]].set_visible(False)
fig.tight_layout()
fig.savefig("wineglass.png", dpi=150)

# ---- finishers and median by year
by = df.groupby("year")["net_minutes"].agg(n="size", median="median")
fig, (a1, a2) = plt.subplots(1, 2, figsize=(11, 4.2))
a1.bar(by.index.astype(str), by["n"], color="#4C72B0")
a1.set_title("Finishers")
a2.plot(by.index.astype(str), by["median"], "o-", color="#4C72B0")
a2.set_title("Median net time")
yt = range(int(by["median"].min()) // 5 * 5, int(by["median"].max()) // 5 * 5 + 10, 5)
a2.set_yticks(yt, [f"{t // 60}:{t % 60:02d}" for t in yt])
for a in (a1, a2):
    a.spines[["top", "right"]].set_visible(False)
fig.suptitle("Wineglass Marathon by year (no race in 2020)")
fig.tight_layout()
fig.savefig("wineglass_years.png", dpi=150)

# ---- report
def fmt(m):
    s = round(m * 60)
    return f"{s // 3600}:{s % 3600 // 60:02d}:{s % 60:02d}"

print("year  rows_kept  last_place  unparsed_lines")
for y in last_place:
    print(f"{y}  {int((df.year == y).sum()):9d}  {last_place[y]:10d}  {unparsed[y]:14d}")
print("\nFinishers by whole minute of net time (all years):")
whole = df["net_minutes"].astype(int)
for m in range(237, 243):
    print(f"  {m // 60}:{m % 60:02d}  {int((whole == m).sum())}")
print("\nMedian net time by year:")
for y, r in by.iterrows():
    print(f"  {y}  {fmt(r['median'])}  (n={int(r['n'])})")
