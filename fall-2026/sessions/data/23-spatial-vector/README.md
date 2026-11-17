# 23-spatial-vector

The project for AEM 6850, session 23, Spatial I: vectors (Tuesday, November 17,
2026): places stored as points, lines and polygons, read with `sf`, joined,
measured and related to each other. The application counts the people under
wildfire smoke on each day of June 2023, from NOAA's daily smoke outlines, and
checks the count against EPA ground monitors. Two worked examples on the session
page compute the variables of research designs: county pairs across the line
between states that expanded Medicaid in 2014 and states that did not, and the
distance from forest clearings in Cujubim, Rondônia (Brazil), to the nearest
mapped road.

Open `23-spatial-vector.Rproj` first. R then starts in this folder, and every path
in the slides, the live script and the scripts below is relative to it. Each
script installs the packages it uses (`sf`, `igraph`, `fixest`, `magick`,
`jsonlite`) if they are missing. Nobody needs an account, a key or the network: every file was
downloaded before class.

## What is where

```
23-spatial-vector/
  23-spatial-vector.Rproj
  23-spatial-vector.R    the live script: every code slide in order, the two exercises, the practice tasks (in the zip)
  README.md              this file
  code/                  the scripts, numbered in the order the lecture uses them
  data/census/           cb_2024_us_county_500k.zip, cb_2024_us_state_500k.zip: county and state outlines
                         co-est2024-alldata.csv: county population estimates, 2020-2024
                         tl_2024_us_primaryroads.zip: primary roads (not in the zip; 38 MB)
  data/noaa/hms/         hms_smoke20230601.zip ... hms_smoke20230630.zip: NOAA's smoke outlines, one shapefile a day
  data/epa/              daily_88101_2023.zip: daily PM2.5 at every EPA monitor in 2023 (not in the zip; 10 MB)
  data/meta/             us_counties.csv: friendship links between every pair of US counties (not in the zip; 245 MB)
  data/sahie/            sahie-2008-csv.zip ... sahie-2018-csv.zip: health insurance estimates (not in the zip; 88 MB)
  data/inpe/             municipalities_RO.json: Rondonia's 52 municipalities
                         yearly_cujubim_bbox_0.json ... _6000.json: forest clearings in Cujubim's box, one polygon
                         per patch per year, in four pages of the download
                         accumulated_2007_cujubim_bbox.json: clearing up to 2007
  data/osm/              roads_cujubim_bbox.json: roads and towns in Cujubim's box, as OpenStreetMap returned them
  data_clean/            interstates_ny_box.gpkg: the Interstate lines that touch New York's bounding box
                         medicaid_expansion.csv: each state's expansion month and group, typed by hand from KFF's table
                         sahie_uninsured.csv: uninsured share of adults 18-64 at or below 138% of poverty, by county, 2008-2018
                         roads_cujubim.gpkg: the OpenStreetMap roads as lines in metres (EPSG 31980), paths and footways dropped
                         sci_tompkins.csv: Tompkins County's row of the friendship file, one line per county
                         pm25_june2023.csv: June 2023 from the EPA file, one row per monitor site and day
                         counties/, states/: the shapefiles unzipped at run time
  tools/                 what made data/ and data_clean/ before class (needs the network)
```

| Script | What it does |
|---|---|
| `code/1_vector.R` | the county file as a data frame, subsetting and plotting, a polygon's corners, points from coordinates, a spatial join, the population merge that fails and the one that works, Exercise 1 |
| `code/2_measure.R` | Tompkins County's area and perimeter in three systems, each New York county's distance to Times Square, distance to a state and to its border, a 50 km buffer, Interstate miles in New York, the direction from Warren Hall to Times Square |
| `code/3_relations.R` | the nearest Interstate to Warren Hall and to each county, counties that touch, corner and rook neighbours, counties as a graph, first and second neighbours and the neighbours' average population, fewest county lines to Los Angeles, Exercise 2, county lines to every county, straight lines between New York's five largest cities, Tompkins County's friendship links, Conley standard errors |
| `code/4_smoke.R` | one day of smoke outlines, the counties fully under each density, the county-by-day table for June 2023 and the people under heavy smoke each day, the animated map, the EPA monitors under the plumes |
| `code/5_medicaid.R` | cross-border county pairs, the line between expansion and non-expansion states, signed distance to it, the uninsured share by pair and year, the change by distance band, the pair gap by year |
| `code/6_amazon.R` | the road layer from the OpenStreetMap download, the clearings read and repaired, distance to the nearest road, the road network and distance along it to the town, the share of each year's clearing within 1 km of a road |
| `code/run_everything.R` | runs the six in order (about 40 seconds, about 1 GB of memory) |

