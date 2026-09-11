# la-fires-2025-monitors.jpg

NASA Terra/MODIS corrected-reflectance true colour, 10 January 2025, with
the HW1 monitoring sites and the two fires' ignition points drawn on.

**Source.** NASA Worldview snapshot service, requested 2026-09-11:

    https://wvs.earthdata.nasa.gov/api/v1/snapshot?REQUEST=GetSnapshot
      &TIME=2025-01-10&BBOX=33.45,-119.30,34.80,-117.20&CRS=EPSG:4326
      &LAYERS=MODIS_Terra_CorrectedReflectance_TrueColor&WRAP=day
      &FORMAT=image/jpeg&WIDTH=1600&HEIGHT=1243

**Georeferencing.** Plate carree (EPSG:4326). Bounds: latitude 33.45 to
34.80 N, longitude -119.30 to -117.20 W. 1600 x 1243 px, so one pixel is
0.0013 deg of longitude by 0.0011 deg of latitude, about 120 m. A point
(lat, lon) sits at

    x = (lon + 119.30) / 2.10 * 1600
    y = (34.80 - lat)  / 1.35 * 1243

The same request with FORMAT=image/tiff returns a GeoTIFF that carries
these bounds in the file.

**Overlays.** Red triangles: ignition points from CAL FIRE's incident
records, Palisades 34.07022 / -118.54453 and Eaton 34.203483 /
-118.069155. White circles: the 22 of HW1's 33 monitoring sites that fall
inside the frame, positioned from the Site Latitude / Site Longitude
columns of the EPA file. Labels and legend drawn with Python PIL.

The companion la-fires-2025-annotated.jpg (session 1) is the same scene
from NASA Earth Observatory, cropped differently, and is not georeferenced.
