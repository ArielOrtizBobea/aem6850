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
| 1870s | 1877 | sep | 2.55 | 2.65 | data_clean/crops/1870s_1877_sep.png |
| 1880s | 1882 | jun | 3.91 | 3.01 | data_clean/crops/1880s_1882_jun.png |
| 1880s | 1882 | total | 38.14 | 38.24 | data_clean/crops/1880s_1882_total.png |
| 1880s | 1884 | mar | 2.51 | 2.57 | data_clean/crops/1880s_1884_mar.png |
| 1880s | 1886 | mar | 3.84 | 5.84 | data_clean/crops/1880s_1886_mar.png |
| 1880s | 1886 | dec | 6.95 | 6.96 | data_clean/crops/1880s_1886_dec.png |
| 1880s | 1888 | oct | 2.42 | 2.12 | data_clean/crops/1880s_1888_oct.png |

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
| 1880s | 1886 | jun | FALSE | 2.82 | data_clean/crops/1880s_1886_jun.png |
| 1880s | 1886 | jul | FALSE | 2.82 | data_clean/crops/1880s_1886_jul.png |
| 1880s | 1887 | jan | FALSE | 4.57 | data_clean/crops/1880s_1887_jan.png |
| 1880s | 1887 | feb | TRUE | 4.57 | data_clean/crops/1880s_1887_feb.png |
| 1890s | 1892 | jan | FALSE | 0.00 | data_clean/crops/1890s_1892_jan.png |
| 1890s | 1892 | feb | FALSE | 0.00 | data_clean/crops/1890s_1892_feb.png |
| 1890s | 1892 | mar | FALSE | 0.00 | data_clean/crops/1890s_1892_mar.png |
| 1890s | 1892 | apr | FALSE | 0.00 | data_clean/crops/1890s_1892_apr.png |
| 1890s | 1892 | may | FALSE | 0.00 | data_clean/crops/1890s_1892_may.png |
| 1890s | 1892 | jun | FALSE | 0.00 | data_clean/crops/1890s_1892_jun.png |
| 1890s | 1892 | jul | FALSE | 0.00 | data_clean/crops/1890s_1892_jul.png |
| 1890s | 1892 | aug | FALSE | 0.00 | data_clean/crops/1890s_1892_aug.png |
| 1890s | 1892 | sep | FALSE | 0.00 | data_clean/crops/1890s_1892_sep.png |
| 1890s | 1892 | oct | FALSE | 0.00 | data_clean/crops/1890s_1892_oct.png |
| 1890s | 1892 | nov | FALSE | 0.00 | data_clean/crops/1890s_1892_nov.png |
| 1890s | 1892 | dec | FALSE | 0.00 | data_clean/crops/1890s_1892_dec.png |
| 1890s | 1892 | total | FALSE | 0.00 | data_clean/crops/1890s_1892_total.png |

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
| 1880s | 1886 | jun | FALSE | 2.82 | data_clean/crops/1880s_1886_jun.png |
| 1880s | 1886 | jul | FALSE | 2.82 | data_clean/crops/1880s_1886_jul.png |
| 1880s | 1887 | jan | FALSE | 4.57 | data_clean/crops/1880s_1887_jan.png |
| 1880s | 1887 | feb | TRUE | 4.57 | data_clean/crops/1880s_1887_feb.png |
| 1910s | 1912 | total | FALSE | -1.00 | data_clean/crops/1910s_1912_total.png |
| 1910s | 1913 | total | FALSE | -1.00 | data_clean/crops/1910s_1913_total.png |
| 1910s | 1917 | total | FALSE | -1.00 | data_clean/crops/1910s_1917_total.png |

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

Prices: USD 2 per million input tokens, USD 10 per million output tokens (the provider's list, 29 Oct 2026).

| sheet | run | seconds | input_tokens | output_tokens | cost |
|---|---|---|---|---|---|
| 1860s | 1 | 39.4000 | 1625 | 113 | 0.0044 |
| 1860s | 2 | 2.3000 | 1625 | 113 | 0.0044 |
| 1870s | 1 | 14.1000 | 1611 | 2443 | 0.0277 |
| 1870s | 2 | 14.2000 | 1611 | 2400 | 0.0272 |
| 1880s | 1 | 6.5000 | 1611 | 1094 | 0.0142 |
| 1880s | 2 | 6.0000 | 1611 | 1094 | 0.0142 |
| 1890s | 1 | 2.7000 | 1650 | 278 | 0.0061 |
| 1890s | 2 | 2.8000 | 1650 | 354 | 0.0068 |
| 1910s | 1 | 4.7000 | 1611 | 500 | 0.0082 |
| 1910s | 2 | 3.1000 | 1611 | 482 | 0.0080 |

Per sheet (both runs):

| sheet | seconds | input_tokens | output_tokens | cost |
|---|---|---|---|---|
| 1860s | 41.7000 | 3250.0000 | 226.0000 | 0.0088 |
| 1870s | 28.3000 | 3222.0000 | 4843.0000 | 0.0549 |
| 1880s | 12.5000 | 3222.0000 | 2188.0000 | 0.0283 |
| 1890s | 5.5000 | 3300.0000 | 632.0000 | 0.0129 |
| 1910s | 7.8000 | 3222.0000 | 982.0000 | 0.0163 |

All ten calls: 95.8 s, 16216 input tokens, 8871 output tokens, USD 0.1211. Mean per call: 9.6 s, USD 0.0121.

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

