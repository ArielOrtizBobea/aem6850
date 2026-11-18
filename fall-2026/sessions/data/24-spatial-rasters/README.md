# 24-spatial-rasters

The project for AEM 6850, session 24, Spatial II: rasters (Thursday, November 19,
2026): data stored as a grid of cells, read with `terra`, cropped, combined cell
by cell and moved from one grid onto another. The session averages PRISM's daily
maximum temperature for July 2012 over every county of the lower 48 states,
first with a packaged function and then as a weight matrix times the matrix of
cells by days, with area, population and cropland weights. Two applications
follow: July heat over cropland against each county's 2012 corn yield loss, and
the people who lived downwind of the Eaton fire in Los Angeles on 9 January
2025.

Open `24-spatial-rasters.Rproj` first. R then starts in this folder, and every
path in the slides, the live script and the scripts below is relative to it.
Each script installs the packages it uses (`terra`, `sf`, `exactextractr`,
`Matrix`) if they are missing. Nobody needs an account, a key or the network:
every file was downloaded before class.

## What is where

```
24-spatial-rasters/
  24-spatial-rasters.Rproj
  24-spatial-rasters.R   the live script: every code slide in order, the two exercises, the practice tasks (in the zip)
  README.md              this file
  code/                  the scripts, numbered in the order the lecture uses them
  data/prism/            prism_tmax_us_25m_20120717.zip: PRISM's daily maximum temperature for 17 July 2012
                         prism_tmax_us_25m_20120701.zip ... _20120731.zip: the other 30 days (not in the zip)
  data/census/           cb_2024_us_county_500k.zip, cb_2024_us_state_500k.zip: county and state outlines
  data/nasa/             worldview_terra_20250109.tif: NASA's satellite picture of Los Angeles, 9 January 2025
  data/era5/             u10_*.nc, v10_*.nc: hourly wind over the whole globe, one file a day (not in the zip; 285 MB)
  data/glad/             Global_cropland_3km_2011.tif: share of each 3 km cell under crops (not in the zip)
  data/sedac/            gpw_v4_population_count_rev11_2010_2pt5_min.tif: people per cell, 2010 (not in the zip)
  data/nass/             corn_yield_county_2002_2012.csv: county corn yields as Quick Stats returned them (not in the zip)
  data_clean/            tmax_july2012.tif: the 31 days of July 2012 in one file, one layer a day
                         u10_ny_20120717.tif, v10_ny_20120717.tif: hourly wind over New York, 17 July 2012
                         u10_la_20250109.tif, v10_la_20250109.tif: hourly wind over Los Angeles, 9 January 2025
                         pop_2010.tif: people per cell, 2010, cut to the lower 48 states
                         cropland_2011.tif: percent of each cell under crops, cut to the lower 48 states
                         corn_yield_2002_2012.csv: one row per county and year
                         timings.csv: the seconds tools/time_methods.R measured
                         prism/, counties/, states/: the zips unzipped at run time (not in the zip)
  tools/                 what made data/ and data_clean/ before class (needs the network)
  logs/                  the logs of the tools (not in the zip)
```

| Script | What it does |
|---|---|
| `code/1_raster.R` | one day of temperature read with `rast()`, a raster as a matrix and Warren Hall's cell, the 31 layers of July 2012, the crop and the mask to New York, Warren Hall's temperature on each day, Exercise 1 |
| `code/2_compute.R` | 17 July minus July's mean, days above 30 °C in each cell, wind moved onto the temperature grid, wind speed and direction at Warren Hall, three more uses of a grid (cells as rows, the cells around each cell, categories in cells) |
| `code/3_aggregate.R` | county means with `extract()`, the timings, Tompkins County's cells and their fractions, its mean by hand, Exercise 2, the 31 means as a matrix product, the weight matrix P for 3,109 counties, sparse matrices, `P %*% M`, population weights |
| `code/4_corn.R` | each county's 2012 corn yield against its 2002-2011 mean, degree days above 29 °C in each cell, cropland moved onto the temperature grid, heat over each county's cropland, heat against the yield change |
| `code/5_eaton.R` | the satellite picture, the wind at the fire at 10 am, the cells within 100 km and 20° of the wind's direction, the people who lived there, the cells drawn over the picture |
| `code/run_everything.R` | runs the five in order (about 25 seconds, about 3.4 GB of memory) |

