# 26-satellite-local

The project for AEM 6850, session 26, Drone & satellite imagery (Tuesday,
December 1, 2026). A camera records sunlight the ground reflects, in separate
bands, and R reads each band as a layer. The session reads a drone image of a
corn field in North Carolina and averages it to satellite-sized cells. It then
reads one Sentinel-2 image of Cayuga Lake (15 August 2024), turns its stored
numbers into reflectance and computes NDVI. It sums lights at night in New
York's counties, counts water bodies at 10, 30 and 250 m, and counts the clear
images of the lake in 2024. It ends by measuring the lake's area three ways and
by training a decision tree on 200 points labelled on aerial photos.

Open `26-satellite-local.Rproj` first. R then starts in this folder, and every
path in the slides and the scripts below is relative to it. Each script installs
the packages it uses (`terra`, `sf`, `rpart`) if they are missing. Nobody needs
an account, a key or the network: every file was downloaded before class.

## What is where

```
26-satellite-local/
  26-satellite-local.Rproj
  README.md              this file
  run_everything.R       runs the seven scripts in order
  code/                  the scripts, numbered in the order the lecture uses them
  data/drone/            willis_corn_trial.tif: the drone image of a corn trial, 4.1 cm pixels (11.4 MB)
                         willis_corn_trial_meta.json: its OpenAerialMap record
  data/sentinel2/        s2_20240815_cayuga_20m.tif: our image, 15 August 2024, five bands and ESA's class
                           for each cell (SCL), 20 m cells (37 MB)
                         s2_tci_20240830_cayuga.tif: the cloudy true-colour image of 30 August 2024, 10 m
  data/sentinel1/        s1_vv_db_20240901_cayuga_20m.tif: the radar image of 1 September 2024, decibels x 10
  data/worldcover/       worldcover2021_cayuga.tif: ESA WorldCover 2021 around the lake, 10 m
  data/lights/           ntl_viirs_2023_ny.tif: VIIRS lights at night over New York State, mean of 2023
                         ntl_li2020_2013_ny.tif: the older series (0 to 63) for 2013, from Li et al.
  data/census/           New York's county boundaries (2023) and county population estimates, as downloaded
  data/naip/chips/       the 2019 aerial photo around each of the 200 labelled points (if present)
  data_clean/drone/      caldwell_roads_near_mosaic.gpkg: Census roads near the field;
                         tiger_offset.csv: the road offsets measured before class;
                         corn_trial_10m.tif, corn_trial_30m.tif: the field in 10 m and 30 m cells
  data_clean/census/     ny_counties.gpkg: the 62 counties with GEOID, NAME, ALAND, pop2023 and pop2013
  data_clean/lights/     ny_county_lights.csv: population and summed lights by county, both series
  data_clean/catalog/    s2_search_20240810_20240820.csv: the catalog search of 10 to 20 August 2024
                         s2_passes_2024_18TUN.csv: every 2024 pass over tile 18TUN, with the tile's cloud share
                         s2_box_clear_2024.csv: every 2024 pass, the share of our image it covers and the
                           share of that which is clear
  data_clean/ndvi/       ndvi_season_2024.csv: median NDVI of cropland and forest near Aurora on each clear
                           date of 2024 (for the page's figure of NDVI over one season)
  data_clean/labels/     labels_200.csv: the 200 labelled points (id, lon, lat, class)
  tools/                 what made data/ and data_clean/ before class (needs the network; not in the zip)
  logs/                  the logs of the tools and of the full run (not in the zip)
```

| Script | Part of the lecture | What it reads | What it does |
|---|---|---|---|
| `code/1_sensors.R` | 1 · Passive and active sensors | `data/sentinel2/s2_tci_20240830_cayuga.tif`, `data/sentinel1/s1_vv_db_20240901_cayuga_20m.tif`, `data/sentinel2/s2_20240815_cayuga_20m.tif` | the cloudy day by camera and by radar; the five bands in our image |
| `code/2_drone.R` | 2 · Drone images | `data/drone/willis_corn_trial.tif`, `data_clean/drone/` | the drone image read in R, `mask()` on its black corners, the field in 10 m and 30 m cells (643 and 83), the Census road 4.1 to 4.5 m off |
| `code/3_sentinel2.R` | 3 · Satellite images in R | `data_clean/catalog/s2_search_20240810_20240820.csv`, `data/sentinel2/s2_20240815_cayuga_20m.tif` | the saved search, reflectance, band medians by ESA's class with `zonal()`, true and false colour, NDVI, Exercise 1, the cloud mask, Practice 1 and 2 |
| `code/4_uses.R` | 4 · Uses in economics | `data/lights/ntl_viirs_2023_ny.tif`, `data_clean/census/ny_counties.gpkg`, `data/sentinel2/`, `data/worldcover/` | lights and population in New York's counties (0.87), NDVI of ESA's land-cover types, Practice 7 and 8 |
| `code/5_resolution.R` | 5 · Resolution in space and time | `data/sentinel2/`, `data/worldcover/`, `data_clean/catalog/` | 406 water bodies at 10 m with `patches()`, Exercise 2 (30 m and 250 m), clear images of the lake in 2024, Practice 6 |
| `code/6_error.R` | 6 · Measurement error | `data/lights/`, `data_clean/census/ny_counties.gpkg` | Manhattan's 127 cells at 63 in the older lights, the correlations with and without New York City, Practice 5 |
| `code/7_lake.R` | 7 · An application to Cayuga Lake | `data/sentinel2/`, `data/worldcover/`, `data_clean/labels/labels_200.csv` | the lake's area from ESA's map, MNDWI and NDWI; training and test points; a decision tree with `rpart()`; accuracy and the confusion table; the tree against ESA's map; Practice 3, 4 and 9 |
| `run_everything.R` | all | | runs the seven in order |

