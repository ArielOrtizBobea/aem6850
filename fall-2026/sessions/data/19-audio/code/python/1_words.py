# =============================================================
# AEM 6850 - Session 19: Audio
# Python, before class: the speech-to-text reply, replies/words.json.
#
# Runs the large speech-to-text model (Whisper large-v3-turbo) on the whole
# press conference of 1 February 2023, with a start and end time on every
# word, and saves its reply as JSON. Not run in class: about 5 minutes on
# the instructor's laptop. code/1_words.R reads the file it writes.
#
# Needs the Python environment of tools/SETUP.md (mlx-whisper runs on
# Apple-silicon Macs; tools/SETUP.md gives faster-whisper for the others)
# and data/media/fomc20230201.wav, which is not in the zip.
#
#   python code/python/1_words.py            from the 19-audio folder
# =============================================================
import json, sys
import mlx_whisper

wav = sys.argv[1] if len(sys.argv) > 1 else "data/media/fomc20230201.wav"
out = sys.argv[2] if len(sys.argv) > 2 else "replies/words.json"

reply = mlx_whisper.transcribe(
    wav,
    path_or_hf_repo="mlx-community/whisper-large-v3-turbo",   # the large model
    language="en",
    word_timestamps=True)                                     # a time on every word

with open(out, "w") as f:
    json.dump(reply, f)
print(len(reply["segments"]), "segments,",
      sum(len(s["words"]) for s in reply["segments"]), "words ->", out)
