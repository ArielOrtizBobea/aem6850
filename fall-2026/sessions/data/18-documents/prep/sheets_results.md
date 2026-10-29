# Session 18, handwritten rainfall sheets: what was built and what came out

Prepared 2026-10-27. All paths are relative to `fall-2026/sessions/data/18-documents/`.

## SOURCE

- Rainfall Rescue station folder for Abbotsbury Castle, Dorset (station RR1039), from
  https://github.com/ed-hawkins/rainfall-rescue (folder `DATA/ABBOTSBURY-CASTLE/`),
  Zenodo record 5770390 (v2.1.0), DOI https://doi.org/10.5281/zenodo.5770390, licence CC BY 4.0.
  Downloaded 2026-10-27.
- `sheets/ABBOTSBURY-CASTLE.pdf`: 6 pages, one JPEG per page at 170 ppi (PDF produced by ImageMagick,
  dated 2020-10-03). `pdfimages -j` extracted the JPEGs unchanged; PDF page 1 = 1860s, 2 = 1870s,
  3 = 1880s, 4 = 1890s, 5 = 1910s, 6 = 1920s (verified from the year headings on each image).
- `volunteers/`: the volunteers' transcriptions as published (five TYRain files used, the 1920s file
  and the combined `ABBOTSBURY-CASTLE.csv` kept but not used).
- Vision model: `claude-sonnet-5-5` through ellmer 0.5.0 (`chat_anthropic`, `chat_structured`),
  called 2026-10-27 between 17:32 and 17:34 local time (21:32-21:34 UTC), two runs per sheet,
  fresh chat each time, `cache = "none"`. System prompt used:

  > This image is a ten-year sheet of handwritten monthly rainfall in inches. Rows are the months
  > January to December, then a row with the written annual total. Columns are years. Return one
  > object per year column. Copy every number exactly as written on the sheet. Where a cell is blank
  > or you cannot read it, return null. Do not compute or correct anything.

  Structured output: an array of objects {year (integer), jan..dec (number, optional),
  total (number, optional, "the annual total as written on the sheet")}.
- Coding-agent captures: `claude` CLI 2.1.280, headless (`claude -p ... --allowedTools "Read,Write,Bash"
  --output-format text`), run 2026-10-27 21:32 UTC.

## 1. The six sheet images

| file | PDF page | pixels (w x h) | years with data | observer on the sheet |
|---|---|---|---|---|
| sheets/abbotsbury_1860s.jpg | 1 | 674 x 1061 | 1869 only | Peter McNeil |
| sheets/abbotsbury_1870s.jpg | 2 | 671 x 1090 | 1870, 1872-1879 | Mr McNeil, Gardener |
| sheets/abbotsbury_1880s.jpg | 3 | 671 x 1087 | 1880-1889 | Mr A. Dight |
| sheets/abbotsbury_1890s.jpg | 4 | 676 x 1082 | 1890-1891 | Mr A. Dight |
| sheets/abbotsbury_1910s.jpg | 5 | 669 x 1073 | 1911, 1914-1916 | Mr H. Kempshall |
| sheets/abbotsbury_1920s.jpg | 6 | 697 x 1060 | 1924-1925 | Mr H. Kempshall, for the Earl of Ilchester |

What is odd about each sheet (read from the images):

- 1860s. Printed form "RAINFALL AT", filled "Abbotsbury Castle, Dorchester" with "Castle" squeezed in above
  the line and "Dorset" below. Gauge diameter 5 in, height above ground 3 ft, 150 ft above sea level.
  "Frome-3" (river basin) in the margin, a large "60" stamp top right, punched holes down the left.
  Only the last column has a year heading (1869); the other nine year cells are blank. A "#" mark before
  January's 5.73. A note under the table: "Gauge stands in the flower garden fully exposed to the South
  & West but rather sheltered from the NE by a Bay Hedge." A small "C" under the Totals row.
