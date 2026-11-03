# Session 20 data build: status

Updated 2026-11-02 17:43:08. `run_all.sh` is not running.

## Conferences finished, by step

| Step | Done (of 24) |
|---|---|
| MP4 (data/media) | 24 |
| WAV (data/media) | 24 |
| transcript PDF | 24 |
| words (replies) | 24 |
| speakers (replies) | 24 |
| emotion (replies) | 24 |

All steps complete: 24 of 24.

## Loop check

A conference is flagged when a segment's text repeats three or more times in a row (empty segments skipped), or when Whisper's word count is more than 20% above the transcript PDF's `pdftotext` count. Flagged ones are rerun with `--condition-on-previous-text False`; the first output is kept as `replies/words_YYYYMMDD_looped.json`.

Checked: 24. Flagged: 20: 20210127 (repeat 5, ratio 0.979, at 2813.4s:"and we're going to be able to do that." (rechecked with empty segments skipped; first check gave 3 at 3295.1s:thank you.)), 20210317 (repeat 4, ratio 0.984, at 3596.3s:'thank you.'), 20210428 (repeat 23, ratio 0.993, at 1945.9s:"i think that's a good question."), 20210728 (repeat 358, ratio 0.886, at 2810.5s:'michael mckee at bloomberg tv.'), 20210922 (repeat 225, ratio 0.766, at 3189.3s:"and that's the case."), 20211103 (repeat 86, ratio 0.984, at 2848.6s:'thank you, chairman.'), 20211215 (repeat 15, ratio 1.003, at 3654.8s:'thank you, mr. chair.'), 20220126 (repeat 15, ratio 0.991, at 2320.9s:"so that's-it's a very important question."), 20220316 (repeat 8, ratio 1.020, at 3263.9s:"and we're going to be a part of the market. and we're going "), 20220504 (repeat 221, ratio 0.814, at 1844.5s:'thank you.'), 20220615 (repeat 49, ratio 1.163, at 3112.6s:"we're not going to be able to do that."), 20220727 (repeat 186, ratio 1.008, at 1271.4s:'and you will raise rates this year in the future.'), 20220921 (repeat 290, ratio 0.921, at 2562.4s:'mr. chairman.'), 20221102 (repeat 11, ratio 1.051, at 2726.7s:'thanks.'), 20221214 (repeat 3, ratio 1.042, at 2731.6s:'thank you very much.'), 20230322 (repeat 145, ratio 0.822, at 2605.9s:'hi.'), 20230503 (repeat 258, ratio 0.798, at 1197.2s:'thank you.'), 20230726 (repeat 6, ratio 0.962, at 2516.8s:'and, and, and, and, and, and, and, and, and, and, and, and, '), 20231101 (repeat 6, ratio 1.011, at 3087.9s:'thank you.'), 20231213 (repeat 390, ratio 0.685, at 2220.3s:'thank you.')

Reruns without conditioning: 20210127 (8844 words, ratio 0.958, max repeat 2, clean), 20210317 (9658 words, ratio 0.951, max repeat 2, clean), 20210428 (9309 words, ratio 0.948, max repeat 15, STILL FLAGGED at 3051.2s:'greg robb.'), 20210728 (8979 words, ratio 0.939, max repeat 2, clean), 20210922 (8872 words, ratio 0.973, max repeat 2, clean), 20211103 (9374 words, ratio 0.974, max repeat 2, clean), 20211215 (10293 words, ratio 0.973, max repeat 1, clean), 20220126 (9091 words, ratio 0.961, max repeat 2, clean), 20220316 (8601 words, ratio 0.949, max repeat 4, STILL FLAGGED at 1395.1s:"i'm sorry."), 20220504 (8028 words, ratio 0.992, max repeat 1, clean), 20220615 (9237 words, ratio 0.980, max repeat 11, STILL FLAGGED at 107.8s:'and the growth of the economy,'), 20220727 (9207 words, ratio 0.953, max repeat 1, clean), 20220921 (7171 words, ratio 0.989, max repeat 2, clean), 20221102 (7741 words, ratio 0.993, max repeat 1, clean), 20221214 (7613 words, ratio 0.976, max repeat 10, STILL FLAGGED at 2152.7s:"i think that's a good thing to do with the fed."), 20230322 (7282 words, ratio 0.958, max repeat 1, clean), 20230503 (8382 words, ratio 0.973, max repeat 1, clean), 20230726 (8579 words, ratio 0.929, max repeat 1, clean), 20231101 (8747 words, ratio 0.967, max repeat 1, clean), 20231213 (7279 words, ratio 0.923, max repeat 2, clean)

