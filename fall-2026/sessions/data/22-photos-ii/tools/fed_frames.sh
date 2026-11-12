#!/bin/bash
# AEM 6850, session 22. Tool, run before class on this laptop with ffmpeg. Students do not run it.
#
# One frame every 30 seconds from each of the Fed's 24 press-conference videos of 2021 to 2023
# (480 by 270 pixels, the Fed's own recordings, already saved for the audio sessions in
# ../20-audio-ii/data/media/). No model runs here and nothing is trained: ffmpeg only decodes
# the video and saves still images. Writes data/fed/frames/fomcYYYYMMDD/<seconds>.jpg, where
# <seconds> is the time from the start of the recording (git-ignored).
#
#   bash tools/fed_frames.sh        from the 22-photos-ii folder
SRC=../20-audio-ii/data/media
t0=$(date +%s); n=0
for v in "$SRC"/fomc*_270p.mp4; do
  d=$(basename "$v" _270p.mp4); out=data/fed/frames/$d; mkdir -p "$out"
  # fps=1/30 keeps one frame per 30 s; yuvj420p is the full-range pixel format JPEG needs
  ffmpeg -loglevel error -y -i "$v" -vf "fps=1/30" -pix_fmt yuvj420p -q:v 3 "$out/tmp_%05d.jpg"
  i=0
  for f in "$out"/tmp_*.jpg; do
    mv "$f" "$out/$(printf '%05d' $((i * 30))).jpg"; i=$((i + 1)); n=$((n + 1))
  done
done
secs=$(( $(date +%s) - t0 ))
echo "$n frames from $(ls -d data/fed/frames/fomc* | wc -l | tr -d ' ') videos in $secs s"
mkdir -p logs
echo "$(date '+%Y-%m-%d %H:%M') $n frames, one every 30 s, in $secs s, ffmpeg" >> logs/fed_frames.log
