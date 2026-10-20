"""Polite cached fetcher for Leone Timing pages."""
import hashlib
import re
import time
from pathlib import Path

import requests

UA = "AEM 6850 class demo; <your address>"
CACHE = Path(__file__).parent / "cache"
CACHE.mkdir(exist_ok=True)
_last = [0.0]


def cache_path(url):
    slug = re.sub(r"[^A-Za-z0-9]+", "_", url.split("://", 1)[-1]).strip("_")[:120]
    h = hashlib.md5(url.encode()).hexdigest()[:8]
    return CACHE / f"{slug}_{h}.html"


def get(url):
    """Return (status, text). Cached pages (including 404s) are never refetched."""
    p = cache_path(url)
    miss = p.with_suffix(".404")
    if p.exists():
        return 200, p.read_text(encoding="utf-8")
    if miss.exists():
        return 404, ""
    wait = 30
    while True:
        dt = time.time() - _last[0]
        if dt < 1.1:
            time.sleep(1.1 - dt)
        r = requests.get(url, headers={"User-Agent": UA}, timeout=60)
        _last[0] = time.time()
        if r.status_code == 429:
            ra = r.headers.get("Retry-After")
            time.sleep(int(ra) if ra and ra.isdigit() else wait)
            wait = min(wait * 2, 600)
            continue
        break
    if r.status_code == 200:
        r.encoding = r.encoding or r.apparent_encoding
        p.write_text(r.text, encoding="utf-8")
        return 200, r.text
    if r.status_code == 404:
        miss.write_text("")
    return r.status_code, ""
