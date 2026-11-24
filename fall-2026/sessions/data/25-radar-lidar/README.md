# 25-radar-lidar

The project for AEM 6850, session 25, Radar & LiDAR (Tuesday, November 24,
2026). A plane times laser pulses, and R turns the returns into grids of heights.
The session first reads a radar elevation raster of Tompkins County and compares
it with USGS's ground elevation, and maps radar hail in seven Plains states. It
then reads the USGS points over Cornell's central campus with `lidR` and
builds the ground, surface and height grids. It measures McGraw Tower and the
Empire State Building. Then it computes slope, the view from McGraw Tower and the
Fall Creek basin from USGS's 30 m elevation grid of Tompkins County.

Open `25-radar-lidar.Rproj` first. R then starts in this folder, and every path
in the slides and the scripts below is relative to it. Each script installs the
packages it uses (`lidR`, `terra`, `sf`, `exactextractr`) if they are missing.
Nobody needs an account, a key or the network: every file was downloaded before
class.

## What is where

```
25-radar-lidar/
  25-radar-lidar.Rproj
  README.md              this file
  run_everything.R       runs the six scripts in order
  code/                  the scripts, numbered in the order the lecture uses them
  data_clean/lidar/      campus.laz: the USGS points, 600 x 600 m around McGraw Tower (15.8 MB)
                         campus_dtm.tif, campus_dsm.tif, campus_height.tif: ground, surface and height, 1 m
  data_clean/lidar_nyc/  esb_height.tif: height above ground around the Empire State Building, 1 m
                         esb.laz, esb_dtm.tif, esb_dsm.tif: the points and the other two grids (not in the zip)
  data_clean/drone/      the drone mosaic's road check and smaller copies, kept for session 26 (not in the zip)
  data_clean/radar/      tompkins_copernicus_utm.tif: radar elevation of Tompkins County, on the cells of tompkins_dem_utm.tif
                         campus_30m.tif: the campus box in 30 m cells, radar, USGS and LiDAR (figures only; not in the zip)
  data_clean/hail/       hail_county_day.csv: radar hail and hail reports by county and day (0.8 MB)
                         hail_county_month.csv: radar hail, reports and crop-insurance hail losses by county and month
                         counties_7states.gpkg: the 567 counties of CO, IA, KS, MN, NE, ND and SD
                         mesh_20220612.tif: the largest hail radar estimated in each 0.01 degree cell on the radar day 12 June 2022, mm (1 MB)
                         reflectivity_20220612.tif: radar reflectivity at 05:00 UTC on 13 June 2022, dBZ (0.6 MB)
  data_clean/terrain/    tompkins_dem_utm.tif: elevation of Tompkins County, 30 m cells, UTM zone 18N
                         tompkins_towns.gpkg: the county's nine towns and the city of Ithaca
                         fallcreek_dem_filled.tif: elevation around Fall Creek, pits filled before class
                         fallcreek_dem_utm.tif: the same grid before the fill (Practice 9)
                         the rest (the raw Fall Creek grid, slope, views, flow): made by tools/ (not in the zip)
  data_clean/coverage/   where USGS has flown: project outlines and the 300-point test (not in the zip)
  data/drone/            willis_corn_trial.tif: the drone mosaic, kept for session 26 (not in the zip)
  data/usgs_gauge/       site_04234000.rdb: the USGS record of the Fall Creek gauge (in the zip)
  data/                  the other raw downloads, exactly as fetched (not in the zip; see Provenance)
  tools/                 what made data/ and data_clean/ before class (needs the network; not in the zip)
  logs/                  the logs and check maps of the tools (not in the zip)
```