| Tool | What it does |
|---|---|
| `tools/fetch_data.R` | downloads every file in `data/` |
| `tools/cut_interstates.R` | `data_clean/interstates_ny_box.gpkg` from the primary-roads file |
| `tools/sahie_panel.R` | `data_clean/sahie_uninsured.csv` from the eleven yearly SAHIE files |
| `tools/cut_sci.R` | `data_clean/sci_tompkins.csv` from Meta's county file |
| `tools/cut_pm25.R` | `data_clean/pm25_june2023.csv` from the EPA's daily file for 2023 |
| `tools/make_zips.sh` | the class zip, without `data/sahie/`, `data/epa/`, `data/meta/` and the primary-roads file |

## Where the data came from

Every file was downloaded by `tools/fetch_data.R`: the smoke, fine-particle and
friendship files on November 16, 2026, the rest on November 13, 2026.

- **County and state outlines.** US Census Bureau, cartographic boundary files,
  2024, 1:500,000, https://www2.census.gov/geo/tiger/GENZ2024/shp/. Public
  domain. NAD83 longitude and latitude (EPSG 4269).
- **Primary roads.** US Census Bureau, TIGER/Line 2024 primary roads,
  https://www2.census.gov/geo/tiger/TIGER2024/PRIMARYROADS/. Public domain. Each
  direction of a divided highway is its own line.
- **County population.** US Census Bureau, county population totals 2020-2024
  (co-est2024-alldata.csv), https://www2.census.gov/programs-surveys/popest/datasets/2020-2024/counties/totals/.
  Public domain. Read it with `fileEncoding = "latin1"`.
- **Health insurance.** US Census Bureau, Small Area Health Insurance Estimates
  (SAHIE), 2008-2018, https://www2.census.gov/programs-surveys/sahie/datasets/time-series/estimates-acs/.
  Public domain. Model-based county estimates that sum to the state estimates.
- **Medicaid expansion dates.** KFF State Health Facts, Status of State Action on
  the Medicaid Expansion Decision, read on November 13, 2026 and typed into
  `data_clean/medicaid_expansion.csv`. Groups: expanded in 2014 (Michigan in April
  and New Hampshire in August included); expanded 2015-16 (left out of the
  comparison); not expanded by the end of 2018.
- **Forest clearing.** PRODES, INPE (Brazil's National Institute for Space
  Research), through TerraBrasilis's WFS service,
  https://terrabrasilis.dpi.inpe.br/geoserver/ows, layers
  `prodes-legal-amz:yearly_deforestation`, `accumulated_deforestation_2007` and
  `municipalities_legal_amazon`, in the box 63.099 to 62.291°W, 9.53 to 8.729°S.
  Through the PRODES year that ended July 31, 2025. CC BY-SA 4.0: anything made
  from these files and shared must carry the same licence and the credit.
- **Roads.** © OpenStreetMap contributors, through the Overpass API, base of
  2026-11-13 07:42 UTC. ODbL: `data_clean/roads_cujubim.gpkg` is a derived
  database and stays under the ODbL, with the credit.
- **Smoke.** NOAA (National Oceanic and Atmospheric Administration), Hazard
  Mapping System smoke polygons, one shapefile a day,
  https://satepsanone.nesdis.noaa.gov/pub/FIRE/web/HMS/Smoke_Polygons/Shapefile/2023/06/.
  US government work, public domain. Analysts outline the smoke seen in
  satellite images as Light, Medium or Heavy; `Start` and `End` are year, day of
  the year and UTC time.
- **Fine particles.** US EPA (Environmental Protection Agency), Air Quality
  System pre-generated daily file for PM2.5 (parameter 88101), 2023,
  https://aqs.epa.gov/aqsweb/airdata/daily_88101_2023.zip. Public domain.
  `tools/cut_pm25.R` keeps June, the lower 48 and DC, and the rows for the
  24-hour standard, averaged over a site's instruments.
- **Friendship links.** Meta, Social Connectedness Index between US counties,
  on the Humanitarian Data Exchange,
  https://data.humdata.org/dataset/social-connectedness-index (`us_counties.csv`).
  Public domain (CC0). Bailey, Cao, Kuchler, Stroebel & Wong (Journal of
  Economic Perspectives, 2018) describe it. Counties use the codes Meta used, so
  Connecticut's old counties and the territories find no match in the 2024
  county file.
