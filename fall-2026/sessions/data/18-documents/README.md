# 18-documents

The project for AEM 6850, session 18, Documents & scans (Thursday, October
29, 2026): turning a born-digital PDF, a scanned printed page and
handwritten sheets into tables you can check.

Open `18-documents.Rproj` first. R then starts in this folder, and every
path in the slides, the live script and the scripts below is relative to it.

## What is where

```
18-documents/
  18-documents.Rproj
  README.md      this file
  code/          the scripts, numbered in the order the lecture uses them
  data/          the raw files, exactly as downloaded; nothing else
  data_clean/    everything computed from data/
  replies/       every vision-model reply, exactly as returned
  logs/          one line per model call: seconds and tokens
  agent/         the two coding-agent runs made before class
  prep/          the instructor's notes from preparing the session
```

**`data/`, raw.**

- `h41.pdf`: the Federal Reserve's H.4.1 release of 3 October 2024, 11 pages.
- `comp1899_p.pdf`: one page (printed page 646) of the Comptroller of the
  Currency's annual report for 1899, a scan with the archive's OCR text.
- `sheets/`: Rainfall Rescue's `ABBOTSBURY-CASTLE.pdf` and its six pages as
  JPEG images, ten-year sheets of monthly rainfall, 1860s to 1920s (the
  session uses five).
- `volunteers/`: the volunteers' typing of each sheet, as Rainfall Rescue
  publishes it. -999 marks a cell they could not read; the `ERROR_` prefix
  marks a sheet where a year's months do not add up to the typed total.

**`data_clean/`, computed.** The number is the script that writes the file.

- `comp1899_p.png` (2): the 1899 page rendered at 300 dpi, the image that
  OCR and the model read.
- `comp1899_truth.csv`: the reference copy of the 1899 table, 58 rows and
  348 cells, read cell by cell from enlarged crops before class and
  confirmed by every sum the page prints. Typed, not computed; every
  reading of the page is scored against it.
- `ocr/` (2): tesseract's text for each page image it read, the images
  themselves, and the three OCR readings of the 1899 page in six columns
  (`comp1899_archive.csv`, `comp1899_tess300.csv`, `comp1899_tess100.csv`).
- `comp1899_model.csv` (3): the model's reading of the 1899 page, row by
  row against the reference copy.
- `table6.csv` (1): Table 6 of the H.4.1, one row per item, twelve banks
  and the Total.
- `rain_volunteers.csv`, `rain_model.csv` (5): the volunteers' and the
  model's readings of the five sheets, one row per sheet, year and month.
- `compare_sheets.md`, `crops/` (6): the model against the volunteers,
  cell by cell, and a crop of every cell discussed.
- `scores_by_size.csv` (8): cells right for each model size.

**`replies/`, the model's raw replies.** Made with the ellmer package on
27 and 29 October 2026; no one needs an API key to use them.

- `abbotsbury_<decade>_run<r>.json`: the medium model's reading of each
  sheet, two runs each (4).
- `comp1899_run1.json` and `comp1899_run1_markdown.md`: its reading of the
  1899 page, as structured data and as the plain table of the first
  request (3). `comp1899_direct_run1.json` to `_run3.json` are the
  one-request form that failed, kept for the record.
- `sizes/`: the same pages read by the provider's small and large models (7).

**`logs/`.**

- `model_calls.csv`: one line per model call, all sizes: the model, the
  page, the run, when, seconds, input and output tokens. The cost slide
  reads it.
- `comp1899_run1_meta.json` and `comp1899_direct_run*_meta.json`: the
  instructions, requests and tokens of each call on the 1899 page.
- `comp1899_small_turns.csv`, `comp1899_large_turns.csv`: tokens per
  request in the two-request calls on the 1899 page.

## The scripts, in lecture order