| Script | What it does |
|---|---|
| `code/1_radar.R` | the radar elevation raster of Tompkins County, radar minus USGS's ground elevation (median 4.6 m), each town's share of land more than 5 m above the ground; radar hail on 12 June 2022, radar hail against hail reports and crop-insurance losses |
| `code/2_lidar.R` | the campus points read with `readLAS()`, their classes, the noise dropped, the ground grid (`rasterize_terrain()`), the surface grid (`rasterize_canopy()`), height above ground, the Arts Quad lawn at 0 m |
| `code/3_heights.R` | McGraw Tower in the height grid (50.6 m), the Empire State Building in 1 m and 30 m cells, Exercise 1 (the tower in 5 m and 10 m cells) |
| `code/4_slope.R` | the 30 m elevation grid, slope with `terrain()`, one cell's slope by hand, each town's share of land steeper than 15% |
| `code/5_views.R` | what McGraw Tower can see with `viewshed()`, each town's share in view, Exercise 2 (the view from the ground), the view as polygons |
| `code/6_watershed.R` | flow direction and flow accumulation, the land that drains to the USGS gauge on Fall Creek |
| `run_everything.R` | runs the six in order (about 20 seconds; see below for memory) |

Scripts 1 and 3 to 6 read what they need from `data_clean/`, so each runs on its
own. Script 3 reads the grids script 2 builds, so it runs even if `lidR` did not
install.

| Tool (instructor prep, not in the zip) | What it does |
|---|---|
| `tools/fetch_lidar.R` | downloads the campus points from USGS's copy on Amazon (EPT nodes), and the original tiles if asked |
| `tools/fetch_nyc.R` | downloads the points around the Empire State Building (and One World Trade Center) the same way |
| `tools/fetch_terrain.R` | downloads the elevation tile, the Census towns and roads, the drone mosaic and the gauge record |
| `tools/make_lidar.R` | clips the campus points and builds the three 1 m grids in `data_clean/lidar/` |
| `tools/make_nyc.R` | clips the Manhattan points and builds the grids in `data_clean/lidar_nyc/` |
| `tools/make_terrain.R` | crops and projects the elevation grid, fills the Fall Creek pits, the drone mosaic at three pixel sizes, the road offsets |
| `tools/drone_for_session26.R` | the drone script, taken out of this session's code on 2026-11-23 and kept for session 26 |
| `tools/make_drone_masked.R` | an optional shortcut: writes `data_clean/drone/corn_trial_masked.tif`, the mosaic with its corners already NA, and checks it against `mask()` on the original |
| `tools/fetch_radar.R` | downloads the Copernicus radar elevation tile, its water mask, metadata and licence |
| `tools/make_radar.R` | puts the radar raster on USGS's cells and logs radar minus USGS for the county and the campus |
| `tools/make_hail.R` | copies the tables of the instructor's hail pilot into `data_clean/hail/` and logs the numbers on the slides |
| `tools/hail_pilot/` | the two pilot scripts that made those tables (their raw downloads are not kept) |
| `tools/fetch_mrms.R` | downloads NOAA's two radar rasters for the radar day 12 June 2022, crops them to the seven states and checks the hail raster against the pilot's county table (91 counties in both) |
| `tools/make_coverage.R` | counts USGS's LiDAR projects and draws where they cover the lower 48 states |
| `tools/check_coverage.R` | tests 300 random places against the laser points |
| `tools/make_zips.sh` | the class zip |

## Provenance

Every file was downloaded on November 23, 2026.

- **The campus points.** USGS 3D Elevation Program (3DEP), project
  NY_FingerLakes_1_2020 (work unit NY_FingerLakes_2020_A20), flown 2 to 14 May
  2020; the campus points date from 13 May. US government work, public domain.
  `tools/fetch_lidar.R` reads USGS's public copy on Amazon Web Services, stored as
  Entwine Point Tiles (EPT):
  https://s3-us-west-2.amazonaws.com/usgs-lidar-public/NY_FingerLakes_1_2020/ept.json.
  EPT cuts the cloud into a tree of cubes. The script downloads the 89 cubes
  (nodes) that touch the campus box into `data/lidar/ept/`. The same points are in
  USGS's original tiles USGS_LPC_NY_FingerLakes_2020_A20_u_3765069950.laz and
  USGS_LPC_NY_FingerLakes_2020_A20_u_3780069950.laz, at
  https://rockyweb.usgs.gov/vdelivery/Datasets/Staged/Elevation/LPC/Projects/NY_FingerLakes_2020_A20/NY_FingerLakes_1_2020/LAZ/.
  Their metadata (`data/lidar/*.xml`) came from
  https://prd-tnm.s3.amazonaws.com/StagedProducts/Elevation/LPC/Projects/NY_FingerLakes_2020_A20/NY_FingerLakes_1_2020/metadata/.
  The first tile is in `data/lidar/`; the second stalled on the rate-limited
  server, and the slides do not need it.
