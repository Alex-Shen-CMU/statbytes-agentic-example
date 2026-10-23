# Best-subset ("full selection") sweep for OLS, ranked by K-fold CV RMSE.
#
# Brand is always in the model. Every other predictor in models.R is optional;
# the fuel factor enters or leaves as a single predictor (all of its indicators
# together). With 8 optional predictors there are 2^8 = 256 candidate models,
# indexed 1..256 by ols_model_grid(). Each model can be fitted independently
# (e.g. one slurm array task per model) and the results combined afterwards.

source("R/clean_data.R")
source("R/cv.R")
source("R/models.R")

always_vars <- "brand"
optional_vars <- setdiff(c(continuous_vars, other_vars), always_vars)

# One row per candidate model, one logical column per optional predictor.
# Row 1 is brand only; the last row is the full model.
ols_model_grid <- function(vars = optional_vars) {
  grid <- expand.grid(rep(list(c(FALSE, TRUE)), length(vars)))
  names(grid) <- vars
  grid
}

# OLS fitter on brand plus the given optional predictors.
fit_ols_vars <- function(vars) {
  f <- reformulate(c(always_vars, vars), response = "log_price")
  function(train) {
    fit <- lm(f, data = add_features(train))
    structure(function(newdata) unname(predict(fit, add_features(newdata))),
              fit = fit)
  }
}

# CV RMSE of model `id` in the grid. Returns a one-row data frame in the
# output table format: model id, RMSE, then one logical column per predictor.
# Folds depend only on the data and seed, so every model sees the same folds.
run_ols_model <- function(id, data = clean_cars(), K = 5, seed = 1) {
  grid <- ols_model_grid()
  included <- grid[id, , drop = FALSE]
  folds <- make_folds(nrow(data), K, strata = data$brand, seed = seed)
  cv <- cv_rmse(data, folds, fit_ols_vars(optional_vars[unlist(included)]))
  cbind(model = id, rmse = cv$rmse, included, row.names = NULL)
}

# Stack per-model result files and sort by RMSE (best first).
combine_ols_results <- function(files) {
  res <- do.call(rbind, lapply(files, read.csv))
  n_total <- nrow(ols_model_grid())
  if (nrow(res) < n_total) {
    warning(sprintf("only %d of %d models present", nrow(res), n_total))
  }
  res <- res[order(res$rmse), ]
  rownames(res) <- NULL
  res
}