| Script | Lecture part | What it does |
|:--|:--|:--|
| `1_fed_table6.R` | 2, born-digital PDF | Table 6 of the H.4.1 from its text layer |
| `2_ocr_runs.R` | 3, scan of a printed page | tesseract on the Fed's page 8 at four resolutions and on the 1899 page; the archive's OCR; each scored |
| `3_model_1899.R` | 3 | a vision model on the 1899 page, scored against the reference copy |
| `4_model_sheets.R` | 4, handwritten page | a vision model on the five rainfall sheets |
| `5_sheets_to_csv.R` | 4 | the volunteers' and the model's readings as long tables |
| `6_compare_sheets.R` | 4 | the model against the volunteers, cell by cell |
| `7_model_sizes.R` | 5, thousands of pages | the same pages read by a smaller and a larger model |
| `8_compare_sizes.R` | 5 | cells right by model size |

`code/run_everything.R` runs them all, in order, in about half a minute.
`code/prompt_sheet.txt` holds the instructions sent with each rainfall
sheet.

Each script opens by loading the packages it uses and installing any that
are missing: pdftools, stringr, tesseract, magick, xml2, jsonlite and
ellmer. On Linux, install the poppler and tesseract system libraries first.

Scripts 3, 4 and 7 call a model only when its reply is missing from
`replies/`, so with the folder as shipped they make no call and need no
key. A new call needs an API key in `ANTHROPIC_API_KEY`, set once in
`~/.Renviron`, never in a script, and it costs money: the 22 calls of
script 7 cost $0.53 on 29 October 2026.

## Where the raw data came from

- `h41.pdf`: Board of Governors of the Federal Reserve System, statistical
  release H.4.1, "Factors Affecting Reserve Balances", 3 October 2024,
  https://www.federalreserve.gov/releases/h41/20241003/h41.pdf (192,780
  bytes, 11 pages, made in Microsoft Word). Table 5 (consolidated
  statement) is on pages 6-7, Table 6 (each Reserve Bank) on pages 8-9.
  US federal work, public domain. Downloaded 27 October 2026.
- `comp1899_p.pdf`: Annual Report of the Comptroller of the Currency, 1899,
  Volume 1, PDF page 693, printed page 646, Table XVII ("Aggregate
  resources, expressed in millions of dollars, of national banks on June
  30, 1899, and State, savings, private banks, and loan and trust companies
  at date of latest returns to this bureau"). Cut with
  `pdftools::pdf_subset()` from
  https://fraser.stlouisfed.org/files/docs/publications/comp/1890s/1899/compcurr_1899_vol1.pdf
  (FRASER, Federal Reserve Bank of St. Louis; 907 pages of 300-dpi scans
  with an OCR text layer added by the archive). US federal work.
  Downloaded 27 October 2026.
- `sheets/`: ten-year sheets of monthly rainfall at Abbotsbury Castle,
  Dorset, England, from the Met Office archive, as published by Rainfall
  Rescue, https://github.com/ed-hawkins/rainfall-rescue,
  `DATA/ABBOTSBURY-CASTLE/ABBOTSBURY-CASTLE.pdf` (six pages, JPEG at 170
  ppi, the JPEGs extracted unchanged with pdfimages). Pages 1-6 are the
  1860s, 1870s, 1880s, 1890s, 1910s and 1920s sheets. Licence CC BY 4.0
  (Zenodo record 5770390, v2.1.0). Paper: Hawkins et al., Geoscience Data
  Journal, 2023, https://doi.org/10.1002/gdj3.157.
- `volunteers/`: the volunteers' transcriptions of each sheet
  (`TYRain_*.csv`, and the `ERROR_` file for the 1880s) and the combined
  station series (`ABBOTSBURY-CASTLE.csv`), from the same repository,
  unchanged.

The coding-agent runs in `agent/` were made on 27 October 2026: Table 6
of `h41.pdf`, and the 1880s sheet. `agent/request_1880s.txt` is the
request typed live in class.