Scripts 2 to 5 open with a section that rebuilds what they need from the scripts
before them, so each runs on its own.

| Tool | What it does |
|---|---|
| `tools/fetch_data.R` | downloads every file in `data/` except the population grid |
| `tools/make_clean.R` | cuts the raw downloads down to the files in `data_clean/` |
| `tools/time_methods.R` | times four ways of averaging July 2012 over every county and writes `data_clean/timings.csv` (about 25 minutes) |
| `tools/make_zips.sh` | the class zip, without `data/era5/`, `data/glad/`, `data/sedac/`, `data/nass/` and 30 of the 31 PRISM zips |

## Where the data came from

`tools/fetch_data.R` downloaded every file in `data/` on November 17, 2026,
except the population grid.

- **Daily maximum temperature.** PRISM Climate Group, Oregon State University,
  daily 4 km grids (1/24 of a degree) for the lower 48 states,
  https://services.nacse.org/prism/data/get/us/4km/tmax/20120717 and the same
  address for each day of July 2012. Free to use, with the credit to the PRISM
  Climate Group. The service allows two downloads of a file in 24 hours, so the
  script never asks for a file already on disk. Each file's day runs from 12:00
  UTC on the day before to 12:00 UTC on its date.
- **County and state outlines.** US Census Bureau, cartographic boundary files,
  2024, 1:500,000, https://www2.census.gov/geo/tiger/GENZ2024/shp/. Public
  domain. NAD83 longitude and latitude (EPSG 4269).
- **Cropland.** University of Maryland, Global Land Analysis and Discovery
  (GLAD), global cropland at 3 km for 2008-2011,
  https://glad.geog.umd.edu/Potapov/Global_Crop/Data/Global_cropland_3km_2011.tif.
  Free to use, with the credit to Potapov, Turubanova, Hansen et al. (Nature
  Food, 2022), https://doi.org/10.1038/s43016-021-00429-z. Each cell holds the
  percent of its land under crops.
- **Corn yields.** USDA National Agricultural Statistics Service, Quick Stats,
  "CORN, GRAIN - YIELD, MEASURED IN BU / ACRE", county level, survey, 2002-2012,
  https://quickstats.nass.usda.gov/api/api_GET/. Public domain. The download
  needs a free key, saved as `NASS_API_KEY` in `~/.Renviron`; the key never
  appears in the file or the log.
- **Wind.** ERA5 hourly 10 m wind, u and v, from the European Centre for
  Medium-Range Weather Forecasts (ECMWF), through Google's public copy,
  https://storage.googleapis.com/gcp-public-data-arco-era5/raw/date-variable-single_level/
  (for 17 July 2012 and 8 and 9 January 2025). Contains modified Copernicus
  Climate Change Service information; free to use under the Copernicus licence,
  with that credit. Cells of 0.25 degrees.
- **Satellite picture.** NASA Worldview snapshot, MODIS on Terra, corrected
  reflectance (true colour), 9 January 2025, box 119.6 to 117.2°W and 33.2 to
  34.8°N, as a GeoTIFF of 1,200 by 966 cells,
  https://wvs.earthdata.nasa.gov/api/v1/snapshot. NASA imagery, free to use with
  the credit. Terra passed over the fire at about 17:20 UTC (9:20 am in Los
  Angeles).
- **Population.** NASA Socioeconomic Data and Applications Center (SEDAC),
  Gridded Population of the World, version 4 (revision 11), population count for
  2010 at 2.5 arc-minutes,
  https://sedac.ciesin.columbia.edu/data/collection/gpw-v4. CC BY 4.0. The
  download needs a free NASA Earthdata login, so it was fetched by hand into
  `data/sedac/` and is not in `tools/fetch_data.R`. The readme that came with it
  is in the same folder.
- **The Eaton fire's origin.** CAL FIRE's incident page gives the start at 6:18
  pm Pacific time on 7 January 2025, at 34.203483 N, 118.069155 W. The
  coordinates are typed into the code.

## Run time and memory

`code/run_everything.R`, run with `Rscript` in this folder on the instructor's
laptop on November 18, 2026: 25 seconds, with a peak of 3.4 GB of memory
(maximum resident set size from `/usr/bin/time -l`). The heavy steps are the national ones in scripts 3 and 4: the stack as a
matrix (220 MB), the table of cells for 3,109 counties and the heat grid.
