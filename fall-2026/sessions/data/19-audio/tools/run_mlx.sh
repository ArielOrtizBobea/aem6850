#!/bin/bash
# Usage: run_mlx.sh <wav> <model-short> <hf-repo> [initial prompt]
# Writes audio/<clip>_mlx-<model-short>[_prompt].json and appends wall time to out/timings.tsv
D=$(cd "$(dirname "$0")/.." && pwd); export HF_HOME=$D/hf HF_HUB_DISABLE_TELEMETRY=1
wav=$1; m=$2; repo=$3; prompt=$4
clip=$(basename "$wav" .wav); name=${clip}_mlx-$m; [ -n "$prompt" ] && name=${name}_prompt
args=(--model "$repo" --language en --word-timestamps True --output-format json --output-dir "$D/audio" --output-name "$name" --verbose False)
[ -n "$prompt" ] && args+=(--initial-prompt "$prompt")
s=$(python3 -c 'import time;print(time.time())')
"$D/venv/bin/mlx_whisper" "$wav" "${args[@]}" 2>/dev/null
e=$(python3 -c 'import time;print(time.time())')
wall=$(python3 -c "print(round($e-$s,1))")
wc=$("$D/venv/bin/python" -I "$D/scripts/wc_json.py" "$D/audio/$name.json")
echo -e "$name\twall_s=$wall\t$wc" | tee -a "$D/out/timings.tsv"
