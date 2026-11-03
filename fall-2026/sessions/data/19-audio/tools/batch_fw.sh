#!/bin/bash
# faster-whisper CPU int8 runs on both clips; appends to out/timings.tsv
D=$(cd "$(dirname "$0")/.." && pwd); export HF_HOME=$D/hf HF_HUB_DISABLE_TELEMETRY=1
for m in base large-v3-turbo; do for c in open2min schneider30; do
  n=${c}_fw-${m}
  s=$(python3 -c 'import time;print(time.time())')
  r=$("$D/venv/bin/python" -I "$D/scripts/run_fw.py" "$D/audio/$c.wav" $m "$D/audio/$n.json" 2>/dev/null | tail -1)
  e=$(python3 -c 'import time;print(time.time())')
  echo -e "$n\twall_s=$(python3 -c "print(round($e-$s,1))")\t$r\t$("$D/venv/bin/python" -I "$D/scripts/wc_json.py" "$D/audio/$n.json")" | tee -a "$D/out/timings.tsv"
done; done