None of the scripts writes a file. Each reads what it needs itself, so each runs
on its own in a fresh R session. Where a script needs an object an earlier
script made (`refl`, `ndvi`, `wc20`, `w10`), its Preliminary section rebuilds it
in a few lines. Figures drawn by the code go to the screen only.

| Tool (instructor prep, not in the zip) | What it does |
|---|---|
| `tools/fetch_sentinel2.R` | searches the Earth Search catalog, writes the two catalog tables, downloads our image of 15 August 2024 and the true-colour image of 30 August 2024 |
| `tools/fetch_sentinel1.R` | downloads the radar image of 1 September 2024 from Microsoft's Planetary Computer and puts it on our 20 m cells |
| `tools/fetch_worldcover.R` | downloads ESA WorldCover 2021 around the lake |
| `tools/fetch_lights.R` | downloads both lights series over New York State |
| `tools/fetch_census.R` | downloads New York's county boundaries and county population |
| `tools/make_counties.R` | joins population to the counties and sums the lights in each county |
| `tools/make_s2_season_2024.R` | reads ESA's class for each cell on every 2024 pass over the box, and NDVI near Aurora on the clear ones |
| `tools/make_label_chips.R` | draws the candidate points for the labels and fetches a 2019 aerial-photo chip around each |
| `tools/drone_for_session26.R` | the drone script as it came from session 25, kept as the source of `code/2_drone.R` |
| `tools/make_zips.sh` | the class zip |

## Provenance

The files were downloaded on November 23 and 24, 2026, by the `tools/` scripts
named below. Each tool skips a file already on disk, and rerunning them into an
empty folder gave the same files.

- **Our Sentinel-2 image.** Copernicus Sentinel-2, Level-2A (surface
  reflectance), item `S2B_18TUN_20240815_0_L2A`, from Earth Search by Element 84
  (https://earth-search.aws.element84.com/v1, collection `sentinel-2-l2a`, files
  in the public bucket `sentinel-cogs` on Amazon). Downloaded on 2026-11-23 by
  `tools/fetch_sentinel2.R`. Bands B02, B03, B04, B8A, B11 and SCL, cropped to
  longitude −76.80 to −76.45 and latitude 42.43 to 42.95; the 10 m bands were
  averaged 2 x 2 to 20 m. The stored numbers are reflectance times 10,000. Earth
  Search had already subtracted ESA's offset of 1,000 (the items say
  `earthsearch:boa_offset_applied: true`), so reflectance is the number divided
  by 10,000. Licence: the Copernicus Sentinel data legal notice. Credit:
  "Contains modified Copernicus Sentinel data (2024)".
- **The cloudy image of 30 August 2024.** Item `S2A_18TUN_20240830_0_L2A`,
  true-colour file (TCI), same source, script and date.
- **The catalog tables.** `s2_search_20240810_20240820.csv` (every image over
  the box from 10 to 20 August 2024) and `s2_passes_2024_18TUN.csv` (one row per
  2024 date on tile 18TUN) come from the same catalog through
  `tools/fetch_sentinel2.R`. `s2_box_clear_2024.csv` and
  `data_clean/ndvi/ndvi_season_2024.csv` come from
  `tools/make_s2_season_2024.R` (2026-11-24), which read ESA's class for each
  cell (SCL) over the box on each of the 146 dates. Clear means SCL is not 0, 1,
  3, 8, 9 or 10.