- **The Manhattan points.** USGS 3DEP, the New York City flight of March 2014
  (tile USGS_LPC_NY_New_York_CMGP_SANDY_LiDAR_15_18TWL850105), public domain.
  `tools/fetch_nyc.R` reads the EPT copy at
  https://s3-us-west-2.amazonaws.com/usgs-lidar-public/NY_NewYorkCity/ept.json and
  downloads the 48 nodes that touch a 400 x 400 m box around the Empire State Building into
  `data/lidar_nyc/esb/`.
- **Where USGS has flown.** The index of every project in the AWS bucket,
  `resources.geojson`, kept by Hobu Inc. at
  https://github.com/hobuinc/usgs-lidar (boundaries/resources.geojson; the
  repository states no licence). USGS's work-unit table `WESM.csv`, public domain,
  from https://prd-tnm.s3.amazonaws.com/StagedProducts/Elevation/metadata/WESM.csv.
  Both are in `data/usgs_index/`.
- **Elevation.** USGS 3DEP 1 arc-second grid (about 30 m), tile n43w077,
  public domain:
  https://prd-tnm.s3.amazonaws.com/StagedProducts/Elevation/1/TIFF/current/n43w077/USGS_1_n43w077.tif
  (`data/usgs_dem/`, 54 MB). `tools/make_terrain.R` crops it to Tompkins County
  and to Fall Creek's basin and projects it to UTM zone 18N.
- **Radar elevation.** Copernicus DEM
  GLO-30, tile N42 W077, downloaded on 2026-11-23 by `tools/fetch_radar.R`:
  https://copernicus-dem-30m.s3.amazonaws.com/Copernicus_DSM_COG_10_N42_00_W077_00_DEM/Copernicus_DSM_COG_10_N42_00_W077_00_DEM.tif
  (`data/copernicus/`, with its metadata, water mask and licence `eula_F.pdf`).
  Free of charge under the Licence for the use of the Copernicus WorldDEM-30, with
  the notice: "produced using Copernicus WorldDEM-30 (c) DLR e.V. 2010-2014 and (c)
  Airbus Defence and Space GmbH 2014-2018 provided under COPERNICUS by the
  European Union and ESA; all rights reserved". `tools/make_radar.R` projects it
