"""Fetch each marathon net-time page and show its layout with letters masked.

Every letter in data lines is replaced by 'x' so no names or towns are printed.
"""
import re
from urllib.parse import urljoin

from bs4 import BeautifulSoup

from fetch import get


def marathon_net_url(year):
    url = f"https://www.leonetiming.com/{year}/Roads/Wineglass/"
    status, html = get(url)
    if status != 200:
        return None
    soup = BeautifulSoup(html, "html.parser")
    for a in soup.find_all("a", href=True):
        href = a["href"]
        name = href.rsplit("/", 1)[-1].lower()
        if "net" in a.get_text().lower() and "marathon" in name and "half" not in name:
            return urljoin(url, href)
    return None


SAFE = {"place", "name", "age", "sex", "div", "division", "city", "state", "st", "bib",
        "no", "net", "gun", "time", "pace", "tot", "tag", "chip", "results", "marathon",
        "wineglass", "overall", "by", "of", "the", "and", "corning", "ny", "oct", "october",
        "finishers", "pl", "guntim", "nettim", "ag", "group", "split", "half", "mi", "mile",
        "official", "sunday", "saturday", "times", "male", "female", "m", "f", "x", "nonbinary"}


def mask(line):
    return re.sub(r"[A-Za-z]+", lambda m: m.group() if m.group().lower() in SAFE else "x" * len(m.group()), line)


if __name__ == "__main__":
    for year in range(2018, 2026):
        u = marathon_net_url(year)
        print(f"== {year} {u}")
        if not u:
            continue
        status, html = get(u)
        text = BeautifulSoup(html, "html.parser").get_text()
        lines = text.splitlines()
        print(f"   status={status} lines={len(lines)}")
        # first 15 non-empty lines and 3 lines near the end, letters masked past header
        nonempty = [l for l in lines if l.strip()]
        for l in nonempty[:14] + ["..."] + nonempty[-4:]:
            print("   |", mask(l)[:130])
