#!/bin/bash
# Build the session 20 data: for each FOMC press conference in data/meetings.csv, in date order,
#   1. download the 270p MP4 through the Brightcove Playback API (fresh token each time)
#   2. convert it to a 16 kHz mono WAV
#   3. download the Fed's transcript PDF
#   4. transcribe with mlx-whisper large-v3-turbo, word timestamps, language en, default conditioning;
#      loop check (tools/loop_check.py); a flagged conference is rerun with
#      --condition-on-previous-text False and the first output is kept as words_YYYYMMDD_looped.json
#   5. speaker labels with the ECAPA clustering script (tools/diarize_ecapa.py, batch 8)
#   6. emotion scores on consecutive 10-s windows on MPS (tools/emotion_windows.py)
# Every step is skipped when its output already exists, so the script can simply be rerun.
# Outputs are written to a temporary name and renamed when complete.
#
# Usage, from anywhere:  tools/run_all.sh [YYYYMMDD ...]     (no dates = all 24)
# Background run used for the full set:
#   cd <project> && nohup caffeinate -i tools/run_all.sh >> logs/run_all.log 2>&1 &
set -u
cd "$(dirname "$0")/.." || exit 1
export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export HF_HUB_DISABLE_TELEMETRY=1
V=${AUDIO_VENV:-$HOME/.venvs/aem6850-audio}
PY="$V/bin/python -I"
WHISPER_MODEL=mlx-community/whisper-large-v3-turbo
UA="Mozilla/5.0 (AEM 6850 course data)"
MEDIA=data/media; TR=data/transcripts; R=replies; L=logs
STEPS=$L/steps.tsv; LOOPS=$L/loopcheck.tsv; FAILS=$L/failures.tsv
mkdir -p "$MEDIA" "$TR" "$R" "$L"
[ -f "$STEPS" ] || printf 'date\tstep\tseconds\tn\tunit\tdetail\tfinished\n' > "$STEPS"
[ -f "$LOOPS" ] || printf 'date\tattempt\twords\tpdf_words\tratio\tmax_repeat\tmax_compression\tflag\trepeat_at\n' > "$LOOPS"
[ -f "$FAILS" ] || printf 'date\tstep\treason\twhen\n' > "$FAILS"

now() { /usr/bin/perl -MTime::HiRes=time -e 'printf "%.2f\n", time'; }
stamp() { date '+%Y-%m-%dT%H:%M:%S'; }
msg() { echo "[$(date '+%H:%M:%S')] $*"; }
logstep() {  # date step t0 n unit detail
  local secs; secs=$(awk -v a="$(now)" -v b="$3" 'BEGIN{printf "%.1f", a-b}')
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$secs" "$4" "$5" "$6" "$(stamp)" >> "$STEPS"
  msg "$1 $2 done in ${secs} s ($4 $5) $6"
}
fail() {  # date step reason
  printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$(stamp)" >> "$FAILS"
  msg "FAIL $1 $2: $3"
}
kv() { tr ' ' '\n' <<< "$2" | sed -n "s/^$1=//p" | head -1; }  # value of key=value in a summary line

whisper() {  # date attempt(cond|nocond): writes replies/words_DATE.json
  local d=$1 att=$2 t0 extra=() out rc
  [ "$att" = nocond ] && extra=(--condition-on-previous-text False)
  t0=$(now)
  "$V/bin/mlx_whisper" "$MEDIA/fomc$d.wav" --model "$WHISPER_MODEL" --language en \
      --word-timestamps True --output-format json --output-dir "$R/.tmp_$d" \
      --output-name "words_$d" --verbose False ${extra[@]+"${extra[@]}"} 2> "$R/.tmp_$d/whisper.err"
  rc=$?
  if [ $rc -ne 0 ]; then tail -5 "$R/.tmp_$d/whisper.err"; fail "$d" "transcribe_$att" "mlx_whisper exit $rc"; return 1; fi
  mv "$R/.tmp_$d/words_$d.json" "$R/words_$d.json"
  out=$($PY tools/loop_check.py "$R/words_$d.json" "$TR/FOMCpresconf$d.pdf")
  logstep "$d" "transcribe_$att" "$t0" "$(kv words "$out")" words "$out"
}

loopcheck() {  # date attempt: appends to loopcheck.tsv, sets FLAG
  local d=$1 att=$2 out
  out=$($PY tools/loop_check.py "$R/words_$d.json" "$TR/FOMCpresconf$d.pdf") || return 1
  FLAG=$(kv flag "$out")
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$d" "$att" "$(kv words "$out")" "$(kv pdf_words "$out")" \
    "$(kv ratio "$out")" "$(kv max_repeat "$out")" "$(kv max_compression "$out")" "$FLAG" \
    "$(sed -n 's/.*repeat_at=//p' <<< "$out")" >> "$LOOPS"
  msg "$d loop check ($att): $out"
}