Final transcripts not flagged but with a segment whose compression ratio is above 2.4 (Whisper's own threshold; a sign of repetition or skipped speech inside one segment): 20211103 (3.95), 20220921 (7.30), 20231213 (5.49)

Speaker tags in capitals ("CHAIR POWELL.", "MICHELLE SMITH.") that Whisper writes in the style of the Fed's transcripts, counted in each final transcript: 20210127 22, 20210317 34, 20210428 45, 20210616 27, 20210728 15, 20210922 27, 20211103 17, 20211215 31, 20220126 31, 20220316 35, 20220504 22, 20220615 16, 20220727 13, 20220921 16, 20221102 11, 20221214 5, 20230322 17, 20230726 1, 20230920 3, 20231101 7, 20231213 9.

## Failures

None.

## Seconds per step

| Date | download | wav | transcript_pdf | transcribe_cond | transcribe_nocond | labels | emotion | words | windows |
|---|---|---|---|---|---|---|---|---|---|
| 20210127 | 8.5 | 3.6 | 0.3 | 198.4 | 187.0 | 41.9 | 34.6 | 8844 | 330 |
| 20210317 | 9.8 | 3.9 | 0.4 | 217.1 | 183.0 | 45.1 | 32.4 | 9658 | 360 |
| 20210428 | 9.6 | 3.5 | 0.3 | 180.0 | 168.2 | 41.4 | 30.0 | 9309 | 333 |
| 20210616 | 10.6 | 3.8 | 0.4 | 199.9 |  | 43.0 | 32.6 | 10351 | 362 |
| 20210728 | 9.2 | 3.5 | 0.3 | 235.8 | 199.3 | 40.4 | 30.8 | 8979 | 329 |
| 20210922 | 9.3 | 3.6 | 0.6 | 184.3 | 162.0 | 39.7 | 29.8 | 8872 | 326 |
| 20211103 | 9.4 | 3.6 | 0.3 | 193.8 | 170.0 | 41.2 | 33.9 | 9374 | 334 |
| 20211215 | 10.5 | 4.0 | 0.3 | 214.1 | 184.0 | 44.6 | 32.6 | 10293 | 366 |
| 20220126 | 9.4 | 3.5 | 0.3 | 188.1 | 166.1 | 41.8 | 31.2 | 9091 | 333 |
| 20220316 | 10.0 | 3.5 | 0.3 | 191.3 | 164.2 | 38.6 | 30.3 | 8601 | 327 |
| 20220504 | 9.3 | 3.1 | 0.3 | 175.6 | 152.8 | 35.8 | 27.3 | 8028 | 285 |
| 20220615 | 10.1 | 3.6 | 0.3 | 208.4 | 169.9 | 38.9 | 30.0 | 9237 | 338 |
| 20220727 | 9.2 | 3.4 | 0.3 | 188.3 | 169.8 | 38.3 | 31.4 | 9207 | 327 |
| 20220921 | 7.8 | 2.7 | 0.3 | 190.0 | 148.9 | 31.8 | 32.9 | 7171 | 257 |
| 20221102 | 8.6 | 3.0 | 0.3 | 215.3 | 171.7 | 34.8 | 32.4 | 7741 | 273 |
| 20221214 | 8.8 | 3.0 | 0.3 | 201.6 | 136.8 | 33.0 | 25.4 | 7613 | 274 |
| 20230201 |  |  | 0.3 | 196.0 |  | 44.6 | 36.8 | 7451 | 268 |
| 20230322 | 8.3 | 2.9 | 0.3 | 151.3 | 135.3 | 32.4 | 25.4 | 7282 | 262 |
| 20230503 | 9.8 | 3.2 | 0.3 | 184.3 | 146.9 | 27.6 | 27.8 | 8382 | 296 |
| 20230614 | 9.7 | 3.3 | 0.3 | 176.8 |  | 37.1 | 30.3 | 8634 | 295 |
| 20230726 | 9.6 | 3.4 | 0.4 | 189.8 | 162.3 | 38.0 | 29.3 | 8579 | 296 |
| 20230920 | 10.7 | 3.4 | 0.3 | 196.9 |  | 41.0 | 32.3 | 9266 | 322 |
| 20231101 | 12.7 | 3.3 | 0.3 | 193.9 | 159.6 | 38.1 | 30.3 | 8747 | 309 |
| 20231213 | 11.0 | 3.1 | 0.3 | 178.6 | 172.6 | 33.2 | 30.8 | 7279 | 270 |

Blank download/wav cells for 20230201: its MP4 and WAV were copied from the feasibility run.

## Resume

Every step skips outputs that already exist, so resuming is the same command:

```bash
cd ~/github/aem6850/fall-2026/sessions/data/20-audio-ii
nohup caffeinate -i tools/run_all.sh >> logs/run_all.log 2>&1 &
```

Progress: `tail -f logs/run_all.log`. One conference only: `tools/run_all.sh 20210127`.
