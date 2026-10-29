# Session 18 prep: the Fed PDF and the 1899 scan

Results of `code/fed_tables.R`, `code/ocr_runs.R` and `code/make_cache_1899.R`,
all run from this folder on 2026-10-27. Every number below is printed by one of
those scripts.

## A. The Fed's H.4.1 text layer (fed_tables.R)

`pdf_text("h41.pdf")` gives 11 pages. Lines are `strsplit(txt[p], "\n")[[1]]`.

### A1. Headline totals of Table 5 (pages 6 and 7)

The exact lines (the `(0)` is the "eliminations from consolidation" column;
the last two numbers are the changes since Sep 25, 2024 and Oct 4, 2023):

```
"Total assets                                                           (0)            7,046,925         -    33,134           -   908,857"
"Total liabilities                                                              (0)              7,003,485              -     33,151             -   909,566"
"Total capital                                                                                       43,440             +          17            +         709"
```

One pattern, one capture group, works for all three (the `(0)` is optional):

```r
str_match(line, "Total assets\\s+(?:\\(\\d+\\)\\s+)?([\\d,]+)")[, 2]        # "7,046,925"
str_match(line, "Total liabilities\\s+(?:\\(\\d+\\)\\s+)?([\\d,]+)")[, 2]   # "7,003,485"
str_match(line, "Total capital\\s+(?:\\(\\d+\\)\\s+)?([\\d,]+)")[, 2]       # "43,440"
```

7,003,485 + 43,440 == 7,046,925: TRUE.

### A2. "An amount" on page 8 (Table 6)

```r
amt <- "(?<=\\s|^)(?:[-+]\\s*)?\\d{1,3}(?:,\\d{3})*(?=\\s|$)"
```

An amount is digits in groups of three with commas, optionally signed, standing
alone between spaces or at a line end. What it rejects and why:

| text on the page | why it is not an amount |
|---|---|
| `loans1`, `Program)2`, `swaps3`, `Other7` (footnote markers) | preceded by a letter or `)`, not a space |
| `(0)` on pages 6-7 | wrapped in parentheses |
| `October 2, 2024` in the title | `2` is followed by a comma; `2024` has four digits |
| `H.4.1`, `6. Statement` | followed by a point |

Zeros are printed as `0` (12 on page 8); there are no dashes and no blank cells
in Table 6. The Interdistrict settlement account row carries its sign as a
separate token (`0 +     23,560 -   128,473 ...`), so the sign may be followed
by spaces; `as.numeric` after removing commas and spaces keeps the sign.

Amounts per line, `table(n)`:

| page | n = 0 | n = 13 | other |
|---|---|---|---|
| 8 | 16 lines | 9 lines | none |
| 9 | 15 lines | 15 lines | none |

The 0-amount lines are the header block (`H.4.1`, title, `Millions of dollars`,
the two-line column headings with `Kansas City` and `San Francisco` split over
lines 5-7), the section words `Assets` / `Liabilities` / `Capital`, blank
lines, the `Note:` line, and the first lines of wrapped item names (`Gold
certificates and special drawing`, `Securities, unamortized premiums and`,
`Net portfolio holdings of MS`, `Foreign currency denominated`, `Earnings
remittances due to the U.S.`, `Other liabilities and accrued`). Every data row
has exactly 13 amounts; no row has more or fewer. Total assets on page 8:

```
7,046,925 186,283 3,612,792 161,095 307,691 628,803 479,435 361,493 111,516 52,039 72,874 335,154 737,750
```

### A3. Table 6 as a data frame

`dim(tab)`: 24 rows x 15 columns (`label`, `label_full`, `Total`, 12 banks).
`label` is the text before the first amount with the footnote digit removed;
for the six wrapped items that is only the last line (`rights certificates`,
`and loans`, `Lending Program)`, `assets`, `Treasury`, `dividends`), so
`label_full` glues the preceding indented no-amount lines back on.