onto the cells of `tompkins_dem_utm.tif` (bilinear) and writes
`data_clean/radar/tompkins_copernicus_utm.tif` (7.2 MB, in the zip). Its heights
are on the EGM2008 geoid and USGS's on NAVD88; on flat land the radar sits
0.49 m below USGS, and `code/1_radar.R` adds that back. `logs/prep_radar.txt`
records the facts and the tests.
- **Hail (the instructor's preliminary work).** The tables in `data_clean/hail/`
  come from a pilot the instructor ran in October 2026 (`_planning/hail_pilot/` in the course
  repository; `tools/make_hail.R` copied them on November 23, 2026). Radar hail is
  NOAA's MRMS estimate of the maximum hail size over 24 hours (12:00 to 12:00 UTC)
  in 1 km cells, product `MESH_Max_1440min_00.50`, from NOAA's public copy on
  Amazon (https://noaa-mrms-pds.s3.amazonaws.com/). The pilot added up, for each
  county and day, the km² with hail of 1 inch (25.4 mm) or more. Hail reports are
  NCEI Storm Events
  (https://www.ncei.noaa.gov/stormevents/), counted on the same radar day. Hail
  losses are USDA Risk Management Agency cause-of-loss records with cause 21, hail
  (https://www.rma.usda.gov/), summed by county and month of loss. Seven states
  (CO, IA, KS, MN, NE, ND, SD), April to September 2021 to 2025, 567 counties. US
  government work, public domain. Counties: Census cartographic boundaries 2023,
  public domain. `hail_county_day.csv` keeps the county-days with radar hail of
  1 inch or more or a report (21,448 of the pilot's 164,500 rows).
  `logs/prep_hail.txt` logs every number on the slides with the code that made it.
- **Radar rasters of one storm day.** `mesh_20220612.tif` and
  `reflectivity_20220612.tif` are crops of two NOAA MRMS files from the public
  bucket https://noaa-mrms-pds.s3.amazonaws.com/ (US government work, public
  domain): `MESH_Max_1440min` stamped 12:00 UTC 13 June 2022, the largest hail
  estimated in each cell from 12:00 UTC 12 June to 12:00 UTC 13 June, and
  `MergedReflectivityQCComposite` stamped 05:00:41 UTC 13 June 2022 (midnight
  Central), the hour with the most area of 50 dBZ or more in the seven states.
  NOAA publishes them as GRIB2 files on a 0.01 degree grid of the lower 48
  states. `tools/fetch_mrms.R` downloaded them on November 24, 2026 and
  `logs/prep_mrms.txt` logs the numbers.
- **Towns and roads.** Census Bureau TIGER/Line 2024, public domain: New York's
  county subdivisions,
  https://www2.census.gov/geo/tiger/TIGER2024/COUSUB/tl_2024_36_cousub.zip, and
  the roads of Caldwell County, North Carolina,
  https://www2.census.gov/geo/tiger/TIGER2024/ROADS/tl_2024_37027_roads.zip
  (`data/census/`).
- **The drone mosaic (kept for session 26; not used by this session's scripts).** "Willis Corn Trial", flown on 12 November 2024 by NC State
  Extension with a DJI Mini 3 Pro, 4.1 cm pixels, near Lenoir, North Carolina.
  Imagery by NC State Extension via OpenAerialMap, licensed CC BY 4.0
  (https://creativecommons.org/licenses/by/4.0/). File:
  https://oin-hotosm-temp.s3.us-east-1.amazonaws.com/673502355604c600010b4336/0/673502355604c600010b4337.tif
  (`data/drone/willis_corn_trial.tif`, 11.4 MB). Record:
  https://api.openaerialmap.org/meta?title=Willis%20Corn%20Trial
  (`data/drone/willis_corn_trial_meta.json`). `tools/make_drone_masked.R` sets the
  12,232,330 pixels that are 0 in all three layers (the corners outside the
  flight) to NA. Inside the flight, 142,410 layer values of 0 became 1, so that 0
  can serve as the file's NA value. The copy is stored without loss, so it is
  larger than the JPEG-compressed original, and the class zip ships the original.
- **The stream gauge.** USGS Water Services, site 04234000, Fall Creek near
  Ithaca, public domain:
  https://waterservices.usgs.gov/nwis/site/?format=rdb&sites=04234000&siteOutput=expanded
  (`data/usgs_gauge/`). Its coordinates are typed into `code/6_watershed.R`.
- **McGraw Tower** is at 42.44757 N, 76.48505 W (Wikipedia's infobox). Its
  published height, 173 ft, is from the Cornell Chronicle of 3 September 2025.

## Run time and memory

`run_everything.R`, run with `Rscript` on the class zip unzipped into an empty
folder, on the instructor's laptop on November 23, 2026 (`/usr/bin/time -l`):
16 seconds and a peak memory footprint of 2.0 GB. Script 2 needs about 1.5 GB
on its own for the 2.3 million points, and lidR does not follow terra's memory
limit.