process() {  # date video_id transcript_url
  local d=$1 vid=$2 turl=$3 t0 info url size got dur n out att
  local mp4=$MEDIA/fomc${d}_270p.mp4 wav=$MEDIA/fomc$d.wav pdf=$TR/FOMCpresconf$d.pdf
  local words=$R/words_$d.json looped=$R/words_${d}_looped.json rttm=$R/speakers_$d.rttm emo=$R/emotion_$d.csv
  mkdir -p "$R/.tmp_$d"

  if [ ! -s "$mp4" ]; then
    local free_gb; free_gb=$(df -g . | awk 'NR==2{print $4}')
    [ "$free_gb" -gt 10 ] || { fail "$d" download "only ${free_gb} GB free"; return 1; }
    t0=$(now)
    info=$($PY tools/bc_url.py "$vid") || { fail "$d" download "playback API"; return 1; }
    url=$(cut -f1 <<< "$info"); size=$(cut -f2 <<< "$info")
    /usr/bin/curl -sS --fail --retry 3 -o "$mp4.part" "$url" || { fail "$d" download "curl exit $?"; return 1; }
    got=$(stat -f%z "$mp4.part")
    [ -z "$size" ] || [ "$got" = "$size" ] || { fail "$d" download "size $got, API says $size"; return 1; }
    mv "$mp4.part" "$mp4"
    logstep "$d" download "$t0" "$got" bytes "height=$(cut -f3 <<< "$info") duration_ms=$(cut -f4 <<< "$info")"
  fi

  if [ ! -s "$wav" ]; then
    t0=$(now)
    ffmpeg -nostdin -v error -y -i "$mp4" -vn -ac 1 -ar 16000 -c:a pcm_s16le -f wav "$wav.part" \
      || { fail "$d" wav "ffmpeg exit $?"; return 1; }
    mv "$wav.part" "$wav"
    dur=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$wav")
    logstep "$d" wav "$t0" "$dur" audio_seconds ""
  fi
  $PY tools/meetings.py fill

  if [ ! -s "$pdf" ]; then
    t0=$(now)
    /usr/bin/curl -sS --fail --retry 3 -A "$UA" -o "$pdf.part" "$turl" || { fail "$d" transcript_pdf "curl exit $?"; return 1; }
    [ "$(head -c 4 "$pdf.part")" = "%PDF" ] || { fail "$d" transcript_pdf "not a PDF"; return 1; }
    mv "$pdf.part" "$pdf"
    n=$(pdftotext "$pdf" - | wc -w | tr -d ' ')
    logstep "$d" transcript_pdf "$t0" "$n" pdf_words "$(stat -f%z "$pdf") bytes"
  fi

  att=cond; [ -s "$looped" ] && att=nocond
  if [ ! -s "$words" ]; then whisper "$d" "$att" || return 1; fi
  if ! grep -q "^$d"$'\t'"$att"$'\t' "$LOOPS"; then
    loopcheck "$d" "$att" || { fail "$d" loop_check "loop_check.py failed"; return 1; }
    if [ "$att" = cond ] && [ "$FLAG" = 1 ]; then
      msg "$d flagged: keeping $looped, rerunning with --condition-on-previous-text False"
      mv "$words" "$looped"
      whisper "$d" nocond || return 1
      loopcheck "$d" nocond || return 1
    fi
  fi

  if [ ! -s "$rttm" ]; then
    t0=$(now)
    out=$($PY tools/diarize_ecapa.py "$wav" "$R/.tmp_$d/speakers_$d.rttm" 2> "$R/.tmp_$d/ecapa.err") \
      || { tail -5 "$R/.tmp_$d/ecapa.err"; fail "$d" labels "diarize_ecapa exit $?"; return 1; }
    mv "$R/.tmp_$d/speakers_$d.rttm" "$rttm"
    out=$(tail -1 <<< "$out")
    logstep "$d" labels "$t0" "$(kv turns "$out")" turns "$out"
  fi

  if [ ! -s "$emo" ]; then
    t0=$(now)
    out=$($PY tools/emotion_windows.py "$wav" "$R/.tmp_$d/emotion_$d.csv" 2> "$R/.tmp_$d/emotion.err") \
      || { tail -5 "$R/.tmp_$d/emotion.err"; fail "$d" emotion "emotion_windows exit $?"; return 1; }
    mv "$R/.tmp_$d/emotion_$d.csv" "$emo"
    out=$(tail -1 <<< "$out")
    logstep "$d" emotion "$t0" "$(kv windows "$out")" windows "$out"
  fi
  rm -f "$R/.tmp_$d"/*; rmdir "$R/.tmp_$d"
}

msg "run_all.sh start, pid $$, venv $V"
echo $$ > "$L/run_all.pid"
tail -n +2 data/meetings.csv | tr -d '\r' | while IFS=, read -r d vid _dur _bytes turl; do
  if [ $# -gt 0 ]; then case " $* " in *" $d "*) ;; *) continue ;; esac; fi
  msg "== $d (video $vid)"
  process "$d" "$vid" "$turl" < /dev/null || msg "$d stopped at a failure; moving on"
  $PY tools/status.py < /dev/null > /dev/null
done
rm -f "$L/run_all.pid"; $PY tools/status.py < /dev/null > /dev/null
msg "run_all.sh finished"