Row labels (`label_full`), in order: Gold certificates and special drawing
rights certificates; Coin; Securities, unamortized premiums and discounts,
repurchase agreements, and loans; Net portfolio holdings of MS Facilities 2020
LLC (Main Street Lending Program); Central bank liquidity swaps; Foreign
currency denominated assets; Other assets; Interdistrict settlement account;
Total assets; Federal Reserve notes, net; Reverse repurchase agreements;
Deposits; Depository institutions; U.S. Treasury, General Account; Foreign
official; Other; Earnings remittances due to the U.S. Treasury; Treasury
contributions to credit facilities; Other liabilities and accrued dividends;
Total liabilities; Capital paid in; Surplus; Other capital; Total liabilities
and capital.

`rowSums(tab[, banks]) - tab$Total`:

| rows exact | off by 1 | off by 2 | larger | largest |diff| |
|---|---|---|---|---|
| 17 | 4 | 3 | 0 | 2 |

Nonzero rows: Coin -1, Central bank liquidity swaps +2, Interdistrict
settlement account -1, Federal Reserve notes, net +1, Reverse repurchase
agreements -1, Foreign official -2, Total liabilities +2. (The Fed rounds each
column to millions; the page says so in its note.)

Headline rows: Total assets 7,046,925; Total liabilities 7,003,485; Total
liabilities and capital 7,046,925; Total liabilities + Capital paid in +
Surplus + Other capital = 7,046,925. Saved as `table6.csv`.

## B. OCR of the Fed's page 8 (ocr_runs.R)

`pdf_convert("h41.pdf", pages = 8, dpi = d, filenames = "ocr/h41_p8_<d>.png")`,
then `tesseract::ocr()`. The page is landscape (11 x 8.5 in).

| dpi | pixels | ocr time | lines of text | Total assets line | amounts found | exactly right |
|---|---|---|---|---|---|---|
| 300 | 3300 x 2550 | 1.2-2.3 s | 21 | found | 13 | 13 of 13 |
| 150 | 1650 x 1275 | 0.7 s | 21 | found | 13 | 13 of 13 |
| 100 | 1100 x 850 | 0.1 s | 1 (the title only) | not found | 0 | 0 of 13 |
| 72 | 792 x 612 | 0.0 s | 0 (empty string) | not found | 0 | 0 of 13 |

Raw OCR of the Total assets line at 300 dpi:

```
Total assets 7,046,925 186 ,283| 3,612,792 161,095 307,691 628 ,803 479,435) 361,493 111,516 52,039] 72,874 335,154 737,750
```

and at 150 dpi:

```
Total assets 7,046,925 186,283} 3,612, 792| 161,095) 307,691) 628, 803} 479,435) 361,493} 111,516 52,039] 72,874| 335,154] 737,750
```

OCR puts a space before or after some commas and reads the table rules as
`| ] } )`. The adapted extraction removes spaces around commas
(`str_replace_all(line, "\\s*,\\s*", ",")`) and the characters `| [ ] { } ( ) /`,
then applies the same `amt` pattern. After that, all 13 amounts are right at
300 and at 150 dpi. At 100 dpi tesseract returns only the title line; at 72
dpi nothing (the body text is about 6 px tall).

`ocr_data()` confidence of the words on the Total assets line, 300 dpi (17
words, mean 80.8, min 36.8):

| word | conf | word | conf | word | conf |
|---|---|---|---|---|---|
| Total | 96.2 | 307,691 | 93.1 | 111,516 | 96.8 |
| assets | 96.2 | 628 | 84.7 | 52,039] | 36.8 |
| 7,046,925 | 83.9 | ,803 | 84.7 | 72,874 | 89.1 |
| 186 | 46.0 | 479,435) | 72.8 | 335,154 | 91.5 |
| ,283\| | 46.0 | 361,493 | 89.5 | 737,750 | 96.0 |
| 3,612,792 | 96.5 | 161,095 | 74.9 | | |

The split words (`186` + `,283|`, `628` + `,803`) and the words with a rule
stuck on (`52,039]`, `479,435)`) are the low-confidence ones, although their
digits are right. At 100 dpi `ocr_data()` finds no Total assets line (0 words).

## C. The 1899 scan

### C6. The page

