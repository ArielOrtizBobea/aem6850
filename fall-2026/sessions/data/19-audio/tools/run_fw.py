# faster-whisper (CTranslate2, CPU int8) with word timestamps; JSON shaped like mlx-whisper's.
# Usage: python -I run_fw.py <wav> <model: base|large-v3-turbo|...> <out.json> [initial prompt]
import sys, json, time
from faster_whisper import WhisperModel
wav, model, out = sys.argv[1:4]; prompt = sys.argv[4] if len(sys.argv) > 4 else None
t0 = time.time()
m = WhisperModel(model, device="cpu", compute_type="int8")
t1 = time.time()
segs, info = m.transcribe(wav, language="en", word_timestamps=True, initial_prompt=prompt, beam_size=5)
S = [{"id": s.id, "start": s.start, "end": s.end, "text": s.text, "avg_logprob": s.avg_logprob,
      "no_speech_prob": s.no_speech_prob,
      "words": [{"word": w.word, "start": w.start, "end": w.end, "probability": w.probability} for w in s.words]}
     for s in segs]   # generator: decoding happens here
t2 = time.time()
json.dump({"text": "".join(s["text"] for s in S), "segments": S, "language": info.language}, open(out, "w"))
print(f"load_s={t1-t0:.1f} transcribe_s={t2-t1:.1f}")
