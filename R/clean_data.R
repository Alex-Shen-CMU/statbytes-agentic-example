# Data cleaning for the cars dataset.
#
# Raw columns are free-text strings ("$12,000-$15,000", "70 - 85 hp",
# "1,600 cc / 13.8 kwh", ...). Every numeric field is parsed by extracting all
# numbers in the string and averaging them, so ranges ("a - b") and
# alternatives ("a / b") both resolve to their midpoint.

# Mean of all numbers appearing in each string; NA if none.
parse_midpoint <- function(x) {
  x <- gsub(",", "", x)
  nums <- regmatches(x, gregexpr("[0-9]+(\\.[0-9]+)?", x))
  vapply(nums, function(v) if (length(v)) mean(as.numeric(v)) else NA_real_,
         numeric(1))
}

# Mean of numbers immediately followed by `unit` (case-insensitive); NA if none.
parse_unit_midpoint <- function(x, unit) {
  x <- gsub(",", "", x)
  pat <- paste0("[0-9]+(\\.[0-9]+)?(?=\\s*", unit, ")")
  nums <- regmatches(x, gregexpr(pat, x, perl = TRUE, ignore.case = TRUE))
  vapply(nums, function(v) if (length(v)) mean(as.numeric(v)) else NA_real_,
         numeric(1))
}

# Collapse the ~20 raw fuel labels into four categories. Hydrogen (fuel-cell,
# electric drive) counts as Electric and CNG/Petrol as Petrol; both are too
# rare (4 cars) to estimate as their own level.
clean_fuel <- function(x) {
  x <- tolower(x)
  out <- ifelse(x %in% c("electric", "hydrogen"), "Electric",
         ifelse(grepl("hybrid|\\bev\\b|electric", x), "Hybrid",
         ifelse(x == "diesel", "Diesel", "Petrol")))
  factor(out, levels = c("Petrol", "Diesel", "Hybrid", "Electric"))
}

# Normalise brand spelling/case and lump brands with < min_n cars into "Other".
clean_brand <- function(x, min_n = 10) {
  x <- tools::toTitleCase(tolower(trimws(x)))
  counts <- table(x)
  x[x %in% names(counts)[counts < min_n]] <- "Other"
  factor(x)
}

# Read and clean the raw CSV. Returns one row per car with log price and
# numeric/factor predictors; rows with unparseable price, non-USD price, or
# missing predictors are dropped.
clean_cars <- function(path = file.path("data", "Cars Datasets 2025.csv"),
                       min_brand_n = 10) {
  raw <- read.csv(path, check.names = FALSE, fileEncoding = "latin1",
                  stringsAsFactors = FALSE)

  price_raw <- raw[["Cars Prices"]]
  usd <- grepl("$", price_raw, fixed = TRUE)
  seats_raw <- sub("^\\s*2\\+2\\s*$", "4", raw$Seats)

  engine_raw <- raw[["CC/Battery Capacity"]]
  engine_cc <- parse_unit_midpoint(engine_raw, "cc")
  battery_kwh <- parse_unit_midpoint(engine_raw, "kwh")

  d <- data.frame(
    brand        = raw[["Company Names"]],
    model        = trimws(raw[["Cars Names"]]),
    price        = ifelse(usd, parse_midpoint(price_raw), NA_real_),
    horsepower   = parse_midpoint(raw$HorsePower),
    top_speed    = parse_midpoint(raw[["Total Speed"]]),
    accel_0_100  = parse_midpoint(raw[["Performance(0 - 100 )KM/H"]]),
    torque       = parse_midpoint(raw$Torque),
    seats        = parse_midpoint(seats_raw),
    # Pure EVs have no displacement and combustion cars no battery: encode as 0.
    engine_cc    = ifelse(is.na(engine_cc) & !is.na(battery_kwh), 0, engine_cc),
    battery_kwh  = ifelse(is.na(battery_kwh), 0, battery_kwh),
    fuel         = clean_fuel(raw[["Fuel Types"]]),
    stringsAsFactors = FALSE
  )
  d$brand <- clean_brand(d$brand, min_n = min_brand_n)

  d <- d[complete.cases(d) & d$price > 0, ]
  d$log_price <- log(d$price)
  rownames(d) <- NULL
  d
}