`pdf_subset(SRC, pages = 693, output = "comp1899_p.pdf")`: 1 page, PDF 1.3,
396 x 612 pt (5.5 x 8.5 in), 495,562 bytes. `pdf_text()` returns 7,962
characters (the archive's OCR layer survives the subset). `pdf_convert()` at
300 dpi: `comp1899_p.png`, 1650 x 2550 px, 712,915 bytes; at 100 dpi:
`ocr/comp1899_100.png`, 550 x 850 px.

### C7. Truth

`ocr/comp1899_truth.csv`: all 58 rows (51 states and territories, 6 region
totals, Total United States), six columns each, typed from 1400 x 420 px crops
of the 300-dpi render. Every row's five components add to its Total, every
region's states add to the region total, and the six region totals add to the
United States row, all to 0.0. Two glyphs are smudged on the scan (Kentucky
national `57.3`, California state `136.0`); both are fixed by the row and
column sums. 236 of the 348 cells are filled, 112 are blank on the page.

| row | national | state | loan_trust | savings | private | total |
|---|---|---|---|---|---|---|
| Total New England States | 728.9 | 14.6 | 187.0 | 956.1 | (blank) | 1,886.6 |
| Total United States | 4,708.6 | 1,636.0 | 1,071.4 | 2,400.7 | 87.8 | 9,904.5 |

### C8. The archive's OCR layer

Raw lines from `pdf_text("comp1899_p.pdf")`:

```
"                Total United States             4, 708. 6   1,636.0       1,071.4      2,400.7        87.8       9, 904.5"
"                Total New England States          728.9        14.0         187.0        956.1            ..      1,886.6"
```

Parsing rule (same for every reading). Every value on the page has one
decimal, so a number token is digits (thousands commas allowed), a point, one
digit, or a point and one digit, allowing a space after a comma or a point
(`1,169. 7`, `4, 708. 6`) and a space in place of the point (`117 9`):

```r
NUM <- "(?<![\\w.])(?:\\d{1,3}(?:, ?\\d{3})*(?:\\. ?| )\\d|\\. ?\\d)(?![\\w.])"
```

Tokens with letters, double points or no decimal (`i.'i)"`, `6.Y`, `n.3`,
`r,,8. o`, `L4`, `29`) are not numbers, so the cell is NA. Numbers are
right-aligned in their columns, so the right edge of each token says which
column it is in: the right edges of all tokens fall into six clusters
(k-means on the position), one per column; tokens in the left 35% of the line
(the label area) are ignored. For the archive layer the position is the
character column in the layout text (`str_locate_all` on the original line;
the repairs are applied to the token text afterwards, never to the line, so
positions do not shift). The row label is the text left of the first number.
Rows are matched to the truth in order by label (letters only, case ignored;
at most 2 edits, 3 for labels of 7 letters or more; a row with no label takes
the next truth row in sequence, which covers the three rows whose label the
archive dropped: New Hampshire, New Jersey, Louisiana).

Archive layer: 58 rows parsed, 58 aligned; column right-edge centres at
character positions 55, 67, 81, 95, 106, 120.

| check | result |
|---|---|
| components vs Total, \|diff\| <= 0.15 | 47 of 58 rows pass |
| cells vs truth | 336 right, 12 wrong, of 348 |
| of the 12 wrong | 9 cells lost (NA), 3 wrong values; no value invented in a blank cell |

The 12 wrong cells: Rhode Island state 1.9 -> NA (`i.'i)"`); Total New England
States state 14.6 -> 14.0; New York national 1,316.7 -> 1,310.7; West Virginia
savings 0.3 -> NA; Georgia total 54.8 -> 51.8; Texas private 6.7 -> NA (`6.Y`);
Total Southern States savings 11.3 -> NA (`n.3`); California state 136.0 -> NA
(`r,,8. o`); Idaho state 0.7 -> NA; Utah state 6.3 -> NA and savings 2.9 -> NA
(`29`); Nevada state 1.4 -> NA (`L4`).

### C9. tesseract

`ocr("comp1899_p.png")` -> `ocr/comp1899_300.txt` (4.7-8.5 s, 762 words on 71
hOCR lines); `ocr("ocr/comp1899_100.png")` -> `ocr/comp1899_100.txt` (1.5 s,
293 words). Same parsing rule; positions are the word boxes from tesseract's
hOCR output (`ocr(png, HOCR = TRUE)`, parsed with xml2). Its line boxes are
stretched by the dot leaders, so words are regrouped into rows from the
number-like words (vertical centres within 12 px at 300 dpi form a row; other
words join the nearest row). Table rules and quotes stuck to words (`728.9|`,
`'Total`) are stripped; a word ending in `,` or `.` followed by a word of
digits (`1,` + `636.0`, `168.` + `3`) is one number split at a space.

| reading | rows parsed | aligned | components pass | cells right | cells wrong |
|---|---|---|---|---|---|
| archive layer | 58 | 58 of 58 | 47 of 58 | 336 | 12 |
| tesseract 300 dpi | 53 | 53 of 58 | 14 of 53 | 277 | 71 |
| tesseract 100 dpi | 0 | 0 of 58 | 0 of 0 | 112 | 236 |

Tesseract at 300 dpi loses five rows entirely (Virginia, Alabama, Ohio,
Montana, Alaska: their digits come out as letters, `BRB] BLD`, `WKB | BG`,
`WGA) OLLI`). Of its 71 wrong cells, 60 are lost (NA where the page has a
value) and 11 are wrong values: 956.1 -> 56.1, 1,316.7 -> 1,816.7, 923.4 ->
570.2, 5.2 -> 6.2, 15.9 -> 18.9, 337.1 -> 387.2, 11.3 -> 1.8, 560.0 -> 580.0,
3.2 -> 8.2, 136.0 -> 106.0, 4,708.6 -> 4,708.0. It invents no value in a blank
cell. At 100 dpi the text is unreadable (`Maing cc carencnnnennee) Beng! m0)`);
fewer than six number positions exist, nothing is parsed, and the 112 "right"
cells are the blank cells matched by an empty reading.

`ocr_data()` confidence on the Total United States row, 300 dpi:

| word | conf | word | conf | word | conf |
|---|---|---|---|---|---|
| 'Total | 90.3 | 4,708.0" | 21.2 | 2, | 69.3 |
| United | 96.9 | 1, | 95.8 | 400.7 | 91.8 |
| States | 90.9 | 636.0 | 52.9 | 87.8 | 21.1 |
| ....... | 27.8 | bovL4 | 0.0 | \| | 21.1 |
| corel | 10.2 | 1 | 41.1 | 9,904.5 | 92.1 |

(`bovL4` is 1,071.4; `4,708.0"` is 4,708.6 with the wrong last digit at
confidence 21.) At 100 dpi the row is not found.

Cells where the archive layer and tesseract 300 dpi disagree: 72 (the script
prints the full list with the truth beside each). The archive is right and
tesseract wrong in 64 of them (tesseract has NA in 56 of those); tesseract is
right and the archive wrong in 5 (Rhode Island state 1.9, Total New England
States state 14.6, Georgia total 54.8, Texas private 6.7, Utah savings 2.9);
both are wrong in different ways in 3 (New York national 1,310.7 vs 1,816.7;
Total Southern States savings NA vs 1.8; California state NA vs 106.0). The
archive's other 4 wrong cells are NA in both readings, so they do not appear
as disagreements.

### C10. Vision model (make_cache_1899.R)

Model `claude-sonnet-5-5` through ellmer 0.5.0 (`chat_anthropic`, `cache =
"none"` and `type_number(required = FALSE)` both accepted). The image is sent
with `content_image_file("comp1899_p.png", resize = "none")`: ellmer's default
`resize = "low"` shrinks to 512 x 512 px, which makes the digits unreadable.
The 300-dpi PNG (1650 x 2550 px, 713 kB) was accepted; no 200-dpi fallback was
needed.

What failed. The one-call form in the task, `chat$chat_structured(image, type =
type_array(row_type))` with PROMPT as the system prompt, returned 2, 2 and 1
rows in three tries (cache/comp1899_direct_run1-3.json, 59-75 output tokens,
3-5 s): a `Maine` row with wrong cells and a row labelled `placeholder`. A
third try with a line of user text beside the image did the same. A plain
`chat$chat()` with the same image reads the whole table correctly, so the
script asks for the transcription as a markdown table first and then calls
`chat_structured()` in the same chat:

```r
chat <- chat_anthropic(model = MODEL, system_prompt = PROMPT, cache = "none")
md    <- chat$chat("Transcribe every row of the table on this page as a markdown table, one row per printed row, blank cells left empty.", img)
reply <- chat$chat_structured("Now return the same rows as structured data.", type = type_array(row_type))
```

Run 1 (`cache/comp1899_run1.json`, markdown in `cache/comp1899_run1_markdown.md`,
tokens in `cache/comp1899_run1_meta.json`), called 2026-10-27 17:48:44:

| seconds | input tokens | output tokens | turns | rows |
|---|---|---|---|---|
| 35.9 | 12,126 | 6,702 | 2 | 58 |

`chat$get_tokens()` in 0.5.0 gives one row per assistant turn with `input`,
`output`, `cached_input` and `cost` (cost came back NA for this model name);
the totals above are sums over the two turns.

| check | model |
|---|---|
| components vs Total, \|diff\| <= 0.15 | 58 of 58 rows pass |
| rows aligned to the truth by label | 58 of 58 |
| cells vs truth | 348 right, 0 wrong |

Three readings cell by cell (348 cells):

| | archive | tesseract 300 | model |
|---|---|---|---|
| cells right | 336 | 277 | 348 |
| all three agree (and are right) | 272 | | |
| model right where the archive is wrong | 12 of 12 | | |
| model right where tesseract is wrong | 71 of 71 | | |
| model right where either OCR is wrong | 76 of 76 | | |
| model wrong | 0 | | |

## SOURCE

- Federal Reserve, H.4.1 statistical release of 3 October 2024,
  https://www.federalreserve.gov/releases/h41/20241003/h41.pdf, downloaded
  2026-10-27; born-digital (Word via Aspose), 11 pages, 192,780 bytes; US
  federal work, public domain. Table 5 on pages 6-7, Table 6 (October 2,
  2024) on pages 8-9.
- Annual Report of the Comptroller of the Currency, 1899, Volume 1, FRASER
  (Federal Reserve Bank of St. Louis),
  https://fraser.stlouisfed.org/files/docs/publications/comp/1890s/1899/compcurr_1899_vol1.pdf,
  907 pages, downloaded 2026-10-27; PDF page 693 = printed page 646, Table
  XVII, "Aggregate resources, expressed in millions of dollars, of national
  banks on June 30, 1899, and State, savings, private banks, and loan and
  trust companies at date of latest returns to this bureau"; 300-dpi bilevel
  scan with the archive's OCR layer. US federal work.
- Model: claude-sonnet-5-5 via ellmer 0.5.0, called 2026-10-27 17:48 (run 1)
  and 17:39-17:41 (the three failed direct runs). System prompt: "This image
  is a scanned page of a printed statistical table. Return every row of the
  table, in order, as one object per row. Copy each number exactly as printed,
  in millions of dollars with one decimal as on the page. Where a cell is
  blank or unreadable return null. Do not compute or correct anything."
- Tools: R 4.6, pdftools 3.9.1 (poppler), tesseract 5.3.1 eng, magick, xml2.

## Files written

- `code/fed_tables.R`, `code/ocr_runs.R`, `code/make_cache_1899.R`
- `table6.csv` (Table 6, 24 x 15)
- `comp1899_p.pdf`, `comp1899_p.png` (300 dpi)
- `ocr/h41_p8_{300,150,100,72}.png` and `.txt`
- `ocr/comp1899_100.png`, `ocr/comp1899_300.txt`, `ocr/comp1899_100.txt`
- `ocr/comp1899_truth.csv` (hand-verified, 58 rows)
- `ocr/comp1899_archive.csv`, `ocr/comp1899_tess300.csv`,
  `ocr/comp1899_tess100.csv`, `ocr/comp1899_model.csv` (each reading aligned
  to the 58 truth rows)
- `cache/comp1899_run1.json`, `cache/comp1899_run1_meta.json`,
  `cache/comp1899_run1_markdown.md`; `cache/comp1899_direct_run{1,2,3}.json`
  and `_meta.json` (the failed one-call form)
- `prep/fed_ocr_results.md` (this file)
