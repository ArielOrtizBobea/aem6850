# Resolve a Brightcove video id to its 270p MP4 through the public Playback API.
# The policy key comes from the Fed player's public config.json; the MP4 URL carries a
# short-lived fastly_token, so call this right before each download.
# Usage: python -I bc_url.py VIDEO_ID   ->  prints "<url>\t<size_bytes>\t<height>\t<duration_ms>"
import json, sys, urllib.request

ACCOUNT = "66043936001"
UA = {"User-Agent": "Mozilla/5.0 (AEM 6850 course data)"}


def get_json(url, headers=None):
    req = urllib.request.Request(url, headers={**UA, **(headers or {})})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r)


cfg = get_json(f"https://players.brightcove.net/{ACCOUNT}/default_default/config.json")
pk = cfg["video_cloud"]["policy_key"]
v = get_json(f"https://edge.api.brightcove.com/playback/v1/accounts/{ACCOUNT}/videos/{sys.argv[1]}",
             {"Accept": f"application/json;pk={pk}"})
mp4 = [s for s in v["sources"] if s.get("container") == "MP4" and s.get("src", "").startswith("https")]
pick = [s for s in mp4 if s.get("height") == 270] or sorted(mp4, key=lambda s: s.get("height", 0))[:1]
s = pick[0]
print(f'{s["src"]}\t{s.get("size", "")}\t{s.get("height", "")}\t{v.get("duration", "")}')