- 1870s. "RAINFALL AT Dorchester, Abbotsbury Castle", County of Dorset (overwritten), observer
  "Mr McNeil, Gardener". Stamp "70". Diameter written ".5" (meaning 5), height 3 ft and 3.6 from the 1875
  column, altitude 150. The 1871 column is empty. June and July 1870 are bracketed together with one figure,
  1.23. A dash before April 1870's .30 and a "+" above October 1870's 3.35. "C" marks under 1870 and 1872.
- 1880s. "RAINFALL AT Abbotsbury Castle", Dorset, observer Mr A. Dight; a different, upright hand from the
  1870s. Diameter 5, height 3.6, altitude 150. Two braces: June+July 1886 share one figure (2.82) and
  January+February 1887 share one figure (4.57). The Means column carries 31.015 in the Totals row.
  Note under the table: "1888 Jan to March No observations. Sent subsequently HSW" (the three cells
  nevertheless hold 1.40, .95 and 3.26).
- 1890s. "RAINFALL AT Abbotsbury", Dorset, Mr A. Dight. The scan has a blue tint. Height "..." in the 1890
  column and 3.6 in the 1891 column. Only 1890 and 1891 are filled; the word "imp" sits in the 1892 cell of
  the Totals row; 1893-1899 are empty.
- 1910s. A different printed form (British Rainfall Organization, 62 Camden Square, London). "RAINFALL at
  Abbotsbury Castle Gardens", County of Dorsetshire, observer Mr H. Kempshall, River Basin "Frome & C 3";
  stamp "10"; a pencil note top left and a line "fumed 8.00 all over" (uncertain reading) under the
  gauge entry. Diameter 8, height 1.0, altitude 100. 1911 and 1914-1916 filled; "N.R." in the Totals row
  for 1912, 1913 and 1917; 1910, 1918, 1919 empty. A long note under the table dated 31.VIII.15: the gauge
  stood on a flower bed surrounded and overhung by trees and shrubs, very badly sheltered, and was moved on
  1.IX.15 100 yards east to an open lawn, "a good site". A bottom table lists the railway station, Abbotsbury.
- 1920s. Form B.R. H.20 (Meteorological Office, Air Ministry). "RAINFALL at Abbotsbury, Castle Gardens",
  Dorsetshire, Mr H. Kempshall "for Earl of Ilchester"; stamp "20". Diameter 8, height 1.0, altitude 120.
  1924 and 1925 filled. Four 1925 months are in parentheses (Jan 4.38, May 3.37, Nov 3.45, Dec 4.52), as is
  the 1925 total (36.95): estimated values, which the volunteers' combined CSV removed. "N.R" in 1926-1928
  with the note "Observer will not send. f 870440/28". Bottom table: 1924, railway station Abbotsbury
  1 1/4 mi E, parish church Abbotsbury 1 mi E.

