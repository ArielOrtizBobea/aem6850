# Farmland values and home values by county

Figure 1 maps how much farmland value per acre and the median value of an
owner-occupied home rose from 1940 to 2022, in real terms, for the counties
of the lower 48 states, and plots one against the other. The
project draws it for two journals, Nature and the American Economic
Review, from one script; the journals' rules are in `specs/`.

## Data

| File | Source | Access |
|---|---|---|
| `data/nass_land_value_county.csv` | USDA NASS Quick Stats, Census of Agriculture, value of land and buildings per acre, by county, 1997 to 2022 | Public; downloaded by `code/1_get_data.R` with a free NASS API key |
| `data/CPIAUCNS.csv` | BLS consumer price index for all urban consumers, via FRED | Public; downloaded by `code/1_get_data.R` |
| `data/icpsr/35206-0001-Data.rda` | Haines, Fishback and Rhode, *United States Agriculture Data, 1840–2012*, ICPSR 35206 v4, part 1 (farm land values, 1850–1959) | Licensed: free with an ICPSR account (Cornell is a member); not included. Download it in R format and save it here. AEM 6850 students: it is on the course's Canvas page |
| `data/nhgis/` | IPUMS NHGIS, 1940 census table NT74 (median value of owner-occupied homes) and 2018–2022 ACS table B25077, by county | Licensed: free with an IPUMS account; not included. `code/1_get_data.R` downloads it through the IPUMS API, from the request in `data/nhgis/extract_definition.json`, with your key |

The ICPSR and NHGIS terms do not allow the files to be passed on, so each
user downloads them. Cite them as their terms ask:

- Haines, Michael, Price Fishback and Paul Rhode. United States Agriculture
  Data, 1840–2012. ICPSR 35206, version 4, 2018.
  <https://doi.org/10.3886/ICPSR35206.v4>
- Schroeder, Jonathan, David Van Riper, Steven Manson, Grace Cooper,
  Zachary Krause, Tracy Kugler, Tsu Zhu and Steven Ruggles. IPUMS National
  Historical Geographic Information System: Version 21.0. Minneapolis, MN:
  IPUMS, 2026. <https://doi.org/10.18128/D050.V21.0>

## Running it

AEM 6850 students: download the data folder from the course's Canvas
page and replace this project's `data` folder with it; the scripts below
then run without any API key. Everyone else:

Two free API keys go in `~/.Renviron`, one line each:
`NASS_API_KEY=...` (https://quickstats.nass.usda.gov/api) and
`IPUMS_API_KEY=...` (https://account.ipums.org/api_keys). Put the ICPSR
file in `data/icpsr/`. Then, from the project folder, in order:

```
Rscript code/1_get_data.R        # NASS, CPI and NHGIS files; checks the ICPSR file
Rscript code/2_clean_data.R      # data_clean/counties.rds, and a copy in match/
Rscript code/3_figure1.R         # figures/nature/figure1.pdf
Rscript code/figure1_default.R   # figures/default/figure1.pdf
```

The NHGIS request takes a minute or two at IPUMS; the script waits for it.

Change `journal <- "nature"` to `"aer"` at the top of `code/3_figure1.R`
to write `figures/aer/Figure1a.pdf` to `Figure1c.pdf`.

## Checking a figure

```
Rscript tools/check_fig.R figures/nature/figure1.pdf nature
```

measures the file against `specs/nature.yml` (width, fonts, text sizes,
panel letters, line weights, raster images) and writes `check/figure1/`
with the figure at print size, in grayscale, and as a reader with
deuteranopia sees it. It needs poppler's command-line tools and the R
packages `yaml` and `magick`.

The Claude Code agents in `.claude/agents/` use the same files:
`figure-critic` reports what to change and edits nothing; `figure-builder`
writes figure code through `R/fig_style.R`.

## The `match/` folder

The session's first demo asks Claude Code to edit a default script until
its figure matches a picture. It runs in `match/`, which holds only a
copy of `code/figure1_default.R`, a 300-dpi picture of Figure 1 for
Nature (`target/figure1.png`) and, once `code/2_clean_data.R` has run,
the data. `match/.claude/settings.json` lets Claude Code run `Rscript`
and `pdftoppm` there without asking each time.