- **The radar image.** Copernicus Sentinel-1, radiometrically terrain-corrected
  (collection `sentinel-1-rtc`, VV polarisation), orbit 106, two frames of
  1 September 2024, from Microsoft's Planetary Computer
  (https://planetarycomputer.microsoft.com/dataset/sentinel-1-rtc). Downloaded
  on 2026-11-24 by `tools/fetch_sentinel1.R`, averaged to our 20 m cells and
  stored as decibels times 10. Licence CC BY 4.0. Contains modified Copernicus
  Sentinel data (2024). Caveat: the collection's catalog record says it needs an
  account (`msft:requires_account: true`), yet the search and the anonymous
  signing worked without one on 2026-11-23 and 2026-11-24. The fallback with no
  account flag is the collection `sentinel-1-grd` (20 August 2024).
- **ESA WorldCover.** ESA WorldCover 10 m 2021 v200, tile N42W078, from ESA's
  public copy on Amazon:
  https://esa-worldcover.s3.eu-central-1.amazonaws.com/v200/2021/map/ESA_WorldCover_10m_2021_v200_N42W078_Map.tif.
  Downloaded on 2026-11-23 by `tools/fetch_worldcover.R`, cropped to longitude
  −76.80 to −76.44 and latitude 42.40 to 42.97. Licence CC BY 4.0. Credit:
  "© ESA WorldCover project 2021 / Contains modified Copernicus Sentinel data
  (2021) processed by ESA WorldCover consortium". Citation: Zanaga et al.
  (2022), https://doi.org/10.5281/zenodo.7254221.
- **VIIRS lights at night.** World Bank Light Every Night, the twelve monthly
  VIIRS composites of 2023 from the Suomi NPP satellite (stray-light corrected,
  average radiance), from the public bucket
  https://globalnightlight.s3.amazonaws.com/, averaged and cropped to New York
  State. Downloaded on 2026-11-23 by `tools/fetch_lights.R`. The AWS registry
  (https://registry.opendata.aws/wb-light-every-night/) names the licence "World
  Bank Open Database License (ODbL)" and links it to CC BY 4.0. Credit: "World
  Bank Light Every Night".
- **The older lights series.** Li, Zhou, Zhao and Zhao (Scientific Data, 2020),
  harmonized global night lights, DMSP-calibrated values 0 to 63, file
  `Harmonized_DN_NTL_2013_calDMSP.tif`, figshare article 9828827
  (https://ndownloader.figshare.com/files/17626034), CC BY 4.0. Downloaded on
  2026-11-23 by `tools/fetch_lights.R` and cropped to New York State.
- **Counties and population.** Census Bureau, public domain. County boundaries:
  cartographic boundary file 2023, 1:500,000
  (https://www2.census.gov/geo/tiger/GENZ2023/shp/cb_2023_us_county_500k.zip),
  New York's 62 rows. Population 2023: county estimates, Vintage 2023
  (https://www2.census.gov/programs-surveys/popest/datasets/2020-2023/counties/totals/co-est2023-alldata.csv).
  Population 2013: Vintage 2019
  (https://www2.census.gov/programs-surveys/popest/datasets/2010-2019/counties/totals/co-est2019-alldata.csv),
  New York's rows. Downloaded on 2026-11-24 by `tools/fetch_census.R`.
  `tools/make_counties.R` made `data_clean/census/ny_counties.gpkg` and
  `data_clean/lights/ny_county_lights.csv` from them.
- **The drone image.** "Willis Corn Trial", flown on 12 November 2024 by NC
  State Extension with a small consumer drone, 4.1 cm pixels, near Lenoir, North
  Carolina. Imagery by NC State Extension via OpenAerialMap, licensed CC BY 4.0
  (https://creativecommons.org/licenses/by/4.0/). File:
  https://oin-hotosm-temp.s3.us-east-1.amazonaws.com/673502355604c600010b4336/0/673502355604c600010b4337.tif.
  Record: https://api.openaerialmap.org/meta?title=Willis%20Corn%20Trial.
  Downloaded on 2026-11-23 for session 25 and copied here, with the road files
  in `data_clean/drone/` (Census TIGER/Line 2024 roads of Caldwell County, North
  Carolina, public domain:
  https://www2.census.gov/geo/tiger/TIGER2024/ROADS/tl_2024_37027_roads.zip).
- **The aerial photos and the 200 labels.** USDA's National Agriculture Imagery
  Program (NAIP), the 2019 New York flight at 0.6 m, from USGS's NAIP image
  service (https://imagery.nationalmap.gov/arcgis/rest/services/USGSNAIPImagery/ImageServer),
  public domain. Credit: "USGS, USDA, The National Map: Orthoimagery."
  `tools/make_label_chips.R` drew the candidate points (centres of 20 m cells of
  our image, the same number from each of four groups of ESA's map, cloudy cells
  left out) and fetched a 100 m chip of the 2019 photo around each. The 200
  labels in `data_clean/labels/labels_200.csv` were then read off those aerial
  photos by hand, one point at a time, 50 in each of four classes: water,
  forest, grass or crops, and built. ESA's map only decided where to look; the
  class of each point is what the photo shows. Points on a boundary between two
  classes were skipped.

## Run time and memory

`run_everything.R`, run with `Rscript` on the class zip unzipped into an empty
folder, on the instructor's laptop on November 24, 2026 (`/usr/bin/time -l`):
115 seconds and a peak memory footprint of 3.9 GB. Every script holds terra to
2 GB (`terraOptions(memmax = 2)`). The heaviest are script 7 (24 seconds, 3.5 GB),
script 4 (40 seconds, most of it the county sums of the lights) and script 3
(12 seconds, 1.8 GB). `logs/run_everything.log` holds the console output of the
full run.