Written Totals row, as read from each image (the human reference for the model's `total` field):

- 1860s: 1860-1868 blank; 1869 = 25.71.
- 1870s: 1870 = 18.45; 1871 blank; 1872 = 41.42; 1873 = 25.94; 1874 = 28.20; 1875 = 35.29; 1876 = 36.99;
  1877 = 34.47; 1878 = 28.08; 1879 = 35.17.
- 1880s: 1880 = 33.52; 1881 = 35.92; 1882 = 38.14; 1883 = 27.95; 1884 = 28.33; 1885 = 28.15; 1886 = 32.51;
  1887 = 25.14; 1888 = 31.88; 1889 = 28.61; Means = 31.015.
- 1890s: 1890 = 27.02; 1891 = 40.16; 1892 = the word "imp"; 1893-1899 blank.
- 1910s: 1910 blank; 1911 = 25.90; 1912 = N.R.; 1913 = N.R.; 1914 = 37.70; 1915 = 41.24; 1916 = 37.76;
  1917 = N.R.; 1918-1919 blank.
- 1920s: 1920-1923 blank; 1924 = 40.70 (a small "a" beneath); 1925 = (36.95) in parentheses, "a" beneath;
  1926 = N.R; 1927 = NR; 1928 = NR with the "Observer will not send" note; 1929 blank.

## 2. Volunteers, long format (`code/build_csv.R` -> `rain_volunteers.csv`)

650 rows (5 sheets x 10 years x 13 = 12 months + total); 333 cells with a number, 1 marked unread
(1887 February, -999.00 in the 1880s file). Columns: sheet, year, month ("jan".."dec", "total"),
inches, unread. Blank and -999 both become NA; unread is TRUE only for -999.

Per sheet: 1860s 13 numbers; 1870s 116; 1880s 126 (+1 unread); 1890s 26; 1910s 52.
The 1920s file was not converted (the sheet was not sent to the model; four of its values are
parenthesised estimates, so it is not a plain copy).

Things in the volunteers' files worth knowing:

- The per-sheet 1870s file has July 1870 = 1.23 (the bracketed June+July figure) and June blank; the
  combined `ABBOTSBURY-CASTLE.csv` has both as -999 ("June and July 1870 observations are combined").
- The 1880s file has June and July 1886 blank and January 1887 blank, February 1887 = -999.00; the
  combined file has all four as -999. The ERROR_ prefix marks that 1886 and 1887 do not add up
  (Difference row: 2.82 and 4.57, exactly the braced figures).
- The station name in row 1 differs sheet by sheet ("ABBOTSBURY CASTLE DORCHESTER", "DORCHESTER ABBOTSBURY
  CASTLE", "ABBOTSBURY", "ABBOTSBURY CASTLE GARDENS").

## 3. Vision-model calls (`code/make_cache.R` -> `cache/abbotsbury_<sheet>_run<r>.json`, `cache/log.csv`)

Ten calls, all succeeded. ellmer 0.5.0 notes:

- `chat_anthropic(cache = "none")` and `type_number(required = FALSE)` both work as given; no change.
- One deliberate change: `content_image_file(img, resize = "none")`. The ellmer default is `resize = "low"`,
  which shrinks the image to fit 512 x 512 (a 671 x 1087 sheet would become about 316 x 512 and the digits
  unreadable). The sheets are within the API's size limits, so they are sent as they are.
- `chat$get_tokens()` returns one row per assistant turn with input, output, cached_input and cost; the
  cost column is NA because ellmer 0.5.0 has no price entry for this model name, so `cost_usd` in
  `cache/log.csv` is NA and the costs below use assumed prices.
- `chat_structured()` returns a data frame (one row per year object); `write_json(..., auto_unbox = TRUE,
  na = "null")` writes it as an array of objects with null for missing cells.
- The 1860s sheet, whose only year heading is 1869, came back as a single object in both runs; the other
  four sheets came back with ten objects each. `build_csv.R` matches the model's years to the volunteers'
  year range per sheet and fills missing years with NA.

`rain_model.csv`: 1300 rows (650 per run), columns sheet, year, month, inches, run.

## 4. Comparisons (computed by compare.R, kept in the scratch folder; numbers below are from it)

### Run 1 model vs volunteers, per sheet (months and Total, cells where both have a number)

| sheet | compared | equal | share_equal | of_which_totals_compared |
|---|---|---|---|---|
| 1860s | 13 | 13 | 1.000 | 1 |
| 1870s | 116 | 115 | 0.991 | 9 |
| 1880s | 126 | 120 | 0.952 | 10 |
| 1890s | 26 | 26 | 1.000 | 2 |
| 1910s | 52 | 52 | 1.000 | 4 |

All sheets: 333 compared, 326 equal, share 0.979.

Disagreeing cells, run 1 (7):

| sheet | year | month | volunteers | model_run1 | crop |
|---|---|---|---|---|---|
| 1870s | 1877 | sep | 2.55 | 2.65 | sheets/crops/1870s_1877_sep.png |
| 1880s | 1882 | jun | 3.91 | 3.01 | sheets/crops/1880s_1882_jun.png |
| 1880s | 1882 | total | 38.14 | 38.24 | sheets/crops/1880s_1882_total.png |
| 1880s | 1884 | mar | 2.51 | 2.57 | sheets/crops/1880s_1884_mar.png |
| 1880s | 1886 | mar | 3.84 | 5.84 | sheets/crops/1880s_1886_mar.png |
| 1880s | 1886 | dec | 6.95 | 6.96 | sheets/crops/1880s_1886_dec.png |
| 1880s | 1888 | oct | 2.42 | 2.12 | sheets/crops/1880s_1888_oct.png |

### Run 2 model vs volunteers, per sheet (same measure)

| sheet | compared | equal | share_equal |
|---|---|---|---|
| 1860s | 13 | 13 | 1.000 |
| 1870s | 116 | 115 | 0.991 |
| 1880s | 126 | 123 | 0.976 |
| 1890s | 26 | 26 | 1.000 |
| 1910s | 52 | 52 | 1.000 |

All sheets, run 2: 333 compared, 329 equal, share 0.988.

Disagreeing cells, run 2 (4):

| sheet | year | month | volunteers | model_run2 |
|---|---|---|---|---|
| 1870s | 1877 | sep | 2.55 | 2.65 |
| 1880s | 1882 | jun | 3.91 | 3.01 |
| 1880s | 1886 | mar | 3.84 | 5.84 |
| 1880s | 1886 | dec | 6.95 | 6.96 |

Run 2 cells with a model number where the volunteers have NA (17):

| sheet | year | month | unread | model2 | crop |
|---|---|---|---|---|---|
| 1880s | 1886 | jun | FALSE | 2.82 | sheets/crops/1880s_1886_jun.png |
| 1880s | 1886 | jul | FALSE | 2.82 | sheets/crops/1880s_1886_jul.png |
| 1880s | 1887 | jan | FALSE | 4.57 | sheets/crops/1880s_1887_jan.png |
| 1880s | 1887 | feb | TRUE | 4.57 | sheets/crops/1880s_1887_feb.png |
| 1890s | 1892 | jan | FALSE | 0.00 | sheets/crops/1890s_1892_jan.png |
| 1890s | 1892 | feb | FALSE | 0.00 | sheets/crops/1890s_1892_feb.png |
| 1890s | 1892 | mar | FALSE | 0.00 | sheets/crops/1890s_1892_mar.png |
| 1890s | 1892 | apr | FALSE | 0.00 | sheets/crops/1890s_1892_apr.png |
| 1890s | 1892 | may | FALSE | 0.00 | sheets/crops/1890s_1892_may.png |
| 1890s | 1892 | jun | FALSE | 0.00 | sheets/crops/1890s_1892_jun.png |
| 1890s | 1892 | jul | FALSE | 0.00 | sheets/crops/1890s_1892_jul.png |
| 1890s | 1892 | aug | FALSE | 0.00 | sheets/crops/1890s_1892_aug.png |
| 1890s | 1892 | sep | FALSE | 0.00 | sheets/crops/1890s_1892_sep.png |
| 1890s | 1892 | oct | FALSE | 0.00 | sheets/crops/1890s_1892_oct.png |
| 1890s | 1892 | nov | FALSE | 0.00 | sheets/crops/1890s_1892_nov.png |
| 1890s | 1892 | dec | FALSE | 0.00 | sheets/crops/1890s_1892_dec.png |
| 1890s | 1892 | total | FALSE | 0.00 | sheets/crops/1890s_1892_total.png |

### Cells with a number on one side only, run 1

| sheet | model_NA_volunteers_number | model_number_volunteers_NA | model_number_volunteers_NA_unread |
|---|---|---|---|
| 1860s | 0 | 0 | 0 |
| 1870s | 0 | 0 | 0 |
| 1880s | 0 | 4 | 1 |
| 1890s | 0 | 0 | 0 |
| 1910s | 0 | 3 | 0 |

Model NA where the volunteers have a number (0):

(none)

Model number where the volunteers have NA (7; unread = the volunteers wrote -999 there). Candidate invented numbers unless the crop shows a value:

| sheet | year | month | unread | model1 | crop |
|---|---|---|---|---|---|
| 1880s | 1886 | jun | FALSE | 2.82 | sheets/crops/1880s_1886_jun.png |
| 1880s | 1886 | jul | FALSE | 2.82 | sheets/crops/1880s_1886_jul.png |
| 1880s | 1887 | jan | FALSE | 4.57 | sheets/crops/1880s_1887_jan.png |
| 1880s | 1887 | feb | TRUE | 4.57 | sheets/crops/1880s_1887_feb.png |
| 1910s | 1912 | total | FALSE | -1.00 | sheets/crops/1910s_1912_total.png |
| 1910s | 1913 | total | FALSE | -1.00 | sheets/crops/1910s_1913_total.png |
| 1910s | 1917 | total | FALSE | -1.00 | sheets/crops/1910s_1917_total.png |

### Sum of the 12 model months (run 1) against the model's total field and the volunteers' transcribed Total

Only years where the model returned at least one month. months_NA = months the model left null (the sum is over the others). Flag = |difference| > 0.01.

| sheet | year | months_NA | model_month_sum | model_total | diff_vs_model_total | volunteers_total | diff_vs_volunteers_total | flag |
|---|---|---|---|---|---|---|---|---|
| 1860s | 1869 | 0 | 25.71 | 25.71 | 0.00 | 25.71 | 0.00 |  |
| 1870s | 1870 | 1 | 18.45 | 18.45 | -0.00 | 18.45 | -0.00 |  |
| 1870s | 1872 | 0 | 41.42 | 41.42 | 0.00 | 41.42 | 0.00 |  |
| 1870s | 1873 | 0 | 25.94 | 25.94 | 0.00 | 25.94 | 0.00 |  |
| 1870s | 1874 | 0 | 28.20 | 28.20 | 0.00 | 28.20 | 0.00 |  |
| 1870s | 1875 | 0 | 35.29 | 35.29 | 0.00 | 35.29 | 0.00 |  |
| 1870s | 1876 | 0 | 36.99 | 36.99 | -0.00 | 36.99 | -0.00 |  |
| 1870s | 1877 | 0 | 34.57 | 34.47 | 0.10 | 34.47 | 0.10 | FLAG |
| 1870s | 1878 | 0 | 28.08 | 28.08 | 0.00 | 28.08 | 0.00 |  |
| 1870s | 1879 | 0 | 35.17 | 35.17 | 0.00 | 35.17 | 0.00 |  |
| 1880s | 1880 | 0 | 33.52 | 33.52 | 0.00 | 33.52 | 0.00 |  |
| 1880s | 1881 | 0 | 35.92 | 35.92 | 0.00 | 35.92 | 0.00 |  |
| 1880s | 1882 | 0 | 37.24 | 38.24 | -1.00 | 38.14 | -0.90 | FLAG |
| 1880s | 1883 | 0 | 27.95 | 27.95 | 0.00 | 27.95 | 0.00 |  |
| 1880s | 1884 | 0 | 28.39 | 28.33 | 0.06 | 28.33 | 0.06 | FLAG |
| 1880s | 1885 | 0 | 28.15 | 28.15 | 0.00 | 28.15 | 0.00 |  |
| 1880s | 1886 | 0 | 37.34 | 32.51 | 4.83 | 32.51 | 4.83 | FLAG |
| 1880s | 1887 | 0 | 29.71 | 25.14 | 4.57 | 25.14 | 4.57 | FLAG |
| 1880s | 1888 | 0 | 31.58 | 31.88 | -0.30 | 31.88 | -0.30 | FLAG |
| 1880s | 1889 | 0 | 28.61 | 28.61 | 0.00 | 28.61 | 0.00 |  |
| 1890s | 1890 | 0 | 27.02 | 27.02 | 0.00 | 27.02 | 0.00 |  |
| 1890s | 1891 | 0 | 40.16 | 40.16 | 0.00 | 40.16 | 0.00 |  |
| 1910s | 1911 | 0 | 25.90 | 25.90 | 0.00 | 25.90 | 0.00 |  |
| 1910s | 1914 | 0 | 37.70 | 37.70 | 0.00 | 37.70 | 0.00 |  |
| 1910s | 1915 | 0 | 41.24 | 41.24 | 0.00 | 41.24 | 0.00 |  |
| 1910s | 1916 | 0 | 37.76 | 37.76 | 0.00 | 37.76 | 0.00 |  |

Flagged years: 6 of 26.

### Run 1 vs run 2, per sheet (all 130 cells per sheet; NA on both sides counts as equal)

| sheet | cells | equal | share_equal | both_numbers_equal | both_NA | changed |
|---|---|---|---|---|---|---|
| 1860s | 130 | 130 | 1.000 | 13 | 117 | 0 |
| 1870s | 130 | 130 | 1.000 | 116 | 14 | 0 |
| 1880s | 130 | 127 | 0.977 | 127 | 0 | 3 |
| 1890s | 130 | 117 | 0.900 | 26 | 91 | 13 |
| 1910s | 130 | 127 | 0.977 | 52 | 75 | 3 |

Cells that changed between runs (19):

| sheet | year | month | volunteers | run1 | run2 |
|---|---|---|---|---|---|
| 1880s | 1882 | total | 38.14 | 38.24 | 38.14 |
| 1880s | 1884 | mar | 2.51 | 2.57 | 2.51 |
| 1880s | 1888 | oct | 2.42 | 2.12 | 2.42 |
| 1890s | 1892 | jan |  |  | 0.00 |
| 1890s | 1892 | feb |  |  | 0.00 |
| 1890s | 1892 | mar |  |  | 0.00 |
| 1890s | 1892 | apr |  |  | 0.00 |
| 1890s | 1892 | may |  |  | 0.00 |
| 1890s | 1892 | jun |  |  | 0.00 |
| 1890s | 1892 | jul |  |  | 0.00 |
| 1890s | 1892 | aug |  |  | 0.00 |
| 1890s | 1892 | sep |  |  | 0.00 |
| 1890s | 1892 | oct |  |  | 0.00 |
| 1890s | 1892 | nov |  |  | 0.00 |
| 1890s | 1892 | dec |  |  | 0.00 |
| 1890s | 1892 | total |  |  | 0.00 |
| 1910s | 1912 | total |  | -1.00 |  |
| 1910s | 1913 | total |  | -1.00 |  |
| 1910s | 1917 | total |  | -1.00 |  |

### Seconds, tokens and cost per call

Prices assumed: USD 3 per million input tokens, USD 15 per million output tokens (to be checked against the current price list; ellmer's own cost column is also shown).

| sheet | run | seconds | input_tokens | output_tokens | cached_input_tokens | cost_at_3_15 | ellmer_cost_usd |
|---|---|---|---|---|---|---|---|
| 1860s | 1 | 39.4000 | 1625 | 113 | 0 | 0.0066 |  |
| 1860s | 2 | 2.3000 | 1625 | 113 | 0 | 0.0066 |  |
| 1870s | 1 | 14.1000 | 1611 | 2443 | 0 | 0.0415 |  |
| 1870s | 2 | 14.2000 | 1611 | 2400 | 0 | 0.0408 |  |
| 1880s | 1 | 6.5000 | 1611 | 1094 | 0 | 0.0212 |  |
| 1880s | 2 | 6.0000 | 1611 | 1094 | 0 | 0.0212 |  |
| 1890s | 1 | 2.7000 | 1650 | 278 | 0 | 0.0091 |  |
| 1890s | 2 | 2.8000 | 1650 | 354 | 0 | 0.0103 |  |
| 1910s | 1 | 4.7000 | 1611 | 500 | 0 | 0.0123 |  |
| 1910s | 2 | 3.1000 | 1611 | 482 | 0 | 0.0121 |  |

Per sheet (both runs):

| sheet | seconds | input_tokens | output_tokens | cost_at_3_15 |
|---|---|---|---|---|
| 1860s | 41.7000 | 3250.0000 | 226.0000 | 0.0131 |
| 1870s | 28.3000 | 3222.0000 | 4843.0000 | 0.0823 |
| 1880s | 12.5000 | 3222.0000 | 2188.0000 | 0.0425 |
| 1890s | 5.5000 | 3300.0000 | 632.0000 | 0.0194 |
| 1910s | 7.8000 | 3222.0000 | 982.0000 | 0.0244 |

All ten calls: 95.8 s, 16216 input tokens, 8871 output tokens, USD 0.1817 at 3/15 (ellmer: USD NA). Mean per call: 9.6 s, USD 0.0182.

### The 1880s sheet: the braced months

On the sheet June and July 1886 share one braced figure (2.82) and January and February 1887 share one (4.57). The volunteers left them blank or -999.

| year | month | volunteers | unread | run1 | run2 |
|---|---|---|---|---|---|
| 1886 | jun |  | FALSE | 2.82 | 2.82 |
| 1886 | jul |  | FALSE | 2.82 | 2.82 |
| 1887 | jan |  | FALSE | 4.57 | 4.57 |
| 1887 | feb |  | TRUE | 4.57 | 4.57 |

- Run 1, 1886: model months sum to 37.34 (0 null), written total 32.51, model total field 32.51, difference +4.83.
- Run 1, 1887: model months sum to 29.71 (0 null), written total 25.14, model total field 25.14, difference +4.57.
- Run 2, 1886: model months sum to 37.34 (0 null), written total 32.51, model total field 32.51, difference +4.83.
- Run 2, 1887: model months sum to 29.71 (0 null), written total 25.14, model total field 25.14, difference +4.57.


### What the crops show (sheets/crops/<sheet>_<year>_<month>.png, 130 x 90 px around the cell, 3x)

Disagreements where both sides have a number:

- 1870s 1877 September: the glyph can be read as 2.55 or 2.65; the written total 34.47 is reached only with
  2.55, so the volunteers are right and the model (2.65 in both runs) is off by 0.10. The model's own total
  field says 34.47, so its months do not add up.
- 1880s 1882 June: the sheet says 3.91; the model wrote 3.01 in both runs. Run 1 also changed the 1882 total
  to 38.24 (sheet: 38.14); run 2 copied 38.14.
- 1880s 1884 March: 2.51 on the sheet; run 1 wrote 2.57, run 2 2.51.
- 1880s 1886 March: 3.84 on the sheet; the model wrote 5.84 in both runs.
- 1880s 1886 December: 6.95 on the sheet; the model wrote 6.96 in both runs.
- 1880s 1888 October: 2.42 on the sheet; run 1 wrote 2.12, run 2 2.42.

So of the seven run-1 disagreements, four persist in run 2 (1877 Sep, 1882 Jun, 1886 Mar, 1886 Dec; run 2
has exactly these four) and three (1882 total, 1884 Mar, 1888 Oct) were read correctly the second time.

Numbers where the volunteers have none:

- 1886 June and July, 1887 January and February: the sheet has one braced figure across each pair of months
  (2.82 and 4.57). Both runs copied the figure into both months, so each pair is counted twice: 1886's months
  sum to 37.34 against the written 32.51 (+4.83 = 2.82 duplicated + the 2.00 error in March + 0.01 in
  December) and 1887's to 29.71 against 25.14 (+4.57). The model's total field has the written totals, so a
  sum check catches both years. The prompt said nothing about braces.
- 1910s 1912, 1913 and 1917 totals, run 1: the sheet says "N.R." (no record) and the model returned -1.00 in
  the numeric field; run 2 returned null. An invented sentinel value, outside the prompt's "return null".
- 1890s 1892, run 2: the whole column is empty on the sheet except the word "imp" in the Totals row; run 2
  returned 0.00 for all twelve months and the total; run 1 returned null. Thirteen invented zeros.

No cell where the model returned null but the volunteers have a number, in either run.

## 5. Coding-agent captures (`agent/`)

Both ran to completion with `claude -p` (CLI 2.1.280, nested inside this session without complaint).
The text transcript does not name the model; the user's `~/.claude/settings.json` sets `"model": "opus[1m]"`,
so that is what the CLI would have used. The two captures ran at the same time as each other and as the ten
API calls, so the elapsed times are under some load.

- Capture A, Table 6 of h41.pdf: 52 s (21:32:23 to 21:33:15 UTC), exit code 0. Wrote `table6.csv` with 24
  rows and 15 columns: Section and Item (two label columns, not one), Total, then the twelve Reserve Banks
  Boston to San Francisco; values in millions with the commas removed; the four Deposits sub-items labelled
  "Deposits: ...". It reported seven rows where the twelve banks do not add to Total, all by 1 or 2 (Coin,
  Central bank liquidity swaps, Interdistrict settlement account, Federal Reserve notes net, Reverse
  repurchase agreements, Deposits: Foreign official, Total liabilities) and attributed them to rounding. It
  read the +/- signs on the Interdistrict settlement account row as signed numbers and checked them against
  the Total assets column. Spot check against `pdftotext` of pages 8-9: the Coin row, the Interdistrict row
  (with signs) and the Total assets / liabilities rows match the printed figures. Files:
  `agent/table6_agent.csv`, `agent/table6_transcript.txt`.
- Capture B, the 1880s sheet image: 41 s (21:32:23 to 21:33:04 UTC), exit code 0. Wrote
  `abbotsbury_1880s.csv` (Month, 1880..1889, Means; 13 rows), keeping leading-dot decimals as written (".52").
  It put each braced figure in one month (4.57 in February 1887, 2.82 in June 1886) and left the other month
  empty, then reported that all ten years add up to the written totals and that 31.015 is the mean of the ten
  totals. Against the volunteers: all 126 cells both have are equal; it differs only in holding 2.82 and 4.57
  where the volunteers have blank / -999. It read 1882 June, 1886 March and 1886 December correctly, the three
  cells the single-shot API call got wrong in both runs. Files: `agent/abbotsbury_1880s_agent.csv`,
  `agent/abbotsbury_1880s_transcript.txt`.

## 6. Files written

- sheets/abbotsbury_1860s.jpg, _1870s.jpg, _1880s.jpg, _1890s.jpg, _1910s.jpg, _1920s.jpg (extracted, renamed)
- sheets/crops/*.png (27 cell crops, named <sheet>_<year>_<month>.png)
- code/build_csv.R, code/make_cache.R
- rain_volunteers.csv, rain_model.csv
- cache/abbotsbury_<sheet>_run1.json and _run2.json for 1860s, 1870s, 1880s, 1890s, 1910s (10 files); cache/log.csv
- agent/table6_agent.csv, agent/table6_transcript.txt, agent/abbotsbury_1880s_agent.csv, agent/abbotsbury_1880s_transcript.txt
- prep/sheets_results.md (this file)
- Scratch only (not in the repo): compare.R, compare_sections.md, make_cache.log, the two capture folders
  agent_table6/ and agent_sheet/, and nest_test/ under
  /private/tmp/claude-501/-Users-ao332-github-aem6850/f96c179c-1948-428f-95c1-3931b2b58aa5/scratchpad/s18_sheets/

Nothing was committed to git.
