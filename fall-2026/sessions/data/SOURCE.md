# Session data — where these files came from

Every file in this folder is a **snapshot**: the bytes a source returned on
the date recorded below, committed unedited so that a session's code produces
the same numbers whenever it is re-run. Nothing here was filtered, sorted, or
reformatted.

---

## `la-weather-dec2024-feb2025.csv` — session 1

**Source:** Open-Meteo historical weather archive (ERA5 reanalysis),
<https://open-meteo.com>. No account or key required.

**Retrieved:** 2026-08-20.

**The exact request:**

```
https://archive-api.open-meteo.com/v1/archive
  ?latitude=34.05&longitude=-118.24
  &start_date=2024-12-01&end_date=2025-02-28
  &daily=wind_gusts_10m_max,wind_speed_10m_max,
         temperature_2m_max,relative_humidity_2m_min,precipitation_sum
  &timezone=America%2FLos_Angeles&format=csv
```

90 daily rows for one model grid cell over downtown Los Angeles (returned
centre 34.0598 N, 118.2375 W, elevation 87 m). The first three lines of the
file describe the location, not the weather — hence `skip = 3`.

Session 1 pulls this live from Open-Meteo and uses this copy only as a
fallback when the network or the API is unavailable.

---

## `epa_pm25_compton_2025.csv` — sessions 4 and 5

**Source:** U.S. EPA AirData, "Download Daily Data" tool,
<https://www.epa.gov/outdoor-air-quality-data/download-daily-data>

**Retrieved:** 2026-08-20. Byte-for-byte what the tool returned.

**The exact selections:**

| Field     | Value                          |
|-----------|--------------------------------|
| Pollutant | PM2.5 (codes 88101 and 88502)  |
| Year      | 2025                           |
| State     | California                     |
| County    | Los Angeles                    |
| Site      | 060371302                      |

662 data rows + header. MD5 `3377ba15fb10d5700a2e5d48bb4e9c1a`.

### The monitor

**Site 06-037-1302 — "Compton"**, 33.9014 N, 118.2050 W. A regulatory
monitor in south Los Angeles County, about 25 km south of where the Eaton
fire burned.

The site runs two instruments, each a distinct **POC** (Parameter Occurrence
Code), and they do not report the same parameter:

| POC | Parameter | Rows in 2025 | What it is                                        |
|-----|-----------|--------------|---------------------------------------------------|
| 1   | 88101     | 301          | FRM/FEM regulatory series — **the one we use**    |
| 3   | 88502     | 354          | Continuous, non-regulatory series                 |
| 3   | 88101     | 7            | A handful of rows reported under the FRM code     |

Parameter 88101 is "PM2.5 – Local Conditions" (regulatory). 88502 is
"Acceptable PM2.5 AQI & Speciation Mass" (non-regulatory). Filtering on POC
alone is not enough — POC 3 appears under both parameter codes, which is why
session 2 filters on `POC == 1 & AQS.Parameter.Code == 88101`.

Over 2025-01-01 to 2025-02-28 that filter gives exactly 59 rows for 59
calendar days: this monitor has no gaps in the window. The monitor HW1 uses
does have gaps — same check, different answer.

### Why this monitor and not HW1's

HW1 uses site 060371103, Los Angeles-North Main Street. Session 2 rehearses
the mechanics on a different monitor so the homework is still work.

### A note on revisions

EPA publishes air quality data twice: **AirNow** in real time and unvalidated,
**AQS** — this source — after the state agency's quality assurance, which can
invalidate readings months later. Re-downloading today may give slightly
different numbers. That is not an error in either copy; it is the archive of
record being corrected. Work from the shipped file.

---

## `epa_pm25_la_county_2025.csv` — session 3

**Source:** U.S. EPA AirData, "Download Daily Data" tool,
<https://www.epa.gov/outdoor-air-quality-data/download-daily-data>

**Retrieved:** 2026-08-27. Byte-for-byte what the tool returned.

**The exact selections:**

| Field     | Value                          |
|-----------|--------------------------------|
| Pollutant | PM2.5 (codes 88101 and 88502)  |
| Year      | 2025                           |
| State     | California                     |
| County    | Los Angeles                    |
| Site      | All Sites                      |

Same tool and same selections as the Compton file above, with the Site field
left on "All Sites". 4,757 data rows + header, the full calendar year.
MD5 `75436f48b70018aeaa90dcaa8710eb5e`.

### The eleven monitors

| Site ID | Local Site Name | Rows | Rows after the FRM filter |
|---------|-----------------|-----:|--------------------------:|
| 060370016 | Glendora | 361 | 0 |
| 060371103 | Los Angeles-North Main Street | 851 | 333 |
| 060371201 | Reseda | 470 | 110 |
| 060371302 | Compton | 662 | 301 |
| 060371602 | Pico Rivera #2 | 119 | 119 |
| 060372005 | Pasadena | 115 | 115 |
| 060374008 | Long Beach-Route 710 Near Road | 682 | 338 |
| 060374009 | Signal Hill (LBSH) | 414 | 57 |
| 060374010 | North Hollywood (NOHO) | 360 | 0 |
| 060376012 | Santa Clarita | 358 | 0 |
| 060379035 | Lancaster - Fairgrounds | 365 | 365 |

"The FRM filter" is `POC == 1 & AQS.Parameter.Code == 88101`, the regulatory
series. On this file it leaves 1,738 rows and exactly 1,738 site-days: no
monitor reports the same day twice.

### Three things in this file that are not mistakes

**The filter deletes three monitors.** Glendora, North Hollywood and Santa
Clarita run continuous non-regulatory instruments only (88502). Filter first
and count sites afterwards and the county quietly loses three monitors.

**The monitors do not run on the same calendar.** Lancaster reports all 365
days; Long Beach, Los Angeles-North Main and Compton report near-daily;
Pico Rivera, Pasadena and Reseda are on a one-day-in-three schedule; Signal
Hill's regulatory series is one day in six. Anything that joins these points
with a straight line is drawing across gaps it cannot see.

**Eight readings are negative,** from −1.2 to −0.1 µg/m³, all at
Lancaster - Fairgrounds. These are real published values, not a corrupted
file. The instrument's zero drifts, and EPA publishes what it measured
rather than rounding up to zero. They are also why `breaks` that start at
0 will fail on this column.

### A note on revisions

The same caution as the Compton file applies: AQS is revised after state
quality assurance, so a re-download may not match these numbers. Work from
the shipped file.
